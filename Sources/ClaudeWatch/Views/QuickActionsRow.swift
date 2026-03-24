import SwiftUI
import AppKit

/// Quick action buttons: open Claude Code terminal, copy usage summary, share screenshot.
struct QuickActionsRow: View {
    let usage: UsageData?
    @State private var copied = false

    private var openLabel: String {
        let app = AppSettings.terminalApp
        return app.isTerminal ? "Open Claude" : "Open \(app.displayName)"
    }

    private var openIcon: String {
        AppSettings.terminalApp.isTerminal ? "terminal" : "chevron.left.forwardslash.chevron.right"
    }

    var body: some View {
        HStack(spacing: 6) {
            // Primary action — fills available space
            ActionButton(label: openLabel, icon: openIcon, style: .primary, disabled: false) {
                openClaudeCode()
            }

            // Secondary actions — icon-only with tooltips
            ActionButton(label: nil, icon: copied ? "checkmark" : "doc.on.doc", style: .secondary, disabled: usage == nil) {
                copyUsageSummary()
            }
            .help(copied ? "Copied!" : "Copy usage summary")

            ActionButton(label: nil, icon: "square.and.arrow.up", style: .secondary, disabled: usage == nil) {
                shareScreenshot()
            }
            .help("Share screenshot")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Open terminal

    private func openClaudeCode() {
        guard let command = AppSettings.terminalApp.shellLaunchCommand(
            directory: AppSettings.terminalWorkingDirectory
        ) else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        do {
            try process.run()
        } catch {
            let displayName = AppSettings.terminalApp.displayName
            guard !displayName.isEmpty else {
                print("[QuickActionsRow] Primary launch failed and terminal display name is empty; cannot fall back: \(error)")
                return
            }
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            fallback.arguments = ["-a", displayName]
            do {
                try fallback.run()
            } catch let fallbackError {
                print("[QuickActionsRow] Fallback launch of '\(displayName)' also failed: \(fallbackError)")
            }
        }
    }

    // MARK: - Copy summary

    private func copyUsageSummary() {
        guard let u = usage else { return }

        let dateStr = Date().formatted(date: .abbreviated, time: .shortened)
        var lines: [String] = [
            "🤖 Claude Watch  •  \(dateStr)",
            "",
            "⚡ Session   \(usageLine(remaining: u.sessionRemaining))",
            "📅 Weekly    \(usageLine(remaining: u.weeklyRemaining))",
        ]
        if let s = u.sonnetRemaining { lines.append("💬 Sonnet    \(usageLine(remaining: s))") }
        if let o = u.opusRemaining   { lines.append("🔮 Opus      \(usageLine(remaining: o))") }

        lines.append("")
        lines.append("📋 Plan      \(u.plan)")

        if let pace = UsageHistoryService.sessionPacePerHour() {
            lines.append(String(format: "🏃 Pace      %.0f%%/h", pace))
        }
        if let hours = UsageHistoryService.estimatedHoursUntilSessionEmpty(currentRemaining: u.sessionRemaining) {
            if hours >= 5 {
                lines.append("✅ ETA       Well within session limits")
            } else {
                lines.append(String(format: "⏱ ETA       %.1fh until session limit", hours))
            }
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lines.joined(separator: "\n"), forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
    }

    private func usageLine(remaining: Double) -> String {
        let used = 100 - remaining
        return String(format: "%3.0f%% used  %@", used, progressBar(used))
    }

    private func progressBar(_ percent: Double, width: Int = 10) -> String {
        let filled = max(0, min(width, Int((percent / 100.0) * Double(width))))
        return String(repeating: "█", count: filled) + String(repeating: "░", count: width - filled)
    }

    // MARK: - Share screenshot

    @MainActor private func shareScreenshot() {
        guard let u = usage else { return }

        let snapshotView = UsageSnapshotView(usage: u)
        let renderer = ImageRenderer(content: snapshotView)
        renderer.scale = 2.0

        guard let image = renderer.nsImage,
              let contentView = NSApp.keyWindow?.contentView else { return }

        let picker = NSSharingServicePicker(items: [image])
        picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    enum Style { case primary, secondary }

    let label: String?
    let icon: String
    let style: Style
    let disabled: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                if let label {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(isHovered ? Color.primary : Color.secondary)
            .padding(.horizontal, style == .primary ? 12 : 9)
            .padding(.vertical, 6)
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed
                          ? Color.primary.opacity(0.11)
                          : isHovered
                              ? Color.primary.opacity(0.08)
                              : Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.primary.opacity(0.09), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .animation(.easeOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
