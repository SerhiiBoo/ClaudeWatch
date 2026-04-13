// MARK: - CharacterSprites

/// Resolves frames and timing for any character or variant.
enum CharacterSprites {

    // MARK: - Variant lookup table

    private static let table: [PetVariant: VariantSpriteData] = [
        .clodeyClassic:    .clodeyClassic,
        .clodeyWizard:     .clodeyWizard,
        .clodeyCat:        .clodeyCat,
        .clodeyKnight:     .clodeyKnight,
        .clodeyDevil:      .clodeyDevil,
        .bytieClassic:     .bytieClassic,
        .bytieTV:          .bytieTV,
        .bytieDrone:       .bytieDrone,
        .bytieSpider:      .bytieSpider,
        .bytieArcade:      .bytieArcade,
        .bytieCuteRobot:   .bytieCuteRobot,
        .sproutClassic:    .sproutClassic,
        .sproutMushroom:   .sproutMushroom,
        .sproutCactus:     .sproutCactus,
        .sproutBonsai:     .sproutBonsai,
        .sproutAcorn:      .sproutAcorn,
        .ghostyClassic:    .ghostyClassic,
        .ghostyBat:        .ghostyBat,
        .ghostyWisp:       .ghostyWisp,
        .ghostyReaper:     .ghostyReaper,
        .ghostyJellyfish:  .ghostyJellyfish,
    ]

    // MARK: - Variant-aware API (primary)

    static func frames(for animation: PetAnimation, variant: PetVariant) -> [[[SpriteColor]]] {
        guard let data = table[variant] else {
            return frames(for: animation, character: variant.character)
        }
        return data.frames(for: animation)
    }

    static func frameDuration(for animation: PetAnimation, variant: PetVariant) -> Double {
        guard let data = table[variant] else {
            return frameDuration(for: animation, character: variant.character)
        }
        return data.frameDuration(for: animation)
    }

    static func defaultFrame(for variant: PetVariant) -> [[SpriteColor]] {
        guard let data = table[variant] else {
            return defaultFrame(for: variant.character)
        }
        return data.frames(for: .idle).first ?? defaultFrame(for: variant.character)
    }

    // MARK: - Character-level API (classic fallback)

    static func frames(for animation: PetAnimation, character: PetCharacter) -> [[[SpriteColor]]] {
        switch character {
        case .clodey: return ClodeySprites.frames(for: animation)
        case .bytie:  return BytieSprites.frames(for: animation)
        case .sprout: return SproutSprites.frames(for: animation)
        case .ghosty: return GhostySprites.frames(for: animation)
        }
    }

    static func frameDuration(for animation: PetAnimation, character: PetCharacter) -> Double {
        switch character {
        case .clodey: return ClodeySprites.frameDuration(for: animation)
        case .bytie:  return BytieSprites.frameDuration(for: animation)
        case .sprout: return SproutSprites.frameDuration(for: animation)
        case .ghosty: return GhostySprites.frameDuration(for: animation)
        }
    }

    static func defaultFrame(for character: PetCharacter) -> [[SpriteColor]] {
        switch character {
        case .clodey: return ClodeySprites.idle1
        case .bytie:  return BytieSprites.idle1
        case .sprout: return SproutSprites.idle1
        case .ghosty: return GhostySprites.idle1
        }
    }
}
