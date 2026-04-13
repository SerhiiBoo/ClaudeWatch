import SwiftUI

extension PopoverView {

    // MARK: - Usage sections stack (compact and full variants)

    func compactContent(usage: UsageData, sessionPace: Double?, paceStatus: PaceStatus) -> some View {
        VStack(spacing: 0) {
            if paceStatus.pressure != .unknown {
                sessionEstimateRow(usage: usage, paceStatus: paceStatus)
                Divider()
            }

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
            if let extra = usage.extraUsage, shouldShowExtraUsage(extra) {
                Divider()
                ExtraUsageSectionView(data: extra)
            }

            // Projected usage during rate limit
            if viewModel.rateLimitedUntil != nil {
                projectedUsageRow(usage: usage, sessionPace: sessionPace)
            }

            Divider()
            planRow(usage: usage)
        }
    }

    func fullContent(
        usage: UsageData,
        sessionPace: Double?,
        recentHistory: [UsageSnapshot],
        paceStatus: PaceStatus
    ) -> some View {
        VStack(spacing: 0) {
            // Session estimate (always shown when pace data is available)
            if paceStatus.pressure != .unknown {
                sessionEstimateRow(usage: usage, paceStatus: paceStatus)
                Divider()
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
            if let extra = usage.extraUsage, shouldShowExtraUsage(extra) {
                Divider()
                ExtraUsageSectionView(data: extra)
            }

            // Projected usage during rate limit
            if viewModel.rateLimitedUntil != nil {
                projectedUsageRow(usage: usage, sessionPace: sessionPace)
            }

            // Sparkline (needs 5+ points over 30+ min to show)
            if showSparkline {
                if sparklineHasSpan(recentHistory) {
                    Divider()
                    HStack(spacing: 10) {
                        SparklineView(
                            snapshots: recentHistory,
                            label: "Session (\(formattedSparklineWindow))",
                            keyPath: \.sessionUsed
                        )
                        .frame(maxWidth: .infinity)

                        Divider()

                        SparklineView(
                            snapshots: recentHistory,
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
            if showQuickActions {
                Divider()
                QuickActionsRow(usage: usage, paceStatus: paceStatus)
            }
        }
    }

    // MARK: - Projected usage (shown during rate limit)

    @ViewBuilder
    func projectedUsageRow(usage: UsageData, sessionPace: Double?) -> some View {
        if let pace = sessionPace, pace > PaceClassifier.minimumMeaningfulPacePerHour {
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

    // MARK: - Helpers

    func shouldShowExtraUsage(_ extra: ExtraUsageData) -> Bool {
        extra.isEnabled || extra.spentDollars > 0
    }

    func sparklineHasSpan(_ history: [UsageSnapshot]) -> Bool {
        guard history.count >= UI.Sparkline.minimumPoints,
              let first = history.first,
              let last = history.last else { return false }
        return last.timestamp.timeIntervalSince(first.timestamp) >= UI.Sparkline.minimumSpanSeconds
    }
}
