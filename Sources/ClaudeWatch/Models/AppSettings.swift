import Foundation
import Carbon.HIToolbox

/// Centralized, UserDefaults-backed settings for all configurable options.
/// Each property auto-persists on write. Read once at init from UserDefaults.
struct AppSettings {
    private static let defaults = UserDefaults.standard

    // MARK: - Named constants

    static let defaultNotificationThresholds: [Double] = [50, 80, 90]
    static let appearanceModeKey = Key.appearanceMode.rawValue
    static let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    static let defaultRefreshInterval: TimeInterval = 120
    /// Seconds of user inactivity after which periodic timer fetches are skipped.
    static let idleFetchThreshold: TimeInterval = 600
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
        case petEnabled
        case petCharacter
        case petVariant
        case petChattiness
        case petPosition
        case petSize
        case petWellnessReminders
        case miniGameHighScore
        case notifiedThresholds
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
        get { rawEnum(.terminalApp, default: .terminal) }
        set { setRawEnum(.terminalApp, newValue) }
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
        get { rawEnum(.menuBarIcon, default: .gauge) }
        set { setRawEnum(.menuBarIcon, newValue) }
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

    // MARK: - Pet settings

    static var petEnabled: Bool {
        get { defaults.object(forKey: Key.petEnabled.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.petEnabled.rawValue) }
    }

    static var petCharacter: PetCharacter {
        get { rawEnum(.petCharacter, default: .clodey) }
        set {
            setRawEnum(.petCharacter, newValue)
            // Side effect: also resets petVariant in UserDefaults when the character changes,
            // to prevent a stale variant from a different character persisting across sessions.
            if let raw = defaults.string(forKey: Key.petVariant.rawValue),
               let variant = PetVariant(rawValue: raw),
               variant.character != newValue {
                let corrected = PetVariant.defaultVariant(for: newValue)
                defaults.set(corrected.rawValue, forKey: Key.petVariant.rawValue)
            }
        }
    }

    static var petVariant: PetVariant {
        get {
            guard let raw = defaults.string(forKey: Key.petVariant.rawValue),
                  let variant = PetVariant(rawValue: raw) else {
                return PetVariant.defaultVariant(for: petCharacter)
            }
            // Return a safe default when stored variant doesn't match the current character.
            // Storage is healed by the petCharacter setter; no side effect here.
            if variant.character != petCharacter {
                return PetVariant.defaultVariant(for: petCharacter)
            }
            return variant
        }
        set { defaults.set(newValue.rawValue, forKey: Key.petVariant.rawValue) }
    }

    static var petChattiness: PetChattiness {
        get { rawEnum(.petChattiness, default: .occasional) }
        set { setRawEnum(.petChattiness, newValue) }
    }

    static var petPosition: PetPosition {
        get { rawEnum(.petPosition, default: .rightOfNotch) }
        set { setRawEnum(.petPosition, newValue) }
    }

    static var petSize: PetSize {
        get { rawEnum(.petSize, default: .small) }
        set { setRawEnum(.petSize, newValue) }
    }

    static var petWellnessReminders: Bool {
        get { defaults.object(forKey: Key.petWellnessReminders.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.petWellnessReminders.rawValue) }
    }

    // MARK: - Notified thresholds (used by NotificationService to track fired notifications)
    static var notifiedThresholds: [String] {
        get { defaults.stringArray(forKey: Key.notifiedThresholds.rawValue) ?? [] }
        set { defaults.set(newValue, forKey: Key.notifiedThresholds.rawValue) }
    }

    // MARK: - Mini-game
    static var miniGameHighScore: Int {
        get { defaults.integer(forKey: Key.miniGameHighScore.rawValue) }
        set { defaults.set(newValue, forKey: Key.miniGameHighScore.rawValue) }
    }

    // MARK: - Menu bar style
    static var menuBarStyle: MenuBarStyle {
        get { rawEnum(.menuBarStyle, default: .iconOnly) }
        set { setRawEnum(.menuBarStyle, newValue) }
    }

    // MARK: - Generic enum-backed UserDefaults helpers

    /// Read a RawRepresentable enum from UserDefaults, returning `defaultValue` on miss or parse failure.
    private static func rawEnum<T: RawRepresentable>(_ key: Key, default defaultValue: T) -> T where T.RawValue == String {
        guard let raw = defaults.string(forKey: key.rawValue), let value = T(rawValue: raw) else {
            return defaultValue
        }
        return value
    }

    /// Write a RawRepresentable enum to UserDefaults.
    private static func setRawEnum<T: RawRepresentable>(_ key: Key, _ value: T) where T.RawValue == String {
        defaults.set(value.rawValue, forKey: key.rawValue)
    }
}

