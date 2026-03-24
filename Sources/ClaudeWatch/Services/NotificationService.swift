import Foundation
import UserNotifications

/// Describes a single usage window for notification checking.
private struct UsageWindow {
    let name: String
    let used: Double           // 0-100
    let remaining: Double      // 0-100
    let resetsAt: Date
    let pacePerHour: Double?   // %/h, nil if insufficient data
    let etaHours: Double?      // hours until limit, nil if pace too low
}

/// Sends macOS notifications when usage crosses configurable thresholds,
/// when limits are reached (100%), and when windows reset.
struct NotificationService {
    private static let notifiedKey = "notifiedThresholds"

    static func setup() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                LogService.error("Notifications", "Authorization failed", error: error)
            }
            if !granted {
                LogService.warning("Notifications", "Permission denied by user")
            }
        }
    }

    /// Check usage and fire notifications for newly crossed thresholds,
    /// limit reached (100%), and window resets.
    /// Pass previousUsage to detect resets (usage dropping from high to low).
    static func checkThresholds(usage: UsageData, previousUsage: UsageData?) {
        guard AppSettings.notificationsEnabled else { return }

        let windows = buildWindows(from: usage)
        let previousWindows = previousUsage.map { buildWindows(from: $0) }

        var notified = Set(UserDefaults.standard.stringArray(forKey: notifiedKey) ?? [])

        // 1. Threshold notifications (enriched with pace, ETA, reset time)
        let thresholds = AppSettings.notificationThresholds
        for threshold in thresholds {
            for window in windows {
                let key = "\(window.name.lowercased())-\(Int(threshold))"
                if window.used >= threshold && !notified.contains(key) {
                    notified.insert(key)
                    sendThresholdNotification(window: window, threshold: threshold)
                }
                if window.used < threshold {
                    notified.remove(key)
                }
            }
        }

        // 2. Limit reached notifications (usage >= 99.5%, treated as 100%)
        for window in windows {
            let limitKey = "\(window.name.lowercased())-limit-reached"
            if window.used >= 99.5 && !notified.contains(limitKey) {
                notified.insert(limitKey)
                sendLimitReachedNotification(window: window)
            }
            if window.used < 99.5 {
                notified.remove(limitKey)
            }
        }

        // 3. Reset notifications (usage was >=30% and dropped significantly)
        if let prev = previousWindows {
            for window in windows {
                let resetKey = "\(window.name.lowercased())-reset"
                let prevWindow = prev.first { $0.name == window.name }
                if let pw = prevWindow,
                   pw.used >= 30,
                   window.used < pw.used - 20,
                   !notified.contains(resetKey) {
                    notified.insert(resetKey)
                    sendResetNotification(window: window)
                }
                // Allow re-triggering once usage climbs back above 30%
                if window.used >= 30 {
                    notified.remove(resetKey)
                }
            }
        }

        UserDefaults.standard.set(Array(notified), forKey: notifiedKey)
    }

    // MARK: - Window construction

    private static func buildWindows(from usage: UsageData) -> [UsageWindow] {
        var windows: [UsageWindow] = [
            UsageWindow(
                name: "Session",
                used: 100 - usage.sessionRemaining,
                remaining: usage.sessionRemaining,
                resetsAt: usage.sessionResetsAt,
                pacePerHour: UsageHistoryService.pacePerHour(for: \.sessionUsed),
                etaHours: UsageHistoryService.estimatedHoursUntilEmpty(
                    currentRemaining: usage.sessionRemaining, keyPath: \.sessionUsed
                )
            ),
            UsageWindow(
                name: "Weekly",
                used: 100 - usage.weeklyRemaining,
                remaining: usage.weeklyRemaining,
                resetsAt: usage.weeklyResetsAt,
                pacePerHour: UsageHistoryService.pacePerHour(for: \.weeklyUsed),
                etaHours: UsageHistoryService.estimatedHoursUntilEmpty(
                    currentRemaining: usage.weeklyRemaining, keyPath: \.weeklyUsed
                )
            ),
        ]
        if let sr = usage.sonnetRemaining, let sra = usage.sonnetResetsAt {
            windows.append(UsageWindow(
                name: "Sonnet",
                used: 100 - sr,
                remaining: sr,
                resetsAt: sra,
                pacePerHour: UsageHistoryService.pacePerHour(forOptional: \.sonnetUsed),
                etaHours: sr > 0
                    ? UsageHistoryService.pacePerHour(forOptional: \.sonnetUsed)
                        .flatMap { $0 > minimumMeaningfulPacePerHour ? sr / $0 : nil }
                    : nil
            ))
        }
        if let or = usage.opusRemaining, let ora = usage.opusResetsAt {
            windows.append(UsageWindow(
                name: "Opus",
                used: 100 - or,
                remaining: or,
                resetsAt: ora,
                pacePerHour: UsageHistoryService.pacePerHour(forOptional: \.opusUsed),
                etaHours: or > 0
                    ? UsageHistoryService.pacePerHour(forOptional: \.opusUsed)
                        .flatMap { $0 > minimumMeaningfulPacePerHour ? or / $0 : nil }
                    : nil
            ))
        }
        return windows
    }

    // MARK: - Notification senders

    /// Threshold crossed: includes pace, ETA, and reset time.
    private static func sendThresholdNotification(window: UsageWindow, threshold: Double) {
        var lines: [String] = []

        // Pace info
        if let pace = window.pacePerHour, pace > minimumMeaningfulPacePerHour {
            lines.append(String(format: "Pace: %.0f%%/h", pace))
        }

        // ETA to limit (skip if beyond the session window — limit resets first)
        if let eta = window.etaHours {
            let isSessionWindow = window.name == "Session"
            if isSessionWindow && eta >= 5 {
                lines.append("Well within limits at this pace")
            } else {
                lines.append("Limit in ~\(formatDuration(eta))")
            }
        }

        // Reset time
        lines.append("Resets \(formatResetDate(window.resetsAt))")

        let body = "\(window.name) usage has reached \(Int(threshold))%. "
            + lines.joined(separator: " · ")

        sendNotification(title: "Claude Usage Alert", body: body)
    }

    /// Limit reached (100%): tells user when it will be restored.
    private static func sendLimitReachedNotification(window: UsageWindow) {
        let body = "\(window.name) limit reached! "
            + "Restores \(formatResetDate(window.resetsAt)) "
            + "(\(formatCountdown(window.resetsAt)))"

        sendNotification(title: "Claude \(window.name) Limit Reached", body: body)
    }

    /// Window reset: usage dropped, quota is available again.
    private static func sendResetNotification(window: UsageWindow) {
        let body = "\(window.name) quota has been reset. "
            + "Current usage: \(Int(window.used))%. Enjoy your fresh allowance!"

        sendNotification(title: "Claude \(window.name) Reset", body: body)
    }

    // MARK: - Formatting helpers

    private static func formatDuration(_ hours: Double) -> String {
        if hours >= 48  { return "\(Int(hours / 24))d" }
        if hours >= 24  { return "1d \(Int(hours.truncatingRemainder(dividingBy: 24)))h" }
        if hours >= 1   { return String(format: "%.0fh", hours) }
        return "\(max(1, Int(hours * 60)))m"
    }

    private static func formatResetDate(_ date: Date) -> String {
        let cal = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        if cal.isDateInToday(date) {
            return "today at \(time)"
        }
        if cal.isDateInTomorrow(date) {
            return "tomorrow at \(time)"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
    }

    private static func formatCountdown(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return "now" }
        let hours = formatDuration(interval / 3600)
        return "in \(hours)"
    }

    // MARK: - Test

    /// Sends one sample of each notification type so the user can verify delivery.
    static func sendTestNotifications() {
        let sampleWindow = UsageWindow(
            name: "Session",
            used: 82,
            remaining: 18,
            resetsAt: Date().addingTimeInterval(2.5 * 3600),
            pacePerHour: 14,
            etaHours: 1.3
        )
        sendThresholdNotification(window: sampleWindow, threshold: 80)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let limitWindow = UsageWindow(
                name: "Session",
                used: 100,
                remaining: 0,
                resetsAt: Date().addingTimeInterval(1.2 * 3600),
                pacePerHour: 20,
                etaHours: nil
            )
            sendLimitReachedNotification(window: limitWindow)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let resetWindow = UsageWindow(
                name: "Session",
                used: 3,
                remaining: 97,
                resetsAt: Date().addingTimeInterval(5 * 3600),
                pacePerHour: nil,
                etaHours: nil
            )
            sendResetNotification(window: resetWindow)
        }
    }

    // MARK: - Core sender

    private static func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
