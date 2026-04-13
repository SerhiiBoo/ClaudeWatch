import SwiftUI

extension SettingsView {

    // MARK: - Visible Sections

    var visibleSectionsSection: some View {
        settingsSection("Visible Sections", subtitle: "Show or hide individual widget sections.") {
            settingsRow("Session limit estimate") {
                Toggle("", isOn: $settings.showCircularTimers)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Session limit estimate")
                    .onChange(of: settings.showCircularTimers) { _, v in AppSettings.showCircularTimers = v }
            }
            settingsRow("Sparkline charts") {
                Toggle("", isOn: $settings.showSparkline)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Sparkline charts")
                    .onChange(of: settings.showSparkline) { _, v in AppSettings.showSparkline = v }
            }
            settingsRow("Quick actions") {
                Toggle("", isOn: $settings.showQuickActions)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Quick actions")
                    .onChange(of: settings.showQuickActions) { _, v in AppSettings.showQuickActions = v }
            }
        }
    }

    // MARK: - Charts & Pace

    var chartsPaceSection: some View {
        settingsSection("Charts & Pace", subtitle: "How much history to show in charts and how far back to calculate your usage rate. Data is only collected while the app is running.") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sparkline window")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $settings.sparklineHours) {
                    Text("6h").tag(6)
                    Text("12h").tag(12)
                    Text("24h").tag(24)
                    Text("7d").tag(168)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Sparkline window")
                .onChange(of: settings.sparklineHours) { _, v in AppSettings.sparklineHours = v }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Pace lookback")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $settings.paceWindowHours) {
                    Text("1h").tag(1.0)
                    Text("2h").tag(2.0)
                    Text("4h").tag(4.0)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Pace lookback window")
                .onChange(of: settings.paceWindowHours) { _, v in AppSettings.paceWindowHours = v }
            }
        }
    }
}
