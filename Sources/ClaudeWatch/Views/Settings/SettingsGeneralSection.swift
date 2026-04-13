import SwiftUI

extension SettingsView {

    // MARK: - General

    var generalSection: some View {
        settingsSection("General", subtitle: "App behavior, refresh frequency, and display density.") {
            settingsRow("Launch at Login") {
                Toggle("", isOn: $settings.loginItemEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Launch at login")
                    .onChange(of: settings.loginItemEnabled) { _, v in setLoginItem(enabled: v) }
            }
            if let err = settings.loginItemError {
                Text(err).font(.caption2).foregroundStyle(.red)
            }
            settingsRow("Auto-refresh") {
                Picker("", selection: $viewModel.refreshInterval) {
                    Text("2m").tag(120.0 as TimeInterval)
                    Text("3m").tag(180.0 as TimeInterval)
                    Text("5m").tag(300.0 as TimeInterval)
                    Text("10m").tag(600.0 as TimeInterval)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Auto-refresh interval")
                .fixedSize()
            }
            settingsRow("Compact mode") {
                Toggle("", isOn: $settings.compactMode)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Compact mode")
                    .onChange(of: settings.compactMode) { _, v in AppSettings.compactMode = v }
            }
            settingsRow("Appearance") {
                Picker("", selection: $appearanceModeRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Appearance mode")
                .fixedSize()
            }
            settingsRow("Menu bar") {
                Picker("", selection: $settings.menuBarStyle) {
                    ForEach(MenuBarStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Menu bar style")
                .fixedSize()
                .onChange(of: settings.menuBarStyle) { _, v in
                    AppSettings.menuBarStyle = v
                    NotificationCenter.default.post(name: .usageDidUpdate, object: nil)
                }
            }
            iconPicker
        }
    }

    var iconPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Menu bar icon")
                .font(.caption)
            HStack(spacing: 6) {
                ForEach(MenuBarIcon.allCases) { icon in
                    Button { settings.menuBarIcon = icon } label: {
                        VStack(spacing: 3) {
                            Image(nsImage: MenuBarIconRenderer.render(style: icon, fraction: iconPickerPreviewFraction))
                                .frame(width: 18, height: 18)
                            Text(icon.displayName)
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(settings.menuBarIcon == icon ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(settings.menuBarIcon == icon ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Menu bar icon: \(icon.displayName)")
                }
            }
        }
    }
}
