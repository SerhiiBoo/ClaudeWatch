import AppKit

/// Draws the menu bar icon for each `MenuBarIcon` style.
/// All icons are 18×18pt, non-template, with orange→red color shifting based on usage.
enum MenuBarIconRenderer {

    /// Render the selected icon style at the given usage fraction.
    /// - Parameters:
    ///   - style: Which icon design to draw.
    ///   - fraction: 1.0 = full/fresh, 0.0 = exhausted.
    /// - Returns: A colored `NSImage` suitable for the status bar.
    static func render(style: MenuBarIcon, fraction: Double) -> NSImage {
        switch style {
        case .gauge:   return drawGauge(fraction: fraction)
        case .spark:   return drawSpark(fraction: fraction)
        case .ring:    return drawRing(fraction: fraction)
        case .pulse:   return drawPulse(fraction: fraction)
        case .battery: return drawBattery(fraction: fraction)
        case .meter:   return drawMeter(fraction: fraction)
        }
    }

    // MARK: - Shared helpers

    private static let iconSize = NSSize(width: 18, height: 18)

    private static func usageColor(fraction: Double) -> NSColor {
        let c = max(0, min(1, fraction))
        let r: CGFloat = 0.91 + (1.0 - 0.91) * (1 - c)
        let g: CGFloat = 0.57 * c
        let b: CGFloat = 0.23 * c
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    private static var sparkleColor: NSColor { .labelColor }

    private static func makeStar(center: NSPoint, size: CGFloat) -> NSBezierPath {
        let cx = center.x, cy = center.y
        let sc = size * 0.25
        let path = NSBezierPath()
        path.move(to: NSPoint(x: cx, y: cy + size))
        path.curve(to: NSPoint(x: cx + size, y: cy),
                   controlPoint1: NSPoint(x: cx + sc, y: cy + sc),
                   controlPoint2: NSPoint(x: cx + sc, y: cy + sc))
        path.curve(to: NSPoint(x: cx, y: cy - size),
                   controlPoint1: NSPoint(x: cx + sc, y: cy - sc),
                   controlPoint2: NSPoint(x: cx + sc, y: cy - sc))
        path.curve(to: NSPoint(x: cx - size, y: cy),
                   controlPoint1: NSPoint(x: cx - sc, y: cy - sc),
                   controlPoint2: NSPoint(x: cx - sc, y: cy - sc))
        path.curve(to: NSPoint(x: cx, y: cy + size),
                   controlPoint1: NSPoint(x: cx - sc, y: cy + sc),
                   controlPoint2: NSPoint(x: cx - sc, y: cy + sc))
        return path
    }

    private static func makeImage(_ draw: @escaping (NSRect) -> Void) -> NSImage {
        let img = NSImage(size: iconSize, flipped: false) { rect in
            draw(rect)
            return true
        }
        img.isTemplate = false
        return img
    }

    // MARK: - 1. Gauge

    /// Arc from 7-o'clock to 5-o'clock (240° sweep) with a needle pointing at the usage level.
    /// Arc fills proportionally; needle tracks the fill endpoint.
    private static func drawGauge(fraction: Double) -> NSImage {
        makeImage { rect in
            let cx = rect.midX
            let cy = rect.midY - 0.5
            let radius: CGFloat = 7.5
            let lineW: CGFloat = 1.8

            let color = usageColor(fraction: fraction)
            let track = color.withAlphaComponent(0.2)

            // Arc spans from 210° (7 o'clock) counter-clockwise to -30° (5 o'clock) = 240° sweep
            let startAngle: CGFloat = 210
            let totalSweep: CGFloat = 240
            let endAngle: CGFloat = startAngle - totalSweep

            // Track
            let trackPath = NSBezierPath()
            trackPath.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: radius,
                                startAngle: startAngle, endAngle: endAngle, clockwise: true)
            trackPath.lineWidth = lineW
            trackPath.lineCapStyle = .round
            track.setStroke()
            trackPath.stroke()

            // Filled arc
            let fillEnd = startAngle - totalSweep * fraction
            if fraction > 0.01 {
                let fillPath = NSBezierPath()
                fillPath.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: radius,
                                   startAngle: startAngle, endAngle: fillEnd, clockwise: true)
                fillPath.lineWidth = lineW
                fillPath.lineCapStyle = .round
                color.setStroke()
                fillPath.stroke()
            }

            // Needle from center toward fill endpoint
            let needleAngle = fillEnd * .pi / 180
            let needleLen: CGFloat = 5.0
            let nx = cx + needleLen * cos(needleAngle)
            let ny = cy + needleLen * sin(needleAngle)
            let needle = NSBezierPath()
            needle.move(to: NSPoint(x: cx, y: cy))
            needle.line(to: NSPoint(x: nx, y: ny))
            needle.lineWidth = 1.2
            needle.lineCapStyle = .round
            color.setStroke()
            needle.stroke()

            // Center dot
            let dotR: CGFloat = 1.2
            let dot = NSBezierPath(ovalIn: NSRect(x: cx - dotR, y: cy - dotR,
                                                   width: dotR * 2, height: dotR * 2))
            sparkleColor.setFill()
            dot.fill()
        }
    }

    // MARK: - 2. Spark

    /// Two concentric arcs (outer 270°, inner 200°) with a 4-point star sparkle in the center.
    /// This is the original "gauge" icon design.
    private static func drawSpark(fraction: Double) -> NSImage {
        makeImage { rect in
            let cx = rect.midX
            let cy = rect.midY
            let color = usageColor(fraction: fraction)
            let track = color.withAlphaComponent(0.2)

            // Outer arc: 270° max
            let outerR: CGFloat = 7.5
            let outerW: CGFloat = 1.5
            let outerMax: CGFloat = 270
            let outerSweep = outerMax * fraction

            let outerTrack = NSBezierPath()
            outerTrack.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: outerR,
                                 startAngle: 90, endAngle: 90 - outerMax, clockwise: true)
            outerTrack.lineWidth = outerW
            outerTrack.lineCapStyle = .round
            track.setStroke()
            outerTrack.stroke()

            if outerSweep > 0 {
                let outerFill = NSBezierPath()
                outerFill.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: outerR,
                                    startAngle: 90, endAngle: 90 - outerSweep, clockwise: true)
                outerFill.lineWidth = outerW
                outerFill.lineCapStyle = .round
                color.setStroke()
                outerFill.stroke()
            }

            // Inner arc: 200° max
            let innerR: CGFloat = 5.0
            let innerW: CGFloat = 1.25
            let innerMax: CGFloat = 200
            let innerSweep = innerMax * fraction

            let innerTrack = NSBezierPath()
            innerTrack.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: innerR,
                                 startAngle: 0, endAngle: innerMax, clockwise: false)
            innerTrack.lineWidth = innerW
            innerTrack.lineCapStyle = .round
            track.setStroke()
            innerTrack.stroke()

            if innerSweep > 0 {
                let innerFill = NSBezierPath()
                innerFill.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: innerR,
                                    startAngle: 0, endAngle: innerSweep, clockwise: false)
                innerFill.lineWidth = innerW
                innerFill.lineCapStyle = .round
                color.setStroke()
                innerFill.stroke()
            }

            // 4-point star sparkle
            let star = makeStar(center: NSPoint(x: cx, y: cy), size: 2.5)
            sparkleColor.setFill()
            star.fill()
        }
    }

    // MARK: - 3. Ring

    /// A single thick ring that fills clockwise from the top.
    /// A small dot marks the fill endpoint.
    private static func drawRing(fraction: Double) -> NSImage {
        makeImage { rect in
            let cx = rect.midX
            let cy = rect.midY
            let radius: CGFloat = 6.5
            let lineW: CGFloat = 2.5
            let color = usageColor(fraction: fraction)
            let track = color.withAlphaComponent(0.2)

            // Full track ring
            let trackPath = NSBezierPath()
            trackPath.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: radius,
                                startAngle: 90, endAngle: -270, clockwise: true)
            trackPath.lineWidth = lineW
            trackPath.lineCapStyle = .round
            track.setStroke()
            trackPath.stroke()

            // Fill arc
            let sweep = 360.0 * fraction
            if sweep > 0.5 {
                let fillPath = NSBezierPath()
                fillPath.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: radius,
                                   startAngle: 90, endAngle: 90 - sweep, clockwise: true)
                fillPath.lineWidth = lineW
                fillPath.lineCapStyle = .round
                color.setStroke()
                fillPath.stroke()
            }

            // Endpoint sparkle (4-point star)
            let endAngle = (90 - sweep) * .pi / 180
            let sx = cx + radius * cos(endAngle)
            let sy = cy + radius * sin(endAngle)
            let star = makeStar(center: NSPoint(x: sx, y: sy), size: 4.5)
            sparkleColor.setFill()
            star.fill()
        }
    }

    // MARK: - 4. Pulse

    /// ECG / heartbeat waveform line. The spike amplitude grows with usage;
    /// at low usage the line flattens toward a near-flatline.
    private static func drawPulse(fraction: Double) -> NSImage {
        makeImage { rect in
            let color = usageColor(fraction: fraction)
            let track = color.withAlphaComponent(0.2)

            let cy = rect.midY
            let left: CGFloat = 1.5
            let right: CGFloat = 16.5
            let amp = 5.5 * max(0.08, fraction)  // spike height scales with usage

            // Baseline (faint)
            let baseline = NSBezierPath()
            baseline.move(to: NSPoint(x: left, y: cy))
            baseline.line(to: NSPoint(x: right, y: cy))
            baseline.lineWidth = 0.6
            track.setStroke()
            baseline.stroke()

            // ECG waveform: flat → small dip → big spike → small dip → flat
            let wave = NSBezierPath()
            wave.move(to: NSPoint(x: left, y: cy))
            wave.line(to: NSPoint(x: 4.5, y: cy))                     // flat lead-in
            wave.line(to: NSPoint(x: 5.5, y: cy - amp * 0.3))         // small P wave
            wave.line(to: NSPoint(x: 6.5, y: cy))                     // back to baseline
            wave.line(to: NSPoint(x: 7.5, y: cy - amp * 0.25))        // Q dip
            wave.line(to: NSPoint(x: 9.0, y: cy + amp))               // R spike (big peak)
            wave.line(to: NSPoint(x: 10.5, y: cy - amp * 0.4))        // S dip
            wave.line(to: NSPoint(x: 11.5, y: cy))                    // back to baseline
            wave.line(to: NSPoint(x: 13.0, y: cy + amp * 0.25))       // T wave
            wave.line(to: NSPoint(x: 14.5, y: cy))                    // back to baseline
            wave.line(to: NSPoint(x: right, y: cy))                   // flat tail

            wave.lineWidth = 1.4
            wave.lineCapStyle = .round
            wave.lineJoinStyle = .round
            color.setStroke()
            wave.stroke()
        }
    }

    // MARK: - 5. Battery

    /// Horizontal battery outline with fill level inside.
    /// Nub on the right side (positive terminal).
    private static func drawBattery(fraction: Double) -> NSImage {
        makeImage { rect in
            let color = usageColor(fraction: fraction)
            let track = color.withAlphaComponent(0.25)

            // Battery body
            let bodyX: CGFloat = 2
            let bodyY: CGFloat = 5
            let bodyW: CGFloat = 12
            let bodyH: CGFloat = 8
            let cornerR: CGFloat = 1.5

            let body = NSBezierPath(roundedRect: NSRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH),
                                     xRadius: cornerR, yRadius: cornerR)
            body.lineWidth = 1.2
            color.withAlphaComponent(0.6).setStroke()
            body.stroke()

            // Nub (positive terminal)
            let nubW: CGFloat = 1.5
            let nubH: CGFloat = 4
            let nubX = bodyX + bodyW
            let nubY = bodyY + (bodyH - nubH) / 2
            let nub = NSBezierPath(roundedRect: NSRect(x: nubX, y: nubY, width: nubW, height: nubH),
                                    xRadius: 0.5, yRadius: 0.5)
            track.setFill()
            nub.fill()

            // Fill level
            let inset: CGFloat = 2.0
            let fillMaxW = bodyW - inset * 2
            let fillW = fillMaxW * max(0, min(1, fraction))
            if fillW > 0.5 {
                let fill = NSBezierPath(roundedRect: NSRect(x: bodyX + inset, y: bodyY + inset,
                                                             width: fillW, height: bodyH - inset * 2),
                                         xRadius: 0.5, yRadius: 0.5)
                color.setFill()
                fill.fill()
            }

        }
    }

    // MARK: - 6. Meter

    /// Horizontal stacked bars (like a signal-strength meter).
    /// Bars light up from bottom to top based on usage fraction.
    private static func drawMeter(fraction: Double) -> NSImage {
        makeImage { rect in
            let color = usageColor(fraction: fraction)
            let track = color.withAlphaComponent(0.18)

            let barCount = 5
            let barW: CGFloat = 12
            let barH: CGFloat = 1.8
            let gap: CGFloat = 1.0
            let totalH = CGFloat(barCount) * barH + CGFloat(barCount - 1) * gap
            let startX: CGFloat = (rect.width - barW) / 2
            let startY: CGFloat = (rect.height - totalH) / 2

            for i in 0..<barCount {
                let y = startY + CGFloat(i) * (barH + gap)
                let barRect = NSRect(x: startX, y: y, width: barW, height: barH)
                let bar = NSBezierPath(roundedRect: barRect, xRadius: 0.8, yRadius: 0.8)

                // Bar i=0 is bottom, i=barCount-1 is top
                // Fill from bottom: bar is lit if its threshold <= fraction
                let threshold = Double(i) / Double(barCount)
                if fraction > threshold + 0.01 {
                    color.setFill()
                } else {
                    track.setFill()
                }
                bar.fill()
            }
        }
    }
}
