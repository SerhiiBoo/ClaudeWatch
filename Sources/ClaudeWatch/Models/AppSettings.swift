import Foundation
import Carbon.HIToolbox
import SwiftUI

/// Centralized, UserDefaults-backed settings for all configurable options.
/// Each property auto-persists on write. Read once at init from UserDefaults.
struct AppSettings {
    private static let defaults = UserDefaults.standard

    // MARK: - Named constants

    static let defaultNotificationThresholds: [Double] = [50, 80, 90]
    static let appearanceModeKey = "appearanceMode"
    static let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    static let defaultRefreshInterval: TimeInterval = 120
    /// Default Carbon modifier flags: cmdKey | shiftKey.
    static let defaultHotkeyModifiers = UInt32(cmdKey) | UInt32(shiftKey)

    // MARK: - Keys
    private enum Key: String {
        case appearanceMode
        case notificationThresholds
        case notificationsEnabled
        case sparklineHours
        case paceWindowHours
        case showCircularTimers
        case showSparkline
        case showQuickActions
        case terminalApp
        case terminalWorkingDirectory
        case compactMode
        case menuBarStyle
        case menuBarIcon
        case globalHotkeyEnabled
        case globalHotkeyKeyCode
        case globalHotkeyModifiers
        case refreshInterval
    }

    // MARK: - Appearance
    /// Read-only accessor. Views write via `@AppStorage("appearanceMode")` for reactivity.
    static var appearanceMode: AppearanceMode {
        guard let raw = defaults.string(forKey: appearanceModeKey),
              let mode = AppearanceMode(rawValue: raw) else {
            return .system
        }
        return mode
    }

    // MARK: - Notification thresholds
    static var notificationsEnabled: Bool {
        get { defaults.object(forKey: Key.notificationsEnabled.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.notificationsEnabled.rawValue) }
    }

    static var notificationThresholds: [Double] {
        get {
            guard let arr = defaults.array(forKey: Key.notificationThresholds.rawValue) as? [Double] else {
                return defaultNotificationThresholds
            }
            return arr
        }
        set { defaults.set(newValue, forKey: Key.notificationThresholds.rawValue) }
    }

    // MARK: - Sparkline
    static var sparklineHours: Int {
        get {
            let v = defaults.integer(forKey: Key.sparklineHours.rawValue)
            return v > 0 ? v : 24
        }
        set { defaults.set(newValue, forKey: Key.sparklineHours.rawValue) }
    }

    // MARK: - Pace
    static var paceWindowHours: Double {
        get {
            let v = defaults.double(forKey: Key.paceWindowHours.rawValue)
            return v > 0 ? v : 2.0
        }
        set { defaults.set(newValue, forKey: Key.paceWindowHours.rawValue) }
    }

    // MARK: - Section visibility
    static var showCircularTimers: Bool {
        get { defaults.object(forKey: Key.showCircularTimers.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showCircularTimers.rawValue) }
    }

    static var showSparkline: Bool {
        get { defaults.object(forKey: Key.showSparkline.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showSparkline.rawValue) }
    }

    static var showQuickActions: Bool {
        get { defaults.object(forKey: Key.showQuickActions.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showQuickActions.rawValue) }
    }

    // MARK: - Terminal app
    static var terminalApp: TerminalApp {
        get {
            guard let raw = defaults.string(forKey: Key.terminalApp.rawValue),
                  let app = TerminalApp(rawValue: raw) else {
                return .terminal
            }
            return app
        }
        set { defaults.set(newValue.rawValue, forKey: Key.terminalApp.rawValue) }
    }

    // MARK: - Terminal working directory
    static var terminalWorkingDirectory: String {
        get { defaults.string(forKey: Key.terminalWorkingDirectory.rawValue) ?? "" }
        set { defaults.set(newValue, forKey: Key.terminalWorkingDirectory.rawValue) }
    }

    // MARK: - Compact mode
    static var compactMode: Bool {
        get { defaults.object(forKey: Key.compactMode.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.compactMode.rawValue) }
    }

