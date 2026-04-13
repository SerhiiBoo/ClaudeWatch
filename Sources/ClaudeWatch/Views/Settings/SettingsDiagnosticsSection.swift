import SwiftUI

extension SettingsView {

    // MARK: - Diagnostics

    var diagnosticsSection: some View {
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
                    settings.logsCopiedMessage = "Logs cleared"
                    clearCopiedMessage()
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if let msg = settings.logsCopiedMessage {
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

    // MARK: - Diagnostics helpers

    func copyLogsToClipboard() {
        if let logs = LogService.allLogs() {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(logs, forType: .string)
            settings.logsCopiedMessage = "Copied to clipboard"
        } else {
            settings.logsCopiedMessage = "No logs to copy"
        }
        clearCopiedMessage()
    }

    func exportLogs() {
        guard let logs = LogService.allLogs() else {
            settings.logsCopiedMessage = "No logs to export"
            clearCopiedMessage()
            return
        }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "claudewatch-logs.txt"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try logs.write(to: url, atomically: true, encoding: .utf8)
                settings.logsCopiedMessage = "Exported"
            } catch {
                settings.logsCopiedMessage = "Export failed: \(error.localizedDescription)"
            }
            clearCopiedMessage()
        }
    }

    func clearCopiedMessage() {
        clearTask?.cancel()
        clearTask = Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { settings.logsCopiedMessage = nil }
        }
    }
}
