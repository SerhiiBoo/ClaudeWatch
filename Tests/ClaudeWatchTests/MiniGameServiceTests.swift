import XCTest
@testable import ClaudeWatch

final class MiniGameServiceTests: XCTestCase {

    // MARK: - MiniGameState.initial()

    func testInitialStateLaneIsCenterLane() {
        let state = MiniGameState.initial()
        XCTAssertEqual(state.petLane, GameConstants.laneCount / 2)
    }

    func testInitialStateScoreIsZero() {
        let state = MiniGameState.initial()
        XCTAssertEqual(state.score, 0)
    }

    func testInitialStateLivesEqualsInitialLives() {
        let state = MiniGameState.initial()
        XCTAssertEqual(state.lives, GameConstants.initialLives)
    }

    func testInitialStateLivesIsThree() {
        XCTAssertEqual(GameConstants.initialLives, 3)
    }

    func testInitialStateIsWaitingToStart() {
        let state = MiniGameState.initial()
        XCTAssertTrue(state.isWaitingToStart)
    }

    func testInitialStateIsNotGameOver() {
        let state = MiniGameState.initial()
        XCTAssertFalse(state.isGameOver)
    }

    func testInitialStateTokensIsEmpty() {
        let state = MiniGameState.initial()
        XCTAssertTrue(state.tokens.isEmpty)
    }

    func testInitialStateDifficultyIsBaseline() {
        let state = MiniGameState.initial()
        XCTAssertEqual(state.difficulty, 1.0, accuracy: 0.001)
    }

    func testInitialStateElapsedSecondsIsZero() {
        let state = MiniGameState.initial()
        XCTAssertEqual(state.elapsedSeconds, 0, accuracy: 0.001)
    }

    func testInitialStateNextTokenIDIsZero() {
        let state = MiniGameState.initial()
        XCTAssertEqual(state.nextTokenID, 0)
    }

    func testInitialStateCatchCountIsZero() {
        let state = MiniGameState.initial()
        XCTAssertEqual(state.catchCount, 0)
    }

    func testInitialStateHitCountIsZero() {
        let state = MiniGameState.initial()
        XCTAssertEqual(state.hitCount, 0)
    }

    // MARK: - MiniGameState.updating(_:)

    func testUpdatingReturnsCopyNotSameInstance() {
        let original = MiniGameState.initial()
        let updated = original.updating { $0.score = 10 }
        XCTAssertEqual(updated.score, 10)
    }

    func testUpdatingLeavesOriginalUnchanged() {
        let original = MiniGameState.initial()
        _ = original.updating { $0.score = 99 }
        XCTAssertEqual(original.score, 0)
    }

    func testUpdatingOnlyChangesSpecifiedField() {
        let original = MiniGameState.initial()
        let updated = original.updating { $0.score = 7 }
        // All other fields must remain at initial values
        XCTAssertEqual(updated.petLane, original.petLane)
        XCTAssertEqual(updated.lives, original.lives)
        XCTAssertEqual(updated.isGameOver, original.isGameOver)
        XCTAssertEqual(updated.isWaitingToStart, original.isWaitingToStart)
        XCTAssertEqual(updated.difficulty, original.difficulty, accuracy: 0.001)
        XCTAssertEqual(updated.elapsedSeconds, original.elapsedSeconds, accuracy: 0.001)
        XCTAssertEqual(updated.nextTokenID, original.nextTokenID)
        XCTAssertEqual(updated.catchCount, original.catchCount)
        XCTAssertEqual(updated.hitCount, original.hitCount)
    }

    func testUpdatingMultipleFieldsAtOnce() {
        let original = MiniGameState.initial()
        let updated = original.updating {
            $0.score = 5
            $0.lives = 2
            $0.isGameOver = true
        }
        XCTAssertEqual(updated.score, 5)
        XCTAssertEqual(updated.lives, 2)
        XCTAssertTrue(updated.isGameOver)
        // Unchanged fields
        XCTAssertEqual(updated.petLane, original.petLane)
        XCTAssertFalse(original.isGameOver)
    }

    func testUpdatingIsChainable() {
        let state = MiniGameState.initial()
            .updating { $0.score = 3 }
            .updating { $0.lives = 1 }
        XCTAssertEqual(state.score, 3)
        XCTAssertEqual(state.lives, 1)
    }

    func testUpdatingIsWaitingToStartCanBeCleared() {
        let original = MiniGameState.initial()
        XCTAssertTrue(original.isWaitingToStart)
        let started = original.updating { $0.isWaitingToStart = false }
        XCTAssertFalse(started.isWaitingToStart)
        XCTAssertTrue(original.isWaitingToStart)
    }

    // MARK: - FallingToken.withY(_:)

    func testWithYChangesYCoordinate() {
        let token = FallingToken(id: 1, kind: .token, lane: 2, y: 0.0, colorIndex: 3, speed: 0.2)
        let moved = token.withY(0.5)
        XCTAssertEqual(moved.y, 0.5, accuracy: 0.0001)
    }

    func testWithYPreservesID() {
        let token = FallingToken(id: 42, kind: .token, lane: 0, y: 0.0, colorIndex: 0, speed: 0.1)
        let moved = token.withY(0.3)
        XCTAssertEqual(moved.id, 42)
    }

