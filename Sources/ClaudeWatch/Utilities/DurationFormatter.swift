import Foundation

/// Centralised duration-formatting helpers used across views and services.
///
/// All call sites should use these functions so the displayed strings are
/// consistent throughout the app.
enum DurationFormatter {

    // MARK: - "2h 15m" style (from a TimeInterval in seconds)

    /// Returns a compact days/hours/minutes string from a `TimeInterval` in seconds.
    ///
    /// Examples: `"3d 2h"`, `"1h 45m"`, `"30m"`, `"now"` (when ≤ 0).
    static func hoursMinutes(from seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "now" }
        let total   = Int(seconds)
        let days    = total / 86_400
        let hours   = (total % 86_400) / 3_600
        let minutes = (total % 3_600) / 60

        if days  > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    // MARK: - Countdown with seconds resolution (rate-limit banner)

    /// Returns a compact countdown string including seconds when under an hour.
    ///
    /// Examples: `"1h 5m"`, `"4m 30s"`, `"45s"`.
    static func countdownWithSeconds(from seconds: TimeInterval) -> String {
        let t = max(0, Int(seconds))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    // MARK: - "in 2h 15m" style (from a Date)

    /// Returns a string like `"in 1h 30m"` for time remaining until `date`.
    /// Returns `"now"` when the date is in the past.
    static func countdown(to date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return "now" }
        return "in \(hoursMinutes(from: interval))"
    }

    // MARK: - Short form (hours-based input, from estimate functions)

    /// Returns a short label from a duration given in *hours*.
    ///
    /// Examples: `"2d"`, `"1.5h"`, `"45m"`.
    static func short(hours: Double) -> String {
        if hours >= 24 { return "\(Int(hours / 24))d" }
        if hours >= 1  { return String(format: "%.1fh", hours) }
        return "\(Int(hours * 60))m"
    }

    /// Returns a rounded short label from a duration given in *hours* (no decimal).
    ///
    /// Examples: `"2d"`, `"2h"`, `"45m"`.
    static func shortRounded(hours: Double) -> String {
        if hours >= 24 { return "\(Int(hours / 24))d" }
        if hours >= 1  { return String(format: "%.0fh", hours) }
        return "\(max(1, Int(hours * 60)))m"
    }

    /// Returns a verbose label from a duration given in *hours*.
    ///
    /// Examples: `"2 days"`, `"1.5 hours"`, `"45 minutes"`.
    static func verbose(hours: Double) -> String {
        if hours >= 24 { return "\(Int(hours / 24)) days" }
        if hours >= 1  { return String(format: "%.1f hours", hours) }
        return "\(Int(hours * 60)) minutes"
    }
}
