import Foundation
import os.log

private let logger = Logger(subsystem: "io.github.SerhiiBoo.ClaudeWatch", category: "UsageHistory")

/// Minimum pace (%/h) considered meaningful for ETA calculations.
let minimumMeaningfulPacePerHour: Double = 0.5

/// Stores periodic usage snapshots for sparkline display and streak tracking.
/// Data persisted as JSON in Application Support.
struct UsageSnapshot: Codable, Equatable {
    let timestamp: Date
    let sessionUsed: Double      // 0-100
    let weeklyUsed: Double       // 0-100
    let sonnetUsed: Double?
    let opusUsed: Double?
}

struct UsageHistoryService {
    private static let maxSnapshots = 168  // ~7 days at 1/hour
    private static let fileName = "usage_history.json"

    /// Serial queue protecting all mutable static state.
    private static let queue = DispatchQueue(label: "io.github.SerhiiBoo.ClaudeWatch.UsageHistoryService")

    // Lazy one-time directory creation; avoids I/O on every access.
    private static let fileURL: URL? = {
        guard let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            logger.error("Application Support directory unavailable")
            LogService.error("UsageHistory", "Application Support directory unavailable")
            return nil
        }
        let dir = base.appendingPathComponent("Claude Watch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }()

    /// In-memory cache to avoid repeated file reads during a single render pass.
    private static var cachedSnapshots: [UsageSnapshot]?
    private static var cacheTimestamp: Date?

    /// Optional history provider. When set, `recent()` returns this instead of reading disk.
    static var historyOverride: (() -> [UsageSnapshot])? = nil

    static func load() -> [UsageSnapshot] {
        queue.sync { loadUnsafe() }
    }

    /// Must only be called from within `queue`. Reads disk and updates the in-memory cache.
    private static func loadUnsafe() -> [UsageSnapshot] {
        // Return cache if fresh (< 5s old) to avoid redundant disk reads
        if let cached = cachedSnapshots,
           let ts = cacheTimestamp,
           -ts.timeIntervalSinceNow < 5 {
            return cached
        }
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let snapshots = try? JSONDecoder().decode([UsageSnapshot].self, from: data) else {
            return []
        }
        cachedSnapshots = snapshots
        cacheTimestamp = Date()
        return snapshots
    }

    static func record(_ usage: UsageData) {
        let snap = UsageSnapshot(
            timestamp: usage.fetchedAt,
            sessionUsed: 100 - usage.sessionRemaining,
            weeklyUsed: 100 - usage.weeklyRemaining,
            sonnetUsed: usage.sonnetRemaining.map { 100 - $0 },
            opusUsed: usage.opusRemaining.map { 100 - $0 }
        )
        queue.sync {
            var history = loadUnsafe()
            // Deduplicate: skip if last snapshot is less than 5 minutes old
            if let last = history.last,
               snap.timestamp.timeIntervalSince(last.timestamp) < 300 {
                return
            }
            history.append(snap)
            if history.count > maxSnapshots {
                history = Array(history.suffix(maxSnapshots))
            }
            guard let fileURL else { return }
            do {
                let data = try JSONEncoder().encode(history)
                try data.write(to: fileURL, options: .atomic)
                // Invalidate cache so next load() picks up the new data
                cachedSnapshots = history
                cacheTimestamp = Date()
            } catch {
                logger.error("Failed to write usage history: \(error.localizedDescription)")
                LogService.error("UsageHistory", "Failed to write usage history", error: error)
            }
        }
    }

    /// Returns snapshots from the last N hours (configurable via settings)
    static func recent(hours: Int? = nil) -> [UsageSnapshot] {
        let overrideFn: (() -> [UsageSnapshot])? = queue.sync { historyOverride }
        if let override = overrideFn { return override() }
        let h = hours ?? AppSettings.sparklineHours
        let cutoff = Date().addingTimeInterval(-Double(h) * 3600)
        return load().filter { $0.timestamp >= cutoff }
    }

    // MARK: - Streak

    /// Number of consecutive calendar days with at least one snapshot
    static func currentStreak() -> Int {
        let history = load()
        guard !history.isEmpty else { return 0 }

        let cal = Calendar.current

        func dayKey(from date: Date) -> DateComponents {
            cal.dateComponents([.year, .month, .day], from: date)
        }

        var seen = Set<DateComponents>()
        for snap in history {
            seen.insert(dayKey(from: snap.timestamp))
        }

        let todayDC = dayKey(from: Date())
        let hasToday = seen.contains(todayDC)

        var streak = 0
        var checkDate = hasToday ? Date() : cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        for _ in 0..<365 {
            let dc = dayKey(from: checkDate)
            if seen.contains(dc) {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Pace

    /// Usage rate: change in the given metric per hour over configurable window.
    /// Pass a keyPath to select which metric (sessionUsed, weeklyUsed, etc.).
    static func pacePerHour(for keyPath: KeyPath<UsageSnapshot, Double>) -> Double? {
        let windowHours = AppSettings.paceWindowHours
        let snapshots = recent(hours: Int(ceil(windowHours)))
        guard let oldest = snapshots.first, let newest = snapshots.last,
              snapshots.count >= 2 else { return nil }
        let hours = newest.timestamp.timeIntervalSince(oldest.timestamp) / 3600
        guard hours > 0.05 else { return nil }
        return (newest[keyPath: keyPath] - oldest[keyPath: keyPath]) / hours
    }

    /// Usage rate for optional metrics (sonnetUsed, opusUsed).
    static func pacePerHour(forOptional keyPath: KeyPath<UsageSnapshot, Double?>) -> Double? {
        let windowHours = AppSettings.paceWindowHours
        let snapshots = recent(hours: Int(ceil(windowHours)))
        guard let oldest = snapshots.first, let newest = snapshots.last,
              snapshots.count >= 2 else { return nil }
        guard let oldVal = oldest[keyPath: keyPath],
              let newVal = newest[keyPath: keyPath] else { return nil }
        let hours = newest.timestamp.timeIntervalSince(oldest.timestamp) / 3600
        guard hours > 0.05 else { return nil }
        return (newVal - oldVal) / hours
    }

    /// Convenience: session pace per hour (most commonly used).
    static func sessionPacePerHour() -> Double? {
        pacePerHour(for: \.sessionUsed)
    }

    /// Estimated time in hours until a limit is reached, based on pace for the given metric.
    static func estimatedHoursUntilEmpty(
        currentRemaining: Double,
        keyPath: KeyPath<UsageSnapshot, Double>
    ) -> Double? {
        guard let pace = pacePerHour(for: keyPath), pace > minimumMeaningfulPacePerHour else { return nil }
        return currentRemaining / pace
    }

    /// Convenience: session-specific ETA.
    static func estimatedHoursUntilSessionEmpty(currentRemaining: Double) -> Double? {
        estimatedHoursUntilEmpty(currentRemaining: currentRemaining, keyPath: \.sessionUsed)
    }
}
