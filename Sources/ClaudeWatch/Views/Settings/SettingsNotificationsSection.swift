import SwiftUI

extension SettingsView {

    // MARK: - Notifications

    static let thresholdPresets: [(label: String, values: [Double])] = [
        ("50/80/90", [50, 80, 90]),
        ("25/50/75", [25, 50, 75]),
        ("70/85/95", [70, 85, 95]),
    ]

    var notificationsSection: some View {
        settingsSection("Notifications", subtitle: "macOS alerts when session, weekly, Sonnet, or Opus usage crosses a threshold.") {
            settingsRow("Usage alerts") {
                Toggle("", isOn: $settings.notificationsEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Usage alerts")
                    .onChange(of: settings.notificationsEnabled) { _, v in AppSettings.notificationsEnabled = v }
            }
            if settings.notificationsEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Thresholds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !settings.thresholds.isEmpty {
                        FlowLayout(spacing: 4) {
                            ForEach(settings.thresholds, id: \.self) { value in
                                thresholdChip(value)
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("e.g. 75", text: $settings.newThresholdText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .controlSize(.small)
                            .onSubmit { addThreshold() }
                        Text("%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Add") { addThreshold() }
                            .controlSize(.small)
                            .disabled(settings.newThresholdText.isEmpty)
                    }
                    HStack(spacing: 6) {
                        Text("Presets:")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        ForEach(Self.thresholdPresets, id: \.label) { preset in
                            Button(preset.label) {
                                settings.thresholds = preset.values
                                persistThresholds()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    Button {
                        NotificationService.sendTestNotifications()
                    } label: {
                        Label("Send Test Notifications", systemImage: "bell.badge")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Threshold helpers

    func addThreshold() {
        let text = settings.newThresholdText.trimmingCharacters(in: .whitespaces)
        guard let value = Double(text), value >= 1, value <= 100 else {
            settings.newThresholdText = ""
            return
        }
        let rounded = value.rounded()
        if !settings.thresholds.contains(rounded) {
            settings.thresholds = (settings.thresholds + [rounded]).sorted()
        }
        settings.newThresholdText = ""
        persistThresholds()
    }

    func removeThreshold(_ value: Double) {
        settings.thresholds = settings.thresholds.filter { $0 != value }
        persistThresholds()
    }

    func persistThresholds() {
        AppSettings.notificationThresholds = settings.thresholds
    }

    func thresholdChip(_ value: Double) -> some View {
        let color = chipColor(value)
        return HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(Int(value))%")
                .font(.caption)
                .fontWeight(.semibold)
            Button {
                removeThreshold(value)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(Int(value))% threshold")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 0.5))
    }

    func chipColor(_ threshold: Double) -> Color {
        switch threshold {
        case 80...: return .red
        case 50..<80: return .orange
        default: return .blue
        }
    }
}
