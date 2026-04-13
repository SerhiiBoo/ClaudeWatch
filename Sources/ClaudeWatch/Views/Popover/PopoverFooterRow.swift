import SwiftUI

extension PopoverView {

    // MARK: - Footer row

    var footerRow: some View {
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
                NotificationCenter.default.post(name: .miniGameManualTrigger, object: nil)
            } label: {
                Image(systemName: "gamecontroller")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Play Token Rush")
            .accessibilityLabel("Play Token Rush")

            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .accessibilityLabel("Refresh usage data")

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
