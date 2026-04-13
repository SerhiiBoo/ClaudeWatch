import Foundation

enum PetVariant: String, CaseIterable, Identifiable {
    // Clodey variants
    case clodeyClassic = "Classic Clodey"
    case clodeyWizard  = "Wizard Clodey"
    case clodeyCat     = "Cat Clodey"
    case clodeyKnight  = "Knight Clodey"
    case clodeyDevil   = "Devil Clodey"
    // Bytie variants
    case bytieClassic   = "Classic Bytie"
    case bytieTV        = "TV Bytie"
    case bytieDrone     = "Drone Bytie"
    case bytieSpider    = "Spider Bytie"
    case bytieArcade    = "Arcade Bytie"
    case bytieCuteRobot = "Cute Robot Bytie"
    // Sprout variants
    case sproutClassic  = "Classic Sprout"
    case sproutMushroom = "Mushroom Sprout"
    case sproutCactus   = "Cactus Sprout"
    case sproutBonsai   = "Bonsai Sprout"
    case sproutAcorn    = "Acorn Sprout"
    // Ghosty variants
    case ghostyClassic   = "Classic Ghosty"
    case ghostyBat       = "Bat Ghosty"
    case ghostyWisp      = "Wisp Ghosty"
    case ghostyReaper    = "Reaper Ghosty"
    case ghostyJellyfish = "Jellyfish Ghosty"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// Which base character this variant belongs to.
    var character: PetCharacter {
        switch self {
        case .clodeyClassic, .clodeyWizard, .clodeyCat, .clodeyKnight, .clodeyDevil:
            return .clodey
        case .bytieClassic, .bytieTV, .bytieDrone, .bytieSpider, .bytieArcade, .bytieCuteRobot:
            return .bytie
        case .sproutClassic, .sproutMushroom, .sproutCactus, .sproutBonsai, .sproutAcorn:
            return .sprout
        case .ghostyClassic, .ghostyBat, .ghostyWisp, .ghostyReaper, .ghostyJellyfish:
            return .ghosty
        }
    }

    /// Whether this variant uses the base character's sprite shapes (classic) or has custom sprites.
    var isClassic: Bool {
        switch self {
        case .clodeyClassic, .bytieClassic, .sproutClassic, .ghostyClassic: return true
        default: return false
        }
    }

    /// Grid size for this variant's sprites (most are 12×12, some high-detail are 16×16).
    var gridSize: Int {
        switch self {
        case .bytieCuteRobot: return 16
        default: return 12
        }
    }

    /// Short display name for compact UI (strips the character name prefix).
    var shortName: String {
        switch character {
        case .clodey: return displayName.replacingOccurrences(of: " Clodey", with: "")
        case .bytie:  return displayName.replacingOccurrences(of: " Bytie", with: "")
        case .sprout: return displayName.replacingOccurrences(of: " Sprout", with: "")
        case .ghosty: return displayName.replacingOccurrences(of: " Ghosty", with: "")
        }
    }

    /// Variants available for a specific character.
    static func variants(for character: PetCharacter) -> [PetVariant] {
        allCases.filter { $0.character == character }
    }

    /// The default (classic) variant for a character.
    static func defaultVariant(for character: PetCharacter) -> PetVariant {
        switch character {
        case .clodey: return .clodeyClassic
        case .bytie:  return .bytieClassic
        case .sprout: return .sproutClassic
        case .ghosty: return .ghostyClassic
        }
    }
}
