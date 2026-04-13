import SwiftUI

// MARK: - View-layer rendering constants for the mini game
//
// Pure view concerns (colours, pixel-art shapes, star field) live here so that
// MiniGameState.swift stays free of SwiftUI and can be tested without a UI host.

enum MiniGameTheme {

    // MARK: Token colours — one per colorIndex slot

    static let tokenColors: [Color] = [
        Color(red: 0.4,  green: 0.8,  blue: 1.0),
        Color(red: 0.5,  green: 0.95, blue: 0.55),
        Color(red: 1.0,  green: 0.85, blue: 0.3),
        Color(red: 0.85, green: 0.5,  blue: 1.0),
        Color(red: 1.0,  green: 0.6,  blue: 0.3),
        Color(red: 0.35, green: 0.9,  blue: 0.85),
        Color(red: 1.0,  green: 0.4,  blue: 0.7),
        Color(red: 0.7,  green: 0.9,  blue: 1.0)
    ]

    // MARK: Star field — deterministic positions, stable across redraws

    struct StarData {
        let x, y: CGFloat
        let phase, twinkleSpeed: Double
    }

    static let starPositions: [StarData] = (0..<50).map { i in
        // xorshift32 — good distribution, no clustering
        var s = UInt32(i) &* 2654435761 &+ 1
        func next() -> Double {
            s ^= s << 13; s ^= s >> 17; s ^= s << 5
            return Double(s) / Double(UInt32.max)
        }
        return StarData(
            x: CGFloat(next()),
            y: CGFloat(next()),
            phase: next() * .pi * 2,
            twinkleSpeed: 0.4 + next() * 1.4
        )
    }

    // MARK: Pixel-art heart shape (7×6 pixels) — used by lives HUD

    static let heartPixels: [(Int, Int)] = [
        (1,0),(2,0),(4,0),(5,0),
        (0,1),(1,1),(2,1),(3,1),(4,1),(5,1),(6,1),
        (0,2),(1,2),(2,2),(3,2),(4,2),(5,2),(6,2),
        (1,3),(2,3),(3,3),(4,3),(5,3),
        (2,4),(3,4),(4,4),
        (3,5)
    ]
}
