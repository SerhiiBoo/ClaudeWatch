import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var viewModel: UsageViewModel
    @State private var showSettings = false
    @AppStorage(AppSettings.appearanceModeKey) private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    var body: some View {
        Group {
            if showSettings {
                SettingsView(onDismiss: { showSettings = false })
                    .environmentObject(viewModel)
            } else {
                VStack(spacing: 0) {
                    headerRow
                    Divider().opacity(0.5)
                    rateLimitBanner
                    VStack(spacing: 0) {
                        contentArea
                    }
                    Divider().opacity(0.5)
                    footerRow
                }
                .frame(width: 320)
                .background(.ultraThinMaterial)
            }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearanceModeRaw)?.colorScheme)
    }

    // MARK: - Header

    private var headerRow: some View {
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

            if let pace = UsageHistoryService.sessionPacePerHour(), pace > minimumMeaningfulPacePerHour {
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

    // MARK: - Rate-limit banner (softer blue/grey tone + progress ring + why tooltip)

    @ViewBuilder
    private var rateLimitBanner: some View {
        if let until = viewModel.rateLimitedUntil {
            let totalWait = max(60, until.timeIntervalSince(viewModel.lastRefreshed ?? until))
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = until.timeIntervalSince(context.date)
                if remaining > 0 {
                    rateLimitRow(remaining: remaining, totalWait: totalWait)
                } else {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Rate limit lifted \u{00b7} refreshing\u{2026}")
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.08))
                }
            }
            Divider()
        } else if let err = viewModel.errorMessage {
            bannerRow(icon: "exclamationmark.triangle.fill", color: .red, text: err)
            Divider()
        }
    }

    private func rateLimitRow(remaining: TimeInterval, totalWait: TimeInterval) -> some View {
        HStack(spacing: 10) {
            // Mini progress ring countdown
            ZStack {
                Circle()
                    .stroke(.primary.opacity(0.08), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: max(0, 1 - remaining / totalWait))
                    .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "pause.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(.blue.opacity(0.8))
            }
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text("API rate limited \u{00b7} retrying in \(formatCountdown(remaining))")
                    .font(.caption)
                    .foregroundStyle(.primary)
                Text("This is the usage API, not your Claude quota")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.06))
    }

    private func bannerRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if let usage = viewModel.usage {
            let isStaleData = viewModel.rateLimitedUntil != nil

            // Stale data overlay wrapper
            VStack(spacing: 0) {
                if isStaleData {
                    staleBadge
                }

                if AppSettings.compactMode {
                    compactContent(usage: usage)
                } else {
                    fullContent(usage: usage)
                }
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

    private var staleBadge: some View {
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

    private var staleAgeText: String {
        guard let date = viewModel.lastRefreshed else { return "unknown" }
        let elapsed = -date.timeIntervalSinceNow
        if elapsed < 60  { return "\(Int(elapsed))s old" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m old" }
        return "\(Int(elapsed / 3600))h old"
    }

    // MARK: - Compact content

    private func compactContent(usage: UsageData) -> some View {
        VStack(spacing: 0) {
            UsageSectionView(
                title: "Session",
                subtitle: "5-hour window",
                remaining: usage.sessionRemaining,
                resetsAt: usage.sessionResetsAt
            )
            Divider()
            UsageSectionView(
                title: "Weekly",
                subtitle: "7-day window",
                remaining: usage.weeklyRemaining,
                resetsAt: usage.weeklyResetsAt
            )
            if let sr = usage.sonnetRemaining, let sra = usage.sonnetResetsAt {
                Divider()
                UsageSectionView(title: "Sonnet", subtitle: "7-day window", remaining: sr, resetsAt: sra)
            }
            if let or = usage.opusRemaining, let ora = usage.opusResetsAt {
                Divider()
                UsageSectionView(title: "Opus", subtitle: "7-day window", remaining: or, resetsAt: ora)
            }

            // Projected usage during rate limit
            if viewModel.rateLimitedUntil != nil {
                projectedUsageRow(usage: usage)
            }

            Divider()
            planRow(usage: usage)
        }
    }

    // MARK: - Full content

    private func fullContent(usage: UsageData) -> some View {
        VStack(spacing: 0) {
            // Session estimate (only if data available)
            if AppSettings.showCircularTimers {
                if let hours = UsageHistoryService.estimatedHoursUntilSessionEmpty(
                    currentRemaining: usage.sessionRemaining
                ), let pace = UsageHistoryService.sessionPacePerHour(), pace > minimumMeaningfulPacePerHour {
                    sessionEstimateRow(usage: usage, hours: hours, pace: pace)
                    Divider()
                }
            }

            // Usage sections
            UsageSectionView(
                title: "Session",
                subtitle: "5-hour window",
                remaining: usage.sessionRemaining,
                resetsAt: usage.sessionResetsAt
            )
            Divider()
            UsageSectionView(
                title: "Weekly",
                subtitle: "7-day window",
                remaining: usage.weeklyRemaining,
                resetsAt: usage.weeklyResetsAt
            )
            if let sr = usage.sonnetRemaining, let sra = usage.sonnetResetsAt {
                Divider()
                UsageSectionView(title: "Sonnet", subtitle: "7-day window", remaining: sr, resetsAt: sra)
            }
            if let or = usage.opusRemaining, let ora = usage.opusResetsAt {
                Divider()
                UsageSectionView(title: "Opus", subtitle: "7-day window", remaining: or, resetsAt: ora)
            }

            // Projected usage during rate limit
            if viewModel.rateLimitedUntil != nil {
                projectedUsageRow(usage: usage)
            }

            // Sparkline (needs 5+ points over 30+ min to show)
            if AppSettings.showSparkline {
                let history = UsageHistoryService.recent()
                let hasSpan = history.count >= 5
                    && (history.last.flatMap { last in history.first.map { last.timestamp.timeIntervalSince($0.timestamp) } } ?? 0) >= 1800
                if hasSpan {
                    Divider()
                    HStack(spacing: 10) {
                        SparklineView(
                            snapshots: history,
                            label: "Session (\(formattedSparklineWindow))",
                            keyPath: \.sessionUsed
                        )
                        .frame(maxWidth: .infinity)

                        Divider()

                        SparklineView(
                            snapshots: history,
                            label: "Weekly (\(formattedSparklineWindow))",
                            keyPath: \.weeklyUsed
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            // Plan + Quick actions
            Divider()
            planRow(usage: usage)
            if AppSettings.showQuickActions {
                Divider()
                QuickActionsRow(usage: usage)
            }
        }
    }

    // MARK: - Projected usage (shown during rate limit)

    @ViewBuilder
    private func projectedUsageRow(usage: UsageData) -> some View {
        if let pace = UsageHistoryService.sessionPacePerHour(), pace > minimumMeaningfulPacePerHour {
            let elapsed = -(viewModel.lastRefreshed ?? Date()).timeIntervalSinceNow
            let projectedSessionUsed = min(100, (100 - usage.sessionRemaining) + pace * (elapsed / 3600))

            Divider()
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Projected session usage")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "~%.0f%% (extrapolated from %.0f%%/h pace)", projectedSessionUsed, pace))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.04))
        }
    }

    // MARK: - Circular timers

    /// Whether the ETA exceeds the 5-hour session window, meaning the limit
    /// will reset before it could ever be reached at the current pace.
    private static let sessionWindowHours: Double = 5

    private func sessionEstimateRow(usage: UsageData, hours: Double, pace: Double) -> some View {
        let beyondWindow = hours >= Self.sessionWindowHours

        let ringColor: Color = beyondWindow ? .green : hours < 1 ? .red : hours < 2 ? .yellow : .blue

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(.primary.opacity(0.06), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: min(1, (100 - usage.sessionRemaining) / 100))
                    .stroke(
                        ringColor.opacity(0.85),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ringColor.opacity(0.3), radius: 4)
                VStack(spacing: 0) {
                    if beyondWindow {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.green)
                    } else {
                        Text(etaText(hours))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text("left")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 3) {
                if beyondWindow {
                    Text("Well within session limits")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("At \(String(format: "%.0f%%/h", pace)), your session will reset long before you'd reach the cap. No worries.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Session limit in ~\(etaText(hours))")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("At your current pace (\(String(format: "%.0f%%/h", pace))), you'll hit the 5-hour session cap in about \(etaTextVerbose(hours)).")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ringColor.opacity(0.04))
    }

    private func etaText(_ hours: Double) -> String {
        if hours >= 24 { return "\(Int(hours / 24))d" }
        if hours >= 1  { return String(format: "%.0fh", hours) }
        return "\(Int(hours * 60))m"
    }

    private func etaTextVerbose(_ hours: Double) -> String {
        if hours >= 24 { return "\(Int(hours / 24)) days" }
        if hours >= 1  { return String(format: "%.1f hours", hours) }
        return "\(Int(hours * 60)) minutes"
    }

    private func planRow(usage: UsageData) -> some View {
        let streak = UsageHistoryService.currentStreak()

        return HStack(alignment: .center, spacing: 8) {
            Text("PLAN")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(1)

            Spacer()

            if streak > 0 {
                HStack(spacing: 3) {
                    // Flame glyphs representing each day of streak (up to 7)
                    let shown = min(streak, 7)
                    ForEach(0..<shown, id: \.self) { i in
                        Image(systemName: "flame.fill")
                            .font(.system(size: streak >= 7 ? 10 : 8))
                            .foregroundStyle(
                                i == shown - 1
                                    ? (streak >= 7 ? .orange : .primary.opacity(0.6))
                                    : .primary.opacity(0.15)
                            )
                    }
                    if streak > 7 {
                        Text("+\(streak - 7)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.orange.opacity(0.8))
                    }
                }
                .help("\(streak)-day streak")
            }

            Text(usage.plan)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: 6) {
            if viewModel.isLoading && viewModel.usage == nil && viewModel.rateLimitedUntil == nil {
                ProgressView().scaleEffect(0.6)
            } else {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
            }
            Text(viewModel.lastUpdatedText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Claude Watch v\(appVersion)")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var appVersion: String { AppSettings.appVersion }

    // MARK: - Sparkline helpers

    private var formattedSparklineWindow: String {
        let hours = AppSettings.sparklineHours
        if hours >= 24, hours % 24 == 0 {
            return "\(hours / 24)d"
        }
        return "\(hours)h"
    }

    // MARK: - Status icon helpers

    private var overallRemaining: Double {
        guard let u = viewModel.usage else { return 100 }
        var lowest = min(u.sessionRemaining, u.weeklyRemaining)
        if let s = u.sonnetRemaining { lowest = min(lowest, s) }
        if let o = u.opusRemaining   { lowest = min(lowest, o) }
        return lowest
    }

    private var statusSymbol: String {
        let used = 100 - overallRemaining
        return used >= 40 ? "flame.fill" : "bolt.fill"
    }

    private var statusColor: Color {
        let used = 100 - overallRemaining
        switch used {
        case ..<40:   return .green
        case 40..<60: return .yellow
        case 60..<80: return .orange
        default:      return .red
        }
    }

    // MARK: - Pace helpers

    private func paceIcon(_ pace: Double) -> String {
        switch pace {
        case 20...:   return "hare.fill"
        case 10..<20: return "figure.walk"
        default:      return "tortoise.fill"
        }
    }

    private func paceColor(_ pace: Double) -> Color {
        switch pace {
        case 20...:   return .red
        case 10..<20: return .yellow
        default:      return .green
        }
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        let t = max(0, Int(interval))
        let h = t / 3600; let m = (t % 3600) / 60; let s = t % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}
