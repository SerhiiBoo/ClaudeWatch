import SwiftUI

/// Shows streak, pace indicator, and time-until-empty estimate.
struct StatsRowView: View {
    let usage: UsageData

    @State private var streak: Int = 0
    @State private var paceStatus = PaceStatus(pressure: .unknown, pacePerHour: 0, etaHours: nil)

    var body: some View {
        let status = paceStatus
        return HStack(spacing: 12) {
            // Streak
            statBadge(
                icon: "flame.fill",
                color: streak >= 7 ? .orange : .secondary,
                value: "\(streak)d",
                label: "streak"
            )

            // Pace indicator
            if status.pressure != .unknown {
                statBadge(
                    icon: PaceClassifier.rawPaceIcon(status.pacePerHour),
                    color: PaceClassifier.rawPaceColor(status.pacePerHour),
                    value: String(format: "%.0f%%/h", status.pacePerHour),
                    label: "pace"
                )
            }

            // Session ETA badge
            switch status.pressure {
            case .unknown:
                EmptyView()
            case .beyondWindow:
                statBadge(icon: "checkmark.seal.fill", color: .green, value: "OK", label: "session")
            case .comfortable, .watch, .urgent:
                if let hours = status.etaHours {
                    statBadge(
                        icon: "hourglass",
                        color: status.pressure == .urgent ? .red : status.pressure == .watch ? .yellow : .green,
                        value: formatEstimate(hours),
                        label: "left"
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onAppear { reloadStats() }
        .onChange(of: usage) { _, _ in reloadStats() }
    }

    private func reloadStats() {
        streak = UsageHistoryService.currentStreak()
        paceStatus = PaceClassifier.classify(
            pace: UsageHistoryService.sessionPacePerHour() ?? 0,
            etaHours: UsageHistoryService.estimatedHoursUntilSessionEmpty(currentRemaining: usage.sessionRemaining)
        )
    }

    private func statBadge(icon: String, color: Color, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption2)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatEstimate(_ hours: Double) -> String {
        DurationFormatter.short(hours: hours)
    }
}
