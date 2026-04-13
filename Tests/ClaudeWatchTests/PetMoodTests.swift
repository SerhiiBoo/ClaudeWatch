import XCTest
@testable import ClaudeWatch

final class PetMoodTests: XCTestCase {

    // MARK: - PetMood.from — rate-limited and reset override

    func testRateLimitedReturnsSleeping() {
        let mood = PetMood.from(sessionRemaining: 80, isRateLimited: true, justReset: false)
        XCTAssertEqual(mood, .sleeping)
    }

    func testJustResetTakesPriorityOverRateLimit() {
        // justReset is checked before isRateLimited in the implementation
        let mood = PetMood.from(sessionRemaining: 80, isRateLimited: true, justReset: true)
        XCTAssertEqual(mood, .reborn)
    }

    func testJustResetReturnReborn() {
        let mood = PetMood.from(sessionRemaining: 50, isRateLimited: false, justReset: true)
        XCTAssertEqual(mood, .reborn)
    }

    // MARK: - PetMood.from — base mood thresholds (no pressure, not limited)

    func testSessionAt100OrAboveReturnsEcstatic() {
        XCTAssertEqual(moodFor(remaining: 100), .ecstatic)
    }

    func testSessionAbove100ReturnsEcstatic() {
        XCTAssertEqual(moodFor(remaining: 150), .ecstatic)
    }

    func testSessionAt99ReturnsHappy() {
        XCTAssertEqual(moodFor(remaining: 99), .happy)
    }

    func testSessionAt80ReturnsHappy() {
        XCTAssertEqual(moodFor(remaining: 80), .happy)
    }

    func testSessionAt79ReturnsNormal() {
        XCTAssertEqual(moodFor(remaining: 79), .normal)
    }

    func testSessionAt50ReturnsNormal() {
        XCTAssertEqual(moodFor(remaining: 50), .normal)
    }

    func testSessionAt49ReturnsTired() {
        XCTAssertEqual(moodFor(remaining: 49), .tired)
    }

    func testSessionAt25ReturnsTired() {
        XCTAssertEqual(moodFor(remaining: 25), .tired)
    }

    func testSessionAt24ReturnsExhausted() {
        XCTAssertEqual(moodFor(remaining: 24), .exhausted)
    }

    func testSessionAt10ReturnsExhausted() {
        XCTAssertEqual(moodFor(remaining: 10), .exhausted)
    }

    func testSessionAt9ReturnsCritical() {
        XCTAssertEqual(moodFor(remaining: 9), .critical)
    }

    func testSessionAt0ReturnsCritical() {
        XCTAssertEqual(moodFor(remaining: 0), .critical)
    }

    // MARK: - PetMood.from — pace pressure overlay

    func testUrgentPressureUpgradesHappyToTired() {
        let mood = PetMood.from(
            sessionRemaining: 90,
            pacePressure: .urgent,
            isRateLimited: false,
            justReset: false
        )
        XCTAssertEqual(mood, .tired)
    }

    func testUrgentPressureUpgradesNormalToTired() {
        let mood = PetMood.from(
            sessionRemaining: 60,
            pacePressure: .urgent,
            isRateLimited: false,
            justReset: false
        )
        XCTAssertEqual(mood, .tired)
    }

    func testUrgentPressureDoesNotUpgradeTiredFurther() {
        let mood = PetMood.from(
            sessionRemaining: 30,
            pacePressure: .urgent,
            isRateLimited: false,
            justReset: false
        )
        XCTAssertEqual(mood, .tired)
    }

    func testUrgentPressureDoesNotUpgradeCritical() {
        let mood = PetMood.from(
            sessionRemaining: 5,
            pacePressure: .urgent,
            isRateLimited: false,
            justReset: false
        )
        XCTAssertEqual(mood, .critical)
    }

    func testUrgentPressureDoesNotUpgradeEcstatic() {
        // ecstatic is not .normal or .happy, so the overlay must not apply
        let mood = PetMood.from(
            sessionRemaining: 100,
            pacePressure: .urgent,
            isRateLimited: false,
            justReset: false
        )
        XCTAssertEqual(mood, .ecstatic)
    }

    func testComfortablePressureDoesNotChangeMood() {
        let mood = PetMood.from(
            sessionRemaining: 90,
            pacePressure: .comfortable,
            isRateLimited: false,
            justReset: false
        )
        XCTAssertEqual(mood, .happy)
    }

    func testUnknownPressureDoesNotChangeMood() {
        let mood = PetMood.from(
            sessionRemaining: 60,
            pacePressure: .unknown,
            isRateLimited: false,
            justReset: false
        )
        XCTAssertEqual(mood, .normal)
    }

    // MARK: - PetMood enum — all cases exist

    func testAllCasesExist() {
        let expected: Set<PetMood> = [
            .ecstatic, .happy, .normal, .tired,
            .exhausted, .critical, .sleeping, .reborn
        ]
        let actual = Set(PetMood.allCases)
        XCTAssertEqual(actual, expected)
    }

