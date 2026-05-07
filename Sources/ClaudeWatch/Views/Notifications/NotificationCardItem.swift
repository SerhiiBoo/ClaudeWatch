import SwiftUI

enum NotificationCardItem: Identifiable {
    case event(HookEvent)
    case request(PermissionRequest)

    var id: UUID {
        switch self {
        case .event(let e):   return e.id
        case .request(let r): return r.id
        }
    }

    var icon: String {
        switch self {
        case .event(let e): return e.kind.icon
        case .request:      return "lock.shield"
        }
    }

    var accentColor: Color {
        switch self {
        case .event(let e): return e.kind == .stop ? .green : .orange
        case .request:      return .blue
        }
    }

    var borderColor: Color {
        switch self {
        case .event:   return Color.primary.opacity(0.08)
        case .request: return Color.blue.opacity(0.35)
        }
    }

    var title: String {
        switch self {
        case .event(let e):   return e.projectName
        case .request(let r): return r.toolName
        }
    }

    var subtitle: String? {
        switch self {
        case .event(let e): return e.sessionLabel
        case .request(let r):
            guard r.isSubAgent else { return nil }
            if let type_ = r.agentType, !type_.isEmpty {
                return "Sub-agent: \(type_)"
            }
            return "Sub-agent"
        }
    }

    var body: String {
        switch self {
        case .event(let e):   return e.message
        case .request(let r): return r.summary
        }
    }

    var timeout: TimeInterval {
        switch self {
        case .event(let e):
            return e.kind == .stop ? AppSettings.hookStopTimeout : AppSettings.hookNotificationTimeout
        case .request:
            return TimeInterval(AppSettings.permissionApprovalTimeoutSeconds)
        }
    }

    var permissionRequest: PermissionRequest? {
        guard case .request(let r) = self else { return nil }
        return r
    }
}
