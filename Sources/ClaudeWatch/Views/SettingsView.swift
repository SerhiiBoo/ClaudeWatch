import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var viewModel: UsageViewModel
    var onDismiss: () -> Void

    @State private var loginItemEnabled: Bool = (SMAppService.mainApp.status == .enabled)
    @State private var loginItemError: String?

    @State private var notificationsEnabled = AppSettings.notificationsEnabled
    @State private var thresholds = AppSettings.notificationThresholds.sorted()
    @State private var newThresholdText = ""
    @State private var sparklineHours = AppSettings.sparklineHours
    @State private var paceWindowHours = AppSettings.paceWindowHours
    @State private var showCircularTimers = AppSettings.showCircularTimers
    @State private var showSparkline = AppSettings.showSparkline
    @State private var showQuickActions = AppSettings.showQuickActions
    @State private var terminalApp = AppSettings.terminalApp
    @State private var terminalWorkingDirectory = AppSettings.terminalWorkingDirectory
    @State private var compactMode = AppSettings.compactMode
    @State private var menuBarStyle = AppSettings.menuBarStyle
    @State private var menuBarIcon = AppSettings.menuBarIcon
    @State private var globalHotkeyEnabled = AppSettings.globalHotkeyEnabled
    @State private var globalHotkeyKeyCode = AppSettings.globalHotkeyKeyCode
    @State private var globalHotkeyModifiers = AppSettings.globalHotkeyModifiers
    @State private var logsCopiedMessage: String?
    @State private var clearTask: Task<Void, Never>?

    private let iconPickerPreviewFraction: Double = 0.75

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    generalSection
                    hotkeysSection
                    visibleSectionsSection
                    chartsPaceSection
                    notificationsSection
                    terminalSection
                    diagnosticsSection
                    credentialsNote
                    errorBanner
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 420)
            Divider()
            footerActions
        }
        .frame(width: 300)
        .onChange(of: menuBarIcon) { _, v in
            AppSettings.menuBarIcon = v
            NotificationCenter.default.post(name: .usageDidUpdate, object: nil)
        }
        .onDisappear {
            clearTask?.cancel()
        }
    }

    // MARK: - Title & Footer

    private var titleBar: some View {
        HStack {
            Text("Settings")
                .font(.headline)
            Spacer()
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var footerActions: some View {
        HStack {
            Button("Refresh Now") {
                viewModel.refresh()
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            Text("v\(appVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - General

    private var generalSection: some View {
        settingsSection("General", subtitle: "App behavior, refresh frequency, and display density.") {
            settingsRow("Launch at Login") {
                Toggle("", isOn: $loginItemEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .onChange(of: loginItemEnabled) { _, v in setLoginItem(enabled: v) }
            }
            if let err = loginItemError {
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
                .fixedSize()
            }
            settingsRow("Compact mode") {
                Toggle("", isOn: $compactMode)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .onChange(of: compactMode) { _, v in AppSettings.compactMode = v }
            }
            settingsRow("Menu bar") {
                Picker("", selection: $menuBarStyle) {
                    ForEach(MenuBarStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
                .onChange(of: menuBarStyle) { _, v in
                    AppSettings.menuBarStyle = v
                    NotificationCenter.default.post(name: .usageDidUpdate, object: nil)
                }
            }
            iconPicker
        }
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Menu bar icon")
                .font(.caption)
            HStack(spacing: 6) {
                ForEach(MenuBarIcon.allCases) { icon in
                    Button { menuBarIcon = icon } label: {
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
                                .fill(menuBarIcon == icon ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(menuBarIcon == icon ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Hotkeys

    private var hotkeysSection: some View {
        settingsSection("Hotkeys", subtitle: "Global keyboard shortcut to show or hide the ClaudeWatch popover from anywhere.") {
            settingsRow("Global shortcut") {
                Toggle("", isOn: $globalHotkeyEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .onChange(of: globalHotkeyEnabled) { _, v in
                        AppSettings.globalHotkeyEnabled = v
                        HotkeyService.shared.updateFromSettings()
                    }
            }
            if globalHotkeyEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shortcut")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HotkeyRecorderView(
                        keyCode: $globalHotkeyKeyCode,
                        carbonModifiers: $globalHotkeyModifiers
                    )
                    .frame(height: 24)
                    .onChange(of: globalHotkeyKeyCode) { _, v in
                        AppSettings.globalHotkeyKeyCode = v
                        HotkeyService.shared.updateFromSettings()
                    }
                    .onChange(of: globalHotkeyModifiers) { _, v in
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

    // MARK: - Visible Sections

    private var visibleSectionsSection: some View {
        settingsSection("Visible Sections", subtitle: "Show or hide individual widget sections.") {
            settingsRow("Session limit estimate") {
                Toggle("", isOn: $showCircularTimers)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .onChange(of: showCircularTimers) { _, v in AppSettings.showCircularTimers = v }
            }
            settingsRow("Sparkline charts") {
                Toggle("", isOn: $showSparkline)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .onChange(of: showSparkline) { _, v in AppSettings.showSparkline = v }
            }
            settingsRow("Quick actions") {
                Toggle("", isOn: $showQuickActions)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .onChange(of: showQuickActions) { _, v in AppSettings.showQuickActions = v }
            }
        }
    }

    // MARK: - Charts & Pace

    private var chartsPaceSection: some View {
        settingsSection("Charts & Pace", subtitle: "How much history to show in charts and how far back to calculate your usage rate. Data is only collected while the app is running.") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sparkline window")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $sparklineHours) {
                    Text("6h").tag(6)
                    Text("12h").tag(12)
                    Text("24h").tag(24)
                    Text("7d").tag(168)
                }
                .pickerStyle(.segmented)
                .onChange(of: sparklineHours) { _, v in AppSettings.sparklineHours = v }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Pace lookback")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $paceWindowHours) {
                    Text("1h").tag(1.0)
                    Text("2h").tag(2.0)
                    Text("4h").tag(4.0)
                }
                .pickerStyle(.segmented)
                .onChange(of: paceWindowHours) { _, v in AppSettings.paceWindowHours = v }
            }
        }
    }

    // MARK: - Notifications

    private static let thresholdPresets: [(label: String, values: [Double])] = [
        ("50/80/90", [50, 80, 90]),
        ("25/50/75", [25, 50, 75]),
        ("70/85/95", [70, 85, 95]),
    ]

    private var notificationsSection: some View {
        settingsSection("Notifications", subtitle: "macOS alerts when session, weekly, Sonnet, or Opus usage crosses a threshold.") {
            settingsRow("Usage alerts") {
                Toggle("", isOn: $notificationsEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .onChange(of: notificationsEnabled) { _, v in AppSettings.notificationsEnabled = v }
            }
            if notificationsEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Thresholds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !thresholds.isEmpty {
                        FlowLayout(spacing: 4) {
                            ForEach(thresholds, id: \.self) { value in
                                thresholdChip(value)
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("e.g. 75", text: $newThresholdText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .controlSize(.small)
                            .onSubmit { addThreshold() }
                        Text("%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Add") { addThreshold() }
                            .controlSize(.small)
                            .disabled(newThresholdText.isEmpty)
                    }
                    HStack(spacing: 4) {
                        Text("Presets:")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                        ForEach(Self.thresholdPresets, id: \.label) { preset in
                            Button(preset.label) {
                                thresholds = preset.values
                                persistThresholds()
                            }
                            .font(.system(size: 9))
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
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

    // MARK: - Terminal / IDE

    private var terminalSection: some View {
        settingsSection("Terminal / IDE", subtitle: "Which app to launch when you tap the quick action button. Requires Automation permission on first use.") {
            settingsRow("Open in") {
                Picker("", selection: $terminalApp) {
                    ForEach(TerminalAppCategory.allCases) { cat in
                        Section(cat.rawValue) {
                            ForEach(TerminalApp.allCases.filter { $0.category == cat }) { app in
                                Text(app.displayName).tag(app)
                            }
                        }
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
                .onChange(of: terminalApp) { _, v in AppSettings.terminalApp = v }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Working directory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(terminalWorkingDirectory.isEmpty ? "Default" : abbreviatePath(terminalWorkingDirectory))
                        .font(.caption)
                        .foregroundStyle(terminalWorkingDirectory.isEmpty ? .tertiary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Choose...") {
                        chooseWorkingDirectory()
                    }
                    .controlSize(.small)
                    if !terminalWorkingDirectory.isEmpty {
                        Button {
                            terminalWorkingDirectory = ""
                            AppSettings.terminalWorkingDirectory = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Diagnostics

    private var diagnosticsSection: some View {
        settingsSection("Diagnostics", subtitle: "Error logs for troubleshooting. Logs auto-rotate at 500 KB.") {
            HStack(spacing: 8) {
                Button {
                    copyLogsToClipboard()
                } label: {
                    Label("Copy Logs", systemImage: "doc.on.clipboard")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    exportLogs()
                } label: {
                    Label("Export Logs", systemImage: "square.and.arrow.up")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button {
                    LogService.clearAll()
                    logsCopiedMessage = "Logs cleared"
                    clearCopiedMessage()
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if let msg = logsCopiedMessage {
                Text(msg)
                    .font(.caption2)
                    .foregroundStyle(.green)
            }

            let size = LogService.totalSize()
            Text("Log size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Info banners

    @ViewBuilder
    private var credentialsNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "key.fill")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("Credentials read from Keychain. Run `claude` to refresh.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let err = viewModel.errorMessage {
            Label(err, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Layout helpers

    private func settingsSection<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func settingsRow<Trailing: View>(_ label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            trailing()
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private func setLoginItem(enabled: Bool) {
        loginItemError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            loginItemError = error.localizedDescription
            loginItemEnabled = !enabled
        }
    }

    private func addThreshold() {
        let text = newThresholdText.trimmingCharacters(in: .whitespaces)
        guard let value = Double(text), value >= 1, value <= 100 else {
            newThresholdText = ""
            return
        }
        let rounded = value.rounded()
        if !thresholds.contains(rounded) {
            thresholds = (thresholds + [rounded]).sorted()
        }
        newThresholdText = ""
        persistThresholds()
    }

    private func removeThreshold(_ value: Double) {
        thresholds = thresholds.filter { $0 != value }
        persistThresholds()
    }

    private func persistThresholds() {
        AppSettings.notificationThresholds = thresholds
    }

    private func thresholdChip(_ value: Double) -> some View {
        let color = chipColor(value)
        return HStack(spacing: 3) {
            Text("\(Int(value))%")
                .font(.caption2)
                .fontWeight(.medium)
            Button {
                removeThreshold(value)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private func chipColor(_ threshold: Double) -> Color {
        switch threshold {
        case 80...: return .red
        case 50..<80: return .orange
        default: return .blue
        }
    }

    private func chooseWorkingDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Choose the folder to open in your terminal or IDE"
        if panel.runModal() == .OK, let url = panel.url {
            terminalWorkingDirectory = url.path
            AppSettings.terminalWorkingDirectory = url.path
        }
    }

    private func copyLogsToClipboard() {
        if let logs = LogService.allLogs() {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(logs, forType: .string)
            logsCopiedMessage = "Copied to clipboard"
        } else {
            logsCopiedMessage = "No logs to copy"
        }
        clearCopiedMessage()
    }

    private func exportLogs() {
        guard let logs = LogService.allLogs() else {
            logsCopiedMessage = "No logs to export"
            clearCopiedMessage()
            return
        }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "claudewatch-logs.txt"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try logs.write(to: url, atomically: true, encoding: .utf8)
                logsCopiedMessage = "Exported"
            } catch {
                logsCopiedMessage = "Export failed: \(error.localizedDescription)"
            }
            clearCopiedMessage()
        }
    }

    private func clearCopiedMessage() {
        clearTask?.cancel()
        clearTask = Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { logsCopiedMessage = nil }
        }
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
