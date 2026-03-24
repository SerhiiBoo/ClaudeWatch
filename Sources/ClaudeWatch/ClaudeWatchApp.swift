import SwiftUI

@main
struct ClaudeWatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window – the app lives in the menu bar only.
        // Settings scene provides a way to open settings via Cmd+, if needed.
        Settings {
            SettingsView(onDismiss: {})
                .environmentObject(appDelegate.viewModel)
        }
    }
}
