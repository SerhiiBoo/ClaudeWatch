import CoreGraphics
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
    private var isPaused = false

    /// Swaps in a mock data provider. For previews and tests only.
    var dataOverride: (() async -> UsageData)? = nil


    init() {
        self.refreshInterval = AppSettings.refreshInterval
    }

    // MARK: - Public interface

    func refresh() {
        guard !isPaused else { return }
        // Don't fire API calls while rate-limited
        if let until = rateLimitedUntil, until > Date() { return }
        rateLimitRetryTask?.cancel()   // Prevent concurrent fetch with retry
        refreshTask?.cancel()
        refreshTask = Task { await fetchUsage() }
    }

    func pauseAutoRefresh() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        refreshTask?.cancel()
    }

    func resumeAutoRefresh() {
        isPaused = false
        restartTimer()
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
        guard !isPaused else { return }
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
            // Check cancellation after each await point — add a guard here if new awaits are inserted above.
            guard !Task.isCancelled else { return }
            applySuccessResponse(response, creds: creds)
        } catch APIError.httpError(let code) where code == 401 || code == 403 {
            // Token may have rotated — invalidate cache and retry exactly once.
            KeychainService.invalidateCache()
            do {
                let freshCreds = try KeychainService.loadCredentials(forceReload: true)
                let retryResponse = try await APIService.fetchUsage(token: freshCreds.accessToken)
                guard !Task.isCancelled else { return }
                applySuccessResponse(retryResponse, creds: freshCreds)
            } catch {
                handleFetchError(error)
            }
        } catch APIError.rateLimited(let retryAfter) {
            handleRateLimit(retryAfter)
        } catch {
            handleFetchError(error)
        }

        // Always ensure the periodic timer is running (unless just rate-limited)
        if rateLimitedUntil == nil && timer == nil {
            scheduleTimer(interval: refreshInterval)
        }

        isLoading = false
        NotificationCenter.default.post(name: .usageDidUpdate, object: nil)
    }

    private func applySuccessResponse(_ response: UsageAPIResponse, creds: ClaudeCredentials) {
        let newUsage = mapResponse(response, plan: planName(creds.subscriptionType))
        let previousUsage = usage
        usage = newUsage
        lastRefreshed = Date()
        errorMessage = nil
        rateLimitedUntil = nil
        consecutiveRateLimits = 0
        UsageHistoryService.record(newUsage)
        NotificationService.checkThresholds(usage: newUsage, previousUsage: previousUsage)
    }

    private func handleRateLimit(_ retryAfter: Date?) {
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
    }

    private func handleFetchError(_ error: Error) {
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

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard !self.isUserIdle() else { return }
                self.refresh()
            }
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    /// Returns true when the user has been inactive longer than `idleFetchThreshold`.
    private func isUserIdle() -> Bool {
        // UInt32.max == kCGAnyInputEventType; CGEventType.init is failable but always
        // succeeds for this well-known constant — safe to force-unwrap.
        let idle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: UInt32.max)! // swiftlint:disable:this force_unwrapping
        )
        if idle >= AppSettings.idleFetchThreshold {
            logger.debug("Timer tick skipped — user idle for \(Int(idle))s")
            return true
        }
        return false
    }

    private func restartTimer() {
        // Don't restart periodic timer while paused or rate-limited
        guard !isPaused else { return }
        guard rateLimitedUntil.map({ $0 <= Date() }) != false else { return }
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

    private static let isoWithFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private func mapResponse(_ r: UsageAPIResponse, plan: String) -> UsageData {
        let now = Date()
        let (sessionRemaining, sessionResetsAt) = mapWindow(
            r.fiveHour, fallback: now.addingTimeInterval(5 * 3600)
        )
        let (weeklyRemaining, weeklyResetsAt) = mapWindow(
            r.sevenDay, fallback: now.addingTimeInterval(7 * 86400)
        )
        let (sonnetRemaining, sonnetResetsAt) = mapOptionalWindow(r.sevenDaySonnet)
        let (opusRemaining,   opusResetsAt)   = mapOptionalWindow(r.sevenDayOpus)

        let extraUsage = r.extraUsage.map {
            ExtraUsageData(
                isEnabled:           $0.isEnabled ?? false,
                spentDollars:        ($0.usedCredits ?? 0) / 100,
                monthlyLimitDollars: ($0.monthlyLimit ?? 0) / 100,
                utilization:         max(0, min(100, $0.utilization ?? 0))
            )
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
            fetchedAt:        now,
            extraUsage:       extraUsage
        )
    }

    /// Maps a required usage window; returns 100% remaining and `fallback` date when absent.
    private func mapWindow(_ window: WindowUsage?, fallback: Date) -> (remaining: Double, resetsAt: Date) {
        guard let w = window else { return (100, fallback) }
        let u = w.utilization.isFinite ? w.utilization : 0
        return (max(0, min(100, 100 - u)), w.resetsAt.flatMap(parseDate) ?? fallback)
    }

    /// Maps an optional usage window; returns `(nil, nil)` when absent.
    private func mapOptionalWindow(_ window: WindowUsage?) -> (remaining: Double?, resetsAt: Date?) {
        guard let w = window else { return (nil, nil) }
        let u = w.utilization.isFinite ? w.utilization : 0
        return (max(0, min(100, 100 - u)), w.resetsAt.flatMap(parseDate))
    }

    private func parseDate(_ s: String) -> Date? {
        if let d = Self.isoWithFrac.date(from: s) { return d }
        if let d = Self.isoPlain.date(from: s) { return d }
        logger.warning("Failed to parse date string: \(s, privacy: .private)")
        LogService.warning("ViewModel", "Failed to parse ISO 8601 date string (value omitted for privacy)")
        return nil
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
