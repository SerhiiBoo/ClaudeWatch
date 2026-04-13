import Foundation
import os.log

private let logger = Logger(subsystem: "io.github.SerhiiBoo.ClaudeWatch", category: "APIService")

enum APIError: LocalizedError {
    case invalidResponse
    case rateLimited(retryAfter: Date?)
    case httpError(Int)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .rateLimited:
            return "Rate limited by Anthropic API."
        case .httpError(let code):
            return "HTTP \(code). Please try again."
        case .decodingFailed(let detail):
            return "Could not parse response: \(detail)"
        }
    }
}

enum APIService {
    private static let usageEndpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private static let decoder = JSONDecoder()

    static func fetchUsage(token: String) async throws -> UsageAPIResponse {
        var request = URLRequest(url: usageEndpoint, timeoutInterval: 10)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 429 {
            // Parse Retry-After header – can be seconds (integer) or HTTP-date
            let retryDate = parseRetryAfter(http.value(forHTTPHeaderField: "Retry-After"))
            throw APIError.rateLimited(retryAfter: retryDate)
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8).map { sanitizeForLog($0) }
            logger.error("HTTP \(http.statusCode): \(body ?? "<empty>", privacy: .private)")
            throw APIError.httpError(http.statusCode)
        }

        logger.debug("Raw usage response: \(sanitizeForLog(String(data: data, encoding: .utf8) ?? "<non-UTF8>"), privacy: .private)")

        do {
            return try decoder.decode(UsageAPIResponse.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-UTF8>"
            logger.error("Decoding failed. Raw response: \(raw, privacy: .private)")
            LogService.error("APIService", "JSON decoding failed", error: error, details: [
                "raw_response_preview": String(sanitizeForLog(raw).prefix(300)),
                "endpoint": usageEndpoint.absoluteString,
                "status": "200",
            ])
            throw APIError.decodingFailed(error.localizedDescription)
        }
    }

    // MARK: - Private

    /// Redact values that could contain tokens or secrets from raw API responses.
    /// Patterns are Swift Regex literals — syntax is verified at compile time.
    private static func sanitizeForLog(_ raw: String) -> String {
        var result = raw
        // Erase values of sensitive JSON keys (case-insensitive)
        result = result.replacing(
            #/(?i)("(?:access_?token|token|key|secret|password|authorization|cookie)")\s*:\s*"[^"]*"/#
        ) { match in
            "\(match.output.1): \"[REDACTED]\""
        }
        // Erase Bearer token values
        result = result.replacing(
            #/(?i)Bearer\s+[A-Za-z0-9\-._~+/]+=*/#,
            with: "Bearer [REDACTED]"
        )
        return result
    }

    static func parseRetryAfter(_ value: String?) -> Date? {
        guard let value else { return nil }
        // Integer seconds
        if let seconds = TimeInterval(value) {
            return Date().addingTimeInterval(seconds)
        }
        // HTTP-date format (RFC 7231)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return fmt.date(from: value)
    }
}

extension APIService: UsageFetching {}
