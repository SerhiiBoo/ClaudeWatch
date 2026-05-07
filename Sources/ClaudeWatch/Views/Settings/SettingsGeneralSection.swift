import SwiftUI

extension SettingsView {

    // MARK: - General

    var generalSection: some View {
        settingsSection("General", systemImage: "slider.horizontal.3", subtitle: "App behavior, refresh frequency, and display density.") {
            settingsRow("Launch at Login", systemImage: "power") {
                Toggle("", isOn: $settings.loginItemEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Launch at login")
                    .onChange(of: settings.loginItemEnabled) { _, v in setLoginItem(enabled: v) }
            }
            if let err = settings.loginItemError {
                Text(err).font(.caption2).foregroundStyle(.red)
            }
            settingsRow("Auto-refresh", systemImage: "arrow.clockwise") {
                Picker("", selection: $viewModel.refreshInterval) {
                    Text("2m").tag(120.0 as TimeInterval)
                    Text("3m").tag(180.0 as TimeInterval)
                    Text("5m").tag(300.0 as TimeInterval)
                    Text("10m").tag(600.0 as TimeInterval)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.regular)
                .accessibilityLabel("Auto-refresh interval")
                .fixedSize()
            }
            settingsRow("Appearance", systemImage: "circle.lefthalf.filled") {
                Picker("", selection: $appearanceModeRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.regular)
                .accessibilityLabel("Appearance mode")
                .fixedSize()
            }
            settingsRow("Menu bar", systemImage: "menubar.rectangle") {
                Picker("", selection: $settings.menuBarStyle) {
                    ForEach(MenuBarStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.regular)
                .accessibilityLabel("Menu bar style")
                .fixedSize()
                .onChange(of: settings.menuBarStyle) { _, v in
                    AppSettings.menuBarStyle = v
                    NotificationCenter.default.post(name: .menuBarSettingsDidChange, object: nil)
                }
            }
            iconPicker
        }
    }

    var iconPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Menu bar icon")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(MenuBarIcon.allCases) { icon in
                    Button { settings.menuBarIcon = icon } label: {
                        VStack(spacing: 3) {
                            Image(nsImage: MenuBarIconRenderer.render(style: icon, fraction: iconPickerPreviewFraction))
                                .frame(width: 22, height: 22)
                            Text(icon.displayName)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(settings.menuBarIcon == icon ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(settings.menuBarIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Menu bar icon: \(icon.displayName)")
                }
            }
        }
    }
}
