import AppKit
import Carbon.HIToolbox

// MARK: - Notification

extension Notification.Name {
    static let hotkeyTriggered = Notification.Name("com.local.ClaudeWatch.hotkeyTriggered")
}

// MARK: - Carbon event handler (free function — required for C function pointer)

private func hotKeyEventHandler(
    _: EventHandlerCallRef?,
    _ event: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    var hkID = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hkID
    )
    guard hkID.signature == HotkeyService.signature, hkID.id == 1 else { return noErr }
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: .hotkeyTriggered, object: nil)
    }
    return noErr
}

// MARK: - HotkeyService

/// Registers and manages a single global hotkey using Carbon's RegisterEventHotKey.
/// Call `updateFromSettings()` after any hotkey setting changes.
final class HotkeyService {
    static let shared = HotkeyService()

    /// FourCharCode "CWAT" (ClaudeWATch)
    static let signature: FourCharCode = 0x43574154

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private init() {}

    // MARK: - Public API

    func updateFromSettings() {
        if AppSettings.globalHotkeyEnabled {
            register(keyCode: AppSettings.globalHotkeyKeyCode,
                     carbonModifiers: AppSettings.globalHotkeyModifiers)
        } else {
            unregister()
        }
    }

    func register(keyCode: UInt32, carbonModifiers: UInt32) {
        unregister()
        installHandlerIfNeeded()
        let hkID = EventHotKeyID(signature: Self.signature, id: 1)
        let status = RegisterEventHotKey(
            keyCode, carbonModifiers, hkID,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
        if status != noErr {
            LogService.log(.warning, category: "HotkeyService",
                           "RegisterEventHotKey failed", details: ["status": "\(status)"])
        }
    }

    /// Unregisters the active hotkey. The Carbon event handler remains installed
    /// for the app's lifetime so re-registration via `register()` is cheap.
    /// The handler is removed in `deinit`.
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    deinit {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
    }

    // MARK: - Private

    private func installHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1, &spec, nil, &eventHandlerRef
        )
    }

    // MARK: - Display helpers

    /// Converts NSEvent modifier flags to Carbon modifier flags.
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.shift)   { mods |= UInt32(shiftKey) }
        if flags.contains(.option)  { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        return mods
    }

    /// Formats a key combo as a human-readable string, e.g. "⌘⇧C".
    static func displayString(keyCode: UInt32, carbonModifiers: UInt32) -> String {
        var result = ""
        if carbonModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if carbonModifiers & UInt32(optionKey)  != 0 { result += "⌥" }
        if carbonModifiers & UInt32(shiftKey)   != 0 { result += "⇧" }
        if carbonModifiers & UInt32(cmdKey)     != 0 { result += "⌘" }
        result += keyName(keyCode)
        return result
    }

    // Maps Carbon/NSEvent virtual key codes to display names.
    private static let keyNames: [UInt32: String] = [
         0: "A",   1: "S",   2: "D",   3: "F",   4: "H",   5: "G",   6: "Z",   7: "X",
         8: "C",   9: "V",  11: "B",  12: "Q",  13: "W",  14: "E",  15: "R",
        16: "Y",  17: "T",  18: "1",  19: "2",  20: "3",  21: "4",  22: "6",
        23: "5",  24: "=",  25: "9",  26: "7",  27: "-",  28: "8",  29: "0",
        30: "]",  31: "O",  32: "U",  33: "[",  34: "I",  35: "P",
        36: "↩",  37: "L",  38: "J",  39: "'",  40: "K",  41: ";",
        42: "\\", 43: ",",  44: "/",  45: "N",  46: "M",  47: ".",
        48: "⇥",  49: "Space", 51: "⌫", 53: "⎋",
       115: "↖", 116: "⇞", 117: "⌦", 119: "↘", 121: "⇟",
       123: "←", 124: "→", 125: "↓", 126: "↑",
       122: "F1", 120: "F2",  99: "F3", 118: "F4",  96: "F5",  97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
    ]

    static func keyName(_ keyCode: UInt32) -> String {
        keyNames[keyCode] ?? "(\(keyCode))"
    }
}
