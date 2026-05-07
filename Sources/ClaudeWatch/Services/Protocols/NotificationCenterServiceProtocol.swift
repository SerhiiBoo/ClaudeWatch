import Foundation

@MainActor
protocol NotificationCenterServiceProtocol: AnyObject {
    func enqueue(_ event: HookEvent)
    func dismiss(_ event: HookEvent)
    func activate(_ event: HookEvent)
}
