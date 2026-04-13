import AppKit
import SwiftUI

struct MiniGameView: View {
    @ObservedObject var gameService: MiniGameService
    let variant: PetVariant

    @State private var petAnimation: PetAnimation = .idle
    @State private var frameIndex: Int = 0
    @State private var isVisible = false
    @State private var catchFlashActive = false
    @State private var hitFlashActive = false

    var body: some View {
        ZStack {
            gameCanvas
            overlays
        }
        .frame(width: GameConstants.gameWidth, height: GameConstants.gameHeight)
        .background(Color(red: 0.04, green: 0.04, blue: 0.12))
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.leftArrow)  { gameService.movePetLeft();  return .handled }
        .onKeyPress(.rightArrow) { gameService.movePetRight(); return .handled }
        .onKeyPress(.space) {
            if gameService.state.isWaitingToStart || gameService.state.isGameOver { gameService.start() }
            return .handled
        }
        .onTapGesture { location in
            if gameService.state.isWaitingToStart {
                gameService.start()
            } else {
                gameService.movePetToNormalizedX(location.x / GameConstants.gameWidth)
            }
        }
        .spriteAnimation(animation: petAnimation, variant: variant, frameIndex: $frameIndex)
        .onChange(of: gameService.state.isGameOver) { _, over in
            petAnimation = over ? .sleeping : .idle
        }
        .onChange(of: gameService.state.catchCount) { _, _ in
            petAnimation = .happy
            catchFlashActive = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                catchFlashActive = false
                guard !gameService.state.isGameOver else { return }
                petAnimation = .idle
            }
        }
        .onChange(of: gameService.state.hitCount) { _, _ in
            petAnimation = .squash
            hitFlashActive = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                hitFlashActive = false
                guard !gameService.state.isGameOver else { return }
                petAnimation = .idle
            }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .sheet(isPresented: Binding(
            get: { gameService.rateLimitLifted },
            set: { if !$0 { gameService.acknowledgeRateLimitLifted() } }
        )) {
            rateLimitLiftedSheet
        }
    }

    // MARK: - Game Canvas

    private var gameCanvas: some View {
        let state = gameService.state
        let isActive = !state.isWaitingToStart && !state.isGameOver
        return Group {
            if isActive {
                // Live 60 fps canvas — only runs while the game is in progress.
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    let anim = petAnimation
                    let catchActive = catchFlashActive
                    let hitActive = hitFlashActive
                    Canvas { ctx, size in
                        let s = gameService.state
                        let fi = frameIndex
                        drawBackground(&ctx, size: size, elapsed: s.elapsedSeconds)
                        drawLaneGuides(&ctx, size: size)
                        for token in s.tokens { drawToken(&ctx, token: token, size: size) }
                        drawPet(&ctx, state: s, size: size, frameIndex: fi, animation: anim)
                        drawLivesHUD(&ctx)
                        drawScoreHUD(&ctx, score: s.score, highScore: gameService.highScore)
                        if catchActive {
                            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                                     with: .color(.green.opacity(0.12)))
                        }
                        if hitActive {
                            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                                     with: .color(.red.opacity(0.22)))
                        }
                    }
                    .onChange(of: timeline.date) { _, date in
                        guard isVisible else { return }
                        gameService.tick(date: date)
                    }
                }
            } else {
                // Static canvas for start/game-over screens — no animation driver needed.
                Canvas { ctx, size in
                    let s = gameService.state
                    drawBackground(&ctx, size: size, elapsed: s.elapsedSeconds)
                    drawLaneGuides(&ctx, size: size)
                    drawPet(&ctx, state: s, size: size, frameIndex: frameIndex, animation: petAnimation)
                    drawLivesHUD(&ctx)
                    drawScoreHUD(&ctx, score: s.score, highScore: gameService.highScore)
                }
            }
        }
    }

    // MARK: - Drawing helpers

    private func drawBackground(_ ctx: inout GraphicsContext, size: CGSize, elapsed: Double) {
        let gradient = Gradient(colors: [
            Color(red: 0.04, green: 0.04, blue: 0.14),
            Color(red: 0.06, green: 0.05, blue: 0.20)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(gradient,
                                       startPoint: .zero,
                                       endPoint: CGPoint(x: 0, y: size.height)))

        for star in MiniGameTheme.starPositions {
            let brightness = 0.25 + 0.75 * abs(sin(elapsed * star.twinkleSpeed + star.phase))
            ctx.fill(
                Path(CGRect(x: star.x * size.width, y: star.y * size.height, width: 2, height: 2)),
                with: .color(.white.opacity(brightness * 0.8))
            )
        }
    }

    private func drawLaneGuides(_ ctx: inout GraphicsContext, size: CGSize) {
        let laneW = size.width / CGFloat(GameConstants.laneCount)
        for i in 1..<GameConstants.laneCount {
            var path = Path()
            let x = CGFloat(i) * laneW
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            ctx.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 1)
        }
        // Floor line
        var floor = Path()
        let floorY = GameConstants.petBaselineY + GameConstants.petSpriteDisplaySize + 2
        floor.move(to: CGPoint(x: 0, y: floorY))
        floor.addLine(to: CGPoint(x: size.width, y: floorY))
        ctx.stroke(floor, with: .color(.white.opacity(0.12)), lineWidth: 1)
    }

    private func drawToken(_ ctx: inout GraphicsContext, token: FallingToken, size: CGSize) {
        let laneW = size.width / CGFloat(GameConstants.laneCount)
        let cx = (CGFloat(token.lane) + 0.5) * laneW
        let cy = token.y * size.height
        let r = GameConstants.tokenSize / 2

        switch token.kind {
        case .token:
            let color = MiniGameTheme.tokenColors[token.colorIndex % MiniGameTheme.tokenColors.count]
            // Soft glow
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r - 4, y: cy - r - 4,
                                             width: (r + 4) * 2, height: (r + 4) * 2)),
                     with: .color(color.opacity(0.20)))
            // Pixel square body
            ctx.fill(Path(CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                     with: .color(color))
            // Highlight dot
            ctx.fill(Path(CGRect(x: cx - r + 2, y: cy - r + 2, width: 3, height: 3)),
                     with: .color(.white.opacity(0.85)))

        case .blocker:
            let red = Color(red: 0.88, green: 0.15, blue: 0.15)
            // Body
            ctx.fill(Path(CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                     with: .color(red))
            // Dark border
            ctx.stroke(Path(CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                       with: .color(Color(red: 0.45, green: 0, blue: 0)), lineWidth: 1.5)
            // X mark (4 corner pixels)
            for dx: CGFloat in [-3, 3] {
                for dy: CGFloat in [-3, 3] {
                    ctx.fill(Path(CGRect(x: cx + dx - 1, y: cy + dy - 1, width: 2, height: 2)),
                             with: .color(.black.opacity(0.65)))
                }
            }
        }
    }

    private func drawPet(_ ctx: inout GraphicsContext, state: MiniGameState, size: CGSize,
                         frameIndex: Int, animation: PetAnimation) {
        let laneW = size.width / CGFloat(GameConstants.laneCount)
        let petCX = (CGFloat(state.petLane) + 0.5) * laneW
        let petTop = GameConstants.petBaselineY

        // Shadow
        ctx.fill(Path(ellipseIn: CGRect(x: petCX - 13, y: petTop + GameConstants.petSpriteDisplaySize - 2,
                                         width: 26, height: 6)),
                 with: .color(.black.opacity(0.30)))

        // Pixel grid
        let frames = CharacterSprites.frames(for: animation, variant: variant)
        guard !frames.isEmpty else { return }
        let frame = frames[frameIndex % frames.count]
        guard !frame.isEmpty, let firstRow = frame.first else { return }

        // Adjust pixel size for non-12×12 grids (e.g. 16×16 Cute Robot)
        let gridCols = CGFloat(firstRow.count)
        let ps = GameConstants.petSpritePixelSize * GameConstants.petSpriteBaseGrid / gridCols
        let spriteW = gridCols * ps
        let originX = petCX - spriteW / 2

        for (row, rowPixels) in frame.enumerated() {
            for (col, spriteColor) in rowPixels.enumerated() {
                guard spriteColor != .clear else { continue }
                let fillColor = spriteColor.color(for: variant)
                let rect = CGRect(
                    x: originX + CGFloat(col) * ps,
                    y: petTop + CGFloat(row) * ps,
                    width: ps, height: ps
                )
                ctx.fill(Path(rect), with: .color(fillColor))
            }
        }
    }

    private func drawLivesHUD(_ ctx: inout GraphicsContext) {
        for i in 0..<GameConstants.initialLives {
            let baseX = CGFloat(14 + i * 20)
            let baseY: CGFloat = 14
            let active = i < gameService.state.lives
            let heartColor: Color = active ? Color(red: 0.95, green: 0.30, blue: 0.40) : .white.opacity(0.18)
            for (px, py) in MiniGameTheme.heartPixels {
                ctx.fill(Path(CGRect(x: baseX + CGFloat(px) * 2, y: baseY + CGFloat(py) * 2,
                                     width: 2, height: 2)),
                         with: .color(heartColor))
            }
        }
    }

    private func drawScoreHUD(_ ctx: inout GraphicsContext, score: Int, highScore: Int) {
        let scoreText = ctx.resolve(
            Text("\(score)")
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white)
        )
        ctx.draw(scoreText,
                 at: CGPoint(x: GameConstants.gameWidth - 14, y: 12),
                 anchor: .topTrailing)

        let hiText = ctx.resolve(
            Text("HI \(highScore)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.45))
        )
        ctx.draw(hiText,
                 at: CGPoint(x: GameConstants.gameWidth - 14, y: 38),
                 anchor: .topTrailing)
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlays: some View {
        if gameService.state.isWaitingToStart {
            startOverlay
        } else if gameService.state.isGameOver {
            gameOverOverlay
        }
    }

    private var startOverlay: some View {
        VStack(spacing: 14) {
            Text("TOKEN RUSH")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(.white)

            VStack(spacing: 6) {
                Text("Catch the tokens!")
                Text("Dodge the red blocks.")
            }
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(.white.opacity(0.75))

            Text("← → arrows  or  tap to move")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))

            Button("START") { gameService.start() }
                .buttonStyle(PixelButtonStyle())
                .padding(.top, 6)
        }
        .padding(32)
        .background(.ultraThinMaterial.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 12) {
            Text("GAME OVER")
                .font(.system(size: 26, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))

            Text("Score: \(gameService.state.score)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            if gameService.state.score > 0 && gameService.state.score >= gameService.highScore {
                Text("NEW HIGH SCORE!")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.yellow)
            }

            HStack(spacing: 12) {
                Button("PLAY AGAIN") { gameService.start() }
                    .buttonStyle(PixelButtonStyle())
                Button("SHARE") { shareResult() }
                    .buttonStyle(PixelButtonStyle(secondary: true))
                Button("CLOSE") {
                    NotificationCenter.default.post(name: .miniGameShouldClose, object: nil)
                }
                .buttonStyle(PixelButtonStyle(secondary: true))
            }
            .padding(.top, 6)
        }
        .padding(32)
        .background(.ultraThinMaterial.opacity(0.90))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sharing

    @MainActor private func shareResult() {
        let s = gameService.state
        let isNewHigh = s.score > 0 && s.score >= gameService.highScore
        let snapshot = GameResultSnapshotView(
            score: s.score,
            highScore: gameService.highScore,
            isNewHighScore: isNewHigh,
            elapsedSeconds: s.elapsedSeconds,
            difficulty: s.difficulty,
            variant: variant
        )
        let renderer = ImageRenderer(content: snapshot)
        renderer.scale = 2.0
        guard let image = renderer.nsImage else { return }

        let anchor = NSApp.windows.first { $0.title == "Token Rush" }?.contentView
            ?? NSApp.keyWindow?.contentView
        guard let contentView = anchor else { return }

        let picker = NSSharingServicePicker(items: [image])
        picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
    }

    private var rateLimitLiftedSheet: some View {
        VStack(spacing: 16) {
            Text("Rate Limit Lifted!")
                .font(.headline)
            Text("The API rate limit has cleared. Keep playing or close the game?")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Button("Keep Playing") {
                    gameService.acknowledgeRateLimitLifted()
                }
                .buttonStyle(.borderedProminent)
                Button("Close") {
                    gameService.acknowledgeRateLimitLifted()
                    NotificationCenter.default.post(name: .miniGameShouldClose, object: nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(width: 300)
    }
}

// MARK: - Pixel art button style

struct PixelButtonStyle: ButtonStyle {
    var secondary: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(secondary ? Color.white.opacity(0.7) : Color.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(secondary ? Color.white.opacity(0.10) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