    func testCaseCountIsEight() {
        XCTAssertEqual(PetMood.allCases.count, 8)
    }

    // MARK: - PetMood.tintColor — non-nil for each case

    func testTintColorIsDefinedForEveryMood() {
        for mood in PetMood.allCases {
            // Color is a struct, always non-nil; just ensure the switch is exhaustive
            // by exercising every case and confirming no crash.
            _ = mood.tintColor
        }
    }

    // MARK: - PetMood.statusLabel — non-empty for each case

    func testStatusLabelIsNonEmptyForEveryMood() {
        for mood in PetMood.allCases {
            let label = mood.statusLabel(for: .clodey)
            XCTAssertFalse(label.isEmpty, "statusLabel for .\(mood) should not be empty")
        }
    }

    func testStatusLabelIncludesCharacterName() {
        for character in PetCharacter.allCases {
            let label = PetMood.happy.statusLabel(for: character)
            XCTAssertTrue(
                label.contains(character.displayName),
                "statusLabel should include '\(character.displayName)'"
            )
        }
    }

    // MARK: - NotchPetService.animationForMood — exhaustive mapping

    @MainActor
    func testAnimationForMoodIsDefinedForEveryMood() {
        let service = NotchPetService()
        for mood in PetMood.allCases {
            let animation = service.animationForMood(mood)
            // Just confirm every mood maps to a valid (non-crashing) PetAnimation value.
            _ = animation
        }
    }

    @MainActor
    func testAnimationForMoodEcstaticIsExcited() {
        let service = NotchPetService()
        XCTAssertEqual(service.animationForMood(.ecstatic), .excited)
    }

    @MainActor
    func testAnimationForMoodHappyIsHappy() {
        let service = NotchPetService()
        XCTAssertEqual(service.animationForMood(.happy), .happy)
    }

    @MainActor
    func testAnimationForMoodNormalIsIdle() {
        let service = NotchPetService()
        XCTAssertEqual(service.animationForMood(.normal), .idle)
    }

    @MainActor
    func testAnimationForMoodTiredIsTired() {
        let service = NotchPetService()
        XCTAssertEqual(service.animationForMood(.tired), .tired)
    }

    @MainActor
    func testAnimationForMoodExhaustedIsTired() {
        let service = NotchPetService()
        XCTAssertEqual(service.animationForMood(.exhausted), .tired)
    }

    @MainActor
    func testAnimationForMoodCriticalIsCritical() {
        let service = NotchPetService()
        XCTAssertEqual(service.animationForMood(.critical), .critical)
    }

    @MainActor
    func testAnimationForMoodSleepingIsSleeping() {
        let service = NotchPetService()
        XCTAssertEqual(service.animationForMood(.sleeping), .sleeping)
    }

    @MainActor
    func testAnimationForMoodRebornIsReborn() {
        let service = NotchPetService()
        XCTAssertEqual(service.animationForMood(.reborn), .reborn)
    }

    // MARK: - PetPhrases static lookups

    func testMoodPhrasePhrasePoolsAreNonEmpty() {
        for mood in PetMood.allCases {
            let phrase = PetPhrases.moodPhrase(for: mood, character: .clodey)
            XCTAssertFalse(phrase.isEmpty, "moodPhrase for .\(mood) should not be empty")
        }
    }

    func testPacePhraseReturnsNilForUnknown() {
        XCTAssertNil(PetPhrases.pacePhrase(for: .unknown))
    }

    func testPacePhraseReturnsNonNilForBeyondWindow() {
        XCTAssertNotNil(PetPhrases.pacePhrase(for: .beyondWindow))
    }

    func testPacePhraseReturnsNonNilForComfortable() {
        XCTAssertNotNil(PetPhrases.pacePhrase(for: .comfortable))
    }

    func testPacePhraseReturnsNonNilForWatch() {
        XCTAssertNotNil(PetPhrases.pacePhrase(for: .watch))
    }

    func testPacePhraseReturnsNonNilForUrgent() {
        XCTAssertNotNil(PetPhrases.pacePhrase(for: .urgent))
    }

    func testPacePhraseForUrgentIsNonEmpty() {
        let phrase = PetPhrases.pacePhrase(for: .urgent)
        XCTAssertFalse(phrase?.isEmpty ?? true)
    }

    func testPersonalityPhrasesAreNonEmptyForAllCharacters() {
        for character in PetCharacter.allCases {
            let phrases = PetPhrases.personalityPhrases(for: character)
            XCTAssertFalse(
                phrases.isEmpty,
                "personalityPhrases for .\(character) should not be empty"
            )
        }
    }

    // MARK: - Helpers

    private func moodFor(remaining: Double) -> PetMood {
        PetMood.from(
            sessionRemaining: remaining,
            pacePressure: .unknown,
            isRateLimited: false,
            justReset: false
        )
    }
}
