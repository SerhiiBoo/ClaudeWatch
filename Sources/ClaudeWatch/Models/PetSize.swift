import CoreGraphics

enum PetSize: String, CaseIterable, Identifiable {
    case tiny   = "Tiny"
    case small  = "Small"
    case medium = "Medium"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// Base pixel size for 12×12 grid rendering.
    var pixelSize: CGFloat {
        switch self {
        case .tiny:   return 1.5
        case .small:  return 2.0
        case .medium: return 2.5
        }
    }

    /// Pixel size adjusted for a specific grid size, keeping total sprite size constant.
    func pixelSize(forGrid gridSize: Int) -> CGFloat {
        // Scale so that gridSize × adjustedPixelSize ≈ 12 × basePixelSize
        let base = pixelSize
        return base * 12.0 / CGFloat(gridSize)
    }

    /// Total sprite dimension (12 × pixelSize for standard 12×12 grid).
    var spriteSize: CGFloat { 12 * pixelSize }
}
