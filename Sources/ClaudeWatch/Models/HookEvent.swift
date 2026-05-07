import Darwin
import Foundation

struct HookEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: HookEventKind
    let projectName: String
    let projectPath: String
    let sessionId: String
    let sessionName: String?
    let message: String
    let pid: pid_t?
    let bundleId: String?
    let timestamp: Date

    var sessionLabel: String? {
        if let name = sessionName, !name.isEmpty { return name }
        return sessionId.isEmpty ? nil : sessionId
    }

    var notificationTitle: String {
        ([projectName] + [sessionLabel].compactMap { $0 }).joined(separator: " · ")
    }
}
