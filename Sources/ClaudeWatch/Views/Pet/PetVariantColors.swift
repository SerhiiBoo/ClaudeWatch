import SwiftUI

// MARK: - Variant color overrides

extension PetVariant {
    /// Returns a color override for a specific sprite color slot, or nil to use character defaults.
    func colorOverride(for slot: SpriteColor) -> Color? {
        switch self {

        // ── Clodey Wizard ──
        case .clodeyWizard:
            switch slot {
            case .body:  return Color(red: 0.42, green: 0.35, blue: 0.80)  // purple robe
            case .dark:  return Color(red: 0.28, green: 0.24, blue: 0.55)  // dark purple
            case .cheek: return Color(red: 0.87, green: 0.63, blue: 0.87)  // plum blush
            case .hat:   return Color(red: 0.29, green: 0.00, blue: 0.51)  // deep indigo hat
            case .spark: return Color(red: 1.0, green: 0.84, blue: 0.0)    // gold stars
            default: return nil
            }

        // ── Clodey Cat ──
        case .clodeyCat:
            switch slot {
            case .body:  return Color(red: 0.96, green: 0.64, blue: 0.38)  // orange tabby
            case .dark:  return Color(red: 0.80, green: 0.52, blue: 0.25)  // dark tabby
            case .cheek: return Color(red: 1.0, green: 0.71, blue: 0.76)   // pink blush
            case .alt1:  return Color(red: 0.82, green: 0.41, blue: 0.12)  // tail (T→A)
            case .alt2:  return Color(red: 1.0, green: 0.89, blue: 0.77)   // whisker/nose (N→G)
            default: return nil
            }

        // ── Clodey Knight ──
        case .clodeyKnight:
            switch slot {
            case .body:  return Color(red: 0.85, green: 0.55, blue: 0.35)  // body under armor
            case .dark:  return Color(red: 0.44, green: 0.44, blue: 0.44)  // dark steel
            case .alt1:  return Color(red: 0.66, green: 0.66, blue: 0.66)  // armor plate
            case .spark: return Color(red: 0.75, green: 0.75, blue: 0.75)  // armor shine
            case .hat:   return Color(red: 0.50, green: 0.50, blue: 0.50)  // helmet
            default: return nil
            }

        // ── Clodey Devil ──
        case .clodeyDevil:
            switch slot {
            case .body:  return Color(red: 0.86, green: 0.08, blue: 0.24)  // crimson
            case .dark:  return Color(red: 0.55, green: 0.0, blue: 0.0)    // dark red
            case .cheek: return Color(red: 1.0, green: 0.39, blue: 0.28)   // hot orange
            case .eye:   return Color(red: 1.0, green: 0.84, blue: 0.0)    // gold eyes
            case .alt1:  return Color(red: 0.70, green: 0.13, blue: 0.13)  // tail (T→A)
            case .hat:   return Color(red: 1.0, green: 0.0, blue: 0.0)     // horn tips
            default: return nil
            }

        // ── Bytie TV ──
        case .bytieTV:
            switch slot {
            case .body:  return Color(red: 0.55, green: 0.45, blue: 0.33)  // wood beige
            case .dark:  return Color(red: 0.36, green: 0.25, blue: 0.20)  // dark wood
            case .alt2:  return Color(red: 0.0, green: 0.20, blue: 0.0)    // dark screen
            case .alt1:  return Color(red: 0.0, green: 0.13, blue: 0.0)    // screen shadow
            case .spark: return Color(red: 0.75, green: 0.75, blue: 0.75)  // antenna
            case .eye:   return Color(red: 0.24, green: 1.0, blue: 0.25)   // green pixel eyes
            default: return nil
            }

        // ── Bytie Drone ──
        case .bytieDrone:
            switch slot {
            case .body:  return Color(red: 0.21, green: 0.27, blue: 0.31)  // dark charcoal
            case .dark:  return Color(red: 0.47, green: 0.53, blue: 0.60)  // propeller plate (P→D)
            case .eye:   return Color(red: 1.0, green: 0.0, blue: 0.0)     // red camera
            case .spark: return Color(red: 0.75, green: 0.75, blue: 0.75)  // propeller shine (R→S)
            case .alt2:  return Color(red: 0.18, green: 0.80, blue: 0.44)  // status LED
            default: return nil
            }

        // ── Bytie Spider ──
        case .bytieSpider:
            switch slot {
            case .body:  return Color(red: 0.18, green: 0.31, blue: 0.31)  // dark teal
            case .dark:  return Color(red: 0.10, green: 0.10, blue: 0.18)  // near black
            case .eye:   return Color(red: 1.0, green: 0.0, blue: 0.0)     // red eyes
            case .alt1:  return Color(red: 0.24, green: 0.36, blue: 0.36)  // legs
            default: return nil
            }

        // ── Bytie Arcade ──
        case .bytieArcade:
            switch slot {
            case .body:  return Color(red: 0.25, green: 0.41, blue: 0.88)  // blue cabinet
            case .dark:  return Color(red: 0.10, green: 0.10, blue: 0.44)  // dark blue
            case .alt1:  return Color(red: 0.0, green: 0.0, blue: 0.50)    // screen bg
            case .eye:   return Color(red: 1.0, green: 0.84, blue: 0.0)    // yellow pixel eyes
            case .alt2:  return Color(red: 0.0, green: 1.0, blue: 0.0)     // green score
            case .spark: return Color(red: 0.75, green: 0.75, blue: 0.75)  // joystick
            default: return nil
            }

        // ── Bytie Cute Robot (16×16) ──
        case .bytieCuteRobot:
            switch slot {
            case .body:  return Color(red: 0.48, green: 0.60, blue: 0.64)  // soft steel blue
            case .dark:  return Color(red: 0.29, green: 0.36, blue: 0.42)  // dark steel
            case .eye:   return Color(red: 1.0, green: 0.84, blue: 0.31)   // glowing yellow eyes
            case .white: return Color(red: 0.78, green: 0.85, blue: 0.91)  // helmet highlight
            case .cheek: return Color(red: 1.0, green: 0.54, blue: 0.40)   // orange joint accents
            case .mouth: return Color(red: 0.69, green: 0.75, blue: 0.77)  // lighter chin panel
            case .spark: return Color(red: 0.66, green: 0.78, blue: 0.85)  // helmet top shine
            case .alt1:  return Color(red: 0.36, green: 0.44, blue: 0.50)  // ear/arm plates
            case .alt2:  return Color(red: 0.23, green: 0.29, blue: 0.34)  // visor dark
            case .hat:   return Color(red: 0.56, green: 0.66, blue: 0.73)  // chest panel
            default: return nil
            }

        // ── Sprout Mushroom ──
        case .sproutMushroom:
            switch slot {
            case .body:  return Color(red: 0.96, green: 0.87, blue: 0.70)  // stalk cream
            case .dark:  return Color(red: 0.87, green: 0.72, blue: 0.53)  // dark stalk
            case .alt1:  return Color(red: 0.86, green: 0.08, blue: 0.24)  // red cap
            case .spark: return Color(red: 1.0, green: 0.98, blue: 0.80)   // white spots
            default: return nil
            }

        // ── Sprout Cactus ──
        case .sproutCactus:
            switch slot {
            case .body:  return Color(red: 0.18, green: 0.55, blue: 0.34)  // cactus green
            case .dark:  return Color(red: 0.0, green: 0.39, blue: 0.0)    // dark cactus
            case .alt1:  return Color(red: 0.80, green: 0.52, blue: 0.25)  // terracotta pot
            case .alt3:  return Color(red: 1.0, green: 0.41, blue: 0.71)   // pink flower
            default: return nil
            }

        // ── Sprout Bonsai ──
        case .sproutBonsai:
            switch slot {
            case .body:  return Color(red: 0.55, green: 0.27, blue: 0.07)  // trunk brown
            case .dark:  return Color(red: 0.40, green: 0.26, blue: 0.13)  // dark trunk
            case .alt1:  return Color(red: 0.33, green: 0.42, blue: 0.18)  // dark green pot/base
            case .alt2:  return Color(red: 0.13, green: 0.55, blue: 0.13)  // foliage green
            case .alt3:  return Color(red: 0.20, green: 0.80, blue: 0.20)  // light leaf
            default: return nil
            }

        // ── Sprout Acorn ──
        case .sproutAcorn:
            switch slot {
            case .body:  return Color(red: 0.80, green: 0.52, blue: 0.25)  // acorn brown
            case .dark:  return Color(red: 0.55, green: 0.36, blue: 0.09)  // dark brown
            case .alt1:  return Color(red: 0.55, green: 0.45, blue: 0.33)  // cap
            case .alt2:  return Color(red: 0.13, green: 0.55, blue: 0.13)  // sprout green
            default: return nil
            }

        // ── Ghosty Bat ──
        case .ghostyBat:
            switch slot {
            case .body:  return Color(red: 0.28, green: 0.24, blue: 0.55)  // dark purple
            case .dark:  return Color(red: 0.18, green: 0.15, blue: 0.33)  // near-black purple
            case .eye:   return Color(red: 1.0, green: 0.27, blue: 0.0)    // orange eyes
            case .spark: return Color(red: 0.42, green: 0.35, blue: 0.80)  // wing membrane (F→S)
            case .cheek: return Color(red: 0.58, green: 0.44, blue: 0.86)  // purple blush
            default: return nil
            }

        // ── Ghosty Wisp ──
        case .ghostyWisp:
            switch slot {
            case .body:  return Color(red: 0.53, green: 0.81, blue: 0.92)  // pale blue
            case .dark:  return Color(red: 0.27, green: 0.51, blue: 0.71)  // steel blue
            case .eye:   return Color(red: 0.0, green: 0.0, blue: 0.50)    // navy eyes
            case .spark: return Color(red: 1.0, green: 0.84, blue: 0.0)    // flame gold
            default: return nil
            }

        // ── Ghosty Reaper ──
        case .ghostyReaper:
            switch slot {
            case .body:  return Color(red: 0.18, green: 0.18, blue: 0.18)  // dark gray
            case .dark:  return Color(red: 0.10, green: 0.10, blue: 0.10)  // near black
            case .eye:   return Color(red: 1.0, green: 0.0, blue: 0.0)     // red eyes
            case .alt1:  return Color(red: 0.25, green: 0.25, blue: 0.25)  // hood
            case .spark: return Color(red: 0.75, green: 0.75, blue: 0.75)  // scythe blade
            case .hat:   return Color(red: 0.25, green: 0.25, blue: 0.25)  // hood
            default: return nil
            }

        // ── Ghosty Jellyfish ──
        case .ghostyJellyfish:
            switch slot {
            case .body:  return Color(red: 0.85, green: 0.44, blue: 0.84)  // orchid
            case .dark:  return Color(red: 0.73, green: 0.33, blue: 0.83)  // dark orchid
            case .eye:   return Color(red: 0.29, green: 0.0, blue: 0.51)   // deep purple eyes
            case .alt1:  return Color(red: 0.87, green: 0.63, blue: 0.87)  // tentacles (T→A)
            case .cheek: return Color(red: 0.93, green: 0.51, blue: 0.93)  // glow
            default: return nil
            }

        // Classic variants use character defaults
        default: return nil
        }
    }
}
