import AppKit

// MARK: - ObserverStore
//
// Accumulates NotificationCenter observer tokens and removes them all in one call.
// Use in lieu of scattered `if let obs = …; removeObserver(obs); obs = nil` blocks.

final class ObserverStore {
    private var tokens: [Any] = []

    func add(_ token: Any) {
        tokens.append(token)
    }

    func removeAll() {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
        tokens = []
    }
}

// MARK: - NSWindow floating configuration

extension NSWindow {
    /// Applies the flags every floating, non-releasing window in this app needs.
    func applyFloatingWindowDefaults() {
        isReleasedWhenClosed = false
        collectionBehavior.insert(.canJoinAllSpaces)
    }
}
