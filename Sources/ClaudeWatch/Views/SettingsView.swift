import SwiftUI
import ServiceManagement

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, pet, shortcuts, notifications, advanced
    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:       return "General"
        case .pet:           return "Pet"
        case .shortcuts:     return "Shortcuts"
        case .notifications: return "Alerts"
        case .advanced:      return "Advanced"
        }
    }

    var systemImage: String {
        switch self {
        case .general:       return "slider.horizontal.3"
        case .pet:           return "pawprint.fill"
        case .shortcuts:     return "keyboard"
        case .notifications: return "bell.fill"
        case .advanced:      return "wrench.and.screwdriver.fill"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: UsageViewModel
    @EnvironmentObject var petService: NotchPetService
    var onDismiss: () -> Void

    @State var settings = SettingsState()
    @AppStorage(AppSettings.appearanceModeKey) var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @State var clearTask: Task<Void, Never>?

    let iconPickerPreviewFraction: Double = 0.75

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBar
            Divider()
            tabBar
            Divider()
            errorBanner
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch settings.selectedTab {
                    case .general:
                        generalSection
                        visibleSectionsSection
                        chartsPaceSection
                    case .pet:
                        petSection
                    case .shortcuts:
                        hotkeysSection
                        terminalSection
                    case .notifications:
                        notificationsSection
                    case .advanced:
                        diagnosticsSection
                        credentialsNote
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .id(settings.selectedTab)
            .frame(height: 460)
            Divider()
            footerActions
        }
        .onChange(of: settings.menuBarIcon) { _, v in
            AppSettings.menuBarIcon = v
            NotificationCenter.default.post(name: .usageDidUpdate, object: nil)
        }
        .onAppear {
            NotificationCenter.default.post(name: .petPositionDidChange, object: nil)
        }
        .onDisappear {
            clearTask?.cancel()
        }
    }

    // MARK: - Title & Footer

    private var titleBar: some View {
        HStack(spacing: 10) {
            accentIconBadge(systemImage: "gearshape.fill", badgeSize: 28, fontSize: 14)
            Text("Settings")
                .font(.headline)
            Spacer()
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    @Namespace private var tabNamespace

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases) { tab in
                let selected = settings.selectedTab == tab
                Button { withAnimation(.easeInOut(duration: 0.18)) { settings.selectedTab = tab } } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 16, weight: selected ? .semibold : .regular))
                        Text(tab.title)
                            .font(.system(size: 10, weight: selected ? .semibold : .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .background {
                        if selected {
                            Capsule()
                                .fill(Color.accentColor.opacity(0.10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(tab.title)
                if tab != SettingsTab.allCases.last {
                    Divider().frame(height: 20)
                }
            }
        }
    }

    private var footerActions: some View {
        HStack {
            Button {
                viewModel.refresh()
                onDismiss()
            } label: {
                Label("Refresh Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Spacer()

            Text("v\(appVersion)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Info banners

    @ViewBuilder
    var credentialsNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "key.fill")
                .font(.caption2)
                .foregroundStyle(.quaternary)
            Text("Credentials read from Keychain. Run `claude` to refresh.")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    var errorBanner: some View {
        if let err = viewModel.errorMessage {
            Label(err, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
        }
    }

    // MARK: - Helpers

    var appVersion: String { AppSettings.appVersion }

    func setLoginItem(enabled: Bool) {
        settings.loginItemError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            settings.loginItemError = error.localizedDescription
            settings.loginItemEnabled = !enabled
        }
    }
}

// MARK: - SettingsState

struct SettingsState {
    // Tab
    var selectedTab: SettingsTab = .general

    // Login item
    var loginItemEnabled: Bool = (SMAppService.mainApp.status == .enabled)
    var loginItemError: String?

    // Notifications
    var notificationsEnabled: Bool = AppSettings.notificationsEnabled
    var thresholds: [Double] = AppSettings.notificationThresholds.sorted()
    var newThresholdText: String = ""

    // Charts & pace
    var sparklineHours: Int = AppSettings.sparklineHours
    var paceWindowHours: Double = AppSettings.paceWindowHours

    // Visible sections
    var showCircularTimers: Bool = AppSettings.showCircularTimers
    var showSparkline: Bool = AppSettings.showSparkline
    var showQuickActions: Bool = AppSettings.showQuickActions
    var showExtraUsage: Bool = AppSettings.showExtraUsage

    // Terminal
    var terminalApp: TerminalApp = AppSettings.terminalApp
    var terminalWorkingDirectory: String = AppSettings.terminalWorkingDirectory

    // Display
    var menuBarStyle: MenuBarStyle = AppSettings.menuBarStyle
    var menuBarIcon: MenuBarIcon = AppSettings.menuBarIcon

    // Hotkeys
    var globalHotkeyEnabled: Bool = AppSettings.globalHotkeyEnabled
    var globalHotkeyKeyCode: UInt32 = AppSettings.globalHotkeyKeyCode
    var globalHotkeyModifiers: UInt32 = AppSettings.globalHotkeyModifiers

    // Pet
    var petEnabled: Bool = AppSettings.petEnabled
    var petCharacter: PetCharacter = AppSettings.petCharacter
    var petVariant: PetVariant = AppSettings.petVariant
    var petChattiness: PetChattiness = AppSettings.petChattiness
    var petPosition: PetPosition = AppSettings.petPosition
    var petSize: PetSize = AppSettings.petSize
    var petWellnessReminders: Bool = AppSettings.petWellnessReminders

    // Diagnostics
    var logsCopiedMessage: String?
}
