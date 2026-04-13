import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: "io.github.SerhiiBoo.ClaudeWatch", category: "NotchPet")

// MARK: - Tuning constants

private enum PetTuning {
    /// Remaining-token jump that triggers a session-reset detection.
    static let resetDetectionThreshold: Double = 20
    /// How long (seconds) the "reborn" mood persists after a reset is detected.
    static let rebornWindowDuration: TimeInterval = 8
    /// Minimum seconds a speech bubble stays visible regardless of phrase length.
    static let bubbleMinDisplayTime: TimeInterval = 3.0
    /// Additional seconds of display time per character in the phrase (read-speed heuristic).
    static let bubbleSecondsPerCharacter: Double = 0.06
    /// Random interval between ambient one-shot animations (coding/debugging/compiling).
    static let ambientAnimationIntervalRange: ClosedRange<TimeInterval> = 45...120
}

// MARK: - Notification for pet events

extension Notification.Name {
    static let petMoodDidChange = Notification.Name("io.github.SerhiiBoo.ClaudeWatch.petMoodDidChange")
}

/// Central service that drives pet mood, animation, and speech.
/// Observes UsageViewModel and maps session state into pet behavior.
@MainActor
final class NotchPetService: ObservableObject {

    // MARK: - Published state

    @Published var mood: PetMood = .happy
    @Published var animation: PetAnimation = .idle
    @Published var currentPhrase: String? = nil
    @Published var showSpeechBubble = false
    @Published var character: PetCharacter = AppSettings.petCharacter
    @Published var variant: PetVariant = AppSettings.petVariant
    @Published var isEnabled: Bool {
        didSet {
            AppSettings.petEnabled = isEnabled
            // Only start/stop after attach() has wired up the viewModel
            guard viewModel != nil else { return }
            isEnabled ? start() : stop()
        }
    }

    // MARK: - Private

    private var phraseTimer: Timer?
    private var bubbleDismissTask: Task<Void, Never>?
    /// Monotonically-increasing ID for speech bubble sessions.
    /// The delayed restore Task checks this before wiping the pose, so a concurrent
    /// movement-driven `setPose()` from `NotchPetWindow` is never overwritten.
    private var speechAnimationID = 0
    private var idleAnimationTimer: Timer?
    private var idleAnimationReturnTask: Task<Void, Never>?
    /// Monotonically-increasing ID for ambient one-shot animation sessions.
    private var ambientAnimationID = 0
    private static let ambientAnimations: [PetAnimation] = [.coding, .debugging, .compiling]
    /// Total duration for each ambient animation (frame count × per-frame duration from VariantSpriteData).
    private static let ambientAnimationDurations: [PetAnimation: TimeInterval] = [
        .coding:    8 * 0.30,   // 2.4 s
        .debugging: 6 * 0.35,   // 2.1 s
        .compiling: 6 * 0.45    // 2.7 s
    ]
    private var usageSubscription: AnyCancellable?
    private var characterObserver: Any?
    private var previousSessionRemaining: Double?
    private var resetDetectedAt: Date?
    private var lastPacePressure: PacePressure = .unknown
    private weak var viewModel: UsageViewModel?

    // MARK: - Init

