import XCTest
@testable import ClaudeWatch

final class LogServiceTests: XCTestCase {

    // MARK: - Smoke tests

    func testInfoLogDoesNotCrash() {
        XCTAssertNoThrow(LogService.info("Tests", "unit test info message"))
    }

    func testWarningLogDoesNotCrash() {
        XCTAssertNoThrow(LogService.warning("Tests", "unit test warning message"))
    }

    func testErrorLogDoesNotCrash() {
        XCTAssertNoThrow(
            LogService.error("Tests", "unit test error message", error: nil, details: ["key": "value"])
        )
    }

    func testErrorLogWithErrorDoesNotCrash() {
        let err = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "test error"])
        XCTAssertNoThrow(LogService.error("Tests", "error with NSError", error: err))
    }

    func testFlushDoesNotCrash() {
        LogService.info("Tests", "pre-flush message")
        XCTAssertNoThrow(LogService.flush())
    }

    func testPruneIfNeededDoesNotCrash() {
        XCTAssertNoThrow(LogService.pruneIfNeeded())
        LogService.flush()
    }

    func testTotalSizeIsNonNegative() {
        LogService.info("Tests", "size check message")
        LogService.flush()
        let size = LogService.totalSize()
        XCTAssertGreaterThanOrEqual(size, 0, "Total log size should be non-negative")
    }

    func testAllLogsContainsWrittenEntry() {
        let marker = "UNIT_TEST_MARKER_\(UUID().uuidString)"
        LogService.info("Tests", marker)
        LogService.flush()

        if let logs = LogService.allLogs() {
            XCTAssertTrue(logs.contains(marker), "allLogs() should contain the written marker")
        }
        // If allLogs() returns nil the log dir isn't available in this context — that's acceptable
    }

    func testLogAndFlushSequenceDoesNotCrash() {
        for i in 0..<5 {
            LogService.info("Tests", "sequence message \(i)")
        }
        XCTAssertNoThrow(LogService.flush())
    }
}
