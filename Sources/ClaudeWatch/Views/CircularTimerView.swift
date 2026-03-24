import SwiftUI

/// Circular countdown ring showing usage percentage and time until reset.
struct CircularTimerView: View {
    let title: String
    let subtitle: String      // e.g. "Resets in" or "Runs out in"
    let resetsAt: Date
    let windowDuration: TimeInterval
    let usedPercent: Double?   // 0-100, shown inside ring. nil = show countdown instead.

    init(title: String, subtitle: String = "Resets in", resetsAt: Date,
         windowDuration: TimeInterval, usedPercent: Double? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.resetsAt = resetsAt
        self.windowDuration = windowDuration
        self.usedPercent = usedPercent
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, resetsAt.timeIntervalSince(context.date))
            let progress = 1 - (remaining / windowDuration)

            VStack(spacing: 3) {
                ZStack {
                    // Track
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 4)
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: min(1, progress))
                        .stroke(
                            ringColor(progress: progress),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    // Center: percentage if available, otherwise countdown
                    if let pct = usedPercent {
                        Text("\(Int(pct))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    } else {
                        Text(shortCountdown(remaining))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(width: 52, height: 52)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary)

                Text("\(subtitle) \(shortCountdown(remaining))")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ringColor(progress: Double) -> Color {
        switch progress {
        case ..<0.4:  return .green
        case 0.4..<0.8: return .yellow
        default:      return .red
        }
    }

    private func shortCountdown(_ interval: TimeInterval) -> String {
        let t = Int(interval)
        let d = t / 86400
        let h = (t % 86400) / 3600
        let m = (t % 3600) / 60
        if d > 0 { return "\(d)d \(h)h" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
