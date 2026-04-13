import AppKit

extension NotchPetWindow {

    // MARK: - Universal animations
    //
    // These animations work at any pet position. They move the NSWindow by
    // stepping through positions using a high-frequency timer (~60fps).
    // At the end, the pet returns to homeOrigin and the next movement is scheduled.

    /// Small bounce in place — with squash on landing.
    func animateBounce(_ w: NSWindow) {
        let myID = beginAnimation()
        let baseY = homeOrigin.y
        let bounceHeight: CGFloat = 6

        setPose(.excited)  // anticipation
        // Bounce: up, down, up small, down
        var keyframes: [(y: CGFloat, duration: TimeInterval)] = []
        keyframes.append((y: baseY + bounceHeight, duration: 0.12))
        keyframes.append((y: baseY, duration: 0.12))
        keyframes.append((y: baseY + bounceHeight * 0.5, duration: 0.10))
        keyframes.append((y: baseY, duration: 0.10))

        // Pose sync: squash on each landing
        schedulePose(.squash, after: 0.12, animID: myID)
        schedulePose(.excited, after: 0.20, animID: myID)
        schedulePose(.squash, after: 0.34, animID: myID)

        animateVerticalKeyframes(w, keyframes: keyframes, xFixed: homeOrigin.x)
    }

    /// Wander slightly left/right, then return — lean into the wander.
    func animateWander(_ w: NSWindow) {
        let myID = beginAnimation()
        let drift: CGFloat = CGFloat.random(in: 10...25) * (Bool.random() ? 1 : -1)
        let driftingRight = drift > 0

        // Lean into the drift direction
        setPose(driftingRight ? .leanRight : .leanLeft)
        schedulePose(.idle, after: 0.6, animID: myID)                                           // idle there
        schedulePose(driftingRight ? .leanLeft : .leanRight, after: 1.4, animID: myID)  // lean back

        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []
        keyframes.append((x: homeOrigin.x + drift, duration: 0.6))        // drift
        keyframes.append((x: homeOrigin.x + drift, duration: 0.8))        // idle there
        keyframes.append((x: homeOrigin.x, duration: 0.5))                // drift back

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }

    /// Quick dash away from the notch, then run back — lean into the run.
    func animateDash(_ w: NSWindow) {
        let myID = beginAnimation()
        let position = AppSettings.petPosition
        let dashDistance: CGFloat = CGFloat.random(in: 60...140)

        // Dash away from notch (left positions go left, right go right)
        let isGoingLeft: Bool
        let dashX: CGFloat
        switch position {
        case .leftOfMenuBar, .leftOfNotch:
            dashX = homeOrigin.x - dashDistance
            isGoingLeft = true
        default:
            dashX = homeOrigin.x + dashDistance
            isGoingLeft = false
        }

        // Lean into the dash direction, then lean back for the return
        setPose(isGoingLeft ? .leanLeft : .leanRight)
        schedulePose(.idle, after: 0.6, animID: myID)  // pause
        schedulePose(isGoingLeft ? .leanRight : .leanLeft, after: 1.0, animID: myID)  // run back

        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []
        keyframes.append((x: dashX, duration: 0.6))           // dash out
        keyframes.append((x: dashX, duration: 0.4))           // pause, look around
        keyframes.append((x: homeOrigin.x, duration: 0.7))    // run back home

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }

    /// Run from home side → under the notch → appear on other side → run back.
    /// Only meaningful for notch-adjacent positions.
    func animateRunAcross(_ w: NSWindow) {
        let myID = beginAnimation()
        let petSize = AppSettings.petSize
        let spriteWidth = petSize.spriteSize
        let position = AppSettings.petPosition
        let isOnRight = (position == .rightOfNotch || position == .rightOfMenuBar)

        // Destination: mirror of home position on the other side of the notch
        let otherSideCenterX: CGFloat
        if isOnRight {
            otherSideCenterX = cachedNotchLeft - spriteWidth / 2 - 6
        } else {
            otherSideCenterX = cachedNotchRight + spriteWidth / 2 + 6
        }

        // Build path: home → other side → pause → home
        let halfW = w.frame.width / 2

        // Lean into the run direction, then reverse
        setPose(isOnRight ? .leanLeft : .leanRight)  // running toward other side
        schedulePose(.idle, after: 0.8, animID: myID)  // pause
        schedulePose(isOnRight ? .leanRight : .leanLeft, after: 1.4, animID: myID)  // running back

        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []
        keyframes.append((x: otherSideCenterX - halfW, duration: 0.8))   // run to other side
        keyframes.append((x: otherSideCenterX - halfW, duration: 0.6))   // pause
        keyframes.append((x: homeOrigin.x, duration: 0.8))               // run back

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }

    /// Peek out from behind the notch edge, then slide back.
    /// Only meaningful for notch-adjacent positions.
    func animatePeekFromNotch(_ w: NSWindow) {
        beginAnimation()
        let petSize = AppSettings.petSize
        let spriteWidth = petSize.spriteSize
        let position = AppSettings.petPosition
        let isOnRight = (position == .rightOfNotch)

        // The peek position: sprite is half-hidden behind the notch edge
        let peekX: CGFloat
        if isOnRight {
            peekX = cachedNotchRight - spriteWidth * 0.4
        } else {
            peekX = cachedNotchLeft - spriteWidth * 0.6
        }
        let peekWindowX = peekX - (w.frame.width - spriteWidth) / 2

        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []
        keyframes.append((x: peekWindowX, duration: 0.5))     // slide to peek
        keyframes.append((x: peekWindowX, duration: 1.0))     // hold peek
        keyframes.append((x: homeOrigin.x, duration: 0.4))    // slide back

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }

