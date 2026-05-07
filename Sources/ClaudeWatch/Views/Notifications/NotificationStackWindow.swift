import AppKit
import Combine
import SwiftUI

private enum NotificationWindowTuning {
    static let cardWidth:      CGFloat = 360
    static let cardHeight:     CGFloat = 88
    static let spacing:        CGFloat = 8
    static let topPadding:     CGFloat = 12
    static let belowNotchGap:  CGFloat = 4
}

@MainActor
final class NotificationStackWindow {
    private var window: NSWindow?
    private var hostingView: NSHostingView<NotificationStackView>?
    private let service: NotificationCenterService
    private let permissionService: PermissionRequestService
    nonisolated(unsafe) let observers = ObserverStore()
    private var cancellables = Set<AnyCancellable>()
    private var autoTimers: [UUID: Timer] = [:]

    init(service: NotificationCenterService, permissionService: PermissionRequestService) {
        self.service = service
        self.permissionService = permissionService
    }

    func show() {
        makeWindowIfNeeded()

        Publishers.CombineLatest(service.$visibleEvents, permissionService.$visibleRequests)
            .receive(on: RunLoop.main)
            .sink { [weak self] events, requests in self?.update(events: events, requests: requests) }
            .store(in: &cancellables)

        observers.add(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.reposition() }
        })
    }

    func hide() {
        cancellables.removeAll()
        autoTimers.values.forEach { $0.invalidate() }
        autoTimers.removeAll()
        observers.removeAll()
        window?.orderOut(nil)
        window?.close()
        window = nil
        hostingView = nil
    }

    // MARK: - Private

    private func makeWindowIfNeeded() {
        guard window == nil else { return }
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: NotificationWindowTuning.cardWidth, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
        w.applyFloatingWindowDefaults()
        w.collectionBehavior.formUnion([.stationary, .ignoresCycle])
        w.ignoresMouseEvents = false

        let stack = makeStackView(events: [], requests: [])
        let hv = NSHostingView(rootView: stack)
        hv.frame = w.contentView?.bounds ?? .zero
        w.contentView = hv

        window = w
        hostingView = hv
        reposition()
    }

    private func update(events: [HookEvent], requests: [PermissionRequest]) {
        guard let w = window, let hv = hostingView else { return }

        hv.rootView = makeStackView(events: events, requests: requests)

        let count = CGFloat(events.count + requests.count)
        let height = count == 0 ? 1 :
            NotificationWindowTuning.topPadding +
            count * NotificationWindowTuning.cardHeight +
            max(count - 1, 0) * NotificationWindowTuning.spacing

        let newSize = NSSize(width: NotificationWindowTuning.cardWidth, height: height)
        w.setContentSize(newSize)
        hv.frame = NSRect(origin: .zero, size: newSize)

        reposition()

        if events.isEmpty && requests.isEmpty {
            w.orderOut(nil)
        } else {
            w.orderFront(nil)
        }

        scheduleAutoTimers(for: events)
    }

    private func activateTerminal(for request: PermissionRequest) {
        _ = TerminalLauncher.activate(bundleId: request.bundleId)
            || TerminalLauncher.activate(pid: request.pid)
    }

    private func makeStackView(events: [HookEvent], requests: [PermissionRequest]) -> NotificationStackView {
        NotificationStackView(
            events: events,
            requests: requests,
            onDismiss: { [weak self] event in self?.service.dismiss(event) },
            onActivate: { [weak self] event in self?.service.activate(event) },
            onDismissRequest: { [weak self] request in self?.permissionService.dismiss(request) },
            onActivateRequest: { [weak self] request in
                self?.permissionService.dismiss(request)
                self?.activateTerminal(for: request)
            },
            onAllow: { [weak self] request in
                self?.permissionService.resolve(id: request.id, decision: .allow)
                self?.activateTerminal(for: request)
            },
            onDeny: { [weak self] request in
                self?.permissionService.resolve(id: request.id, decision: .deny)
                self?.activateTerminal(for: request)
            }
        )
    }

    private func reposition() {
        guard let w = window else { return }
        guard let screen = NSScreen.main else { return }

        let frame = screen.frame
        let visibleFrame = screen.visibleFrame

        let windowX = frame.midX - NotificationWindowTuning.cardWidth / 2
        let menuBarBottom = visibleFrame.maxY
        let windowY = menuBarBottom - w.frame.height - NotificationWindowTuning.belowNotchGap

        w.setFrameOrigin(NSPoint(x: windowX, y: windowY))
    }

    private func scheduleAutoTimers(for events: [HookEvent]) {
        let currentIDs = Set(events.map(\.id))
        for (id, timer) in autoTimers where !currentIDs.contains(id) {
            timer.invalidate()
            autoTimers.removeValue(forKey: id)
        }
        for event in events where autoTimers[event.id] == nil {
            let timeout: TimeInterval = event.kind == .stop
                ? AppSettings.hookStopTimeout
                : AppSettings.hookNotificationTimeout
            let timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in self?.service.dismiss(event) }
            }
            autoTimers[event.id] = timer
        }
    }
}
