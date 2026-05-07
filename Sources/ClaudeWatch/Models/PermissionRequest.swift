import Darwin
import Foundation

enum PermissionDecision: String, Sendable {
    case allow
    case deny
    case none
}

enum PermissionActionIdentifier {
    static let allow = "permission_allow"
    static let deny  = "permission_deny"
}

struct PermissionRequest: Identifiable {
    let id: UUID
    let toolName: String
    let summary: String
    let pid: pid_t?
    let bundleId: String?
    let sessionId: String?
    let receivedAt: Date
    let isSubAgent: Bool
    let agentType: String?
    let reply: (PermissionDecision) -> Void
}
