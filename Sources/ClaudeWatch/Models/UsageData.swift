import Foundation

// MARK: - Notifications

extension Notification.Name {
    static let usageDidUpdate = Notification.Name("com.local.ClaudeWatch.usageDidUpdate")
}

// MARK: - Domain model

struct UsageData: Equatable {
    /// Remaining percentage 0–100 (= 100 − utilization reported by API)
    let sessionRemaining: Double
    let sessionResetsAt: Date
    /// Remaining percentage 0–100
    let weeklyRemaining: Double
    let weeklyResetsAt: Date
    /// Model-specific weekly limits (nil if not returned by API)
    let sonnetRemaining: Double?
    let sonnetResetsAt: Date?
    let opusRemaining: Double?
    let opusResetsAt: Date?
    let plan: String
    let fetchedAt: Date
}

// MARK: - Raw API models

struct UsageAPIResponse: Codable {
    let fiveHour: WindowUsage?
    let sevenDay: WindowUsage?
    let sevenDaySonnet: WindowUsage?
    let sevenDayOpus: WindowUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
    }
}

struct WindowUsage: Codable {
    /// 0–100 percentage of the window's allowance consumed
    let utilization: Double
    /// ISO 8601 reset timestamp – nil when the window has no active reset.
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}
