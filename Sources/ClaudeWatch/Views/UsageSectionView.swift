import SwiftUI

struct UsageSectionView: View {
    let title: String
    let subtitle: String
    let remaining: Double   // 0–100 (percentage remaining, used internally)
    let resetsAt: Date

    /// Display as "used" — how much of the limit has been consumed
    private var used: Double { 100 - remaining }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(" · \(subtitle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(used.rounded()))% used")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(barColor)
            }

            // Progress bar — fills left-to-right as usage increases
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.primary.opacity(0.06))
                        .overlay {
                            Capsule()
                                .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
                        }
                        .frame(height: 8)
                    Capsule()
                        .fill(
                            .linearGradient(
                                colors: [barColor.opacity(0.9), barColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay {
                            Capsule()
                                .fill(Color.primary.opacity(0.15))
                                .frame(height: 3)
                                .padding(.horizontal, 1)
                        }
                        .frame(width: max(used > 0 ? 8 : 0, geo.size.width * (used / 100)), height: 8)
                }
            }
            .frame(height: 8)

            // Reset countdown
            Label(resetLabel, systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    /// Color reflects severity: green when low usage, red when high
    private var barColor: Color {
        switch used {
        case ..<40:  return .green
        case 40..<80: return .yellow
        default:      return .red
        }
    }

    private var resetLabel: String {
        let timeStr = resetsAt.formatted(date: .omitted, time: .shortened)
        let countdown = formatCountdown(resetsAt.timeIntervalSinceNow)

        if Calendar.current.isDateInToday(resetsAt) {
            return "Resets Today, \(timeStr) · \(countdown)"
        }
        let dateStr = resetsAt.formatted(.dateTime.day().month().year().hour().minute())
        return "Resets \(dateStr) · \(countdown)"
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "now" }
        let total = Int(interval)
        let days    = total / 86_400
        let hours   = (total % 86_400) / 3_600
        let minutes = (total % 3_600) / 60

        if days > 0  { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