    func testWithYPreservesKind() {
        let token = FallingToken(id: 1, kind: .blocker, lane: 0, y: 0.0, colorIndex: 0, speed: 0.1)
        let moved = token.withY(0.3)
        XCTAssertEqual(moved.kind, .blocker)
    }

    func testWithYPreservesLane() {
        let token = FallingToken(id: 1, kind: .token, lane: 5, y: 0.0, colorIndex: 0, speed: 0.1)
        let moved = token.withY(0.7)
        XCTAssertEqual(moved.lane, 5)
    }

    func testWithYPreservesColorIndex() {
        let token = FallingToken(id: 1, kind: .token, lane: 0, y: 0.0, colorIndex: 7, speed: 0.1)
        let moved = token.withY(0.2)
        XCTAssertEqual(moved.colorIndex, 7)
    }

    func testWithYPreservesSpeed() {
        let token = FallingToken(id: 1, kind: .token, lane: 0, y: 0.0, colorIndex: 0, speed: 0.35)
        let moved = token.withY(0.9)
        XCTAssertEqual(moved.speed, 0.35, accuracy: 0.0001)
    }

    func testWithYLeavesOriginalUnchanged() {
        let token = FallingToken(id: 1, kind: .token, lane: 0, y: 0.0, colorIndex: 0, speed: 0.1)
        _ = token.withY(0.8)
        XCTAssertEqual(token.y, 0.0, accuracy: 0.0001)
    }

    // MARK: - GameConstants difficulty constants

    func testDifficultyRampRate() {
        XCTAssertEqual(GameConstants.difficultyRampRate, 0.04, accuracy: 0.0001)
    }

    func testMaxDifficulty() {
        XCTAssertEqual(GameConstants.maxDifficulty, 4.0, accuracy: 0.0001)
    }

    func testBaselineDifficulty() {
        // Difficulty starts at 1.0 and ramps toward maxDifficulty
        let initial = MiniGameState.initial()
        XCTAssertEqual(initial.difficulty, 1.0, accuracy: 0.001)
        XCTAssertLessThan(initial.difficulty, GameConstants.maxDifficulty)
    }

    func testDifficultyAfterTenSecondsIsWithinBounds() {
        let elapsed = 10.0
        let expected = min(GameConstants.maxDifficulty, 1.0 + elapsed * GameConstants.difficultyRampRate)
        XCTAssertEqual(expected, 1.4, accuracy: 0.001)
        XCTAssertLessThanOrEqual(expected, GameConstants.maxDifficulty)
    }

    func testDifficultyClampedAtMax() {
        // At very long elapsed time, difficulty should be capped at maxDifficulty
        let elapsed = 10_000.0
        let clamped = min(GameConstants.maxDifficulty, 1.0 + elapsed * GameConstants.difficultyRampRate)
        XCTAssertEqual(clamped, GameConstants.maxDifficulty, accuracy: 0.001)
    }

    func testDifficultyRampReachesMaxAfterExpectedSeconds() {
        // 1.0 + elapsed * 0.04 = 4.0  →  elapsed = 75 seconds
        let secondsToMax = (GameConstants.maxDifficulty - 1.0) / GameConstants.difficultyRampRate
        XCTAssertEqual(secondsToMax, 75.0, accuracy: 0.001)
    }

    // MARK: - GameConstants other values

    func testLaneCountIsEight() {
        XCTAssertEqual(GameConstants.laneCount, 8)
    }

    func testBlockerProbabilityBoundsAreOrdered() {
        XCTAssertLessThan(GameConstants.blockerProbabilityBase, GameConstants.blockerProbabilityMax)
    }

    func testBlockerProbabilityMaxDoesNotExceedOne() {
        XCTAssertLessThanOrEqual(GameConstants.blockerProbabilityMax, 1.0)
    }

    // MARK: - petXNormalized derived property

    func testPetXNormalizedForCenterLane() {
        let state = MiniGameState.initial()
        let centerLane = GameConstants.laneCount / 2  // 4
        let laneWidth = 1.0 / CGFloat(GameConstants.laneCount)
        let expected = laneWidth * (CGFloat(centerLane) + 0.5)
        XCTAssertEqual(state.petXNormalized, expected, accuracy: 0.0001)
    }

    func testPetXNormalizedForLaneZero() {
        let state = MiniGameState.initial().updating { $0.petLane = 0 }
        let laneWidth = 1.0 / CGFloat(GameConstants.laneCount)
        let expected = laneWidth * 0.5
        XCTAssertEqual(state.petXNormalized, expected, accuracy: 0.0001)
    }

    func testPetXNormalizedForLastLane() {
        let lastLane = GameConstants.laneCount - 1
        let state = MiniGameState.initial().updating { $0.petLane = lastLane }
        let laneWidth = 1.0 / CGFloat(GameConstants.laneCount)
        let expected = laneWidth * (CGFloat(lastLane) + 0.5)
        XCTAssertEqual(state.petXNormalized, expected, accuracy: 0.0001)
        XCTAssertLessThanOrEqual(state.petXNormalized, 1.0)
    }
}
