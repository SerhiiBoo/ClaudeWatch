import SwiftUI

struct NotificationCardView: View {
    @ObservedObject var viewModel: NotificationCardViewModel
    let onDismiss: () -> Void
    let onActivate: () -> Void
    let onAllow: (() -> Void)?
    let onDeny: (() -> Void)?

    private var item: NotificationCardItem { viewModel.item }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(item.accentColor)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(6)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Text(item.body)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, onAllow != nil ? 6 : 8)

            if let onAllow, let onDeny {
                HStack(spacing: 8) {
                    Button(action: onDeny) {
                        Text("Deny")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)

                    Button(action: onAllow) {
                        Text("Allow")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            progressBar
        }
        .frame(width: 360)
        .background(RoundedRectangle(cornerRadius: 10).fill(.regularMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(item.borderColor, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .onHover { hovering in
            if hovering { viewModel.pause() } else { viewModel.resume() }
        }
        .onTapGesture { onActivate() }
        .onAppear { viewModel.startTimer() }
        .onDisappear { viewModel.stopTimer() }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.primary.opacity(0.08))
                Rectangle()
                    .fill(item.accentColor)
                    .frame(width: geo.size.width * (1 - viewModel.progress))
            }
        }
        .frame(height: 3)
        .clipShape(RoundedRectangle(cornerRadius: 1.5))
    }
}