    init() {
        _isEnabled = Published(wrappedValue: AppSettings.petEnabled)
        // Listen for character/variant changes from settings
        characterObserver = NotificationCenter.default.addObserver(
            forName: .petCharacterDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCharacter()
            }
        }
    }

    /// Update published character/variant from AppSettings.
    func refreshCharacter() {
        character = AppSettings.petCharacter
        variant = AppSettings.petVariant
    }

    // MARK: - Lifecycle

    func attach(to viewModel: UsageViewModel) {
        guard self.viewModel == nil else {
            assertionFailure("NotchPetService.attach(to:) called more than once")
            return
        }
        self.viewModel = viewModel

        // Subscribe to usage updates
        usageSubscription = viewModel.$usage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] usage in
                guard let self else { return }
                self.updateMood(from: usage, isRateLimited: viewModel.rateLimitedUntil != nil)
            }

        if isEnabled { start() }
    }

    func start() {
        guard isEnabled else { return }
        schedulePhraseTimer()
        scheduleIdleAnimationTimer()
        logger.info("NotchPet started")
    }

    func stop() {
        phraseTimer?.invalidate()
        phraseTimer = nil
        bubbleDismissTask?.cancel()
        idleAnimationTimer?.invalidate()
        idleAnimationTimer = nil
        idleAnimationReturnTask?.cancel()
        idleAnimationReturnTask = nil
        if let o = characterObserver { NotificationCenter.default.removeObserver(o) }
        characterObserver = nil
        currentPhrase = nil
        showSpeechBubble = false
        logger.info("NotchPet stopped")
    }

    // MARK: - Mood engine

    private func updateMood(from usage: UsageData?, isRateLimited: Bool) {
        guard isEnabled else { return }
        guard let usage else { return }

        let remaining = usage.sessionRemaining

        // Detect session reset: remaining jumped up significantly
        let justReset: Bool
        if let prev = previousSessionRemaining, remaining > prev + PetTuning.resetDetectionThreshold {
            justReset = true
            resetDetectedAt = Date()
            logger.info("Session reset detected: \(prev, privacy: .public) -> \(remaining, privacy: .public)")
        } else if let resetAt = resetDetectedAt, Date().timeIntervalSince(resetAt) < PetTuning.rebornWindowDuration {
            justReset = true  // Keep reborn mood for a few seconds
        } else {
            justReset = false
        }

        previousSessionRemaining = remaining

        let paceStatus = PaceClassifier.classify(
            pace: UsageHistoryService.sessionPacePerHour() ?? 0,
            etaHours: UsageHistoryService.estimatedHoursUntilSessionEmpty(currentRemaining: remaining)
        )
        lastPacePressure = paceStatus.pressure

        let newMood = PetMood.from(
            sessionRemaining: remaining,
            pacePressure: paceStatus.pressure,
            isRateLimited: isRateLimited,
            justReset: justReset
        )

        if newMood != mood {
            let oldMood = mood
            mood = newMood
            animation = animationForMood(newMood)
            showMoodPhrase(for: newMood)
            NotificationCenter.default.post(name: .petMoodDidChange, object: nil)
            logger.info("Pet mood: \(oldMood.rawValue) -> \(newMood.rawValue)")

            if oldMood == .sleeping && newMood != .sleeping {
                NotificationCenter.default.post(name: .petDidLeaveSleep, object: nil)
            }
        }
    }

    func animationForMood(_ mood: PetMood) -> PetAnimation {
        switch mood {
        case .ecstatic:  return .excited
        case .happy:     return .happy
        case .normal:    return .idle
        case .tired:     return .tired
        case .exhausted: return .tired
        case .critical:  return .critical
        case .sleeping:  return .sleeping
        case .reborn:    return .reborn
        }
    }

    // MARK: - Phrase system

    private func schedulePhraseTimer() {
        phraseTimer?.invalidate()
        let chattiness = AppSettings.petChattiness
        var interval = TimeInterval.random(in: chattiness.intervalRange)
        if lastPacePressure == .urgent {
            interval = max(interval / 2, chattiness.intervalRange.lowerBound)
        }
        phraseTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isEnabled else { return }
                self.showRandomPhrase()
                guard self.isEnabled else { return }  // re-check after async hop
                self.schedulePhraseTimer()
            }
        }
    }

    private func showMoodPhrase(for mood: PetMood) {
        let character = AppSettings.petCharacter
        let phrase = PetPhrases.moodPhrase(for: mood, character: character)
        displayPhrase(phrase)
    }

    func showRandomPhrase() {
        let character = AppSettings.petCharacter
        let wellnessEnabled = AppSettings.petWellnessReminders
        let phrase: String

        // Urgent pace: always show a pace warning
        if lastPacePressure == .urgent {
            phrase = PetPhrases.pacePhrase(for: .urgent)
                ?? PetPhrases.moodPhrase(for: mood, character: character)
        } else {
            let roll = Double.random(in: 0..<1)
            if roll < 0.20 {
                phrase = PetPhrases.moodPhrase(for: mood, character: character)
            } else if roll < 0.50, let pPhrase = PetPhrases.pacePhrase(for: lastPacePressure) {
                phrase = pPhrase
            } else {
                phrase = PetPhrases.randomAmbientPhrase(character: character, wellnessEnabled: wellnessEnabled)
            }
        }
        displayPhrase(phrase)
    }

    private func displayPhrase(_ phrase: String) {
        guard isEnabled else { return }
        bubbleDismissTask?.cancel()
        speechAnimationID += 1
        let myID = speechAnimationID

        currentPhrase = phrase
        showSpeechBubble = true
        animation = .talking

        // Dismiss bubble after a duration proportional to phrase length.
        // Guard against `myID` so a concurrent movement-driven setPose() from
        // NotchPetWindow isn't overwritten after the window has already changed the pose.
        let readTime = max(PetTuning.bubbleMinDisplayTime, Double(phrase.count) * PetTuning.bubbleSecondsPerCharacter)
        bubbleDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(readTime))
            guard let self, !Task.isCancelled, self.isEnabled,
                  self.speechAnimationID == myID else { return }
            self.showSpeechBubble = false
            self.currentPhrase = nil
            self.animation = self.animationForMood(self.mood)
        }
    }

    /// Manually trigger a phrase (e.g. when user clicks the pet).
    func poke() {
        guard isEnabled else { return }
        // When poked, show a random phrase immediately
        showRandomPhrase()
    }

    deinit {
        phraseTimer?.invalidate()
        bubbleDismissTask?.cancel()
        idleAnimationTimer?.invalidate()
        idleAnimationReturnTask?.cancel()
    }

    // MARK: - Ambient animation system

    /// Directly fires an ambient one-shot animation, bypassing the calm-mood guard.
    /// Use for programmatic triggers (e.g. preview mode buttons).
    func triggerAmbientAnimation(_ animation: PetAnimation) {
        idleAnimationReturnTask?.cancel()
        ambientAnimationID += 1
        let myID = ambientAnimationID
        self.animation = animation
        guard let totalDuration = NotchPetService.ambientAnimationDurations[animation] else { return }
        idleAnimationReturnTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(totalDuration))
            guard let self, !Task.isCancelled, self.ambientAnimationID == myID else { return }
            self.animation = self.animationForMood(self.mood)
        }
    }

    private func scheduleIdleAnimationTimer() {
        idleAnimationTimer?.invalidate()
        let interval = TimeInterval.random(in: PetTuning.ambientAnimationIntervalRange)
        idleAnimationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isEnabled else { return }
                self.fireIdleAnimation()
                self.scheduleIdleAnimationTimer()
            }
        }
    }

    private func fireIdleAnimation() {
        // Only play when calm (not talking, not in a stressed/special mood)
        guard !showSpeechBubble,
              mood == .normal || mood == .happy || mood == .ecstatic else { return }

        guard let chosen = NotchPetService.ambientAnimations.randomElement() else { return }
        let totalDuration = NotchPetService.ambientAnimationDurations[chosen] ?? {
            logger.error("Missing ambient duration for .\(chosen.rawValue) — pet may be stuck; defaulting to 2.4 s")
            return 2.4
        }()

        // Cancel previous return-task before bumping the ID, mirroring the displayPhrase pattern.
        idleAnimationReturnTask?.cancel()
        ambientAnimationID += 1
        let myID = ambientAnimationID

        animation = chosen

        idleAnimationReturnTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(totalDuration))
            guard let self, !Task.isCancelled, self.isEnabled,
                  self.ambientAnimationID == myID else { return }
            self.animation = self.animationForMood(self.mood)
        }
    }
}
