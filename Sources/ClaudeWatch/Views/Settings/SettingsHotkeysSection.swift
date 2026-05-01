import SwiftUI

extension SettingsView {

    // MARK: - Hotkeys

    var hotkeysSection: some View {
        settingsSection("Hotkeys", systemImage: "keyboard", subtitle: "Global keyboard shortcut to show or hide the ClaudeWatch popover from anywhere.") {
            settingsRow("Enable hotkey", systemImage: "command") {
                Toggle("", isOn: $settings.globalHotkeyEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Enable global hotkey")
                    .onChange(of: settings.globalHotkeyEnabled) { _, v in
                        AppSettings.globalHotkeyEnabled = v
                        HotkeyService.shared.updateFromSettings()
                    }
            }
            if settings.globalHotkeyEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shortcut")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HotkeyRecorderView(
                        keyCode: $settings.globalHotkeyKeyCode,
                        carbonModifiers: $settings.globalHotkeyModifiers
                    )
                    .frame(height: 24)
                    .onChange(of: settings.globalHotkeyKeyCode) { _, v in
                        AppSettings.globalHotkeyKeyCode = v
                        HotkeyService.shared.updateFromSettings()
                    }
                    .onChange(of: settings.globalHotkeyModifiers) { _, v in
                        AppSettings.globalHotkeyModifiers = v
                        HotkeyService.shared.updateFromSettings()
                    }
                    Text("Default: ⌘⇧W — click the field and press a new combination to change")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
