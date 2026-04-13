import SwiftUI

/// Maps a usage percentage (0–100, where higher = more consumed) to a semantic color.
///
/// Use this for progress bars and value indicators that communicate how much of a
/// quota has been consumed. All call sites share the same thresholds so the UI is
/// consistent throughout the app.
enum UsageSeverity {

    // MARK: - Thresholds

    /// Percentage-used below which the situation is considered healthy.
    static let warningThreshold: Double  = 40
    /// Percentage-used above which the situation is considered critical.
    static let criticalThreshold: Double = 80

    // MARK: - Color helpers

    /// Accent color for a progress bar or value based on the percentage *used* (0–100).
    ///
    /// - Green  when `used < 40` (healthy)
    /// - Yellow when `40 ≤ used < 80` (moderate)
    /// - Red    when `used ≥ 80` (critical)
    static func color(for used: Double) -> Color {
        switch used {
        case ..<warningThreshold:  return .green
        case ..<criticalThreshold: return .yellow
        default:                   return .red
        }
    }

    /// Foreground text color variant — same semantics as ``color(for:)``.
    static func textColor(for used: Double) -> Color {
        color(for: used)
    }
}
