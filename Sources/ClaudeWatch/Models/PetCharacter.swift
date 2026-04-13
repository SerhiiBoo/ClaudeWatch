import Foundation

enum PetCharacter: String, CaseIterable, Identifiable {
    case clodey  = "Clodey"
    case bytie   = "Bytie"
    case sprout  = "Sprout"
    case ghosty  = "Ghosty"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .clodey: return "A friendly Claude-inspired blob"
        case .bytie:  return "A retro pixel robot"
        case .sprout: return "A tiny plant in a pot"
        case .ghosty: return "A playful little ghost"
        }
    }
}
