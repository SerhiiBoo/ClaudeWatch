import SwiftUI
import ServiceManagement

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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    generalSection
                    petSection
                    hotkeysSection
                    visibleSectionsSection
                    chartsPaceSection
                    notificationsSection
                    terminalSection
                    diagnosticsSection
                    credentialsNote
                    errorBanner
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .frame(maxHeight: 500)
            Divider()
            footerActions
        }
        .frame(width: 300)
        .frame(minHeight: 500)
        .onChange(of: settings.menuBarIcon) { _, v in
            AppSettings.menuBarIcon = v
            NotificationCenter.default.post(name: .usageDidUpdate, object: nil)
        }
        .onDisappear {
            clearTask?.cancel()
        }
    }

    // MARK: - Title & Footer

    private var titleBar: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    private var footerActions: some View {
        HStack {
            Button {
                viewModel.refresh()
                onDismiss()
            } label: {
                Label("Refresh Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            Text("v\(appVersion)")
                .font(.caption2)
                .foregroundStyle(.quaternary)
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

    // Terminal
    var terminalApp: TerminalApp = AppSettings.terminalApp
    var terminalWorkingDirectory: String = AppSettings.terminalWorkingDirectory

    // Display
    var compactMode: Bool = AppSettings.compactMode
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
