import SwiftUI

// MARK: - Character color palettes

extension PetCharacter {
    var bodyColor: Color {
        switch self {
        case .clodey: return Color(red: 0.85, green: 0.55, blue: 0.35)  // terracotta
        case .bytie:  return Color(red: 0.70, green: 0.90, blue: 0.96)  // light cyan
        case .sprout: return Color(red: 0.45, green: 0.75, blue: 0.40)  // leafy green
        case .ghosty: return Color(red: 0.85, green: 0.85, blue: 0.92)  // pale lavender-white
        }
    }

    var darkColor: Color {
        switch self {
        case .clodey: return Color(red: 0.60, green: 0.35, blue: 0.20)  // dark terracotta
        case .bytie:  return Color(red: 0.10, green: 0.10, blue: 0.12)  // near-black outline
        case .sprout: return Color(red: 0.30, green: 0.55, blue: 0.25)  // dark green
        case .ghosty: return Color(red: 0.65, green: 0.65, blue: 0.75)  // medium gray-lavender
        }
    }

    var cheekColor: Color {
        switch self {
        case .clodey: return Color(red: 0.95, green: 0.55, blue: 0.50)  // rosy
        case .bytie:  return Color(red: 0.90, green: 0.55, blue: 0.10)  // orange/amber (eyes)
        case .sprout: return Color(red: 0.95, green: 0.65, blue: 0.50)  // warm peach
        case .ghosty: return Color(red: 0.80, green: 0.70, blue: 0.90)  // soft purple
        }
    }

    var alt1Color: Color {
        switch self {
        case .clodey: return Color(red: 0.85, green: 0.55, blue: 0.35)  // same as body
        case .bytie:  return Color(red: 0.60, green: 0.22, blue: 0.20)  // dark reddish-brown (body/legs)
        case .sprout: return Color(red: 0.65, green: 0.45, blue: 0.30)  // terracotta pot
        case .ghosty: return Color(red: 0.70, green: 0.70, blue: 0.80)  // tail fade
        }
    }

    var alt2Color: Color {
        switch self {
        case .clodey: return Color(red: 0.85, green: 0.55, blue: 0.35)  // same as body
        case .bytie:  return Color(red: 0.82, green: 0.95, blue: 1.00)  // lighter cyan edge/highlight
        case .sprout: return Color(red: 0.35, green: 0.65, blue: 0.30)  // darker leaf
        case .ghosty: return Color(red: 0.90, green: 0.80, blue: 1.0)   // light glow
        }
    }

    var alt3Color: Color {
        switch self {
        case .clodey: return Color(red: 0.85, green: 0.55, blue: 0.35)  // same as body
        case .bytie:  return Color(red: 0.85, green: 0.30, blue: 0.15)  // red-orange antenna ball
        case .sprout: return Color(red: 0.95, green: 0.85, blue: 0.30)  // flower yellow
        case .ghosty: return Color(red: 0.60, green: 0.50, blue: 0.80)  // deep purple
        }
    }
}
