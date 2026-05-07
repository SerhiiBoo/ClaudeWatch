import AppKit
import Foundation
import UserNotifications

@MainActor
final class NotificationCenterService: NotificationCenterServiceProtocol {
    @Published private(set) var visibleEvents: [HookEvent] = []
    private var queue: [HookEvent] = []
    private static let maxVisible = 3

    func enqueue(_ event: HookEvent) {
        switch AppSettings.hookDeliveryStyle {
        case .popover:
            enqueuePopover(event)
        case .native:
            sendNativeNotification(event)
        }
        if AppSettings.hookSoundEnabled && AppSettings.hookDeliveryStyle == .popover {
            NSSound.beep()
        }
    }

    func dismiss(_ event: HookEvent) {
        visibleEvents.removeAll { $0.id == event.id }
        dequeueNext()
    }

    func dismissAll() {
        visibleEvents.removeAll()
        queue.removeAll()
    }

    func activate(_ event: HookEvent) {
        _ = TerminalLauncher.activate(bundleId: event.bundleId)
            || TerminalLauncher.activate(pid: event.pid)
        dismiss(event)
    }

    // MARK: - Popover delivery

    private func enqueuePopover(_ event: HookEvent) {
        if visibleEvents.count < Self.maxVisible {
            visibleEvents.append(event)
        } else {
            queue.append(event)
        }
    }

    private func dequeueNext() {
        guard !queue.isEmpty, visibleEvents.count < Self.maxVisible else { return }
        visibleEvents.append(queue.removeFirst())
    }

    // MARK: - Native delivery

    private func sendNativeNotification(_ event: HookEvent) {
        let content = UNMutableNotificationContent()
        content.title = event.notificationTitle
        content.body = event.message
        content.sound = AppSettings.hookSoundEnabled ? .default : nil
        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                LogService.error("HookNotifications", "Failed to send native notification", error: error)
            }
        }
    }

}
