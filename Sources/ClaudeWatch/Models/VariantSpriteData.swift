import Foundation

/// All sprite frames and timing data for one pet variant.
/// Values are looked up by `CharacterSprites` via a static dictionary — no protocol dispatch needed.
struct VariantSpriteData {
    let idle:     [[[SpriteColor]]]
    let happy:    [[[SpriteColor]]]
    let tired:    [[[SpriteColor]]]
    let sleeping: [[[SpriteColor]]]
    let excited:  [[[SpriteColor]]]
    let critical: [[[SpriteColor]]]
    let reborn:   [[[SpriteColor]]]
    let talking:  [[[SpriteColor]]]   // if empty, happy frames are reused
    let peeking:  [[[SpriteColor]]]
    let falling:   [[SpriteColor]]     // single frame (2D)
    let squash:    [[SpriteColor]]
    let leanLeft:  [[SpriteColor]]
    let leanRight: [[SpriteColor]]
    let coding:    [[[SpriteColor]]]   // ambient one-shot
    let debugging: [[[SpriteColor]]]   // ambient one-shot
    let compiling: [[[SpriteColor]]]   // ambient one-shot
    let durations: [PetAnimation: Double]

    func frames(for animation: PetAnimation) -> [[[SpriteColor]]] {
        switch animation {
        case .idle:      return idle
        case .happy:     return happy
        case .tired:     return tired
        case .sleeping:  return sleeping
        case .excited:   return excited
        case .critical:  return critical
        case .reborn:    return reborn
        case .talking:   return talking.isEmpty ? happy : talking
        case .peeking:   return peeking
        case .falling:   return [falling]
        case .squash:    return [squash]
        case .leanLeft:  return [leanLeft]
        case .leanRight: return [leanRight]
        case .coding:    return coding
        case .debugging: return debugging
        case .compiling: return compiling
        }
    }

    func frameDuration(for animation: PetAnimation) -> Double {
        durations[animation] ?? 0.5
    }
}