    // MARK: - Menu bar icon
    static var menuBarIcon: MenuBarIcon {
        get {
            guard let raw = defaults.string(forKey: Key.menuBarIcon.rawValue),
                  let icon = MenuBarIcon(rawValue: raw) else {
                return .gauge
            }
            return icon
        }
        set { defaults.set(newValue.rawValue, forKey: Key.menuBarIcon.rawValue) }
    }

    // MARK: - Global hotkey

    static var globalHotkeyEnabled: Bool {
        get { defaults.object(forKey: Key.globalHotkeyEnabled.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.globalHotkeyEnabled.rawValue) }
    }

    /// Carbon virtual key code. Default 13 = kVK_ANSI_W.
    static var globalHotkeyKeyCode: UInt32 {
        get {
            guard defaults.object(forKey: Key.globalHotkeyKeyCode.rawValue) != nil else { return 13 }
            return UInt32(defaults.integer(forKey: Key.globalHotkeyKeyCode.rawValue))
        }
        set { defaults.set(Int(newValue), forKey: Key.globalHotkeyKeyCode.rawValue) }
    }

    /// Carbon modifier flags. Default = cmdKey | shiftKey.
    static var globalHotkeyModifiers: UInt32 {
        get {
            guard defaults.object(forKey: Key.globalHotkeyModifiers.rawValue) != nil else { return defaultHotkeyModifiers }
            return UInt32(defaults.integer(forKey: Key.globalHotkeyModifiers.rawValue))
        }
        set { defaults.set(Int(newValue), forKey: Key.globalHotkeyModifiers.rawValue) }
    }

    // MARK: - Refresh interval
    static var refreshInterval: TimeInterval {
        get {
            let v = defaults.double(forKey: Key.refreshInterval.rawValue)
            return v >= 60 ? v : defaultRefreshInterval
        }
        set { defaults.set(newValue, forKey: Key.refreshInterval.rawValue) }
    }

    // MARK: - Menu bar style
    static var menuBarStyle: MenuBarStyle {
        get {
            guard let raw = defaults.string(forKey: Key.menuBarStyle.rawValue),
                  let style = MenuBarStyle(rawValue: raw) else {
                return .iconOnly
            }
            return style
        }
        set { defaults.set(newValue.rawValue, forKey: Key.menuBarStyle.rawValue) }
    }
}

// MARK: - Menu bar display style

enum MenuBarStyle: String, CaseIterable, Identifiable {
    case iconOnly = "Icon only"
    case session = "Session %"
    case weekly = "Weekly %"
    case sessionAndWeekly = "Session + Weekly"
    case pace = "Pace (%/h)"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Menu bar icon style

enum MenuBarIcon: String, CaseIterable, Identifiable {
    case gauge    = "Gauge"
    case spark    = "Spark"
    case ring     = "Ring"
    case pulse    = "Pulse"
    case battery  = "Battery"
    case meter    = "Meter"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Appearance mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Terminal / IDE app enum

enum TerminalAppCategory: String, CaseIterable, Identifiable {
    case terminals = "Terminals"
    case editors = "Editors & IDEs"

    var id: String { rawValue }
}

enum TerminalApp: String, CaseIterable, Identifiable {
    // Terminals
    case terminal = "Terminal"
    case iterm = "iTerm"
    case warp = "Warp"
    case ghostty = "Ghostty"
    case kitty = "Kitty"
    case alacritty = "Alacritty"
    case hyper = "Hyper"
    // Editors & IDEs
    case vscode = "VS Code"
    case cursor = "Cursor"
    case zed = "Zed"
    case phpstorm = "PhpStorm"
    case windsurf = "Windsurf"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var category: TerminalAppCategory {
        switch self {
        case .terminal, .iterm, .warp, .ghostty, .kitty, .alacritty, .hyper:
            return .terminals
        case .vscode, .cursor, .zed, .phpstorm, .windsurf:
            return .editors
        }
    }

    /// Whether this app has a built-in terminal where we can run `claude`.
    var isTerminal: Bool { category == .terminals }

    /// The bundle identifier or app name used with `open -a`.
    private var bundleAppName: String {
        switch self {
        case .vscode: return "Visual Studio Code"
        case .kitty:  return "kitty"
        default:      return rawValue
        }
    }

