import AppKit
import SwiftUI
import Combine

// MARK: - Tuning constants

private enum PetWindowTuning {
    /// Width and height of the transparent host window (must fit sprite + speech bubble).
    static let contentWidth:  CGFloat = 270
    static let contentHeight: CGFloat = 130
    /// Random interval range (seconds) between autonomous pet movement animations.
    static let movementIntervalRange: ClosedRange<TimeInterval> = 30...90
    /// Half-width (points) of the fallback notch region on screens without a physical notch.
    static let notchFallbackHalfWidth: CGFloat = 50
}

/// Manages a transparent, always-on-top window that hosts the pet near the Mac notch.
/// Drives fun position animations: running under the notch, peeking, bouncing, wandering.
@MainActor
final class NotchPetWindow {

    var window: NSWindow?
    let petService: NotchPetService
    nonisolated(unsafe) let observers = ObserverStore()
    var mouseMonitor: Any?
    var movementTimer: Timer?
    var animationTimer: Timer?

    private var lastScreenCheckDate: Date = .distantPast

    /// The screen the pet is currently displayed on.
    var currentScreen: NSScreen?

    /// Cached geometry for the current screen.
    var homeOrigin: NSPoint = .zero
    var cachedNotchLeft: CGFloat = 0
    var cachedNotchRight: CGFloat = 0
    var cachedMenuBarBottom: CGFloat = 0
    var cachedScreenMinX: CGFloat = 0
    var cachedScreenMaxX: CGFloat = 0
    var screenHasNotch = false

    /// True while a movement animation is playing (don't interrupt).
    var isAnimating = false

    /// Incremented each time a new animation starts or is stopped.
    /// asyncAfter pose callbacks capture this value and no-op if it no longer matches.
    var animationID = 0

    init(petService: NotchPetService) {
        self.petService = petService
    }

    // MARK: - Show / Hide

