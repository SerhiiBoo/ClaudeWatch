import AppKit
import SwiftUI

// MARK: - Notification

extension Notification.Name {
    static let miniGameShouldClose = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.miniGameShouldClose")
}

// MARK: - Trigger context

enum MiniGameTrigger {
    case rateLimited
    case sessionCritical
    case manual
}

// MARK: - Panel subclass

/// NSPanel with `canBecomeKey` overridden so that keyboard events reach the
/// NSHostingView even when the panel is created with `.nonactivatingPanel`.
/// Without this, `onKeyPress(.leftArrow/.rightArrow)` in MiniGameView is silently ignored.
private final class MiniGamePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Window wrapper

@MainActor
final class MiniGameWindow: NSObject, NSWindowDelegate {

    // MARK: - Public

    private(set) var gameService = MiniGameService()

    // MARK: - Private

    private var panel: MiniGamePanel?
    private let observers = ObserverStore()

    // MARK: - Show

    func show(triggeredBy trigger: MiniGameTrigger = .manual) {
        if let existing = panel {
            existing.makeKeyAndOrderFront(nil)
            gameService.reset()
            return
        }

        gameService.reset()
        let variant = AppSettings.petVariant
        let contentView = MiniGameView(gameService: gameService, variant: variant)

        let panel = MiniGamePanel(
            contentRect: NSRect(x: 0, y: 0,
                                width: GameConstants.gameWidth,
                                height: GameConstants.gameHeight),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Token Rush"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = true
        panel.backgroundColor = NSColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1)
        panel.hasShadow = true
        panel.applyFloatingWindowDefaults()
        panel.collectionBehavior.insert(.fullScreenAuxiliary)
        panel.delegate = self
        panel.center()

        let hosting = NSHostingView(rootView: contentView)
        panel.contentView = hosting
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel

        observers.add(NotificationCenter.default.addObserver(
            forName: .miniGameShouldClose,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.close() }
        })
    }

    // MARK: - Close

    func close() {
        guard panel != nil else { return }
        observers.removeAll()
        gameService.stop()
        let p = panel
        panel = nil     // nil before .close() so windowWillClose skips redundant cleanup
        p?.close()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        guard panel != nil else { return }  // already cleaned up via close()
        observers.removeAll()
        gameService.stop()
        panel = nil
    }
}
