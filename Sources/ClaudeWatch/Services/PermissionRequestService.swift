import AppKit
import Combine
import Darwin
import Foundation
import UserNotifications

@MainActor
final class PermissionRequestService {
    @Published private(set) var visibleRequests: [PermissionRequest] = []
    private var overflow: [PermissionRequest] = []
    private static let maxVisible = 3

    private var continuations: [UUID: CheckedContinuation<PermissionDecision, Never>] = [:]
    private let reachability: TerminalReachabilityService
    private var serverFD: Int32 = -1
    private var acceptSource: DispatchSourceRead?

    private static let socketPath: String = {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return support.appendingPathComponent("ClaudeWatch/permission.sock").path
    }()

    init(reachability: TerminalReachabilityService = .init()) {
        self.reachability = reachability
    }

    // MARK: - Lifecycle

    func startListening() {
        guard serverFD < 0 else { return }
        do {
            try bindAndListen()
        } catch {
            LogService.error("PermissionRequest", "Failed to bind socket", error: error)
        }
    }

    func stopListening() {
        acceptSource?.cancel()
        acceptSource = nil
        if serverFD >= 0 {
            Darwin.close(serverFD)
            serverFD = -1
        }
        Darwin.unlink(Self.socketPath)
        let pending = continuations
        continuations.removeAll()
        visibleRequests.removeAll()
        overflow.removeAll()
        for (_, cont) in pending { cont.resume(returning: .none) }
    }

    // MARK: - Resolution

    func resolve(id: UUID, decision: PermissionDecision) {
        guard let continuation = continuations.removeValue(forKey: id) else { return }
        visibleRequests.removeAll { $0.id == id }
        overflow.removeAll { $0.id == id }
        dequeueNext()
        continuation.resume(returning: decision)
    }

    func dismiss(_ request: PermissionRequest) {
        resolve(id: request.id, decision: .none)
    }

    // MARK: - Private queue management

    private func enqueue(_ request: PermissionRequest) {
        if visibleRequests.count < Self.maxVisible {
            visibleRequests.append(request)
        } else {
            overflow.append(request)
        }
    }

    private func dequeueNext() {
        guard !overflow.isEmpty, visibleRequests.count < Self.maxVisible else { return }
        visibleRequests.append(overflow.removeFirst())
    }

    // MARK: - Timeout

