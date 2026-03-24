import Foundation
import os.log

private let logger = Logger(subsystem: "io.github.SerhiiBoo.ClaudeWatch", category: "ViewModel")

@MainActor
final class UsageViewModel: ObservableObject {
    @Published var usage: UsageData?
    @Published var errorMessage: String?
    @Published var rateLimitedUntil: Date?
    @Published var isLoading = false
    @Published var lastRefreshed: Date?

    /// Auto-refresh interval in seconds – persisted via AppSettings.
    @Published var refreshInterval: TimeInterval {
        didSet {
            AppSettings.refreshInterval = refreshInterval
            restartTimer()
        }
    }

    private var refreshTask: Task<Void, Never>?
    private var rateLimitRetryTask: Task<Void, Never>?
    private var timer: Timer?
    private var consecutiveRateLimits = 0

    /// Optional data provider. When set, `fetchUsage()` calls this instead of the API.
    var dataOverride: (() async -> UsageData)? = nil


    init() {
        self.refreshInterval = AppSettings.refreshInterval
    }

    // MARK: - Public interface

    func refresh() {
        // Don't fire API calls while rate-limited
        if let until = rateLimitedUntil, until > Date() { return }
        rateLimitRetryTask?.cancel()   // Prevent concurrent fetch with retry
        refreshTask?.cancel()
        refreshTask = Task { await fetchUsage() }
    }

    func startAutoRefresh() {
        refresh()
        scheduleTimer(interval: refreshInterval)
    }

    // MARK: - Computed

    /// True if there's no data yet, or the last fetch is older than the refresh interval.
    var isStale: Bool {
        guard let date = lastRefreshed else { return true }
        return -date.timeIntervalSinceNow >= refreshInterval
    }

    var lastUpdatedText: String {
        guard let date = lastRefreshed else { return "Not yet updated" }
        let elapsed = -date.timeIntervalSinceNow
        switch elapsed {
        case ..<60:   return "Updated \(Int(elapsed))s ago"
        case ..<3600: return "Updated \(Int(elapsed / 60))m ago"
        default:      return "Updated \(Int(elapsed / 3600))h ago"
        }
    }

    // MARK: - Private

    private func fetchUsage() async {
        // Don't hammer API while still rate-limited
        if let until = rateLimitedUntil, until > Date() { return }

        if let override = dataOverride {
            usage = await override()
            lastRefreshed = Date()
            errorMessage = nil
            isLoading = false
            NotificationCenter.default.post(name: .usageDidUpdate, object: nil)
            return
        }

        // Only show spinner on the very first load (no cached data, not rate-limited)
        if usage == nil && rateLimitedUntil == nil {
            isLoading = true
        }

        do {
            let creds = try KeychainService.loadCredentials()
            let response = try await APIService.fetchUsage(token: creds.accessToken)
            let newUsage = mapResponse(response, plan: planName(creds.subscriptionType))
            let previousUsage = usage
            usage = newUsage
            lastRefreshed = Date()
            errorMessage = nil      // Clear error only on success
            rateLimitedUntil = nil  // Clear only on success
            consecutiveRateLimits = 0
            // Record snapshot for history/sparkline and check alert thresholds
            UsageHistoryService.record(newUsage)
            NotificationService.checkThresholds(usage: newUsage, previousUsage: previousUsage)
        } catch APIError.rateLimited(let retryAfter) {
            consecutiveRateLimits += 1
            logger.info("Rate limited (attempt \(self.consecutiveRateLimits)), retry after: \(retryAfter?.description ?? "nil")")
            LogService.warning("ViewModel", "Rate limited by API", details: [
                "attempt": "\(consecutiveRateLimits)",
                "retry_after": retryAfter?.description ?? "nil",
            ])
            let serverDate = retryAfter ?? Date().addingTimeInterval(60)
            errorMessage = nil          // banner handles display
            // Pause periodic timer — no point polling while rate limited
            timer?.invalidate()
            timer = nil
            scheduleRateLimitRetry(serverDate: serverDate)
        } catch {
            rateLimitedUntil = nil      // Clear on non-rate-limit errors
            logger.error("Fetch failed: \(error.localizedDescription)")
            // Show user-friendly messages; log structured detail for diagnostics
            if let apiErr = error as? APIError {
                errorMessage = apiErr.errorDescription
                LogService.error("ViewModel", "API error", error: apiErr, details: [
                    "error_case": String(describing: apiErr),
                ])
            } else if let urlErr = error as? URLError {
                LogService.error("ViewModel", "Network error", error: urlErr, details: [
                    "url_error_code": "\(urlErr.code.rawValue)",
                ])
                switch urlErr.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    errorMessage = "No internet connection."
                case .timedOut:
                    errorMessage = "Request timed out."
                default:
                    errorMessage = "Network error. Check your connection."
                }
            } else if let kcErr = error as? KeychainError {
                errorMessage = kcErr.errorDescription
                LogService.error("ViewModel", "Keychain error", error: kcErr, details: [
                    "error_case": String(describing: kcErr),
                ])
            } else {
                errorMessage = "An unexpected error occurred."
                LogService.error("ViewModel", "Unexpected error", error: error)
            }
        }

