import Foundation

enum MenuBarStyle: String, CaseIterable, Identifiable {
    case iconOnly         = "Icon only"
    case session          = "Session %"
    case weekly           = "Weekly %"
    case sessionAndWeekly = "Session + Weekly"
    case pace             = "Pace (%/h)"

    var id: String          { rawValue }
    var displayName: String { rawValue }
}

enum MenuBarIcon: String, CaseIterable, Identifiable {
    case gauge   = "Gauge"
    case spark   = "Spark"
    case ring    = "Ring"
    case pulse   = "Pulse"
    case battery = "Battery"
    case meter   = "Meter"

    var id: String          { rawValue }
    var displayName: String { rawValue }
}
