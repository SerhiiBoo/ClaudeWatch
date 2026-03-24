import AppKit
import SwiftUI

/// A click-to-record control that captures global hotkey combinations.
/// Click it, then press any modifier + key combination to set a new shortcut.
/// Press Escape or click again to cancel recording.
struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var keyCode: UInt32
    @Binding var carbonModifiers: UInt32

    func makeNSView(context: Context) -> RecorderButton {
        let view = RecorderButton()
        view.onHotkeyRecorded = { code, mods in
            keyCode = code
            carbonModifiers = mods
        }
        return view
    }

    func updateNSView(_ nsView: RecorderButton, context: Context) {
        nsView.displayLabel = HotkeyService.displayString(
            keyCode: keyCode,
            carbonModifiers: carbonModifiers
        )
        nsView.needsDisplay = true
    }
}

// MARK: - RecorderButton

final class RecorderButton: NSView {
    var onHotkeyRecorded: ((UInt32, UInt32) -> Void)?
    var displayLabel: String = ""
    private(set) var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    // MARK: - Interaction

    override func mouseDown(with event: NSEvent) {
        if isRecording {
            cancelRecording()
        } else {
            isRecording = true
            window?.makeFirstResponder(self)
            needsDisplay = true
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        if event.keyCode == 53 { // Escape
            cancelRecording()
            return
        }

        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard !mods.isEmpty else { return } // require at least one modifier

        let carbonMods = HotkeyService.carbonModifiers(from: mods)
        isRecording = false
        needsDisplay = true
        onHotkeyRecorded?(UInt32(event.keyCode), carbonMods)
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else { return }
        needsDisplay = true
    }

    override func resignFirstResponder() -> Bool {
        if isRecording { cancelRecording() }
        return super.resignFirstResponder()
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let label: String
        let textColor: NSColor

        if isRecording {
            label = "Press shortcut…"
            textColor = .systemBlue
        } else if displayLabel.isEmpty {
            label = "Click to record"
            textColor = .tertiaryLabelColor
        } else {
            label = displayLabel
            textColor = .labelColor
        }

        let bgColor: NSColor = isRecording
            ? NSColor.systemBlue.withAlphaComponent(0.08)
            : NSColor.controlBackgroundColor
        bgColor.setFill()

        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        path.fill()

        let borderColor: NSColor = isRecording ? .systemBlue : .separatorColor
        borderColor.setStroke()
        path.lineWidth = 1
        path.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: textColor
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let strSize = str.size()
        let origin = NSPoint(
            x: (bounds.width - strSize.width) / 2,
            y: (bounds.height - strSize.height) / 2
        )
        str.draw(at: origin)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 130, height: 24)
    }

    // MARK: - Private

    private func cancelRecording() {
        isRecording = false
        window?.makeFirstResponder(nil)
        needsDisplay = true
    }
}
