import Foundation

enum HookDeliveryStyle: String, CaseIterable, Sendable {
    case popover
    case native

    var label: String {
        switch self {
        case .popover: return "Floating card"
        case .native:  return "macOS notification"
        }
    }
}
