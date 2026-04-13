import Foundation
import SwiftUI

enum PetMood: String, CaseIterable {
    case ecstatic    // 100% fresh reset
    case happy       // 80–99%
    case normal      // 50–79%
    case tired       // 25–49%
    case exhausted   // 10–24%
    case critical    // <10%
    case sleeping    // rate-limited
    case reborn      // just detected a reset

    var tintColor: Color {
        switch self {
        case .ecstatic, .reborn: return .green
        case .happy:             return .blue
        case .normal:            return .clear
        case .tired:             return .yellow
        case .exhausted:         return .orange
        case .critical:          return .red
        case .sleeping:          return .purple
        }
    }

    func statusLabel(for character: PetCharacter) -> String {
        let name = character.displayName
        switch self {
        case .ecstatic:  return "\(name) is ecstatic!"
        case .happy:     return "\(name) is happy"
        case .normal:    return "\(name) is chillin'"
        case .tired:     return "\(name) is getting tired..."
        case .exhausted: return "\(name) is exhausted"
        case .critical:  return "\(name) is barely alive"
        case .sleeping:  return "\(name) is napping"
        case .reborn:    return "\(name) is REBORN!"
        }
    }

    /// Derive mood from usage remaining percentage, rate-limit state, and pace pressure.
    /// `pacePressure` is an overlay: `.urgent` upgrades `.normal`/`.happy` to `.tired`.
    static func from(
        sessionRemaining: Double,
        pacePressure: PacePressure = .unknown,
        isRateLimited: Bool,
        justReset: Bool
    ) -> PetMood {
        if justReset { return .reborn }
        if isRateLimited { return .sleeping }

        let baseMood: PetMood
        switch sessionRemaining {
        case let r where r >= 100: baseMood = .ecstatic
        case 80..<100:             baseMood = .happy
        case 50..<80:              baseMood = .normal
        case 25..<50:              baseMood = .tired
        case 10..<25:              baseMood = .exhausted
        default:                   baseMood = .critical
        }

        // Pace overlay: urgent pressure upgrades .normal/.happy to .tired so the pet
        // appears worried even when tokens remain.
        if pacePressure == .urgent, baseMood == .normal || baseMood == .happy {
            return .tired
        }
        return baseMood
    }
}
