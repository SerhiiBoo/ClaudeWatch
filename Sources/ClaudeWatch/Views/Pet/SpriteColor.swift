import SwiftUI

// MARK: - Sprite color palette

/// A small, fixed palette for pixel art sprites.
/// Using a compact enum instead of raw Color values keeps sprite data readable.
enum SpriteColor: String {
    case clear = "."    // transparent
    case body  = "B"    // main body color
    case dark  = "D"    // darker outline/shadow
    case eye   = "E"    // eyes
    case cheek = "C"    // blush/cheek
    case white = "W"    // highlights/sparkles
    case mouth = "M"    // mouth when speaking
    case zzz   = "Z"    // sleep bubble color
    case spark  = "S"   // sparkle/star
    case alt1  = "A"    // alternate color 1 (e.g. pot, antenna)
    case alt2  = "G"    // alternate color 2 (e.g. leaf, screen)
    case alt3  = "L"    // alternate color 3 (e.g. light/glow)
    case hat   = "H"    // hat/hood/helmet (used by variant skins)

    /// Character-specific color mapping.
    func color(for character: PetCharacter) -> Color {
        switch self {
        case .clear: return .clear
        case .eye:   return Color(red: 0.15, green: 0.15, blue: 0.20)
        case .cheek: return character.cheekColor
        case .white: return Color.white
        case .mouth: return Color(red: 0.90, green: 0.40, blue: 0.40)
        case .zzz:   return Color(red: 0.60, green: 0.70, blue: 0.85)
        case .spark: return Color(red: 1.0, green: 0.85, blue: 0.30)
        case .body:  return character.bodyColor
        case .dark:  return character.darkColor
        case .alt1:  return character.alt1Color
        case .alt2:  return character.alt2Color
        case .alt3:  return character.alt3Color
        case .hat:   return character.darkColor  // default: same as dark
        }
    }

    /// Variant-specific color mapping (overrides character colors for variant skins).
    func color(for variant: PetVariant) -> Color {
        // For classic variants, use character colors
        if variant.isClassic { return color(for: variant.character) }

        // Check variant-specific overrides first
        if let override = variant.colorOverride(for: self) { return override }

        // Fall back to character base colors
        return color(for: variant.character)
    }
}
