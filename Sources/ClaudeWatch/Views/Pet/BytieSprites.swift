// MARK: - Bytie sprite data (retro pixel robot)

/// All sprite frames for Bytie the robot.
/// Uses B=body (steel), D=dark, A=antenna/plate, G=screen, L=LED, E=eyes, W=white.
enum BytieSprites {

    // ── Idle frames (gentle hum / bob) ─────────────────────────────
    //  Cute pixel robot: large light-cyan head, dark outline, lighter-cyan
    //  edge highlight (G), orange eyes (C), dark mouth (D), dark-red body
    //  and legs (A), red-orange antenna gem (L).
    //  D=black outline, B=cyan head, G=lighter-cyan edge, C=orange eyes,
    //  A=dark-red body/legs, L=antenna gem, S=spark, Z=zzz

    static let idle1: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
............
""")

    static let idle2: [[SpriteColor]] = parseSprite("""
............
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    // ── Happy frames (wide smile, sparks) ──────────────────────────

    static let happy1: [[SpriteColor]] = parseSprite("""
..........S.
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let happy2: [[SpriteColor]] = parseSprite("""
.S..........
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let happy3: [[SpriteColor]] = parseSprite("""
S..........S
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    // ── Tired frames (no smile, sunk lower) ────────────────────────

    static let tired1: [[SpriteColor]] = parseSprite("""
............
............
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let tired2: [[SpriteColor]] = parseSprite("""
............
............
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGBBBBBBGD.
.DGCBBBBCGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    // ── Sleeping frames (eyes off, ZZZ) ────────────────────────────

    static let sleeping1: [[SpriteColor]] = parseSprite("""
..........Z.
.........Z..
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGBBBBBBGD.
.DGBBBBBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let sleeping2: [[SpriteColor]] = parseSprite("""
.........Z..
..........Z.
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGBBBBBBGD.
.DGBBBBBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    // ── Excited frames (sparks, bouncing, wide smile) ───────────────

    static let excited1: [[SpriteColor]] = parseSprite("""
.S...LL...S.
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let excited2: [[SpriteColor]] = parseSprite("""
............
............
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let excited3: [[SpriteColor]] = parseSprite("""
S....LL....S
.S.........S
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    // ── Critical frames (glitching, face static) ───────────────────

    static let critical1: [[SpriteColor]] = parseSprite("""
............
............
....DLD.....
.DDDDDDDDDD.
.DGBDBDBDGD.
.DGDBDBDBGD.
.DGBDBDBDGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
..AA....AA..
""")

    static let critical2: [[SpriteColor]] = parseSprite("""
............
............
............
....DLD.....
.DDDDDDDDDD.
.DGBDBDBDGD.
.DGDBDBDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
..AAA..AAA..
""")

    // ── Reborn frames (full power-on sequence) ─────────────────────

    static let reborn1: [[SpriteColor]] = parseSprite("""
S....LL....S
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let reborn2: [[SpriteColor]] = parseSprite("""
.S.S.LL.S.S.
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let reborn3: [[SpriteColor]] = parseSprite("""
S.S.S..S.S.S
.S.S.LL.S.S.
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    // ── Peeking frames (peering up from below) ─────────────────────

    static let peeking1: [[SpriteColor]] = parseSprite("""
............
............
............
............
............
............
............
............
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
""")

    static let peeking2: [[SpriteColor]] = parseSprite("""
............
............
............
............
............
............
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGBBBBBBGD.
.DGCBBBBCGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
""")

    // ── Movement poses ─────────────────────────────────────────────

    /// Falling: antenna LEDs on, legs spread wide
    static let falling1: [[SpriteColor]] = parseSprite("""
.....LL.....
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
..AA....AA..
""")

    /// Squash: compressed flat, spread wide
    static let squash1: [[SpriteColor]] = parseSprite("""
............
............
............
............
............
............
.DDDDDDDDDD.
DGBBCBBCBBGD
DGBBDDDDBGGD
DGGGGGGGGGGD
.DDDDDDDDDD.
............
""")

    /// Lean left: chassis tilted left
    static let leanLeft1: [[SpriteColor]] = parseSprite("""
...DLD......
DDDDDDDDDD..
DGGGGGGGGD..
DGCBBBBCGD..
DGBBBBBBGD..
DGBBDDBBGD..
DGGGGGGGGD..
DDDDDDDDDD..
.AAAAAA.....
AAAAAAAA....
.AA..AA.....
............
""")

    /// Lean right: chassis tilted right
    static let leanRight1: [[SpriteColor]] = parseSprite("""
......DLD...
..DDDDDDDDDD
..DGGGGGGGGD
..DGCBBBBCGD
..DGBBBBBBGD
..DGBBDDBBGD
..DGGGGGGGGD
..DDDDDDDDDD
.....AAAAAA.
....AAAAAAAA
.....AA..AA.
............
""")

    // ── Coding frames (laptop tray slides out from chassis) ──────────

    static let coding1: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAADD
...AA..AA...
............
""")

    static let coding2: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
..DDDDDDDD..
.DDDDDDDDDD.
...DD..DD...
............
""")

    static let coding3: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
.DDDDDDDDDD.
.DGGGGGGGGD.
.DAAAAAAAAD.
............
""")

    static let coding4: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
.DDDDDDDDDD.
.DGLGGGGGGD.
.DAADAAADAD.
............
""")

    static let coding5: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
.DDDDDDDDDD.
.DGGGGGLGGD.
.DADADAADAD.
............
""")

    static let coding6: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
.DDDDDDDDDD.
.DGGGGGGGLD.
.DAADAAADAD.
............
""")

    static let coding7: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
..DDDDDDDD..
.DDDDDDDDDD.
...DD..DD...
............
""")

    static let coding8: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
............
""")

    // ── Debugging frames (magnifier in top corner, found-it sparks) ──

    static let debug1: [[SpriteColor]] = parseSprite("""
.........DD.
....DLD..DGD
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let debug2: [[SpriteColor]] = parseSprite("""
.........DD.
....DLD..DGD
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGBBBBBBGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let debug3: [[SpriteColor]] = parseSprite("""
.........DD.
....DLD..DGD
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let debug4: [[SpriteColor]] = parseSprite("""
.........S..
....DLD...S.
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
""")

    static let debug5: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
..AAAAAAAA..
...AA..AA...
............
""")

    // ── Compiling frames (progress bar below robot) ──────────────────

    static let compile1: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
.DDDDDDDDDD.
.D........D.
............
""")

    static let compile2: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
.DDDDDDDDDD.
.DGG......D.
............
""")

    static let compile3: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
.DDDDDDDDDD.
.DGGGG....D.
............
""")

    static let compile4: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
.DDDDDDDDDD.
.DGGGGGG..D.
............
""")

    static let compile5: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBBDDBBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
.DDDDDDDDDD.
.DGGGGGGGGD.
............
""")

    static let compile6: [[SpriteColor]] = parseSprite("""
....DLD.....
.DDDDDDDDDD.
.DGGGGGGGGD.
.DGCBBBBCGD.
.DGBBBBBBGD.
.DGBDDDDBGD.
.DGGGGGGGGD.
.DDDDDDDDDD.
...AAAAAA...
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
        case .idle:      return 0.8
        case .happy:     return 0.3
        case .tired:     return 1.2
        case .sleeping:  return 1.0
        case .excited:   return 0.2
        case .critical:  return 1.5
        case .reborn:    return 0.25
        case .talking:   return 0.4
        case .peeking:   return 0.7
        case .falling, .squash, .leanLeft, .leanRight: return 0.5
        case .coding:    return 0.3
        case .debugging: return 0.35
        case .compiling: return 0.45
        }
    }
}
