import SwiftUI

// MARK: - Pixel grid renderer

/// Renders a pixel art sprite from a 2D grid of color codes.
/// Each cell in the grid maps to a small square. Transparent cells are skipped.
struct PixelGridView: View {
    let grid: [[SpriteColor]]
    let pixelSize: CGFloat
    let character: PetCharacter
    let variant: PetVariant?

    private var canvasSize: CGSize {
        let cols = CGFloat(grid.first?.count ?? 0)
        let rows = CGFloat(grid.count)
        return CGSize(width: cols * pixelSize, height: rows * pixelSize)
    }

    var body: some View {
        let size = canvasSize
        Canvas { context, _ in
            for (row, rowPixels) in grid.enumerated() {
                for (col, spriteColor) in rowPixels.enumerated() {
                    guard spriteColor != .clear else { continue }
                    let fillColor = variant.map { spriteColor.color(for: $0) }
                        ?? spriteColor.color(for: character)
                    let rect = CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    context.fill(Path(rect), with: .color(fillColor))
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Animated sprite view

/// Automatically cycles through sprite frames for the given animation and character.
struct AnimatedSpriteView: View {
    let animation: PetAnimation
    let pixelSize: CGFloat
    let character: PetCharacter
    let variant: PetVariant?
    @State private var frameIndex = 0

    private let baselineGridSize: CGFloat = 12

    /// Resolved variant: uses explicit variant or falls back to classic for character.
    private var resolvedVariant: PetVariant {
        variant ?? PetVariant.defaultVariant(for: character)
    }

    /// Pixel size adjusted for this variant's grid (16×16 grids use smaller pixels to keep same physical size).
    private var adjustedPixelSize: CGFloat {
        let gridSize = resolvedVariant.gridSize
        if gridSize == 12 { return pixelSize }
        return pixelSize * baselineGridSize / CGFloat(gridSize)
    }

    var body: some View {
        let v = resolvedVariant
        let frames = CharacterSprites.frames(for: animation, variant: v)
        let currentFrame = frames.isEmpty
            ? CharacterSprites.defaultFrame(for: v)
            : frames[frameIndex % frames.count]

        PixelGridView(grid: currentFrame, pixelSize: adjustedPixelSize, character: character, variant: variant)
            .spriteAnimation(animation: animation, variant: v, frameIndex: $frameIndex)
    }
}
