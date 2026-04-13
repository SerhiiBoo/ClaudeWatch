import AppKit

extension NotchPetWindow {

    // MARK: - Keyframe animation engine

    /// Unified keyframe animator: moves the window through a series of (X, Y) positions.
    func animateKeyframes(_ w: NSWindow, keyframes: [(x: CGFloat, y: CGFloat, duration: TimeInterval)]) {
        let myID = animationID
        guard !keyframes.isEmpty else {
            if animationID == myID { finishAnimation(w) }
            return
        }

        var remaining = keyframes
        let target = remaining.removeFirst()
        let startX = w.frame.origin.x
        let startY = w.frame.origin.y
        let deltaX = target.x - startX
        let deltaY = target.y - startY
        let steps = max(1, Int(target.duration / 0.016))  // ~60fps
        var step = 0

        animationTimer?.invalidate()
        // Timer fires on the main thread (scheduled from @MainActor context).
        // MainActor.assumeIsolated lets us check the ID and update state synchronously
        // without spawning a Task — eliminating the work-leak that occurred when stopAll()
        // bumped animationID but queued Tasks still ran before being guarded.
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self, self.animationID == myID else { timer.invalidate(); return }
                step += 1
                let t = min(1.0, Double(step) / Double(steps))
                let eased = self.easeInOut(t)
                let x = startX + deltaX * eased
                let y = startY + deltaY * eased
                w.setFrameOrigin(NSPoint(x: x, y: y))

                if step >= steps {
                    timer.invalidate()
                    self.animateKeyframes(w, keyframes: remaining)
                }
            }
        }
    }

    /// Convenience wrapper: animate through X positions with a fixed Y.
    func animateKeyframes(_ w: NSWindow, keyframes: [(x: CGFloat, duration: TimeInterval)], yFixed: CGFloat) {
        animateKeyframes(w, keyframes: keyframes.map { (x: $0.x, y: yFixed, duration: $0.duration) })
    }

    /// Convenience wrapper: animate through Y positions with a fixed X.
    func animateVerticalKeyframes(_ w: NSWindow, keyframes: [(y: CGFloat, duration: TimeInterval)], xFixed: CGFloat) {
        animateKeyframes(w, keyframes: keyframes.map { (x: xFixed, y: $0.y, duration: $0.duration) })
    }

    // MARK: - Animation helpers

    func finishAnimation(_ w: NSWindow) {
        snapToHome(w)
        restoreMoodAnimation()
        isAnimating = false
        scheduleNextMovement()
    }

    /// Temporarily override the sprite animation during a movement.
    func setPose(_ pose: PetAnimation) {
        petService.animation = pose
    }

    /// Restore the sprite animation to match the current mood.
    func restoreMoodAnimation() {
        petService.animation = petService.animationForMood(petService.mood)
    }

    /// Smooth ease-in-out curve.
    func easeInOut(_ t: Double) -> CGFloat {
        let t2 = t * t
        return CGFloat(t2 / (2.0 * (t2 - t) + 1.0))
    }

    // MARK: - Animation boilerplate helpers

    /// Start a new animation: marks animating, bumps ID, returns the new ID for guard checks.
    @discardableResult
    func beginAnimation() -> Int {
        isAnimating = true
        animationID += 1
        return animationID
    }

    /// Schedule a pose change after a delay, no-op if a newer animation has started.
    func schedulePose(_ pose: PetAnimation, after delay: TimeInterval, animID: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.animationID == animID else { return }
            self.setPose(pose)
        }
    }
}
