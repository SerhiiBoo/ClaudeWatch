import AppKit

extension NotchPetWindow {

    // MARK: - Character-specific animations
    //
    // Each animation targets a particular character's physics or personality.
    // They all move the NSWindow by stepping through positions using a
    // high-frequency timer (~60fps).

    // MARK: Clodey

    /// Clodey: jelly-like horizontal wobble (blob physics) — lean with each wobble.
    func animateWobble(_ w: NSWindow) {
        let myID = beginAnimation()
        let amp1: CGFloat = 8
        let amp2: CGFloat = 5
        let amp3: CGFloat = 2

        // Lean alternates with wobble
        setPose(.leanRight)
        schedulePose(.leanLeft, after: 0.08, animID: myID)
        schedulePose(.leanRight, after: 0.24, animID: myID)
        schedulePose(.leanLeft, after: 0.38, animID: myID)
        schedulePose(.idle, after: 0.50, animID: myID)

        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []
        keyframes.append((x: homeOrigin.x + amp1, duration: 0.08))
        keyframes.append((x: homeOrigin.x - amp1, duration: 0.16))
        keyframes.append((x: homeOrigin.x + amp2, duration: 0.14))
        keyframes.append((x: homeOrigin.x - amp2, duration: 0.12))
        keyframes.append((x: homeOrigin.x + amp3, duration: 0.10))
        keyframes.append((x: homeOrigin.x - amp3, duration: 0.08))
        keyframes.append((x: homeOrigin.x, duration: 0.06))

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }

    /// Clodey: vertical squash & stretch — blob bounces up and overshoots.
    func animateStretch(_ w: NSWindow) {
        let myID = beginAnimation()
        let stretchUp: CGFloat = 10
        let squashDown: CGFloat = 3

        // Squash down, stretch up, squash on landing
        setPose(.squash)
        schedulePose(.excited, after: 0.08, animID: myID)   // stretching up
        schedulePose(.squash, after: 0.29, animID: myID)    // squash on land
        schedulePose(.idle, after: 0.41, animID: myID)

        var keyframes: [(y: CGFloat, duration: TimeInterval)] = []
        keyframes.append((y: homeOrigin.y - squashDown, duration: 0.08))      // squash down
        keyframes.append((y: homeOrigin.y + stretchUp, duration: 0.15))       // stretch up
        keyframes.append((y: homeOrigin.y + stretchUp + 4, duration: 0.06))   // overshoot
        keyframes.append((y: homeOrigin.y - squashDown * 0.5, duration: 0.12))// squash on landing
        keyframes.append((y: homeOrigin.y + 3, duration: 0.08))               // small bounce
        keyframes.append((y: homeOrigin.y, duration: 0.06))                   // settle

        animateVerticalKeyframes(w, keyframes: keyframes, xFixed: homeOrigin.x)
    }

    // MARK: Bytie

    /// Bytie: rapid jittery horizontal shake, like a screen glitch.
    func animateGlitch(_ w: NSWindow) {
        beginAnimation()
        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []

        // 6 rapid random jitters
        for _ in 0..<6 {
            let offset = CGFloat.random(in: -6...6)
            keyframes.append((x: homeOrigin.x + offset, duration: 0.04))
        }
        // Hold shifted briefly
        keyframes.append((x: homeOrigin.x + 4, duration: 0.15))
        // Snap back to normal
        keyframes.append((x: homeOrigin.x, duration: 0.03))

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }

    /// Bytie: smooth slow horizontal sweep, like a scanning beam — lean into scan.
    func animateScan(_ w: NSWindow) {
        let myID = beginAnimation()
        let scanRange: CGFloat = 40

        // Lean follows the scan direction
        setPose(.leanLeft)     // sweeping left
        schedulePose(.leanRight, after: 0.8, animID: myID)   // sweeping right
        schedulePose(.idle, after: 2.4, animID: myID)        // returning

        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []
        keyframes.append((x: homeOrigin.x - scanRange, duration: 0.8))    // sweep left
        keyframes.append((x: homeOrigin.x + scanRange, duration: 1.6))    // sweep right (full range)
        keyframes.append((x: homeOrigin.x, duration: 0.8))                // return to center

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }

    // MARK: Sprout