    func show() {
        if let w = window {
            w.orderFront(nil)
            recomputeGeometry()
            snapToHome(w)
            return
        }

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0,
                                width: PetWindowTuning.contentWidth,
                                height: PetWindowTuning.contentHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = .statusBar
        w.applyFloatingWindowDefaults()
        w.collectionBehavior.formUnion([.stationary, .ignoresCycle])
        w.ignoresMouseEvents = true
        w.isMovableByWindowBackground = false

        let hostingView = NSHostingView(
            rootView: NotchPetOverlayView(petService: petService)
        )
        hostingView.frame = NSRect(x: 0, y: 0,
                                   width: PetWindowTuning.contentWidth,
                                   height: PetWindowTuning.contentHeight)
        w.contentView = hostingView

        recomputeGeometry()
        snapToHome(w)
        w.orderFront(nil)
        window = w

        // Reposition when screens change
        observers.add(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.onScreenChange() }
        })

        // Reposition when switching spaces
        observers.add(NotificationCenter.default.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.moveToActiveScreen() }
        })

        // Listen for preview animation triggers from Settings
        observers.add(NotificationCenter.default.addObserver(
            forName: .petTriggerAnimation,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let userInfo = notification.userInfo
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let movement = userInfo?["movement"] as? String,
                   let petMovement = PetMovement(rawValue: movement) {
                    self.triggerAnimation(petMovement)
                } else if let animRaw = userInfo?["animation"] as? String,
                          let animation = PetAnimation(rawValue: animRaw) {
                    self.petService.triggerAmbientAnimation(animation)
                }
            }
        })

        startMouseTracking()
        startMovementScheduler()
    }

    func hide() {
        stopAll()
        window?.orderOut(nil)
        window?.close()
        window = nil
    }

    func updatePosition() {
        guard let w = window, !isAnimating else { return }
        recomputeGeometry()
        snapToHome(w)
    }

    /// Trigger a specific movement animation (used by Settings preview).
    func triggerAnimation(_ movement: PetMovement) {
        guard !isAnimating, let w = window else { return }
        recomputeGeometry()
        snapToHome(w)
        performAnimation(movement, window: w)
    }

    private func performAnimation(_ movement: PetMovement, window w: NSWindow) {
        switch movement {
        case .bounce:    animateBounce(w)
        case .wander:    animateWander(w)
        case .dash:      animateDash(w)
        case .runAcross: animateRunAcross(w)
        case .peek:      animatePeekFromNotch(w)
        case .hideUp:    animateHideUp(w)
        case .peekDown:  animatePeekDown(w)
        case .dropCatch: animateDropCatch(w)
        case .swing:     animateSwing(w)
        // Character-specific
        case .wobble:    animateWobble(w)
        case .stretch:   animateStretch(w)
        case .glitch:    animateGlitch(w)
        case .scan:      animateScan(w)
        case .sway:      animateSway(w)
        case .grow:      animateGrow(w)
        case .phase:     animatePhase(w)
        case .spook:     animateSpook(w)
        }
    }

    // MARK: - Cleanup

    // NOTE: hide() is the primary cleanup path — it calls stopAll() on the main actor.
    // deinit provides a best-effort fallback for the non-isolated properties.

    deinit {
        mouseMonitor.map { NSEvent.removeMonitor($0) }
        movementTimer?.invalidate()
        animationTimer?.invalidate()
        observers.removeAll()
    }

    private func stopAll() {
        animationID += 1
        mouseMonitor.map { NSEvent.removeMonitor($0) }
        mouseMonitor = nil
        movementTimer?.invalidate()
        movementTimer = nil
        animationTimer?.invalidate()
        animationTimer = nil
        observers.removeAll()
        isAnimating = false
    }

    // MARK: - Multi-monitor

    private func startMouseTracking() {
        mouseMonitor.map { NSEvent.removeMonitor($0) }
        mouseMonitor = nil
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            Task { @MainActor [weak self] in self?.onMouseMoved() }
        }
        updateIgnoresMouseEvents()
    }

    private func onMouseMoved() {
        updateIgnoresMouseEvents()
        // Multi-display tracking: throttled to avoid recomputing geometry every event.
        guard NSScreen.screens.count > 1 else { return }
        let now = Date()
        guard now.timeIntervalSince(lastScreenCheckDate) >= 1.0 else { return }
        lastScreenCheckDate = now
        moveToActiveScreen()
    }

    private func updateIgnoresMouseEvents() {
        guard let w = window else { return }
        let spriteSize = AppSettings.petSize.spriteSize
        let padding: CGFloat = 4
        let spriteRect = NSRect(
            x: w.frame.origin.x + (w.frame.width - spriteSize) / 2 - padding,
            y: w.frame.origin.y + w.frame.height - spriteSize - padding,
            width: spriteSize + padding * 2,
            height: spriteSize + padding * 2
        )
        w.ignoresMouseEvents = !spriteRect.contains(NSEvent.mouseLocation)
    }

    private func moveToActiveScreen() {
        guard let w = window, !isAnimating else { return }
        guard let screen = screenWithMouse() else { return }
        if screen != currentScreen {
            currentScreen = screen
            recomputeGeometry()
            snapToHome(w)
        }
    }

    private func onScreenChange() {
        guard let w = window else { return }
        isAnimating = false
        animationTimer?.invalidate()
        currentScreen = nil
        // Reinstall (or remove) the global mouse monitor based on the new screen count.
        startMouseTracking()
        moveToActiveScreen()
        // Always recompute geometry after a screen-layout change — screen size/arrangement
        // may have changed even if the "active" screen identity is the same.
        recomputeGeometry()
        if currentScreen == nil {
            snapToHome(w)
        }
    }

    private func screenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    // MARK: - Geometry

    private func recomputeGeometry() {
        guard let w = window else { return }
        guard let screen = currentScreen ?? screenWithMouse() else { return }
        currentScreen = screen

        let frame = screen.frame
        let visibleFrame = screen.visibleFrame
        cachedMenuBarBottom = visibleFrame.maxY
        cachedScreenMinX = visibleFrame.minX
        cachedScreenMaxX = visibleFrame.maxX

        // Notch edges
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            cachedNotchLeft = leftArea.maxX
            cachedNotchRight = rightArea.minX
            screenHasNotch = true
        } else {
            let center = frame.origin.x + frame.width / 2
            cachedNotchLeft  = center - PetWindowTuning.notchFallbackHalfWidth
            cachedNotchRight = center + PetWindowTuning.notchFallbackHalfWidth
            screenHasNotch = false
        }

        // Compute home origin
        let petSize = AppSettings.petSize
        let spriteWidth = petSize.spriteSize
        let gap: CGFloat = 6
        let position = AppSettings.petPosition

        let petX: CGFloat
        switch position {
        case .leftOfMenuBar, .leftOfNotch:
            petX = cachedNotchLeft - spriteWidth - gap
        case .rightOfMenuBar, .rightOfNotch:
            petX = cachedNotchRight + gap
        }

        let windowX = petX - (w.frame.width - spriteWidth) / 2

        // Decide vertical placement:
        // - "Menu bar" positions always sit in the menu bar strip.
        // - "Of notch" positions hang below the menu bar on notch screens,
        //   but fall back to the menu bar strip on non-notch screens
        //   (there's no notch edge to hang from).
        let spriteHeight = petSize.spriteSize  // sprite is square (12 × pixelSize)
        let useMenuBarY = (position == .leftOfMenuBar || position == .rightOfMenuBar) || !screenHasNotch
        let windowY: CGFloat
        if useMenuBarY {
            let menuBarHeight = frame.maxY - visibleFrame.maxY
            let spriteCenterY = visibleFrame.maxY + menuBarHeight / 2
            let windowTopY = spriteCenterY + spriteHeight / 2
            windowY = windowTopY - w.frame.height
        } else {
            windowY = cachedMenuBarBottom - w.frame.height
        }

        homeOrigin = NSPoint(x: windowX, y: windowY)
    }

    func snapToHome(_ w: NSWindow) {
        w.setFrameOrigin(homeOrigin)
    }

    // MARK: - Movement animation scheduler

    private func startMovementScheduler() {
        movementTimer?.invalidate()
        scheduleNextMovement()
    }

    func scheduleNextMovement() {
        movementTimer?.invalidate()
        let interval = TimeInterval.random(in: PetWindowTuning.movementIntervalRange)
        movementTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.petService.isEnabled else { return }
                guard !self.petService.showSpeechBubble else {
                    self.scheduleNextMovement()
                    return
                }
                self.playRandomMovement()
            }
        }
    }

    private func playRandomMovement() {
        guard !isAnimating, let w = window else {
            scheduleNextMovement()
            return
        }

        let position = AppSettings.petPosition
        let character = AppSettings.petCharacter

        // Collect all movements available for the current position, screen & character
        let available = PetMovement.allCases.filter {
            $0.isAvailable(for: position, screenHasNotch: screenHasNotch, character: character)
        }

        // Build weighted pool — position-specific and character-specific animations get extra weight
        var pool: [PetMovement] = []
        for movement in available {
            // Character-specific get triple weight, position-specific get double, universal get single
            let weight: Int
            if movement.characterAffinity != nil {
                weight = 3
            } else if movement.positionFit != .universal {
                weight = 2
            } else {
                weight = 1
            }
            for _ in 0..<weight { pool.append(movement) }
        }

        if let picked = pool.randomElement() {
            recomputeGeometry()
            snapToHome(w)
            performAnimation(picked, window: w)
        }
    }
}
