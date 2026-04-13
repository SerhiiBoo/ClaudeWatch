import Foundation

// MARK: - Token kind

enum TokenKind {
    case token    // colorful Claude token — catch for +1 point
    case blocker  // red rate-limit block — dodge to avoid losing a life
}

// MARK: - Falling item

struct FallingToken: Identifiable {
    let id: Int
    let kind: TokenKind
    let lane: Int         // 0..<GameConstants.laneCount
    let y: CGFloat        // 0.0 (top) to 1.0 (bottom), normalized
    let colorIndex: Int   // visual variety
    let speed: CGFloat    // normalized units per second
}

extension FallingToken {
    func withY(_ newY: CGFloat) -> FallingToken {
        FallingToken(id: id, kind: kind, lane: lane, y: newY,
                     colorIndex: colorIndex, speed: speed)
    }
}

// MARK: - Game state snapshot
// Fields are `var` to support the `updating(_:)` inout-copy pattern.
// Callers must always bind results to `let` and go through `updating` —
// direct field mutation on a live state value is not permitted by convention.

struct MiniGameState {
    var petLane: Int
    var tokens: [FallingToken]
    var score: Int
    var lives: Int
    var isGameOver: Bool
    var isWaitingToStart: Bool
    var difficulty: Double      // 1.0 baseline → 4.0 max
    var elapsedSeconds: Double
    var nextTokenID: Int
    var catchCount: Int         // incremented on every token catch
    var hitCount: Int           // incremented on every blocker hit

    // MARK: Derived

    var petXNormalized: CGFloat {
        let laneWidth = 1.0 / CGFloat(GameConstants.laneCount)
        return laneWidth * (CGFloat(petLane) + 0.5)
    }

    // MARK: Factory

    static func initial() -> MiniGameState {
        MiniGameState(
            petLane: GameConstants.laneCount / 2,
            tokens: [],
            score: 0,
            lives: GameConstants.initialLives,
            isGameOver: false,
            isWaitingToStart: true,
            difficulty: 1.0,
            elapsedSeconds: 0,
            nextTokenID: 0,
            catchCount: 0,
            hitCount: 0
        )
    }
}

// MARK: - Immutable copy helpers

extension MiniGameState {
    /// Returns a copy of this state with selective field updates applied via a mutating closure.
    func updating(_ block: (inout MiniGameState) -> Void) -> MiniGameState {
        var copy = self
        block(&copy)
        return copy
    }
}

// MARK: - Game constants

enum GameConstants {
    static let gameWidth:  CGFloat = 400
    static let gameHeight: CGFloat = 500
    static let laneCount: Int = 8

    static let petSpritePixelSize: CGFloat = 2.5  // px per grid cell for 12×12 sprites
    static let petSpriteBaseGrid: CGFloat = 12
    static let petSpriteDisplaySize: CGFloat = petSpriteBaseGrid * petSpritePixelSize  // 30
    static let petBaselineY: CGFloat = gameHeight - petSpriteDisplaySize - 18
    static let catchZoneHeight: CGFloat = petSpriteDisplaySize + 6

    static let initialLives: Int = 3
    static let baseTokenSpeed: CGFloat = 0.20     // normalized/sec at difficulty 1.0
    static let baseSpawnInterval: TimeInterval = 1.4
    static let difficultyRampRate: Double = 0.04  // added per second of play
    static let maxDifficulty: Double = 4.0
    static let blockerProbabilityBase: Double = 0.18
    static let blockerProbabilityMax:  Double = 0.50

    static let tokenSize: CGFloat = 12

    // Number of distinct token colours — used by spawn logic to pick a colorIndex.
    // The actual Color values live in MiniGameTheme (view layer).
    static let tokenColorCount: Int = 8
}
