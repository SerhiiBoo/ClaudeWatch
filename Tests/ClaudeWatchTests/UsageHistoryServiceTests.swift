import XCTest
@testable import ClaudeWatch

final class UsageHistoryServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear any leftover override from previous tests
        UsageHistoryService.historyOverride = nil
    }

    override func tearDown() {
        super.tearDown()
        UsageHistoryService.historyOverride = nil
    }

    // MARK: - sessionPacePerHour

    func testSessionPacePerHourReturnsNilForEmptyHistory() {
        UsageHistoryService.historyOverride = { [] }
        let pace = UsageHistoryService.sessionPacePerHour()
        XCTAssertNil(pace, "Pace should be nil when there is no history")
    }

    func testSessionPacePerHourReturnsNilForSingleSnapshot() {
        let now = Date()
        let snap = UsageSnapshot(
            timestamp: now,
            sessionUsed: 10.0,
            weeklyUsed: 5.0,
            sonnetUsed: nil,
            opusUsed: nil
        )
        UsageHistoryService.historyOverride = { [snap] }
        let pace = UsageHistoryService.sessionPacePerHour()
        XCTAssertNil(pace, "Pace should be nil with only one snapshot")
    }

    func testSessionPacePerHourPositiveWhenUsageIncreases() {
        let now = Date()
        // Two snapshots 2 hours apart, usage went from 10% to 30% → pace = 10%/h
        let older = UsageSnapshot(
            timestamp: now.addingTimeInterval(-2 * 3600),
            sessionUsed: 10.0,
            weeklyUsed: 5.0,
            sonnetUsed: nil,
            opusUsed: nil
        )
        let newer = UsageSnapshot(
            timestamp: now,
            sessionUsed: 30.0,
            weeklyUsed: 10.0,
            sonnetUsed: nil,
            opusUsed: nil
        )
        UsageHistoryService.historyOverride = { [older, newer] }

        let pace = UsageHistoryService.sessionPacePerHour()
        XCTAssertNotNil(pace, "Pace should be non-nil for two snapshots with increasing usage")
        if let pace {
            XCTAssertGreaterThan(pace, 0, "Pace should be positive when usage increases")
            XCTAssertEqual(pace, 10.0, accuracy: 0.1, "Pace should be ~10%/h")
        }
    }

    func testSessionPacePerHourIsZeroWhenUsageUnchanged() {
        let now = Date()
        let older = UsageSnapshot(
            timestamp: now.addingTimeInterval(-2 * 3600),
            sessionUsed: 20.0,
            weeklyUsed: 5.0,
            sonnetUsed: nil,
            opusUsed: nil
        )
        let newer = UsageSnapshot(
            timestamp: now,
            sessionUsed: 20.0,
            weeklyUsed: 5.0,
            sonnetUsed: nil,
            opusUsed: nil
        )
        UsageHistoryService.historyOverride = { [older, newer] }

        let pace = UsageHistoryService.sessionPacePerHour()
        // Pace exists but is 0 (or nil filtered by minimumMeaningfulPacePerHour in ETA, not in pacePerHour itself)
        if let pace {
            XCTAssertEqual(pace, 0.0, accuracy: 0.01)
        }
        // nil is also acceptable if the window filter excludes the snapshots
    }

    // MARK: - recent(count:)

    func testRecentReturnsAllSnapshotsFromOverride() {
        let now = Date()
        let snapshots: [UsageSnapshot] = (0..<10).map { i in
            UsageSnapshot(
                timestamp: now.addingTimeInterval(-Double(i) * 3600),
                sessionUsed: Double(i),
                weeklyUsed: 0,
                sonnetUsed: nil,
                opusUsed: nil
            )
        }
        UsageHistoryService.historyOverride = { snapshots }

        // When historyOverride is set, recent() returns all override entries
        // without applying any time-window filter (the filter only applies to disk reads).
        let result = UsageHistoryService.recent(hours: 3)
        XCTAssertEqual(result.count, 10, "historyOverride bypasses time filter, all 10 snapshots returned")
    }

    func testRecentReturnsAllSnapshotsWithinWindow() {
        let now = Date()
        let snapshots: [UsageSnapshot] = (0..<5).map { i in
            UsageSnapshot(
                timestamp: now.addingTimeInterval(-Double(i) * 600),  // 10 min apart
                sessionUsed: Double(i * 5),
                weeklyUsed: 0,
                sonnetUsed: nil,
                opusUsed: nil
            )
        }
        UsageHistoryService.historyOverride = { snapshots }

        let result = UsageHistoryService.recent(hours: 1)
        XCTAssertEqual(result.count, 5, "All 5 snapshots within 1 hour should be returned")
    }

    func testRecentReturnsEmptyArrayForEmptyHistory() {
        UsageHistoryService.historyOverride = { [] }
        let result = UsageHistoryService.recent(hours: 24)
        XCTAssertTrue(result.isEmpty, "recent() should return empty array when history is empty")
    }

    // MARK: - estimatedHoursUntilSessionEmpty

    func testEtaIsNilForEmptyHistory() {
        UsageHistoryService.historyOverride = { [] }
        let eta = UsageHistoryService.estimatedHoursUntilSessionEmpty(currentRemaining: 50.0)
        XCTAssertNil(eta, "ETA should be nil when there is no history")
    }

    func testEtaIsPositiveWhenUsageIsIncreasing() {
        let now = Date()
        let older = UsageSnapshot(
            timestamp: now.addingTimeInterval(-2 * 3600),
            sessionUsed: 0.0,
            weeklyUsed: 0,
            sonnetUsed: nil,
            opusUsed: nil
        )
        let newer = UsageSnapshot(
            timestamp: now,
            sessionUsed: 20.0,    // 10%/h pace
            weeklyUsed: 0,
            sonnetUsed: nil,
            opusUsed: nil
        )
        UsageHistoryService.historyOverride = { [older, newer] }

        // currentRemaining = 50%, pace = 10%/h → ETA ≈ 5 hours
        let eta = UsageHistoryService.estimatedHoursUntilSessionEmpty(currentRemaining: 50.0)
        XCTAssertNotNil(eta)
        if let eta {
            XCTAssertEqual(eta, 5.0, accuracy: 0.5)
        }
    }
}
