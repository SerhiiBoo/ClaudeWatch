import SwiftUI

/// A self-contained card rendered to an NSImage for sharing via the system share sheet.
struct UsageSnapshotView: View {
    let usage: UsageData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            usageRows
            Divider()
            footerRow
        }
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .padding(12) // give shadow room to breathe
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)
            Text("Claude Watch")
                .font(.system(size: 13, weight: .bold))
            Spacer()
            Text(Date(), style: .time)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Usage rows

    private var usageRows: some View {
        VStack(spacing: 0) {
            usageRow(icon: "bolt.fill",      iconColor: .blue,   label: "Session", remaining: usage.sessionRemaining)
            Divider().padding(.leading, 40)
            usageRow(icon: "calendar",       iconColor: .purple, label: "Weekly",  remaining: usage.weeklyRemaining)
            if let sr = usage.sonnetRemaining {
                Divider().padding(.leading, 40)
                usageRow(icon: "message.fill",   iconColor: .cyan,   label: "Sonnet",  remaining: sr)
            }
            if let or = usage.opusRemaining {
                Divider().padding(.leading, 40)
                usageRow(icon: "sparkles",       iconColor: .indigo, label: "Opus",    remaining: or)
            }
        }
    }

    private func usageRow(icon: String, iconColor: Color, label: String, remaining: Double) -> some View {
        let used = 100 - remaining
        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(iconColor)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 50, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.12))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(used))
                        .frame(width: max(0, geo.size.width * CGFloat(used / 100)))
                }
            }
            .frame(height: 6)
            Text(String(format: "%.0f%%", used))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(barColor(used))
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private func barColor(_ used: Double) -> Color {
        switch used {
        case ..<50:   return .green
        case 50..<75: return .yellow
        case 75..<90: return .orange
        default:      return .red
        }
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(usage.plan)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let pace = UsageHistoryService.sessionPacePerHour() {
                HStack(spacing: 3) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f%%/h", pace))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            if let hours = UsageHistoryService.estimatedHoursUntilSessionEmpty(
                currentRemaining: usage.sessionRemaining
            ) {
                HStack(spacing: 3) {
                    Image(systemName: hours >= 5 ? "checkmark.circle.fill" : "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(hours >= 5 ? .green : hours < 1 ? .red : .yellow)
                    Text(hours >= 5 ? "On track" : String(format: "%.1fh left", hours))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}
