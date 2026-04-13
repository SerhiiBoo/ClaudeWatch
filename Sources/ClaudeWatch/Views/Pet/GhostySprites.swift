// MARK: - Ghosty sprite data (playful little ghost)

/// All sprite frames for Ghosty the ghost.
/// Uses B=body (pale), D=dark gray, A=tail fade, G=glow, L=deep purple, E=eyes, C=cheek.
enum GhostySprites {

    // ── Idle frames (gentle float / tail wiggle) ───────────────────
    //  Ghost: rounded top, big eyes, wavy bottom tail

    static let idle1: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    static let idle2: [[SpriteColor]] = parseSprite("""
............
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.BB..BB..BB.
............
""")

    // ── Happy frames (spinning/floating) ───────────────────────────

    static let happy1: [[SpriteColor]] = parseSprite("""
.S..BBBB..S.
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    static let happy2: [[SpriteColor]] = parseSprite("""
............
.S..BBBB..S.
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.BB..BB..BB.
............
""")

    static let happy3: [[SpriteColor]] = parseSprite("""
S...BBBB...S
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB...B..BB.
............
""")

    // ── Tired frames (sinking, droopy) ─────────────────────────────

    static let tired1: [[SpriteColor]] = parseSprite("""
............
............
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
............
""")

    static let tired2: [[SpriteColor]] = parseSprite("""
............
............
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BDEBBDEB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.BB..BB..BB.
............
""")

    // ── Sleeping frames (transparent/faded, ZZZ) ───────────────────

    static let sleeping1: [[SpriteColor]] = parseSprite("""
..........Z.
.........Z..
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBDBBDBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
............
""")

    static let sleeping2: [[SpriteColor]] = parseSprite("""
.........Z..
..........Z.
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBDBBDBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.BB..BB..BB.
............
""")

    // ── Excited frames (zooming around) ────────────────────────────

    static let excited1: [[SpriteColor]] = parseSprite("""
.S..BBBB..S.
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    static let excited2: [[SpriteColor]] = parseSprite("""
............
............
.S..BBBB..S.
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
............
""")

    static let excited3: [[SpriteColor]] = parseSprite("""
S..........S
.S..BBBB..S.
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
............
""")

    // ── Critical frames (fading away) ──────────────────────────────

    static let critical1: [[SpriteColor]] = parseSprite("""
............
............
............
....DDDD....
...DDDDDD...
..DDEBBEDD..
..DDDDDDDD..
..DDDDDDDD..
...DDDDDD...
..DD.DD.DD..
............
............
""")

    static let critical2: [[SpriteColor]] = parseSprite("""
............
............
............
............
....DDDD....
...DDEBBEDD.
..DDDDDDDD..
..DDDDDDDD..
..DDDDDDDD..
...DDDDDD...
.DD..DD..DD.
............
""")

    // ── Reborn frames (burst of spectral energy) ───────────────────

    static let reborn1: [[SpriteColor]] = parseSprite("""
S...BBBB...S
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    static let reborn2: [[SpriteColor]] = parseSprite("""
.S.S.SS.S.S.
S...BBBB...S
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
............
""")

    static let reborn3: [[SpriteColor]] = parseSprite("""
S.S.S..S.S.S
.S.S.SS.S.S.
S...BBBB...S
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
............
""")

    // ── Peeking frames (ghostly peek from behind notch) ────────────

    static let peeking1: [[SpriteColor]] = parseSprite("""
............
............
............
............
............
............
............
............
....BBBB....
...BBBBBB...
..BBEBBEBB..
..BBBBBBBB..
""")

    static let peeking2: [[SpriteColor]] = parseSprite("""
............
............
............
............
............
............
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
""")

    // ── Movement poses ─────────────────────────────────────────────

    /// Falling: stretched vertically, scared wide eyes, tail trails up
    static let falling1: [[SpriteColor]] = parseSprite("""
..BB.BB.BB..
...BBBBBB...
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BWWBBWWB..
..BBEBBEBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
....BBBB....
............
""")

    /// Squash: flat puddle ghost, spread out
    static let squash1: [[SpriteColor]] = parseSprite("""
............
............
............
............
............
............
............
..BBBBBBBB..
.BBBBBBBBBB.
.BBEBBBBEBB.
.BBBBBBBBBB.
.BB.BB.BB.B.
""")

    /// Lean left: ghost trailing to the left, tail wisps right
    static let leanLeft1: [[SpriteColor]] = parseSprite("""
...BBBB.....
..BBBBBB....
.BBBBBBBB...
.BBEBBEBB...
.BBBBBBBB...
.BCBBBBCB...
.BBBBBBBB...
.BBBBBBBB...
..BBBBBB....
.BB.BB.BB...
BB..BB......
............
""")

    /// Lean right: ghost trailing to the right, tail wisps left
    static let leanRight1: [[SpriteColor]] = parseSprite("""
.....BBBB...
....BBBBBB..
...BBBBBBBB.
...BBEBBEBB.
...BBBBBBBB.
...BCBBBBCB.
...BBBBBBBB.
...BBBBBBBB.
....BBBBBB..
...BB.BB.BB.
......BB..BB
............
""")

    // ── Coding frames (laptop replaces tail) ────────────────────────

    static let coding1: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBBD..
..........D.
............
............
""")

    static let coding2: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DDDDDDDDDD.
.DAAAAAAAAD.
""")

    static let coding3: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBDBBDBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DGGGGGGGGD.
.DAAAAAAAAD.
""")

