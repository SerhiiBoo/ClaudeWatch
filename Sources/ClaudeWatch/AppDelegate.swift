import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var hotkeyObserver: Any?
    let viewModel = UsageViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        LogService.pruneIfNeeded()
        NotificationService.setup()
        setupStatusItem()
        setupPopover()
        viewModel.startAutoRefresh()
        setupHotkey()
        // Keep status bar icon in sync
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(usageDidChange),
            name: .usageDidUpdate,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let observer = hotkeyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Setup

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
        )
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            if viewModel.isStale { viewModel.refresh() }
            startEventMonitor()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        stopEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self, self.popover.isShown else { return }
            DispatchQueue.main.async { self.closePopover() }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    @objc private func usageDidChange() {
        updateStatusBar()
    }

    // MARK: - Status bar

    private func updateStatusBar() {
        guard let button = statusItem?.button else { return }
        let remaining = viewModel.usage.map { u -> Double in
            let base = min(u.sessionRemaining, u.weeklyRemaining)
            let extras = [u.sonnetRemaining, u.opusRemaining].compactMap { $0 }
            return extras.reduce(base) { min($0, $1) }
        }
        button.image = statusIcon(remaining: remaining)
        button.title = menuBarTitle()
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
            if let pace = UsageHistoryService.sessionPacePerHour(), pace > minimumMeaningfulPacePerHour {
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