    /// Scurry towards the notch edge, slide up behind it, hold, peek back, then return home.
    func animateHideUp(_ w: NSWindow) {
        let myID = beginAnimation()
        let spriteHeight = AppSettings.petSize.spriteSize
        let position = AppSettings.petPosition
        let goingRight = (position == .leftOfNotch || position == .leftOfMenuBar)

        // Step 1 X: center the window on the notch so the pet is fully hidden when it goes up
        let notchCenterX = (cachedNotchLeft + cachedNotchRight) / 2
        let notchWindowX = notchCenterX - w.frame.width / 2

        // Step 2 Y: slide up well behind the notch (entire sprite above menu bar bottom)
        let menuBarHeight = (currentScreen?.frame.maxY ?? 0) - cachedMenuBarBottom
        let hideY = homeOrigin.y + spriteHeight + menuBarHeight + 8

        // Pose: lean into the scurry, peeking when it peeks back, lean home
        setPose(goingRight ? .leanRight : .leanLeft)           // scurry toward notch
        schedulePose(.idle, after: 0.60, animID: myID)         // hiding
        schedulePose(.peeking, after: 1.40, animID: myID)      // peek back
        schedulePose(goingRight ? .leanLeft : .leanRight, after: 2.00, animID: myID)  // scurry home

        var keyframes: [(x: CGFloat, y: CGFloat, duration: TimeInterval)] = []
        keyframes.append((x: notchWindowX, y: homeOrigin.y, duration: 0.35))   // scurry to notch edge
        keyframes.append((x: notchWindowX, y: hideY, duration: 0.25))          // slide up behind notch
        keyframes.append((x: notchWindowX, y: hideY, duration: 0.8))           // stay hidden
        keyframes.append((x: notchWindowX, y: hideY - spriteHeight * 0.3, duration: 0.2)) // peek back down
        keyframes.append((x: notchWindowX, y: hideY - spriteHeight * 0.3, duration: 0.4)) // hold peek
        keyframes.append((x: notchWindowX, y: homeOrigin.y, duration: 0.25))   // slide back down
        keyframes.append((x: homeOrigin.x, y: homeOrigin.y, duration: 0.35))   // scurry back home

        animateKeyframes(w, keyframes: keyframes)
    }

    /// Drop lower to peek at what's on screen below — peeking pose while looking.
    func animatePeekDown(_ w: NSWindow) {
        let myID = beginAnimation()
        let peekDistance: CGFloat = CGFloat.random(in: 14...22)

        // Sprite: peeking during the hold, excited on the curious dip
        setPose(.peeking)
        schedulePose(.excited, after: 1.3, animID: myID)   // curious!
        schedulePose(.idle, after: 1.45, animID: myID)     // slide back

        var keyframes: [(y: CGFloat, duration: TimeInterval)] = []
        keyframes.append((y: homeOrigin.y - peekDistance, duration: 0.3))       // drop down to peek
        keyframes.append((y: homeOrigin.y - peekDistance, duration: 1.0))       // hold, looking around
        keyframes.append((y: homeOrigin.y - peekDistance - 3, duration: 0.15))  // tiny extra dip (curious!)
        keyframes.append((y: homeOrigin.y, duration: 0.25))                    // slide back up

        animateVerticalKeyframes(w, keyframes: keyframes, xFixed: homeOrigin.x)
    }

    /// Drop down as if losing grip, then snap back up — with falling/squash poses.
    func animateDropCatch(_ w: NSWindow) {
        let myID = beginAnimation()
        let dropDistance: CGFloat = CGFloat.random(in: 12...20)

        // Sprite: surprised → falling → squash on catch → settle
        setPose(.falling)
        schedulePose(.squash, after: 0.15, animID: myID)    // hit bottom
        schedulePose(.excited, after: 0.23, animID: myID)   // catch! relief
        schedulePose(.idle, after: 0.35, animID: myID)      // settle

        var keyframes: [(y: CGFloat, duration: TimeInterval)] = []
        keyframes.append((y: homeOrigin.y - dropDistance, duration: 0.15))       // drop fast
        keyframes.append((y: homeOrigin.y - dropDistance, duration: 0.08))       // tiny hang
        keyframes.append((y: homeOrigin.y + 3, duration: 0.12))                 // snap back up (overshoot)
        keyframes.append((y: homeOrigin.y, duration: 0.08))                     // settle

        animateVerticalKeyframes(w, keyframes: keyframes, xFixed: homeOrigin.x)
    }

    /// Pendulum swing left and right with diminishing arcs — lean with the swing.
    func animateSwing(_ w: NSWindow) {
        let myID = beginAnimation()
        let amp1: CGFloat = 18
        let amp2: CGFloat = 11
        let amp3: CGFloat = 5

        // Lean matches swing direction
        setPose(.leanRight)  // initial swing right
        schedulePose(.leanLeft, after: 0.25, animID: myID)
        schedulePose(.leanRight, after: 0.75, animID: myID)
        schedulePose(.leanLeft, after: 1.20, animID: myID)
        schedulePose(.idle, after: 1.60, animID: myID)  // settling

        var keyframes: [(x: CGFloat, duration: TimeInterval)] = []
        keyframes.append((x: homeOrigin.x + amp1, duration: 0.25))    // swing right
        keyframes.append((x: homeOrigin.x - amp1, duration: 0.5))     // swing left (full arc)
        keyframes.append((x: homeOrigin.x + amp2, duration: 0.45))    // swing right (smaller)
        keyframes.append((x: homeOrigin.x - amp2, duration: 0.4))     // swing left (smaller)
        keyframes.append((x: homeOrigin.x + amp3, duration: 0.3))     // swing right (tiny)
        keyframes.append((x: homeOrigin.x, duration: 0.25))           // settle to center

        animateKeyframes(w, keyframes: keyframes, yFixed: homeOrigin.y)
    }
}
