import Foundation

@MainActor
final class HookIngestionService: HookIngestionServiceProtocol {
    private let notificationCenter: NotificationCenterServiceProtocol
    private let reachability: TerminalReachabilityService
    private var seenIDs: Set<UUID> = []
    private var seenIDsOrder: [UUID] = []
    private static let maxSeenIDs = 200

    init(notificationCenter: NotificationCenterServiceProtocol,
         reachability: TerminalReachabilityService = TerminalReachabilityService()) {
        self.notificationCenter = notificationCenter
        self.reachability = reachability
    }

    func ingest(url: URL) {
        guard let event = parse(url: url) else { return }
        guard !seenIDs.contains(event.id) else { return }
        seenIDs.insert(event.id)
        seenIDsOrder.append(event.id)
        if seenIDsOrder.count > Self.maxSeenIDs {
            seenIDs.remove(seenIDsOrder.removeFirst())
        }
        if let pid = event.pid, let bundleId = event.bundleId,
           reachability.reachability(pid: pid, bundleId: bundleId) == .reachable {
            return
        }
        notificationCenter.enqueue(event)
    }

    // MARK: - Parse

    private func parse(url: URL) -> HookEvent? {
        guard url.scheme == "claudewatch", url.host == "notify" else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let payloadItem = components.queryItems?.first(where: { $0.name == "payload" }),
              let encoded = payloadItem.value else { return nil }

        // Pad base64url → standard base64
        let padded = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = padded.count % 4
        let padding = remainder == 0 ? "" : String(repeating: "=", count: 4 - remainder)
        guard let data = Data(base64Encoded: padded + padding) else { return nil }

        return decode(data: data)
    }

    private func decode(data: Data) -> HookEvent? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let hookEventName = json["hook_event_name"] as? String ?? json["kind"] as? String ?? ""
        guard let kind = HookEventKind(hookEventName: hookEventName) else { return nil }
        guard AppSettings.hookNotificationsEnabled else { return nil }
        switch kind {
        case .notification: guard AppSettings.hookNotificationEventEnabled else { return nil }
        case .stop:         guard AppSettings.hookStopEventEnabled else { return nil }
        }

        let id: UUID
        if let idStr = json["id"] as? String, let parsed = UUID(uuidString: idStr) {
            id = parsed
        } else {
            id = UUID()
        }

        let cwd = json["cwd"] as? String ?? ""
        let projectPath = cwd
        let projectName = (json["project_name"] as? String)
            ?? (cwd.isEmpty ? "" : URL(fileURLWithPath: cwd).lastPathComponent)
        let sessionId = json["session_id"] as? String ?? ""
        let sessionName = json["session_name"] as? String
        let message = json["message"] as? String ?? kind.defaultMessage

        let pid: pid_t?
        if let p = json["pid"] as? Int { pid = pid_t(p) } else { pid = nil }
        let bundleId = json["bundle_id"] as? String

        let timestamp: Date
        if let ts = json["ts"] as? TimeInterval {
            timestamp = Date(timeIntervalSince1970: ts)
        } else {
            timestamp = Date()
        }

        return HookEvent(
            id: id,
            kind: kind,
            projectName: projectName,
            projectPath: projectPath,
            sessionId: sessionId,
            sessionName: sessionName,
            message: message,
            pid: pid,
            bundleId: bundleId.flatMap { $0.isEmpty ? nil : $0 },
            timestamp: timestamp
        )
    }
}
