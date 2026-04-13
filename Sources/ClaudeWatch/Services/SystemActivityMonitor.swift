import AppKit
import os.log

private let logger = Logger(subsystem: "io.github.SerhiiBoo.ClaudeWatch", category: "SystemActivity")

/// Observes macOS sleep/wake and screen lock/unlock events.
/// Call `invalidate()` before releasing to deregister all observers safely on the main actor.
@MainActor
final class SystemActivityMonitor {
    private let onPause: () -> Void
    private let onResume: () -> Void

    private var workspaceObservers: [Any] = []
    private var distributedObservers: [Any] = []

    init(onPause: @escaping () -> Void, onResume: @escaping () -> Void) {
        self.onPause  = onPause
        self.onResume = onResume

        let ws = NSWorkspace.shared.notificationCenter

        // queue: .main ensures closures run on the main thread; MainActor.assumeIsolated
        // informs the Swift concurrency system so @MainActor properties can be accessed
        // without an extra Task hop (preserving strict FIFO ordering of callbacks).
        workspaceObservers.append(ws.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                logger.debug("System will sleep — pausing auto-refresh")
                self?.onPause()
            }
        })

        workspaceObservers.append(ws.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                logger.debug("System did wake — resuming auto-refresh")
                self?.onResume()
            }
        })

        let dn = DistributedNotificationCenter.default()

        distributedObservers.append(dn.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                logger.debug("Screen locked — pausing auto-refresh")
                self?.onPause()
            }
        })

        distributedObservers.append(dn.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                logger.debug("Screen unlocked — resuming auto-refresh")
                self?.onResume()
            }
        })
    }

    /// Deregisters all notification observers. Must be called on the main actor before releasing.
    func invalidate() {
        let ws = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach { ws.removeObserver($0) }
        workspaceObservers = []

        let dn = DistributedNotificationCenter.default()
        distributedObservers.forEach { dn.removeObserver($0) }
        distributedObservers = []
    }
}
