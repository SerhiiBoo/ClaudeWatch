import AppKit
import Foundation

/// Launches terminal apps and editors with an optional working directory.
///
/// Shell-command-building logic lives here, not in the settings model.
enum TerminalLauncher {

    /// Opens `path` in the given terminal `app`, running `claude` for terminal
    /// apps or just opening the folder for editor apps.
    ///
    /// - Parameters:
    ///   - path: Working directory to open. Pass an empty string to use the
    ///           app's default location.
    ///   - app: The `TerminalApp` to launch.
    static func open(path: String, app: TerminalApp) {
        guard let command = shellLaunchCommand(for: app, directory: path) else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        do {
            try process.run()
        } catch {
            let displayName = app.displayName
            guard !displayName.isEmpty else {
                LogService.log(
                    .error,
                    category: "TerminalLauncher",
                    "Primary launch failed and terminal display name is empty; cannot fall back",
                    details: ["error": "\(error)"]
                )
                return
            }
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            fallback.arguments = ["-a", displayName]
            do {
                try fallback.run()
            } catch let fallbackError {
                LogService.log(
                    .error,
                    category: "TerminalLauncher",
                    "Fallback launch of '\(displayName)' also failed",
                    details: ["error": "\(fallbackError)"]
                )
            }
        }
    }

    // MARK: - Hook notification activation

    /// Resolves a running GUI app by bundleId first, then pid. Returns nil if neither matches.
    static func resolveApp(bundleId: String?, pid: pid_t?) -> NSRunningApplication? {
        if let bundleId, !bundleId.isEmpty,
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first {
            return app
        }
        if let pid, pid > 0 {
            return NSRunningApplication(processIdentifier: pid)
        }
        return nil
    }

    /// Activates the app with the given PID. Returns true on success.
    @discardableResult
    static func activate(pid: pid_t?) -> Bool {
        guard let pid, pid > 0 else { return false }
        guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
        return performActivation(app, context: "pid:\(pid)")
    }

    /// Activates the frontmost instance of the app with the given bundle ID. Returns true on success.
    @discardableResult
    static func activate(bundleId: String?) -> Bool {
        guard let bundleId, !bundleId.isEmpty else { return false }
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first else { return false }
        return performActivation(app, context: bundleId)
    }

    @discardableResult
    private static func performActivation(_ app: NSRunningApplication, context: String) -> Bool {
        NSApp.deactivate()
        let ok = app.activate(options: [.activateAllWindows])
        if !ok {
            LogService.log(.warning, category: "TerminalLauncher", "activate returned false", details: ["context": context])
        }
        return ok
    }

    // MARK: - Shell command building

    /// Builds a shell command string for launching `app`, optionally in
    /// `directory`. Returns `nil` when the directory path contains unsafe
    /// characters.
    static func shellLaunchCommand(for app: TerminalApp, directory: String = "") -> String? {
        let dir = directory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard dir.isEmpty || validateDirectoryPath(dir) else { return nil }
        let safeDir = shellEscape(dir)

        switch app {

        // ── Terminals with native AppleScript support ────────────
        case .terminal:
            guard let cmd = claudeCommand(directory: dir) else { return nil }
            let escaped = appleScriptEscape(cmd)
            return """
            osascript -e 'tell application "Terminal"' -e 'activate' -e 'do script "\(escaped)"' -e 'end tell'
            """

        case .iterm:
            guard let cmd = claudeCommand(directory: dir) else { return nil }
            let escaped = appleScriptEscape(cmd)
            return """
            osascript -e 'tell application "iTerm"' -e 'activate' -e 'create window with default profile command "\(escaped)"' -e 'end tell'
            """

        // ── Terminals with CLI support ───────────────────────────
        case .kitty:
            var args = "kitty --single-instance"
            if !dir.isEmpty { args += " -d \(safeDir)" }
            args += " sh -c claude"
            return args

        case .alacritty:
            var args = "alacritty"
            if !dir.isEmpty { args += " --working-directory \(safeDir)" }
            args += " -e claude"
            return args

        case .ghostty:
            var args = "ghostty"
            if !dir.isEmpty { args += " --working-directory=\(safeDir)" }
            args += " -e claude"
            return args

        case .warp:
            if dir.isEmpty {
                return "open -a 'Warp'"
            }
            guard let cmd = claudeCommand(directory: dir) else { return nil }
            let warpEscaped = appleScriptEscape(cmd)
            return """
            open -a 'Warp' && sleep 0.5 && osascript -e 'tell application "System Events"' -e 'keystroke "\(warpEscaped)"' -e 'key code 36' -e 'end tell'
            """

        case .hyper:
            if dir.isEmpty {
                return "open -a 'Hyper'"
            }
            guard let cmd = claudeCommand(directory: dir) else { return nil }
            let hyperEscaped = appleScriptEscape(cmd)
            return """
            open -a 'Hyper' && sleep 0.5 && osascript -e 'tell application "System Events"' -e 'keystroke "\(hyperEscaped)"' -e 'key code 36' -e 'end tell'
            """

        // ── Editors & IDEs ───────────────────────────────────────
        case .vscode, .cursor, .zed, .phpstorm, .windsurf:
            let bundleName = bundleAppName(for: app)
            if dir.isEmpty {
                return "open -a '\(appleScriptEscape(bundleName))'"
            }
            return "open -a '\(appleScriptEscape(bundleName))' \(safeDir)"
        }
    }

    // MARK: - Private helpers

    /// Returns `true` when `path` contains only characters that are safe for
    /// shell and AppleScript embedding. Rejects any character not in the
    /// allowlist `^[A-Za-z0-9/_. ~-]+$` to prevent shell injection.
    private static func validateDirectoryPath(_ path: String) -> Bool {
        guard !path.isEmpty else { return false }
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/_. ~-")
        return path.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    /// Build the command string: `cd <dir> && claude` or just `claude`.
    /// Returns `nil` if the directory path is invalid.
    private static func claudeCommand(directory: String) -> String? {
        let dir = directory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dir.isEmpty else { return "claude" }
        guard validateDirectoryPath(dir) else { return nil }
        return "cd \(shellEscape(dir)) && claude"
    }

    /// Escape a string for safe embedding in a single-quoted shell argument.
    private static func shellEscape(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Escape a string for safe embedding inside an AppleScript double-quoted string.
    /// Strips control characters and backticks (which have AppleScript evaluation
    /// semantics), then escapes backslash and double-quote.
    private static func appleScriptEscape(_ value: String) -> String {
        let stripped = value.unicodeScalars
            .filter { $0.value >= 0x20 && $0.value != 0x7F && $0 != "`" }
            .reduce(into: "") { $0.append(Character($1)) }
        return stripped
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// The bundle identifier or app name used with `open -a`.
    private static func bundleAppName(for app: TerminalApp) -> String {
        switch app {
        case .vscode: return "Visual Studio Code"
        case .kitty:  return "kitty"
        default:      return app.rawValue
        }
    }
}
