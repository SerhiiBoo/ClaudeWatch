import Foundation

enum PetChattiness: String, CaseIterable, Identifiable {
    case quiet      = "Quiet"
    case occasional = "Occasional"
    case chatty     = "Chatty"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// Average seconds between random phrases.
    var intervalRange: ClosedRange<TimeInterval> {
        switch self {
        case .quiet:      return 600...1200    // 10–20 min
        case .occasional: return 300...600     // 5–10 min
        case .chatty:     return 120...300     // 2–5 min
        }
    }
}
