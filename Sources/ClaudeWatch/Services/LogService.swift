import Foundation
import os.log

/// Persistent file-based logging for error diagnostics.
/// Logs are stored in `~/Library/Application Support/Claude Watch/logs/`.
///
/// Log format (designed for paste-into-chat debugging):
/// ```
/// [2026-03-25T14:30:00.123Z] ERROR APIService | Decoding failed
///   error: The data couldn't be read because it is missing.
///   raw: {"unexpected":"json"}
/// ```
///
/// - Automatic size-based rotation: when the active log exceeds `maxFileSize`,
///   it is archived and a fresh file starts. Only one archive is kept.
/// - On launch, `pruneIfNeeded()` enforces these limits.
/// - Users can retrieve logs via "Copy Logs" or "Export Logs" in Settings.
struct LogService {
    enum Level: String {
        case info    = "INFO "
        case warning = "WARN "
        case error   = "ERROR"
    }

    // MARK: - Configuration

    private static let maxFileSize: UInt64 = 500_000      // ~500 KB
    private static let activeFileName = "claudewatch.log"
    private static let archiveFileName = "claudewatch.1.log"

    private static let osLogger = Logger(
        subsystem: "io.github.SerhiiBoo.ClaudeWatch",
        category: "LogService"
    )

    // MARK: - Directory

    private static let logsDirectory: URL? = {
        guard let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return nil }
        let dir = base
            .appendingPathComponent("Claude Watch", isDirectory: true)
            .appendingPathComponent("logs", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            osLogger.error("logsDirectory: failed to create logs directory: \(error.localizedDescription)")
            return nil
        }
        return dir
    }()

    private static var activeFileURL: URL? {
        logsDirectory?.appendingPathComponent(activeFileName)
    }

    private static var archiveFileURL: URL? {
        logsDirectory?.appendingPathComponent(archiveFileName)
    }

    // MARK: - Public API

    /// Write a structured log entry to disk. Thread-safe via a serial queue.
    ///
    /// - Parameters:
    ///   - level: Severity level.
    ///   - category: Source component (e.g. "APIService", "ViewModel").
    ///   - message: Human-readable summary of what happened.
    ///   - details: Key-value pairs with structured context for debugging.
    static func log(
        _ level: Level,
        category: String,
        _ message: String,
        details: [String: String] = [:]
    ) {
        queue.async {
            writeEntry(level: level, category: category, message: message, details: details)
        }
    }

    /// Log an error with optional structured context.
    static func error(
        _ category: String,
        _ message: String,
        error: Error? = nil,
        details: [String: String] = [:]
    ) {
        var allDetails = details
        if let error {
            allDetails["error"] = error.localizedDescription
            allDetails["type"] = String(describing: type(of: error))
        }
        log(.error, category: category, message, details: allDetails)
    }

    /// Log a warning with optional structured context.
    static func warning(
        _ category: String,
        _ message: String,
        details: [String: String] = [:]
    ) {
        log(.warning, category: category, message, details: details)
    }

    /// Log an informational message.
    static func info(_ category: String, _ message: String) {
        log(.info, category: category, message)
    }

    /// Remove stale archives and rotate if the active log is oversized.
    /// Call once at app launch.
    static func pruneIfNeeded() {
        queue.async {
            rotateIfNeeded()
        }
    }

    /// Returns all logs prefixed with a system-info header for debugging.
    /// Newest entries first. Returns nil if no logs exist.
    static func allLogs() -> String? {
        guard logsDirectory != nil else { return nil }
        var parts: [String] = []

        // Active log (most recent)
        if let active = activeFileURL,
           let data = try? String(contentsOf: active, encoding: .utf8),
           !data.isEmpty {
            parts.append(data)
        }

        // Archive
        if let archive = archiveFileURL,
           let data = try? String(contentsOf: archive, encoding: .utf8),
           !data.isEmpty {
            parts.append("--- archived log ---\n" + data)
        }

        guard !parts.isEmpty else { return nil }

        let header = systemInfoHeader()
        return header + parts.joined(separator: "\n")
    }

    /// Total size on disk of all log files in bytes.
    static func totalSize() -> UInt64 {
        let fm = FileManager.default
        return [activeFileURL, archiveFileURL]
            .compactMap { $0 }
            .reduce(into: UInt64(0)) { total, url in
                total += (try? fm.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0
            }
    }

    /// Delete all log files.
    static func clearAll() {
        queue.async {
            let fm = FileManager.default
            for url in [activeFileURL, archiveFileURL].compactMap({ $0 }) {
                do {
                    try fm.removeItem(at: url)
                } catch {
                    osLogger.error("clearAll: failed to remove \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Internal

    private static let queue = DispatchQueue(label: "io.github.SerhiiBoo.ClaudeWatch.LogService")

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Format:
    /// ```
    /// [2026-03-25T14:30:00.123Z] ERROR APIService | Decoding failed
    ///   error: The data couldn't be read because it is missing.
    ///   raw: {"unexpected":"json"}
    /// ```
    private static func writeEntry(
        level: Level,
        category: String,
        message: String,
        details: [String: String] = [:]
    ) {
        guard let fileURL = activeFileURL else { return }

        let timestamp = dateFormatter.string(from: Date())
        var line = "[\(timestamp)] \(level.rawValue) \(category) | \(message)\n"

        // Append structured key-value details indented under the main line
        for (key, value) in details.sorted(by: { $0.key < $1.key }) {
            line += "  \(key): \(value)\n"
        }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let handle = try FileHandle(forWritingTo: fileURL)
                handle.seekToEndOfFile()
                handle.write(Data(line.utf8))
                handle.closeFile()
            } catch {
                osLogger.error("writeEntry: failed to open log file for writing: \(error.localizedDescription)")
                return
            }
        } else {
            do {
                try Data(line.utf8).write(to: fileURL, options: .atomic)
            } catch {
                osLogger.error("writeEntry: failed to create log file: \(error.localizedDescription)")
                return
            }
        }

        rotateIfNeeded()
    }

    private static func rotateIfNeeded() {
        guard let activeURL = activeFileURL,
              let archiveURL = archiveFileURL else { return }

        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: activeURL.path),
              let size = attrs[.size] as? UInt64,
              size >= maxFileSize else { return }

        do { try fm.removeItem(at: archiveURL) } catch {
            // Ignore "file not found" — archive simply doesn't exist yet
            if (error as NSError).code != NSFileNoSuchFileError {
                osLogger.error("rotateIfNeeded: failed to remove archive: \(error.localizedDescription)")
            }
        }
        do {
            try fm.moveItem(at: activeURL, to: archiveURL)
        } catch {
            osLogger.error("rotateIfNeeded: failed to rotate log file: \(error.localizedDescription)")
        }
    }

    /// Header block included when exporting logs for debugging.
    private static func systemInfoHeader() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        let now = dateFormatter.string(from: Date())
        return """
        === Claude Watch Diagnostic Log ===
        app_version: \(version) (\(build))
        macos: \(os)
        exported_at: \(now)
        ==================================

        """
    }
}
