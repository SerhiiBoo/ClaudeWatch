import SwiftUI

extension PopoverView {

    // MARK: - Rate-limit banner

    @ViewBuilder
    var rateLimitBanner: some View {
        if let until = viewModel.rateLimitedUntil {
            // When lastRefreshed is unavailable, assume a 5-minute default window so the
            // progress ring starts at a meaningful position rather than collapsing to 0.
            let defaultWaitWindow: TimeInterval = 300
            let totalWait = max(60, viewModel.lastRefreshed.map { until.timeIntervalSince($0) } ?? defaultWaitWindow)
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

    func rateLimitRow(remaining: TimeInterval, totalWait: TimeInterval) -> some View {
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
                Text("API rate limited \u{00b7} retrying in \(DurationFormatter.countdownWithSeconds(from: remaining))")
                    .font(.caption)
                    .foregroundStyle(.primary)
                Text("This is the usage API, not your Claude quota")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            Button {
                NotificationCenter.default.post(name: .miniGameManualTrigger, object: nil)
            } label: {
                Text("Play Token Rush")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.06))
    }

    func bannerRow(icon: String, color: Color, text: String) -> some View {
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

}
