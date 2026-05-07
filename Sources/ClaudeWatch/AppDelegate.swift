import AppKit
import Combine
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var hotkeyObserver: Any?
    private var petPositionObserver: Any?
    private var usageObserver: Any?
    private(set) var viewModel = UsageViewModel()
    private(set) var petService = NotchPetService()
    private var petWindow: NotchPetWindow?
    private var miniGameWindow: MiniGameWindow?
    private var miniGameObservers: [Any] = []
    private var menuBarSettingsObserver: Any?
    private var activityMonitor: SystemActivityMonitor?
    private var hookIngestion: HookIngestionService?
    private var hookNotificationCenter: NotificationCenterService?
    private var permissionRequestService: PermissionRequestService?
    private var notificationStackWindow: NotificationStackWindow?
    private var hookEventsSubscription: AnyCancellable?
    private var permissionApprovalObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let runningInstances = NSRunningApplication.runningApplications(
            withBundleIdentifier: Bundle.main.bundleIdentifier ?? ""
        )
        if runningInstances.count > 1 {
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)
        LogService.pruneIfNeeded()
        UNUserNotificationCenter.current().delegate = self
        NotificationService.setup()
        setupStatusItem()
        setupPopover()
        setupHotkey()
        setupPet()          // attach before startAutoRefresh so no update is lost
        setupActivityMonitor()
        viewModel.startAutoRefresh()
        setupMiniGame()
        setupHookNotifications()
        // Keep status bar icon in sync
        usageObserver = NotificationCenter.default.addObserver(
            forName: .usageDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateStatusBar() }
        }
        // Settings-triggered changes update immediately even with popover open
        menuBarSettingsObserver = NotificationCenter.default.addObserver(
            forName: .menuBarSettingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateStatusBarForSettingsChange() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let observer = hotkeyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = petPositionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = usageObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = menuBarSettingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        miniGameObservers.forEach { NotificationCenter.default.removeObserver($0) }
        if let observer = permissionApprovalObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        hookEventsSubscription?.cancel()
        permissionRequestService?.stopListening()
        miniGameWindow?.close()
        petWindow?.hide()
        notificationStackWindow?.hide()
        activityMonitor?.invalidate()
        activityMonitor = nil
        LogService.flush()
    }

    // MARK: - Setup

    private func setupHookNotifications() {
        let nc = NotificationCenterService()
        let reachability = TerminalReachabilityService()
        let ingestion = HookIngestionService(notificationCenter: nc, reachability: reachability)
        let permService = PermissionRequestService(reachability: reachability)
        let stackWindow = NotificationStackWindow(service: nc, permissionService: permService)
        hookNotificationCenter = nc
        hookIngestion = ingestion
        permissionRequestService = permService
        notificationStackWindow = stackWindow
        stackWindow.show()

        if AppSettings.permissionApprovalEnabled && AppSettings.hookNotificationsEnabled {
            permService.startListening()
        }

        hookEventsSubscription = Publishers.CombineLatest(
            nc.$visibleEvents.map { !$0.isEmpty },
            permService.$visibleRequests.map { !$0.isEmpty }
        )
        .map { $0 || $1 }
        .removeDuplicates()
        .sink { [weak self] hasVisible in
            guard let self else { return }
            if hasVisible {
                self.petService.beginSustainedAnimation(.excited)
            } else {
                self.petService.endSustainedAnimation()
            }
        }

        permissionApprovalObserver = NotificationCenter.default.addObserver(
            forName: .permissionApprovalSettingDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let permService = self.permissionRequestService else { return }
                if AppSettings.permissionApprovalEnabled && AppSettings.hookNotificationsEnabled {
                    permService.startListening()
                } else {
                    permService.stopListening()
                    if !AppSettings.hookNotificationsEnabled {
                        self.hookNotificationCenter?.dismissAll()
                    }
                }
                try? HookInstaller.shared.updatePermissionApprovalEntry(enabled: AppSettings.permissionApprovalEnabled && AppSettings.hookNotificationsEnabled)
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            hookIngestion?.ingest(url: url)
        }
    }

    private func setupActivityMonitor() {
        activityMonitor = SystemActivityMonitor(
            onPause:  { [weak self] in self?.viewModel.pauseAutoRefresh() },
            onResume: { [weak self] in self?.viewModel.resumeAutoRefresh() }
        )
    }

    private func setupPet() {
        petService.attach(to: viewModel)
        petWindow = NotchPetWindow(petService: petService)

        // Show notch overlay if enabled
        if petService.isEnabled {
            petWindow?.show()
        }

        // Listen for position/size changes from settings
        petPositionObserver = NotificationCenter.default.addObserver(
            forName: .petPositionDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if !self.petService.isEnabled {
                    self.petWindow?.hide()
                } else {
                    self.petWindow?.show()
                    self.petWindow?.updatePosition()
                }
            }
        }

    }

    private func setupMiniGame() {
        let nc = NotificationCenter.default
        miniGameObservers = [
            nc.addObserver(forName: .petDidLeaveSleep, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.miniGameOrCreate().gameService.notifyRateLimitLifted() }
            },
            nc.addObserver(forName: .miniGameManualTrigger, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.miniGameOrCreate().show(triggeredBy: .manual) }
            }
        ]
    }

    /// Returns the existing MiniGameWindow, creating it on first use.
    private func miniGameOrCreate() -> MiniGameWindow {
        if let w = miniGameWindow { return w }
        let w = MiniGameWindow()
        miniGameWindow = w
        return w
    }

    private func setupHotkey() {
        HotkeyService.shared.updateFromSettings()
        hotkeyObserver = NotificationCenter.default.addObserver(
            forName: .hotkeyTriggered,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.togglePopover() }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = statusIcon(remaining: nil)
        button.imagePosition = .imageLeft
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverView()
                .environmentObject(viewModel)
                .environmentObject(petService)
        )
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            startEventMonitor()
        }
    }

    private func closePopover() {
        guard popover.isShown else { return }
        popover.performClose(nil)
        stopEventMonitor()
        // Apply any title update that was deferred while the popover was open.
        statusItem?.button?.title = menuBarTitle()
    }

    private func startEventMonitor() {
        stopEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.popover.isShown else { return }
                self.closePopover()
            }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Status bar

    private func updateStatusBarForSettingsChange() {
        guard let button = statusItem?.button else { return }
        let remaining = viewModel.usage.map { u -> Double in
            let base = min(u.sessionRemaining, u.weeklyRemaining)
            let extras = [u.sonnetRemaining, u.opusRemaining].compactMap { $0 }
            return extras.reduce(base) { min($0, $1) }
        }
        button.image = statusIcon(remaining: remaining)
        button.title = menuBarTitle()
    }

    private func updateStatusBar() {
        guard let button = statusItem?.button else { return }
        let remaining = viewModel.usage.map { u -> Double in
            let base = min(u.sessionRemaining, u.weeklyRemaining)
            let extras = [u.sonnetRemaining, u.opusRemaining].compactMap { $0 }
            return extras.reduce(base) { min($0, $1) }
        }
        button.image = statusIcon(remaining: remaining)
        // Skip title update while the popover is shown — changing the title
        // resizes the variableLength status item, shifting the button frame and
        // causing NSPopover to appear mispositioned (jumps to the left).
        if !popover.isShown {
            button.title = menuBarTitle()
        }
    }

    private func menuBarTitle() -> String {
        let style = AppSettings.menuBarStyle
        guard let u = viewModel.usage else { return "" }
        switch style {
        case .iconOnly:
            return ""
        case .session:
            return " \(Int(100 - u.sessionRemaining))%"
        case .weekly:
            return " \(Int(100 - u.weeklyRemaining))%"
        case .sessionAndWeekly:
            return " S:\(Int(100 - u.sessionRemaining))% W:\(Int(100 - u.weeklyRemaining))%"
        case .pace:
            if let pace = UsageHistoryService.sessionPacePerHour(), pace > PaceClassifier.minimumMeaningfulPacePerHour {
                return String(format: " %.0f%%/h", pace)
            }
            return ""
        }
    }

    /// Renders the menu bar icon using the user's chosen style.
    private func statusIcon(remaining: Double?) -> NSImage? {
        let fraction = (remaining ?? 100.0) / 100.0
        return MenuBarIconRenderer.render(style: AppSettings.menuBarIcon, fraction: fraction)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard let idString = response.notification.request.content.userInfo["request_id"] as? String,
              let id = UUID(uuidString: idString) else { completionHandler(); return }
        let decision: PermissionDecision
        switch response.actionIdentifier {
        case PermissionActionIdentifier.allow: decision = .allow
        case PermissionActionIdentifier.deny:  decision = .deny
        default:                               decision = .none
        }
        let userInfo = response.notification.request.content.userInfo
        let bundleId = userInfo["bundle_id"] as? String
        let pid = (userInfo["pid"] as? Int).map { pid_t($0) }
        Task { @MainActor [weak self] in
            guard let self else { completionHandler(); return }
            self.permissionRequestService?.resolve(id: id, decision: decision)
            if decision == .none {
                try? await Task.sleep(for: .milliseconds(200))
                _ = TerminalLauncher.activate(bundleId: bundleId) || TerminalLauncher.activate(pid: pid)
            }
            completionHandler()
        }
    }
}

