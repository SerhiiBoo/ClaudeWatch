import SwiftUI

extension SettingsView {

    // MARK: - Terminal / IDE

    var terminalSection: some View {
        settingsSection("Terminal / IDE", subtitle: "Which app to launch when you tap the quick action button. Requires Automation permission on first use.") {
            settingsRow("Open in") {
                Picker("", selection: $settings.terminalApp) {
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
                .accessibilityLabel("Open in terminal app")
                .fixedSize()
                .onChange(of: settings.terminalApp) { _, v in AppSettings.terminalApp = v }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Working directory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(settings.terminalWorkingDirectory.isEmpty ? "Default" : abbreviatePath(settings.terminalWorkingDirectory))
                        .font(.caption)
                        .foregroundStyle(settings.terminalWorkingDirectory.isEmpty ? .tertiary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Choose...") {
                        chooseWorkingDirectory()
                    }
                    .controlSize(.small)
                    if !settings.terminalWorkingDirectory.isEmpty {
                        Button {
                            settings.terminalWorkingDirectory = ""
                            AppSettings.terminalWorkingDirectory = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear working directory")
                    }
                }
            }
        }
    }

    // MARK: - Terminal helpers

    func chooseWorkingDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Choose the folder to open in your terminal or IDE"
        if panel.runModal() == .OK, let url = panel.url {
            settings.terminalWorkingDirectory = url.path
            AppSettings.terminalWorkingDirectory = url.path
        }
    }

    func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