    /// Returns `true` when `path` contains no characters that could break
    /// shell or AppleScript embedding (newlines, null bytes, other control chars).
    private static func validateDirectoryPath(_ path: String) -> Bool {
        path.unicodeScalars.allSatisfy { scalar in
            scalar.value >= 0x20 && scalar.value != 0x7F
        }
    }

    /// Launch this app, optionally in `directory`, running `claude` for terminals.
    /// Returns shell commands to execute via `/bin/sh -c`, or `nil` if the
    /// directory path contains unsafe characters.
    func shellLaunchCommand(directory: String = "") -> String? {
        let dir = directory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard dir.isEmpty || Self.validateDirectoryPath(dir) else { return nil }
        let safeDir = Self.shellEscape(dir)

        switch self {

        // ── Terminals with native AppleScript support ────────────
        case .terminal:
            guard let cmd = Self.claudeCommand(directory: dir) else { return nil }
            let escaped = Self.appleScriptEscape(cmd)
            return """
            osascript -e 'tell application "Terminal"' -e 'activate' -e 'do script "\(escaped)"' -e 'end tell'
            """

        case .iterm:
            guard let cmd = Self.claudeCommand(directory: dir) else { return nil }
            let escaped = Self.appleScriptEscape(cmd)
            return """
            osascript -e 'tell application "iTerm"' -e 'activate' -e 'create window with default profile command "\(escaped)"' -e 'end tell'
            """

        // ── Terminals with CLI support ───────────────────────────
        case .kitty:
            var args = "kitty --single-instance"
            if !dir.isEmpty { args += " -d \(safeDir)" }
            args += " sh -c claude"
            return args

        case .alacritty:
            var args = "alacritty"
            if !dir.isEmpty { args += " --working-directory \(safeDir)" }
            args += " -e claude"
            return args

        case .ghostty:
            var args = "ghostty"
            if !dir.isEmpty { args += " --working-directory=\(safeDir)" }
            args += " -e claude"
            return args

        case .warp:
            if dir.isEmpty {
                return "open -a 'Warp'"
            }
            guard let cmd = Self.claudeCommand(directory: dir) else { return nil }
            let warpEscaped = Self.appleScriptEscape(cmd)
            return """
            open -a 'Warp' && sleep 0.5 && osascript -e 'tell application "System Events"' -e 'keystroke "\(warpEscaped)"' -e 'key code 36' -e 'end tell'
            """

        case .hyper:
            if dir.isEmpty {
                return "open -a 'Hyper'"
            }
            guard let cmd = Self.claudeCommand(directory: dir) else { return nil }
            let hyperEscaped = Self.appleScriptEscape(cmd)
            return """
            open -a 'Hyper' && sleep 0.5 && osascript -e 'tell application "System Events"' -e 'keystroke "\(hyperEscaped)"' -e 'key code 36' -e 'end tell'
            """

        // ── Editors & IDEs ───────────────────────────────────────
        case .vscode, .cursor, .zed, .phpstorm, .windsurf:
            let app = bundleAppName
            if dir.isEmpty {
                return "open -a '\(Self.appleScriptEscape(app))'"
            }
            return "open -a '\(Self.appleScriptEscape(app))' \(safeDir)"
        }
    }

    /// Build the command string: `cd <dir> && claude` or just `claude`.
    /// Returns `nil` if the directory path is invalid.
    private static func claudeCommand(directory: String) -> String? {
        let dir = directory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dir.isEmpty else { return "claude" }
        guard validateDirectoryPath(dir) else { return nil }
        return "cd \(shellEscape(dir)) && claude"
    }

    /// Escape a string for safe embedding in a single-quoted shell argument.
    private static func shellEscape(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Escape a string for safe embedding inside an AppleScript double-quoted string.
    /// Strips control characters and backticks (which have AppleScript evaluation semantics),
    /// then escapes backslash and double-quote.
    private static func appleScriptEscape(_ value: String) -> String {
        let stripped = value.unicodeScalars
            .filter { $0.value >= 0x20 && $0.value != 0x7F && $0 != "`" }
            .reduce(into: "") { $0.append(Character($1)) }
        return stripped
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
