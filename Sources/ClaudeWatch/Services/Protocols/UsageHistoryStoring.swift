import Foundation

protocol UsageHistoryStoring {
    static func record(_ usage: UsageData)
    static func recent(hours: Int?) -> [UsageSnapshot]
    static func sessionPacePerHour() -> Double?
    static func estimatedHoursUntilSessionEmpty(currentRemaining: Double) -> Double?
}
