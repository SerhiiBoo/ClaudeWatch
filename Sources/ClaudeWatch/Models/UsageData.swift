import Foundation

// MARK: - Notifications

extension Notification.Name {
    static let usageDidUpdate = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.usageDidUpdate")
    static let petPositionDidChange = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.petPositionDidChange")
    static let petCharacterDidChange = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.petCharacterDidChange")
    static let petTriggerAnimation = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.petTriggerAnimation")
    // Mini-game triggers
    static let petDidLeaveSleep    = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.petDidLeaveSleep")
    static let miniGameManualTrigger = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.miniGameManualTrigger")
    static let menuBarSettingsDidChange = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.menuBarSettingsDidChange")
    static let permissionApprovalSettingDidChange = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.permissionApprovalSettingDidChange")
}

// MARK: - Domain model

struct ExtraUsageData: Equatable {
    let isEnabled: Bool
    /// Amount spent in dollars (converted from cents)
    let spentDollars: Double
    /// Monthly spend cap in dollars (converted from cents)
    let monthlyLimitDollars: Double
    /// 0–100 percent of the monthly limit consumed
    let utilization: Double
}

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
    /// Extra (pay-as-you-go) usage data — nil when not returned by the API
    let extraUsage: ExtraUsageData?
}

// MARK: - Raw API models

struct UsageAPIResponse: Codable {
    let fiveHour: WindowUsage?
    let sevenDay: WindowUsage?
    let sevenDaySonnet: WindowUsage?
    let sevenDayOpus: WindowUsage?
    let extraUsage: ExtraUsageAPIResponse?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
        case extraUsage = "extra_usage"
    }
}

struct ExtraUsageAPIResponse: Codable {
    let isEnabled: Bool?
    /// Monthly spend cap in cents (e.g. 5000 = $50.00)
    let monthlyLimit: Double?
    /// Amount consumed in cents (e.g. 1407 = $14.07)
    let usedCredits: Double?
    /// 0–100 percent of the monthly limit consumed
    let utilization: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled    = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits  = "used_credits"
        case utilization
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
