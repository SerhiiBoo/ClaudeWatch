import Foundation

enum HookEventKind: String, Sendable {
    case notification
    case stop

    var defaultTimeout: TimeInterval {
        self == .notification ? 15 : 8
    }

    var icon: String {
        self == .stop ? "checkmark.seal" : "bell.badge"
    }

    var defaultMessage: String {
        self == .stop ? "Done." : "Waiting for your input."
    }

    init?(hookEventName: String) {
        switch hookEventName {
        case "Notification":
            self = .notification
        case "Stop":
            self = .stop
        default:
            return nil
        }
    }
}
