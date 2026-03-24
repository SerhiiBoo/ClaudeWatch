import SwiftUI

/// Shows streak, pace indicator, and time-until-empty estimate.
struct StatsRowView: View {
    let usage: UsageData

    private var streak: Int { UsageHistoryService.currentStreak() }
    private var pacePerHour: Double? { UsageHistoryService.sessionPacePerHour() }
    private var hoursUntilEmpty: Double? {
        UsageHistoryService.estimatedHoursUntilSessionEmpty(currentRemaining: usage.sessionRemaining)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Streak
            statBadge(
                icon: "flame.fill",
                color: streak >= 7 ? .orange : .secondary,
                value: "\(streak)d",
                label: "streak"
            )

            // Pace indicator
            if let pace = pacePerHour {
                statBadge(
                    icon: paceIcon(pace),
                    color: paceColor(pace),
                    value: String(format: "%.0f%%/h", pace),
                    label: "pace"
                )
            }

            // Time until empty (only meaningful within the 5h session window)
            if let hours = hoursUntilEmpty {
                if hours >= 5 {
                    statBadge(
                        icon: "checkmark.seal.fill",
                        color: .green,
                        value: "OK",
                        label: "session"
                    )
                } else {
                    statBadge(
                        icon: "hourglass",
                        color: hours < 1 ? .red : hours < 2 ? .yellow : .green,
                        value: formatEstimate(hours),
                        label: "left"
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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

    private func paceIcon(_ pace: Double) -> String {
        switch pace {
        case 20...:  return "hare.fill"          // burning fast
        case 10..<20: return "figure.walk"        // moderate
        default:      return "tortoise.fill"      // chill
        }
    }

    private func paceColor(_ pace: Double) -> Color {
        switch pace {
        case 20...:  return .red
        case 10..<20: return .yellow
        default:      return .green
        }
    }

    private func formatEstimate(_ hours: Double) -> String {
        if hours >= 24 { return "\(Int(hours / 24))d" }
        if hours >= 1  { return String(format: "%.1fh", hours) }
        return "\(Int(hours * 60))m"
    }
}