        // Always ensure the periodic timer is running (unless just rate-limited)
        if rateLimitedUntil == nil && timer == nil {
            scheduleTimer(interval: refreshInterval)
        }

        isLoading = false
        NotificationCenter.default.post(name: .usageDidUpdate, object: nil)
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.refresh() }
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func restartTimer() {
        // Don't restart periodic timer while rate-limited (it's paused on purpose)
        guard rateLimitedUntil == nil || rateLimitedUntil! <= Date() else { return }
        scheduleTimer(interval: refreshInterval)
    }

    private func scheduleRateLimitRetry(serverDate: Date) {
        rateLimitRetryTask?.cancel()
        // Backoff: 90s, 180s, 300s, then 600s cap
        // Avoids retry-after:0 trap — always wait at least 90s
        let backoff: Double
        switch consecutiveRateLimits {
        case 1:  backoff = 90
        case 2:  backoff = 180
        case 3:  backoff = 300
        default: backoff = 600  // 10 min cap after 3+ failures
        }
        let delay = max(backoff, serverDate.timeIntervalSinceNow) + 1
        // Set rateLimitedUntil to the ACTUAL retry time so the banner countdown matches
        rateLimitedUntil = Date().addingTimeInterval(delay)
        rateLimitRetryTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            // Don't clear rateLimitedUntil here — expired date passes guard naturally
            // (until > Date() is false). Banner shows "lifted · refreshing…" during fetch.
            // Cleared on success (line 80) or non-rate-limit error (line 91).
            await fetchUsage()
        }
    }

    private func mapResponse(_ r: UsageAPIResponse, plan: String) -> UsageData {
        let now = Date()

        func parseDate(_ s: String) -> Date? {
            let withFrac = ISO8601DateFormatter()
            withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = withFrac.date(from: s) { return d }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let d = plain.date(from: s) { return d }
            logger.warning("Failed to parse date string: \(s, privacy: .private)")
            LogService.warning("ViewModel", "Failed to parse date string: \(s)")
            return nil
        }

        let sessionRemaining: Double
        let sessionResetsAt: Date
        if let w = r.fiveHour {
            sessionRemaining = max(0, min(100, 100 - w.utilization))
            sessionResetsAt  = w.resetsAt.flatMap(parseDate) ?? now.addingTimeInterval(5 * 3600)
        } else {
            sessionRemaining = 100
            sessionResetsAt  = now.addingTimeInterval(5 * 3600)
        }

        let weeklyRemaining: Double
        let weeklyResetsAt: Date
        if let w = r.sevenDay {
            weeklyRemaining = max(0, min(100, 100 - w.utilization))
            weeklyResetsAt  = w.resetsAt.flatMap(parseDate) ?? now.addingTimeInterval(7 * 86400)
        } else {
            weeklyRemaining = 100
            weeklyResetsAt  = now.addingTimeInterval(7 * 86400)
        }

        let sonnetRemaining: Double?
        let sonnetResetsAt: Date?
        if let w = r.sevenDaySonnet {
            sonnetRemaining = max(0, min(100, 100 - w.utilization))
            sonnetResetsAt  = w.resetsAt.flatMap(parseDate)
        } else {
            sonnetRemaining = nil
            sonnetResetsAt  = nil
        }

        let opusRemaining: Double?
        let opusResetsAt: Date?
        if let w = r.sevenDayOpus {
            opusRemaining = max(0, min(100, 100 - w.utilization))
            opusResetsAt  = w.resetsAt.flatMap(parseDate)
        } else {
            opusRemaining = nil
            opusResetsAt  = nil
        }

        return UsageData(
            sessionRemaining: sessionRemaining,
            sessionResetsAt:  sessionResetsAt,
            weeklyRemaining:  weeklyRemaining,
            weeklyResetsAt:   weeklyResetsAt,
            sonnetRemaining:  sonnetRemaining,
            sonnetResetsAt:   sonnetResetsAt,
            opusRemaining:    opusRemaining,
            opusResetsAt:     opusResetsAt,
            plan:             plan,
            fetchedAt:        now
        )
    }

    private func planName(_ type: String) -> String {
        switch type.lowercased() {
        case "max":  return "Max"
        case "pro":  return "Pro"
        case "free": return "Free"
        default:     return type.capitalized
        }
    }

    deinit {
        timer?.invalidate()
        refreshTask?.cancel()
        rateLimitRetryTask?.cancel()
    }
}
