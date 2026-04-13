import Foundation

protocol UsageFetching {
    static func fetchUsage(token: String) async throws -> UsageAPIResponse
}
