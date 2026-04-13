import XCTest
@testable import ClaudeWatch

final class APIServiceTests: XCTestCase {

    // MARK: - parseRetryAfter

    func testParseRetryAfterNilReturnsNil() {
        XCTAssertNil(APIService.parseRetryAfter(nil))
    }

    func testParseRetryAfterZeroSecondsReturnsNearNow() {
        let before = Date()
        guard let result = APIService.parseRetryAfter("0") else {
            XCTFail("Expected non-nil date for '0'")
            return
        }
        let after = Date()
        XCTAssertGreaterThanOrEqual(result, before - 1)
        XCTAssertLessThanOrEqual(result, after + 1)
    }

    func testParseRetryAfterSixtySecondsReturnsFutureDate() {
        let before = Date()
        guard let result = APIService.parseRetryAfter("60") else {
            XCTFail("Expected non-nil date for '60'")
            return
        }
        let expectedMin = before.addingTimeInterval(59)
        let expectedMax = Date().addingTimeInterval(61)
        XCTAssertGreaterThan(result, expectedMin)
        XCTAssertLessThan(result, expectedMax)
    }

    func testParseRetryAfterNonNumericStringReturnsNil() {
        XCTAssertNil(APIService.parseRetryAfter("abc"))
    }

    func testParseRetryAfterHTTPDateReturnsNonNil() {
        // RFC 7231 HTTP-date format
        let httpDate = "Mon, 01 Jan 2030 00:00:00 GMT"
        let result = APIService.parseRetryAfter(httpDate)
        XCTAssertNotNil(result, "Expected non-nil date for valid HTTP-date '\(httpDate)'")
        if let date = result {
            XCTAssertGreaterThan(date, Date(), "Parsed date should be in the future")
        }
    }

    func testParseRetryAfterEmptyStringReturnsNil() {
        XCTAssertNil(APIService.parseRetryAfter(""))
    }

    func testParseRetryAfterNegativeSecondsReturnsDateInPast() {
        guard let result = APIService.parseRetryAfter("-30") else {
            XCTFail("Expected non-nil date for '-30' (negative seconds)")
            return
        }
        XCTAssertLessThan(result, Date(), "Negative offset should produce a past date")
    }
}
