import Foundation
import os.log

private let logger = Logger(subsystem: "io.github.SerhiiBoo.ClaudeWatch", category: "MiniGame")

@MainActor
final class MiniGameService: ObservableObject {

    // MARK: - Published

    @Published private(set) var state: MiniGameState = .initial()
    @Published private(set) var highScore: Int = AppSettings.miniGameHighScore
    @Published var rateLimitLifted: Bool = false

    // MARK: - Private

    private var spawnTimer: Timer?
    private var lastTickDate: Date?

    // MARK: - Lifecycle

    func start() {
        lastTickDate = Date()
        state = MiniGameState.initial().updating { $0.isWaitingToStart = false }
        scheduleNextSpawn()
        logger.info("MiniGame started")
    }

    func reset() {
        stopSpawnTimer()
        lastTickDate = nil
        state = .initial()
        highScore = AppSettings.miniGameHighScore
    }

    func stop() {
        stopSpawnTimer()
        lastTickDate = nil
        logger.info("MiniGame stopped")
    }

    // MARK: - Input

    func movePetLeft() {
        guard !state.isGameOver, !state.isWaitingToStart else { return }
        let newLane = max(0, state.petLane - 1)
        if newLane != state.petLane {
            state = state.updating { $0.petLane = newLane }
        }
    }

    func movePetRight() {
        guard !state.isGameOver, !state.isWaitingToStart else { return }
        let newLane = min(GameConstants.laneCount - 1, state.petLane + 1)
        if newLane != state.petLane {
            state = state.updating { $0.petLane = newLane }
        }
    }

    func movePetToNormalizedX(_ x: CGFloat) {
        guard !state.isGameOver, !state.isWaitingToStart else { return }
        let lane = Int(x * CGFloat(GameConstants.laneCount))
            .clamped(to: 0, max: GameConstants.laneCount - 1)
        state = state.updating { $0.petLane = lane }
    }

    // MARK: - Game loop (called every frame by TimelineView)

    func tick(date: Date) {
        guard !state.isGameOver, !state.isWaitingToStart else { return }
        let delta = frameDelta(for: date)
        lastTickDate = date

        let moved   = applyTokenMovement(delta: delta)
        let result  = resolveCollisions(tokens: moved)
        let elapsed = state.elapsedSeconds + delta
        let newDifficulty = advanceDifficulty(elapsed: elapsed)
        let newLives = max(0, result.lives)

        state = state.updating {
            $0.tokens         = result.surviving
            $0.score          = result.score
            $0.lives          = newLives
            $0.isGameOver     = newLives <= 0
            $0.difficulty     = newDifficulty
            $0.elapsedSeconds = elapsed
            if result.didCatch { $0.catchCount += 1 }
            if result.didHit   { $0.hitCount   += 1 }
        }

        if state.isGameOver {
            commitGameOver(finalScore: result.score)
        }
    }

    // MARK: - Tick helpers

    private func frameDelta(for date: Date) -> Double {
        guard let last = lastTickDate else { return 1.0 / 60.0 }
        return min(date.timeIntervalSince(last), 0.05)
    }

    private func applyTokenMovement(delta: Double) -> [FallingToken] {
        state.tokens.map { $0.withY($0.y + $0.speed * CGFloat(delta)) }
    }

    private struct CollisionResult {
        var surviving: [FallingToken]
        var score: Int
        var lives: Int
        var didCatch: Bool
        var didHit: Bool
    }

    private func resolveCollisions(tokens: [FallingToken]) -> CollisionResult {
        var result = CollisionResult(
            surviving: [],
            score: state.score,
            lives: state.lives,
            didCatch: false,
            didHit: false
        )
        let catchThreshold = catchZoneNormalized

        for token in tokens {
            guard token.y <= 1.0 else { continue } // fell off screen — no penalty
            if token.y >= catchThreshold && token.lane == state.petLane {
                switch token.kind {
                case .token:   result.score   += 1; result.didCatch = true
                case .blocker: result.lives   -= 1; result.didHit   = true
                }
                // token consumed on collision — not added to surviving
            } else {
                result.surviving.append(token)
            }
        }
        return result
    }

    private func advanceDifficulty(elapsed: Double) -> Double {
        min(GameConstants.maxDifficulty, 1.0 + elapsed * GameConstants.difficultyRampRate)
    }

    private func commitGameOver(finalScore: Int) {
        stopSpawnTimer()
        if finalScore > highScore {
            highScore = finalScore
            AppSettings.miniGameHighScore = finalScore
            logger.info("New high score: \(finalScore)")
        }
    }

    // MARK: - Spawn (separate timer — decoupled from frame rate)

    private func scheduleNextSpawn() {
        let interval = spawnInterval(for: state.difficulty)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.state.isGameOver, !self.state.isWaitingToStart else { return }
                self.spawnToken()
                self.scheduleNextSpawn()
            }
        }
    }

    private func spawnToken() {
        let blockerProb = min(
            GameConstants.blockerProbabilityMax,
            GameConstants.blockerProbabilityBase + (state.difficulty - 1.0) * 0.08
        )
        let kind: TokenKind = Double.random(in: 0..<1) < blockerProb ? .blocker : .token
        let lane = Int.random(in: 0..<GameConstants.laneCount)
        let speed = GameConstants.baseTokenSpeed * CGFloat(state.difficulty)
            * CGFloat.random(in: 0.85...1.15)

        let token = FallingToken(
            id: state.nextTokenID,
            kind: kind,
            lane: lane,
            y: -0.02,
            colorIndex: Int.random(in: 0..<GameConstants.tokenColorCount),
            speed: speed
        )

        state = state.updating {
            $0.tokens.append(token)
            $0.nextTokenID += 1
        }
    }

    private func spawnInterval(for difficulty: Double) -> TimeInterval {
        let t = (difficulty - 1.0) / (GameConstants.maxDifficulty - 1.0)
        return GameConstants.baseSpawnInterval * (1.0 - t * 0.68)
    }

    private func stopSpawnTimer() {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }

    // MARK: - Rate-limit lifted signal

    func notifyRateLimitLifted() {
        guard !state.isGameOver else { return }
        rateLimitLifted = true
    }

    func acknowledgeRateLimitLifted() {
        rateLimitLifted = false
    }

    // MARK: - Private helpers

    private var catchZoneNormalized: CGFloat {
        let catchTop = GameConstants.petBaselineY - GameConstants.catchZoneHeight
        return catchTop / GameConstants.gameHeight
    }
}

private extension Int {
    func clamped(to min: Int, max: Int) -> Int {
        Swift.max(min, Swift.min(max, self))
    }
}
