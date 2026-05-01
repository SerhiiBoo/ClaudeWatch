import SwiftUI

extension SettingsView {

    // MARK: - Visible Sections

    var visibleSectionsSection: some View {
        settingsSection("Visible Sections", systemImage: "eye", subtitle: "Show or hide individual widget sections.") {
            settingsRow("Session limit estimate", systemImage: "gauge.with.dots.needle.50percent") {
                Toggle("", isOn: $settings.showCircularTimers)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Session limit estimate")
                    .onChange(of: settings.showCircularTimers) { _, v in AppSettings.showCircularTimers = v }
            }
            settingsRow("Sparkline charts", systemImage: "chart.xyaxis.line") {
                Toggle("", isOn: $settings.showSparkline)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Sparkline charts")
                    .onChange(of: settings.showSparkline) { _, v in AppSettings.showSparkline = v }
            }
            settingsRow("Quick actions", systemImage: "bolt.fill") {
                Toggle("", isOn: $settings.showQuickActions)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Quick actions")
                    .onChange(of: settings.showQuickActions) { _, v in AppSettings.showQuickActions = v }
            }
            settingsRow("Extra usage", systemImage: "chart.bar.fill") {
                Toggle("", isOn: $settings.showExtraUsage)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Extra usage")
                    .onChange(of: settings.showExtraUsage) { _, v in AppSettings.showExtraUsage = v }
            }
        }
    }

    // MARK: - Charts & Pace

    var chartsPaceSection: some View {
        settingsSection("Charts & Pace", systemImage: "waveform.path.ecg", subtitle: "How much history to show in charts and how far back to calculate your usage rate. Data is only collected while the app is running.") {
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
