import Foundation

enum PetMovement: String, CaseIterable, Identifiable {
    // Universal animations (work for any overlay position)
    case bounce     = "Bounce"
    case wander     = "Wander"
    case dash       = "Dash"
    // Menu bar positions (pet is ON the bar, can hide behind notch horizontally)
    case runAcross  = "Run Across"
    case peek       = "Peek"
    // Below-notch positions (pet hangs below, can hide UP behind the notch)
    case hideUp     = "Hide Up"
    case peekDown   = "Peek Down"
    case dropCatch  = "Drop & Catch"
    case swing      = "Swing"
    // Character-specific animations
    case wobble     = "Wobble"       // Clodey: jelly wiggle
    case stretch    = "Stretch"      // Clodey: vertical squash & stretch
    case glitch     = "Glitch"       // Bytie: screen-glitch jitter
    case scan       = "Scan"         // Bytie: smooth horizontal sweep
    case sway       = "Sway"         // Sprout: gentle wind sway
    case grow       = "Grow"         // Sprout: vertical growth spurt
    case phase      = "Phase"        // Ghosty: fade out & reappear offset
    case spook      = "Spook"        // Ghosty: quick lunge & retreat

    var id: String { rawValue }
    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .bounce:    return "arrow.up.arrow.down"
        case .wander:    return "point.topleft.down.to.point.bottomright.curvepath"
        case .dash:      return "hare"
        case .runAcross: return "figure.run"
        case .peek:      return "eye"
        case .hideUp:    return "arrow.up.to.line"
        case .peekDown:  return "arrow.down.to.line"
        case .dropCatch: return "arrow.down.app"
        case .swing:     return "metronome"
        case .wobble:    return "water.waves"
        case .stretch:   return "arrow.up.and.down"
        case .glitch:    return "waveform.path.ecg"
        case .scan:      return "barcode.viewfinder"
        case .sway:      return "wind"
        case .grow:      return "leaf"
        case .phase:     return "eye.slash"
        case .spook:     return "exclamationmark.triangle"
        }
    }

    /// Which position category this movement is designed for.
    enum PositionFit {
        case universal        // works anywhere
        case menuBar          // needs to be ON the menu bar (horizontal notch tricks)
        case belowNotch       // needs to be BELOW the notch (vertical tricks)
        case notchVertical    // vertical tricks that work for both menu bar and below-notch
    }

    var positionFit: PositionFit {
        switch self {
        case .bounce, .wander, .dash:                             return .universal
        case .wobble, .stretch, .glitch, .scan, .sway, .grow:    return .universal
        case .phase, .spook:                                       return .universal
        case .runAcross, .peek:                                    return .menuBar
        case .hideUp, .swing:                                      return .belowNotch
        case .peekDown, .dropCatch:                                return .notchVertical
        }
    }

    /// Which character this movement belongs to (nil = available to all).
    var characterAffinity: PetCharacter? {
        switch self {
        case .wobble, .stretch: return .clodey
        case .glitch, .scan:    return .bytie
        case .sway, .grow:      return .sprout
        case .phase, .spook:    return .ghosty
        default:                return nil  // generic, all characters
        }
    }

    /// Whether this movement is appropriate for the given position, screen, and character.
    func isAvailable(for position: PetPosition, screenHasNotch: Bool, character: PetCharacter? = nil) -> Bool {
        // Character-specific: only show for matching character
        if let affinity = characterAffinity {
            if let char = character, char != affinity { return false }
        }

        switch positionFit {
        case .universal:
            return true
        case .menuBar:
            return screenHasNotch && (position == .leftOfMenuBar || position == .rightOfMenuBar)
        case .belowNotch:
            return screenHasNotch && (position == .leftOfNotch || position == .rightOfNotch)
        case .notchVertical:
            return screenHasNotch
        }
    }
}
