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

    // MARK: - Hook Notifications

    var hookNotificationsSection: some View {
        settingsSection("Claude Code Hooks", subtitle: "Notifications when Claude Code needs your attention or finishes work.", badge: "Beta") {
            settingsRow("Enable hook notifications") {
                Toggle("", isOn: $settings.hookNotificationsEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Enable hook notifications")
                    .onChange(of: settings.hookNotificationsEnabled) { _, v in
                        AppSettings.hookNotificationsEnabled = v
                        if v { try? HookInstaller.shared.install() }
                        else { try? HookInstaller.shared.uninstall() }
                        NotificationCenter.default.post(name: .permissionApprovalSettingDidChange, object: nil)
                    }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Writes to ~/.claude/settings.json:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("• Notification, Stop hooks (always when enabled)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("• PreToolUse hook, matcher Bash|mcp__.* (when Permission approval is on)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Existing settings are preserved on both install and uninstall.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, 2)
            if settings.hookNotificationsEnabled {
                settingsRow("Style") {
                    Picker("", selection: $settings.hookDeliveryStyle) {
                        ForEach(HookDeliveryStyle.allCases, id: \.self) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .labelsHidden()
                    .onChange(of: settings.hookDeliveryStyle) { _, v in AppSettings.hookDeliveryStyle = v }
                }
                VStack(alignment: .leading, spacing: 2) {
                    settingsRow("Notification events") {
                        Toggle("", isOn: $settings.hookNotificationEventEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                            .accessibilityLabel("Notification events")
                            .onChange(of: settings.hookNotificationEventEnabled) { _, v in AppSettings.hookNotificationEventEnabled = v }
                    }
                    Text("Claude Code pauses and waits for your input")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if settings.hookNotificationEventEnabled && settings.hookDeliveryStyle == .popover {
                        settingsRow("Timeout") {
                            HStack(spacing: 8) {
                                Slider(value: $settings.hookNotificationTimeout, in: 5...60, step: 1)
                                    .frame(width: 120)
                                    .onChange(of: settings.hookNotificationTimeout) { _, v in AppSettings.hookNotificationTimeout = v }
                                Text("\(Int(settings.hookNotificationTimeout))s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, alignment: .leading)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    settingsRow("Stop events") {
                        Toggle("", isOn: $settings.hookStopEventEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                            .accessibilityLabel("Stop events")
                            .onChange(of: settings.hookStopEventEnabled) { _, v in AppSettings.hookStopEventEnabled = v }
                    }
                    Text("Claude Code finishes a task")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if settings.hookStopEventEnabled && settings.hookDeliveryStyle == .popover {
                        settingsRow("Timeout") {
                            HStack(spacing: 8) {
                                Slider(value: $settings.hookStopTimeout, in: 3...30, step: 1)
                                    .frame(width: 120)
                                    .onChange(of: settings.hookStopTimeout) { _, v in AppSettings.hookStopTimeout = v }
                                Text("\(Int(settings.hookStopTimeout))s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, alignment: .leading)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    settingsRow("Permission approval") {
                        Toggle("", isOn: $settings.permissionApprovalEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                            .accessibilityLabel("Permission approval")
                            .onChange(of: settings.permissionApprovalEnabled) { _, v in
                                AppSettings.permissionApprovalEnabled = v
                                NotificationCenter.default.post(name: .permissionApprovalSettingDidChange, object: nil)
                            }
                    }
                    Text("Show Allow/Deny prompt when terminal isn't visible")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if settings.permissionApprovalEnabled && settings.hookDeliveryStyle == .popover {
                        settingsRow("Timeout") {
                            HStack(spacing: 8) {
                                Slider(value: $settings.permissionApprovalTimeout, in: 5...120, step: 5)
                                    .frame(width: 120)
                                    .onChange(of: settings.permissionApprovalTimeout) { _, v in
                                        AppSettings.permissionApprovalTimeoutSeconds = Int(v)
                                    }
                                Text("\(Int(settings.permissionApprovalTimeout))s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, alignment: .leading)
                            }
                        }
                    }
                }
                settingsRow("Sound") {
                    Toggle("", isOn: $settings.hookSoundEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                        .accessibilityLabel("Sound")
                        .onChange(of: settings.hookSoundEnabled) { _, v in AppSettings.hookSoundEnabled = v }
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
