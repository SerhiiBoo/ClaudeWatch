import Foundation

enum PetPosition: String, CaseIterable, Identifiable {
    case leftOfMenuBar    = "Left menu bar"
    case rightOfMenuBar   = "Right menu bar"
    case leftOfNotch      = "Left of notch"
    case rightOfNotch     = "Right of notch"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .leftOfMenuBar:  return "On menu bar, left of notch"
        case .rightOfMenuBar: return "On menu bar, right of notch"
        case .leftOfNotch:    return "Below notch, left side"
        case .rightOfNotch:   return "Below notch, right side"
        }
    }

}
