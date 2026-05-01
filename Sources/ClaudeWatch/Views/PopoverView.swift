import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var viewModel: UsageViewModel
    @State var showSettings = false
    @AppStorage(AppSettings.appearanceModeKey) private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("showCircularTimers") var showCircularTimers: Bool = true
    @AppStorage("showSparkline") var showSparkline: Bool = true
    @AppStorage("showQuickActions") var showQuickActions: Bool = true
    @AppStorage(AppSettings.showExtraUsageKey) var showExtraUsage: Bool = true

    var body: some View {
        let sessionPace   = UsageHistoryService.sessionPacePerHour()
        let recentHistory = UsageHistoryService.recent()
        let paceStatus = PaceClassifier.classify(
            pace: sessionPace ?? 0,
            etaHours: {
                guard let remaining = viewModel.usage?.sessionRemaining else { return nil }
                return UsageHistoryService.estimatedHoursUntilSessionEmpty(currentRemaining: remaining)
            }()
        )

        return Group {
            if showSettings {
                SettingsView(onDismiss: { showSettings = false })
                    .frame(width: UI.Size.settingsWidth)
            } else {
                VStack(spacing: 0) {
                    headerRow(sessionPace: sessionPace)
                    Divider().opacity(0.5)
                    rateLimitBanner
                    contentArea(
                        sessionPace: sessionPace,
                        recentHistory: recentHistory,
                        paceStatus: paceStatus
                    )
                    Divider().opacity(0.5)
                    footerRow
                }
                .frame(width: UI.Size.popoverWidth)
                .background(.ultraThinMaterial)
            }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearanceModeRaw)?.colorScheme)
    }

    // MARK: - Header

    func headerRow(sessionPace: Double?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: statusSymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(statusColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 20, height: 20)

            Text("Claude Usage")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if let pace = sessionPace, pace > PaceClassifier.minimumMeaningfulPacePerHour {
                HStack(spacing: 3) {
                    Image(systemName: paceIcon(pace))
                        .font(.caption2)
                    Text(String(format: "%.0f%%/h", pace))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(paceColor(pace))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .strokeBorder(paceColor(pace).opacity(0.2), lineWidth: 0.5)
                }
                .clipShape(Capsule())
                .help("Session usage pace: you're consuming ~\(Int(pace))% of your 5-hour session quota per hour")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Content

    @ViewBuilder
    func contentArea(
        sessionPace: Double?,
        recentHistory: [UsageSnapshot],
        paceStatus: PaceStatus
    ) -> some View {
        if let usage = viewModel.usage {
            let isStaleData = viewModel.rateLimitedUntil != nil

            VStack(spacing: 0) {
                if isStaleData {
                    staleBadge
                }

                fullContent(usage: usage, sessionPace: sessionPace, recentHistory: recentHistory, paceStatus: paceStatus)
            }
            .opacity(isStaleData ? 0.6 : 1.0)

        } else if viewModel.rateLimitedUntil != nil {
            VStack(spacing: 8) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Waiting for rate limit to lift before loading data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        } else if viewModel.isLoading {
            ProgressView()
                .padding(24)
        } else if viewModel.errorMessage != nil {
            Text("Tap refresh to retry.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        } else {
            Text("No data")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        }
    }

    // MARK: - Stale badge

    var staleBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.caption2)
            Text("Stale data \u{00b7} \(staleAgeText)")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .overlay {
            Capsule()
                .strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
        }
        .clipShape(Capsule())
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    var staleAgeText: String {
        guard let date = viewModel.lastRefreshed else { return "unknown" }
        let elapsed = -date.timeIntervalSinceNow
        if elapsed < 60  { return "\(Int(elapsed))s old" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m old" }
        return "\(Int(elapsed / 3600))h old"
    }

    // MARK: - Sparkline helpers

    var formattedSparklineWindow: String {
        let hours = AppSettings.sparklineHours
        if hours >= 24, hours % 24 == 0 {
            return "\(hours / 24)d"
        }
        return "\(hours)h"
    }

    // MARK: - Status icon helpers

    var overallRemaining: Double {
        guard let u = viewModel.usage else { return 100 }
        var lowest = min(u.sessionRemaining, u.weeklyRemaining)
        if let s = u.sonnetRemaining { lowest = min(lowest, s) }
        if let o = u.opusRemaining   { lowest = min(lowest, o) }
        return lowest
    }

    var statusSymbol: String {
        let used = 100 - overallRemaining
        return used >= 40 ? "flame.fill" : "bolt.fill"
    }

    var statusColor: Color { UsageSeverity.color(for: 100 - overallRemaining) }

    // MARK: - Pace helpers (raw burn-rate display for header pill)

    func paceIcon(_ pace: Double) -> String { PaceClassifier.rawPaceIcon(pace) }
    func paceColor(_ pace: Double) -> Color { PaceClassifier.rawPaceColor(pace) }

    var appVersion: String { AppSettings.appVersion }
}

