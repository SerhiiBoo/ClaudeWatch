import Foundation

enum PetAnimation: String {
    // Mood-based animations
    case idle
    case happy
    case tired
    case sleeping
    case excited
    case critical
    case reborn
    case talking
    case peeking
    // Movement pose overrides (set during window animations)
    case falling      // surprised/flailing during drops
    case squash       // compressed flat on landing
    case leanLeft     // body leaning/tilted left
    case leanRight    // body leaning/tilted right
    // Ambient personality animations (one-shot, random cadence)
    case coding       // fetch laptop → type → hide
    case debugging    // magnifier → squint → "!" discovery
    case compiling    // progress bar filling
}
