import SwiftUI

extension PopoverView {

    // MARK: - Session estimate (circular timer)

    func sessionEstimateRow(usage: UsageData, paceStatus: PaceStatus) -> some View {
        let pressure  = paceStatus.pressure
        let pace      = paceStatus.pacePerHour
        let hours     = paceStatus.etaHours

        let ringColor: Color = pressure.color

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
                    if pressure == .beyondWindow {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.green)
                    } else if let h = hours {
                        Text(etaText(h))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text("left")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 3) {
                if pressure == .beyondWindow {
                    Text("Well within session limits")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("At \(String(format: "%.0f%%/h", pace)), your session will reset long before you'd reach the cap. No worries.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let h = hours {
                    Text("Session limit in ~\(etaText(h))")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("At your current pace (\(String(format: "%.0f%%/h", pace))), you'll hit the 5-hour session cap in about \(etaTextVerbose(h)).")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Session limit approaching")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("At \(String(format: "%.0f%%/h", pace)), the 5-hour cap could be within reach. Keep an eye on it.")
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

    func etaText(_ hours: Double) -> String {
        DurationFormatter.shortRounded(hours: hours)
    }

    func etaTextVerbose(_ hours: Double) -> String {
        DurationFormatter.verbose(hours: hours)
    }
}