    static let coding4: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBDBBDBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DGLGGGGGGD.
.DAADAAADAD.
""")

    static let coding5: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBDBBDBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DGGGGGLGGD.
.DADADAADAD.
""")

    static let coding6: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBDBBDBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DGGGGGGGLD.
.DAADAAADAD.
""")

    static let coding7: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DDDDDDDDDD.
.DAAAAAAAAD.
""")

    static let coding8: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    // ── Debugging frames (magnifier overlay top-right) ────────────────

    static let debug1: [[SpriteColor]] = parseSprite("""
....BBBB.DD.
...BBBBBBDGD
..BBBBBBBBDD
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    static let debug2: [[SpriteColor]] = parseSprite("""
....BBBB.DD.
...BBBBBBDGD
..BBBBBBBBDD
..BBDBBDBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    static let debug3: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBBDD.
..BBBBBBBDGD
..BBDBBDBBDD
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    static let debug4: [[SpriteColor]] = parseSprite("""
....BBBBS...
...BBBBBB.S.
..BBBBBBBBSS
..BBDBBDBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    static let debug5: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
..BB.BB.BB..
.BB..BB..BB.
............
""")

    // ── Compiling frames (progress bar replaces tail) ────────────────

    static let compile1: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.D........D.
............
""")

    static let compile2: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DGG......D.
............
""")

    static let compile3: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DGGGG....D.
............
""")

    static let compile4: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DGGGGGG..D.
............
""")

    static let compile5: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBBBBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.DDDDDDDDDD.
.DGGGGGGGGD.
............
""")

    static let compile6: [[SpriteColor]] = parseSprite("""
....BBBB....
...BBBBBB...
..BBBBBBBB..
..BBEBBEBB..
..BBBBBBBB..
..BCBMMBCB..
..BBBBBBBB..
..BBBBBBBB..
...BBBBBB...
.LLLLLLLLLL.
.LGGGGGGGGL.
............
""")

    // MARK: - Frame sequences

    static func frames(for animation: PetAnimation) -> [[[SpriteColor]]] {
        switch animation {
        case .idle:      return [idle1, idle2]
        case .happy:     return [happy1, happy2, happy3, happy2]
        case .tired:     return [tired1, tired2]
        case .sleeping:  return [sleeping1, sleeping2]
        case .excited:   return [excited1, excited2, excited3, excited2]
        case .critical:  return [critical1, critical2]
        case .reborn:    return [reborn1, reborn2, reborn3, reborn2]
        case .talking:   return [happy1, happy2]
        case .peeking:   return [peeking1, peeking2]
        case .falling:   return [falling1]
        case .squash:    return [squash1]
        case .leanLeft:  return [leanLeft1]
        case .leanRight: return [leanRight1]
        case .coding:    return [coding1, coding2, coding3, coding4, coding5, coding6, coding7, coding8]
        case .debugging: return [debug1, debug2, debug3, debug4, debug3, debug5]
        case .compiling: return [compile1, compile2, compile3, compile4, compile5, compile6]
        }
    }

    static func frameDuration(for animation: PetAnimation) -> Double {
        switch animation {
        case .idle:      return 0.9
        case .happy:     return 0.28
        case .tired:     return 1.3
        case .sleeping:  return 1.1
        case .excited:   return 0.18
        case .critical:  return 1.8
        case .reborn:    return 0.22
        case .talking:   return 0.35
        case .peeking:   return 0.75
        case .falling, .squash, .leanLeft, .leanRight: return 0.5
        case .coding:    return 0.3
        case .debugging: return 0.35
        case .compiling: return 0.45
        }
    }
}
