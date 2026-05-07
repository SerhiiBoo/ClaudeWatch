import SwiftUI

/// Shared layout helpers used across SettingsView and its extensions.
extension SettingsView {

    func accentIconBadge(systemImage: String, badgeSize: CGFloat, fontSize: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: badgeSize * 0.28)
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: badgeSize, height: badgeSize)
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
    }

    func settingsSection<Content: View>(
        _ title: String,
        systemImage: String? = nil,
        subtitle: String? = nil,
        badge: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let systemImage {
                    accentIconBadge(systemImage: systemImage, badgeSize: 18, fontSize: 9)
                }
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                if let badge {
                    Text(badge.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange))
                }
                Spacer()
            }
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .primary.opacity(0.08), radius: 3, y: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        .linearGradient(
                            colors: [Color.primary.opacity(0.15), Color.primary.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
        }
    }

    func settingsRow<Trailing: View>(
        _ label: String,
        systemImage: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: UI.Size.settingsRowIconWidth, alignment: .center)
            }
            Text(label)
                .font(.system(.callout, weight: .medium))
            Spacer()
            trailing()
        }
    }
}