    private func scheduleTimeout(for id: UUID, seconds: TimeInterval) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            self?.resolve(id: id, decision: .none)
        }
    }

    // MARK: - Native notification delivery

    private func sendNativePermissionRequest(
        id: UUID,
        toolName: String,
        summary: String,
        pid: pid_t?,
        bundleId: String?,
        isSubAgent: Bool,
        agentType: String?
    ) {
        let content = UNMutableNotificationContent()
        let titlePrefix = isSubAgent ? "[Sub-agent] " : ""
        content.title = "\(titlePrefix)Allow \(toolName)?"
        content.body = summary
        content.categoryIdentifier = "permission_request"
        var info: [String: Any] = ["request_id": id.uuidString]
        if let pid { info["pid"] = Int(pid) }
        if let bundleId { info["bundle_id"] = bundleId }
        content.userInfo = info
        if AppSettings.hookSoundEnabled { content.sound = .default }
        let req = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req) { error in
            if let error { LogService.error("PermissionRequest", "Failed to send native notification", error: error) }
        }
    }

    // MARK: - Socket setup

    private func bindAndListen() throws {
        let dir = (Self.socketPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        Darwin.unlink(Self.socketPath)

        let oldMask = Darwin.umask(0o077)
        defer { _ = Darwin.umask(oldMask) }
        let fd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw SocketError.createFailed(errno) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathLen = Self.socketPath.utf8.count
        guard pathLen < MemoryLayout.size(ofValue: addr.sun_path) else {
            Darwin.close(fd)
            throw SocketError.pathTooLong
        }
        withUnsafeMutableBytes(of: &addr.sun_path) { buf in
            Self.socketPath.withCString { src in
                _ = Darwin.strlcpy(buf.baseAddress!.assumingMemoryBound(to: CChar.self), src, buf.count)
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindResult == 0 else {
            Darwin.close(fd)
            throw SocketError.bindFailed(errno)
        }

        Darwin.chmod(Self.socketPath, 0o600)

        guard Darwin.listen(fd, 5) == 0 else {
            Darwin.close(fd)
            throw SocketError.listenFailed(errno)
        }

        serverFD = fd

        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: .global())
        source.setEventHandler { [weak self, fd] in
            let clientFD = Darwin.accept(fd, nil, nil)
            guard clientFD >= 0, let self else {
                if clientFD >= 0 { Darwin.close(clientFD) }
                return
            }
            Task { await self.handleConnection(fd: clientFD) }
        }
        source.resume()
        acceptSource = source
    }

    // MARK: - Connection handling (nonisolated — runs off main actor)

    nonisolated private func handleConnection(fd: Int32) async {
        defer { Darwin.close(fd) }

        guard let line = socketReadLine(fd: fd),
              let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            socketWriteLine(fd: fd, string: "{\"decision\":\"none\"}")
            return
        }

        let toolName       = json["tool_name"] as? String ?? "Unknown"
        let toolInput      = json["tool_input"] as? [String: Any] ?? [:]
        let sessionId      = json["session_id"] as? String
        let cwd            = (json["cwd"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let pid            = (json["pid"] as? Int).map { pid_t($0) }
        let bundleId       = (json["bundle_id"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let permissionMode = (json["permission_mode"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let agentId        = (json["agent_id"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let agentType      = (json["agent_type"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        // agent_id present ↔ sub-agent call (hook payload contract, 2026-05)
        let isSubAgent     = agentId != nil

        let requestId: UUID
        if let s = json["request_id"] as? String, let uuid = UUID(uuidString: s) {
            requestId = uuid
        } else {
            requestId = UUID()
        }

        // If Claude's runtime mode or static rules already cover this call,
        // let Claude handle it natively — never prompt more than the terminal would.
        switch ClaudePermissionsChecker.check(
            toolName: toolName,
            toolInput: toolInput,
            cwd: cwd,
            permissionMode: permissionMode
        ) {
        case .allow, .deny:
            socketWriteLine(fd: fd, string: "{\"decision\":\"none\"}")
            return
        case .noMatch:
            break
        }

        let summary = ToolSummaryBuilder.summary(toolName: toolName, toolInput: toolInput)

        let isReachable = await MainActor.run { [reachability] in
            guard let pid, let bundleId else { return false }
            return reachability.reachability(pid: pid, bundleId: bundleId) == .reachable
        }

        if isReachable {
            socketWriteLine(fd: fd, string: "{\"decision\":\"none\"}")
            return
        }

        let decision: PermissionDecision = await withCheckedContinuation { continuation in
            Task { @MainActor [weak self] in
                guard let self else {
                    continuation.resume(returning: .none)
                    return
                }

                self.continuations[requestId] = continuation

                switch AppSettings.hookDeliveryStyle {
                case .native:
                    self.sendNativePermissionRequest(
                        id: requestId,
                        toolName: toolName,
                        summary: summary,
                        pid: pid,
                        bundleId: bundleId,
                        isSubAgent: isSubAgent,
                        agentType: agentType
                    )
                    // Fixed timeout just under nc's -w 125 safety window.
                    self.scheduleTimeout(for: requestId, seconds: 120)
                case .popover:
                    let request = PermissionRequest(
                        id: requestId,
                        toolName: toolName,
                        summary: summary,
                        pid: pid,
                        bundleId: bundleId,
                        sessionId: sessionId,
                        receivedAt: Date(),
                        isSubAgent: isSubAgent,
                        agentType: agentType
                    ) { [weak self] d in
                        self?.resolve(id: requestId, decision: d)
                    }
                    self.enqueue(request)
                    let popoverTimeout = min(TimeInterval(AppSettings.permissionApprovalTimeoutSeconds), 110)
                    self.scheduleTimeout(for: requestId, seconds: popoverTimeout)
                }
            }
        }

        socketWriteLine(fd: fd, string: "{\"decision\":\"\(decision.rawValue)\"}")
    }

    // MARK: - Socket I/O helpers

    nonisolated private func socketReadLine(fd: Int32) -> String? {
        var bytes = [UInt8]()
        var ch = UInt8(0)
        while Darwin.read(fd, &ch, 1) == 1 {
            if ch == UInt8(ascii: "\n") { break }
            bytes.append(ch)
            if bytes.count > 65_536 { return nil } // guard against runaway input
        }
        return bytes.isEmpty ? nil : String(bytes: bytes, encoding: .utf8)
    }

    nonisolated private func socketWriteLine(fd: Int32, string: String) {
        var line = string + "\n"
        line.withUTF8 { buf in _ = Darwin.write(fd, buf.baseAddress, buf.count) }
    }
}

enum SocketError: Error {
    case createFailed(Int32)
    case bindFailed(Int32)
    case listenFailed(Int32)
    case pathTooLong
}
