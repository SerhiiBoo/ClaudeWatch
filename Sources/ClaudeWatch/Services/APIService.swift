import Foundation
import os.log

private let logger = Logger(subsystem: "io.github.SerhiiBoo.ClaudeWatch", category: "APIService")

enum APIError: LocalizedError {
    case invalidResponse
    case rateLimited(retryAfter: Date?)
    case httpError(Int, String?)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .rateLimited:
            return "Rate limited by Anthropic API."
        case .httpError(let code, let msg):
            return "HTTP \(code)\(msg.map { ": \($0)" } ?? "")."
        case .decodingFailed(let detail):
            return "Could not parse response: \(detail)"
        }
    }
}

struct APIService {
    private static let usageEndpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

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
            throw APIError.httpError(http.statusCode, body)
        }

        do {
            return try JSONDecoder().decode(UsageAPIResponse.self, from: data)
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

    // Compiled once at startup — patterns are compile-time constants so try! is safe.
    private static let sensitiveRegexes: [NSRegularExpression] = [
        try! NSRegularExpression(
            pattern: #"("(?:access_?token|token|key|secret|password|authorization|cookie)")\s*:\s*"[^"]*""#,
            options: .caseInsensitive
        ),
        try! NSRegularExpression(
            pattern: #"Bearer\s+[A-Za-z0-9\-._~+/]+=*"#,
            options: .caseInsensitive
        ),
    ]

    /// Redact values that could contain tokens or secrets from raw API responses.
    private static func sanitizeForLog(_ raw: String) -> String {
        sensitiveRegexes.reduce(raw) { sanitized, regex in
            regex.stringByReplacingMatches(
                in: sanitized,
                range: NSRange(sanitized.startIndex..., in: sanitized),
                withTemplate: "$1: \"[REDACTED]\""
            )
        }
    }

    private static func parseRetryAfter(_ value: String?) -> Date? {
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
