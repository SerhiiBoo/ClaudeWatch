import XCTest
@testable import ClaudeWatch

final class PaceClassifierTests: XCTestCase {

    // MARK: - Unknown pressure (pace below threshold)

    func testBelowMinimumPaceReturnsUnknown() {
        let status = PaceClassifier.classify(pace: 0.4, etaHours: 2)
        XCTAssertEqual(status.pressure, .unknown)
    }

    func testZeroPaceReturnsUnknown() {
        let status = PaceClassifier.classify(pace: 0, etaHours: 1)
        XCTAssertEqual(status.pressure, .unknown)
    }

    func testExactlyAtMinimumThresholdReturnsUnknown() {
        // 0.5 is the threshold; pace must be *above* it
        let status = PaceClassifier.classify(pace: PaceClassifier.minimumMeaningfulPacePerHour, etaHours: 3)
        XCTAssertEqual(status.pressure, .unknown)
    }

    func testUnknownPreservesPassedValues() {
        let status = PaceClassifier.classify(pace: 0.1, etaHours: 4)
        XCTAssertEqual(status.pacePerHour, 0.1, accuracy: 0.001)
        XCTAssertEqual(status.etaHours, 4)
    }

    // MARK: - Beyond window (ETA >= sessionWindowHours)

    func testEtaExactlyAtWindowReturnsBeyondWindow() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 5)
        XCTAssertEqual(status.pressure, .beyondWindow)
    }

    func testEtaAboveWindowReturnsBeyondWindow() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 10)
        XCTAssertEqual(status.pressure, .beyondWindow)
    }

    func testCustomWindowRespected() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 8, sessionWindowHours: 10)
        XCTAssertEqual(status.pressure, .comfortable)
    }

    // MARK: - Comfortable (2h <= ETA < 5h)

    func testEtaJustBelowWindowReturnsComfortable() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 4.9)
        XCTAssertEqual(status.pressure, .comfortable)
    }

    func testEtaAtTwoHoursReturnsComfortable() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 2)
        XCTAssertEqual(status.pressure, .comfortable)
    }

    // MARK: - Watch (1h <= ETA < 2h)

    func testEtaJustBelowTwoHoursReturnsWatch() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 1.9)
        XCTAssertEqual(status.pressure, .watch)
    }

    func testEtaAtOneHourReturnsWatch() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 1)
        XCTAssertEqual(status.pressure, .watch)
    }

    // MARK: - Urgent (ETA < 1h)

    func testEtaJustBelowOneHourReturnsUrgent() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 0.9)
        XCTAssertEqual(status.pressure, .urgent)
    }

    func testEtaZeroReturnsUrgent() {
        let status = PaceClassifier.classify(pace: 5, etaHours: 0)
        XCTAssertEqual(status.pressure, .urgent)
    }

    // MARK: - Nil ETA (sparse history)

    func testNilEtaWithMeaningfulPaceReturnsComfortable() {
        let status = PaceClassifier.classify(pace: 5, etaHours: nil)
        XCTAssertEqual(status.pressure, .comfortable)
    }

    func testNilEtaPreservesValues() {
        let status = PaceClassifier.classify(pace: 12.5, etaHours: nil)
        XCTAssertEqual(status.pacePerHour, 12.5, accuracy: 0.001)
        XCTAssertNil(status.etaHours)
    }

    // MARK: - rawPaceIcon

    func testRawPaceIconLowPace() {
        XCTAssertEqual(PaceClassifier.rawPaceIcon(5), "tortoise.fill")
    }

    func testRawPaceIconMediumPace() {
        XCTAssertEqual(PaceClassifier.rawPaceIcon(15), "figure.walk")
    }

    func testRawPaceIconHighPace() {
        XCTAssertEqual(PaceClassifier.rawPaceIcon(25), "hare.fill")
    }

    func testRawPaceIconExactBoundary20() {
        XCTAssertEqual(PaceClassifier.rawPaceIcon(20), "hare.fill")
    }

    func testRawPaceIconExactBoundary10() {
        XCTAssertEqual(PaceClassifier.rawPaceIcon(10), "figure.walk")
    }
}
