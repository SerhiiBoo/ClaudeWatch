import XCTest
@testable import ClaudeWatch

@MainActor
final class UsageViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeTestUsageData(
        sessionRemaining: Double = 75.0,
        weeklyRemaining: Double = 60.0
    ) -> UsageData {
        let now = Date()
        return UsageData(
            sessionRemaining: sessionRemaining,
            sessionResetsAt: now.addingTimeInterval(5 * 3600),
            weeklyRemaining: weeklyRemaining,
            weeklyResetsAt: now.addingTimeInterval(7 * 86400),
            sonnetRemaining: nil,
            sonnetResetsAt: nil,
            opusRemaining: nil,
            opusResetsAt: nil,
            plan: "Pro",
            fetchedAt: now,
            extraUsage: nil
        )
    }

    // MARK: - Tests

    func testDataOverridePopulatesUsage() async {
        let expected = makeTestUsageData(sessionRemaining: 88.0, weeklyRemaining: 55.0)
        let viewModel = UsageViewModel()
        viewModel.dataOverride = { expected }

        viewModel.refresh()
        // Allow the async Task launched by refresh() to complete
        await Task.yield()
        // Spin briefly to let the internal Task finish
        for _ in 0..<20 {
            if viewModel.usage != nil { break }
            await Task.yield()
        }

        XCTAssertEqual(viewModel.usage?.sessionRemaining, 88.0)
        XCTAssertEqual(viewModel.usage?.weeklyRemaining, 55.0)
        XCTAssertEqual(viewModel.usage?.plan, "Pro")
    }

    func testRefreshWhileRateLimitedIsNoOp() async {
        let viewModel = UsageViewModel()
        // Simulate an active rate limit 60 seconds in the future
        viewModel.rateLimitedUntil = Date().addingTimeInterval(60)

        var overrideCalled = false
        viewModel.dataOverride = {
            overrideCalled = true
            return self.makeTestUsageData()
        }

        viewModel.refresh()
        await Task.yield()

        XCTAssertFalse(overrideCalled, "dataOverride should not be called while rate-limited")
        XCTAssertNil(viewModel.usage, "Usage should remain nil when rate-limited prevents refresh")
    }

    func testSuccessfulFetchClearsError() async {
        let viewModel = UsageViewModel()
        // Pre-set an error message
        viewModel.errorMessage = "Previous error"
        viewModel.dataOverride = { self.makeTestUsageData() }

        viewModel.refresh()
        await Task.yield()
        for _ in 0..<20 {
            if viewModel.usage != nil { break }
            await Task.yield()
        }

        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared after successful fetch")
    }

    func testIsStaleWhenNeverRefreshed() {
        let viewModel = UsageViewModel()
        XCTAssertTrue(viewModel.isStale, "isStale should be true when lastRefreshed is nil")
    }

    func testIsStaleAfterRefresh() async {
        let viewModel = UsageViewModel()
        viewModel.dataOverride = { self.makeTestUsageData() }

        viewModel.refresh()
        await Task.yield()
        for _ in 0..<20 {
            if viewModel.lastRefreshed != nil { break }
            await Task.yield()
        }

        XCTAssertNotNil(viewModel.lastRefreshed)
        XCTAssertFalse(viewModel.isStale, "isStale should be false immediately after a successful refresh")
    }
}
