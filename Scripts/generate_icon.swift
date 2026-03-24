#!/usr/bin/env swift
// Generates AppIcon.icns — an Activity-ring style icon in Claude's orange/brown palette.

import AppKit
import Foundation

/// Draw the icon at a given size into an NSImage.
func renderIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }

    let s = size
    let center = CGPoint(x: s / 2, y: s / 2)

    // ── Background: rounded rect with dark gradient ──────────────
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    let bgColors: [CGColor] = [
        NSColor(red: 0.10, green: 0.08, blue: 0.12, alpha: 1.0).cgColor,
        NSColor(red: 0.16, green: 0.12, blue: 0.18, alpha: 1.0).cgColor,
    ]
    let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: bgColors as CFArray,
                                 locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: 0, y: s),
                           end: CGPoint(x: s, y: 0),
                           options: [])

    // ── Outer ring (track) ───────────────────────────────────────
    let ringRadius = s * 0.33
    let ringWidth = s * 0.09
    let trackColor = NSColor(white: 1.0, alpha: 0.08).cgColor
    ctx.setStrokeColor(trackColor)
    ctx.setLineWidth(ringWidth)
    ctx.setLineCap(.round)
    ctx.addArc(center: center, radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()

    // ── Outer ring (filled arc ~72%) — Claude orange ─────────────
    let arcFraction: CGFloat = 0.72
    let startAngle: CGFloat = .pi / 2          // 12 o'clock (in CG coords, +Y is up)
    let endAngle = startAngle - (.pi * 2 * arcFraction)

    // Draw the arc with a gradient by stroking in segments
    let segments = 60
    for i in 0..<segments {
        let t0 = CGFloat(i) / CGFloat(segments)
        let t1 = CGFloat(i + 1) / CGFloat(segments)
        if t1 > arcFraction { break }

        let a0 = startAngle - (.pi * 2 * t0)
        let a1 = startAngle - (.pi * 2 * t1)

        // Gradient from warm orange → deep coral
        let r = 0.93 - 0.25 * t0
        let g = 0.55 - 0.25 * t0
        let b = 0.20 + 0.10 * t0
        ctx.setStrokeColor(NSColor(red: r, green: g, blue: b, alpha: 1.0).cgColor)
        ctx.setLineWidth(ringWidth)
        ctx.setLineCap(.round)
        ctx.addArc(center: center, radius: ringRadius, startAngle: a0, endAngle: a1, clockwise: true)
        ctx.strokePath()
    }

    // ── Inner ring (track) ───────────────────────────────────────
    let innerRadius = s * 0.21
    let innerWidth = s * 0.07
    ctx.setStrokeColor(trackColor)
    ctx.setLineWidth(innerWidth)
    ctx.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()

    // ── Inner ring (filled arc ~45%) — warm brown/amber ──────────
    let innerFraction: CGFloat = 0.45
    for i in 0..<segments {
        let t0 = CGFloat(i) / CGFloat(segments)
        let t1 = CGFloat(i + 1) / CGFloat(segments)
        if t1 > innerFraction { break }

        let a0 = startAngle - (.pi * 2 * t0)
        let a1 = startAngle - (.pi * 2 * t1)

        let r = 0.85 - 0.15 * t0
        let g = 0.65 - 0.20 * t0
        let b = 0.35 + 0.05 * t0
        ctx.setStrokeColor(NSColor(red: r, green: g, blue: b, alpha: 1.0).cgColor)
        ctx.setLineWidth(innerWidth)
        ctx.setLineCap(.round)
        ctx.addArc(center: center, radius: innerRadius, startAngle: a0, endAngle: a1, clockwise: true)
        ctx.strokePath()
    }

    // ── Center spark ✦ ───────────────────────────────────────────
    let sparkSize = s * 0.18
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: sparkSize, weight: .bold),
        .foregroundColor: NSColor(red: 0.95, green: 0.65, blue: 0.30, alpha: 1.0),
    ]
    let spark = NSAttributedString(string: "✦", attributes: attrs)
    let sparkBounds = spark.boundingRect(with: NSSize(width: s, height: s))
    let sparkOrigin = NSPoint(
        x: center.x - sparkBounds.width / 2,
        y: center.y - sparkBounds.height / 2
    )
    spark.draw(at: sparkOrigin)

    img.unlockFocus()
    return img
}

/// Convert an NSImage to a PNG Data at a specific pixel size.
func pngData(image: NSImage, pixelSize: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let icon = renderIcon(size: CGFloat(pixelSize))
    icon.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

// ── Main ─────────────────────────────────────────────────────────────────────

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath

let iconsetPath = "\(outputDir)/AppIcon.iconset"
let icnsPath = "\(outputDir)/AppIcon.icns"

// Create .iconset directory
try? FileManager.default.removeItem(atPath: iconsetPath)
try FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Required sizes for macOS .icns
let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16",        16),
    ("icon_16x16@2x",     32),
    ("icon_32x32",        32),
    ("icon_32x32@2x",     64),
    ("icon_128x128",      128),
    ("icon_128x128@2x",   256),
    ("icon_256x256",      256),
    ("icon_256x256@2x",   512),
    ("icon_512x512",      512),
    ("icon_512x512@2x",   1024),
]

for entry in sizes {
    let data = pngData(image: renderIcon(size: CGFloat(entry.pixels)), pixelSize: entry.pixels)
    let path = "\(iconsetPath)/\(entry.name).png"
    try data.write(to: URL(fileURLWithPath: path))
}

// Convert iconset → icns
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]
try task.run()
task.waitUntilExit()

// Clean up iconset
try? FileManager.default.removeItem(atPath: iconsetPath)

print("✓ Generated \(icnsPath)")
