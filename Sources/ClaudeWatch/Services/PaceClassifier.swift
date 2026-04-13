import Foundation
import SwiftUI

/// Semantic classification of the current session burn rate.
enum PacePressure {
    /// Pace is below the meaningful threshold — no reliable estimate.
    case unknown
    /// At current pace the 5-hour session window resets before the cap is hit.
    case beyondWindow
    /// ETA is 2–5 h — comfortable headroom.
    case comfortable
    /// ETA is 1–2 h — worth watching.
    case watch
    /// ETA is under 1 h — session cap approaching fast.
    case urgent

    /// SF Symbol name for this pressure level.
    var icon: String {
        switch self {
        case .unknown:      return "tortoise.fill"
        case .beyondWindow: return "tortoise.fill"
        case .comfortable:  return "tortoise.fill"
        case .watch:        return "figure.walk"
        case .urgent:       return "hare.fill"
        }
    }

    /// Tint color for pace badges and ring indicators.
    var color: Color {
        switch self {
        case .unknown:      return .secondary
        case .beyondWindow: return .green
        case .comfortable:  return .blue
        case .watch:        return .yellow
        case .urgent:       return .red
        }
    }
}

/// Fully-resolved pace context consumed by both the popover and the pet.
struct PaceStatus {
    let pressure: PacePressure
    let pacePerHour: Double
    let etaHours: Double?
}

/// Single source of truth for pace classification.
/// All callers (popover row, pet service, notifications) derive pressure from here
/// so the messaging can never diverge.
enum PaceClassifier {

    /// Minimum pace (%/h) considered meaningful for ETA calculations.
    static let minimumMeaningfulPacePerHour: Double = 0.5

    /// SF Symbol for a raw %/h burn rate (for display in header pills and stats badges).
    /// Uses magnitude thresholds, not ETA-based pressure.
    static func rawPaceIcon(_ pace: Double) -> String {
        switch pace {
        case 20...:   return "hare.fill"
        case 10..<20: return "figure.walk"
        default:      return "tortoise.fill"
        }
    }

    /// Tint color for a raw %/h burn rate (for display in header pills and stats badges).
    static func rawPaceColor(_ pace: Double) -> Color {
        switch pace {
        case 20...:   return .red
        case 10..<20: return .yellow
        default:      return .green
        }
    }

    /// Classify pace pressure from the current burn rate and estimated ETA.
    ///
    /// - Parameters:
    ///   - pace: Session usage consumed per hour (% points / h).
    ///   - etaHours: Hours until the session cap is reached, or `nil` when history
    ///               is too sparse to produce a reliable estimate.
    ///   - sessionWindowHours: Length of a session window in hours (default 5).
    static func classify(
        pace: Double,
        etaHours: Double?,
        sessionWindowHours: Double = 5
    ) -> PaceStatus {
        guard pace > minimumMeaningfulPacePerHour else {
            return PaceStatus(pressure: .unknown, pacePerHour: pace, etaHours: etaHours)
        }

        let pressure: PacePressure
        if let hours = etaHours {
            switch hours {
            case sessionWindowHours...: pressure = .beyondWindow
            case 2..<sessionWindowHours: pressure = .comfortable
            case 1..<2:                  pressure = .watch
            default:                     pressure = .urgent
            }
        } else {
            // Meaningful pace but sparse history — not enough data to confirm safety.
            pressure = .comfortable
        }

        return PaceStatus(pressure: pressure, pacePerHour: pace, etaHours: etaHours)
    }
}