    /// Sprout: gentle sinusoidal sway, like swaying in the wind — lean with it.
    func animateSway(_ w: NSWindow) {
        let myID = beginAnimation()
        let amp: CGFloat = 6

        // Lean follows the sway
        setPose(.leanRight)
        schedulePose(.leanLeft, after: 0.5, animID: myID)
        schedulePose(.leanRight, after: 1.5, animID: myID)
        schedulePose(.leanLeft, after: 2.4, animID: myID)
        schedulePose(.idle, after: 3.2, animID: myID)

        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []
        // Slow, smooth oscillation — 3 gentle cycles
        keyframes.append((x: homeOrigin.x + amp, duration: 0.5))
        keyframes.append((x: homeOrigin.x - amp, duration: 1.0))
        keyframes.append((x: homeOrigin.x + amp * 0.7, duration: 0.9))
        keyframes.append((x: homeOrigin.x - amp * 0.7, duration: 0.8))
        keyframes.append((x: homeOrigin.x + amp * 0.3, duration: 0.6))
        keyframes.append((x: homeOrigin.x, duration: 0.4))

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }

    /// Sprout: brief upward growth spurt, holds tall, then settles.
    func animateGrow(_ w: NSWindow) {
        let myID = beginAnimation()
        let growHeight: CGFloat = 14

        // Pose: excited during growth, happy at peak, squash on settle
        setPose(.excited)
        schedulePose(.happy, after: 0.45, animID: myID)    // at peak
        schedulePose(.squash, after: 1.15, animID: myID)   // settling
        schedulePose(.idle, after: 1.35, animID: myID)

        var keyframes: [(y: CGFloat, duration: TimeInterval)] = []
        keyframes.append((y: homeOrigin.y + growHeight * 0.3, duration: 0.15))   // start growing
        keyframes.append((y: homeOrigin.y + growHeight, duration: 0.3))          // full growth
        keyframes.append((y: homeOrigin.y + growHeight + 2, duration: 0.1))      // tiny extra pop
        keyframes.append((y: homeOrigin.y + growHeight, duration: 0.6))          // hold tall (show off)
        keyframes.append((y: homeOrigin.y, duration: 0.4))                       // settle back

        animateVerticalKeyframes(w, keyframes: keyframes, xFixed: homeOrigin.x)
    }

    // MARK: Ghosty

    /// Ghosty: fade out by sliding off-screen briefly, reappear offset.
    func animatePhase(_ w: NSWindow) {
        beginAnimation()
        let phaseOffset: CGFloat = CGFloat.random(in: 20...40) * (Bool.random() ? 1 : -1)

        // Phase: drift to offset, "teleport" by fast jump, hold, return
        var keyframes: [(x: CGFloat, y: CGFloat, duration: TimeInterval)] = []
        // Drift up slightly (becoming ethereal)
        keyframes.append((x: homeOrigin.x, y: homeOrigin.y + 8, duration: 0.3))
        // Quick "phase" to new position
        keyframes.append((x: homeOrigin.x + phaseOffset, y: homeOrigin.y + 4, duration: 0.05))
        // Settle at new position
        keyframes.append((x: homeOrigin.x + phaseOffset, y: homeOrigin.y, duration: 0.2))
        // Hold (looking around)
        keyframes.append((x: homeOrigin.x + phaseOffset, y: homeOrigin.y, duration: 0.5))
        // Phase back
        keyframes.append((x: homeOrigin.x + phaseOffset, y: homeOrigin.y + 8, duration: 0.2))
        keyframes.append((x: homeOrigin.x, y: homeOrigin.y + 4, duration: 0.05))
        keyframes.append((x: homeOrigin.x, y: homeOrigin.y, duration: 0.2))

        animateKeyframes(w, keyframes: keyframes)
    }

    /// Ghosty: quick lunge toward the screen center, then retreat (spooky!).
    func animateSpook(_ w: NSWindow) {
        let myID = beginAnimation()
        let lungeDistance: CGFloat = 30
        let position = AppSettings.petPosition

        // Lunge toward center of screen (away from notch edge)
        let isGoingLeft: Bool
        let lungeX: CGFloat
        switch position {
        case .leftOfMenuBar, .leftOfNotch:
            lungeX = homeOrigin.x - lungeDistance
            isGoingLeft = true
        default:
            lungeX = homeOrigin.x + lungeDistance
            isGoingLeft = false
        }
        let lungeDown: CGFloat = 12

        // Pose: lean into lunge, then happy on retreat
        setPose(isGoingLeft ? .leanLeft : .leanRight)
        schedulePose(.excited, after: 0.1, animID: myID)   // BOO!
        schedulePose(.happy, after: 0.4, animID: myID)     // retreat satisfied

        var keyframes: [(x: CGFloat, y: CGFloat, duration: TimeInterval)] = []
        // Quick lunge forward and down
        keyframes.append((x: lungeX, y: homeOrigin.y - lungeDown, duration: 0.1))
        // Hold (BOO!)
        keyframes.append((x: lungeX, y: homeOrigin.y - lungeDown, duration: 0.3))
        // Retreat slowly (satisfied)
        keyframes.append((x: homeOrigin.x, y: homeOrigin.y, duration: 0.5))

        animateKeyframes(w, keyframes: keyframes)
    }
}
