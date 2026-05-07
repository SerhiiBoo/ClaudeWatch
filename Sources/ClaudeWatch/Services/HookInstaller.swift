import Foundation

@MainActor
final class HookInstaller {
    static let shared = HookInstaller()

    private let settingsURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".claude/settings.json")
    }()

    private var scriptPath: String? {
        Bundle.module.path(forResource: "claudewatch-hook", ofType: "sh")
    }

    private var hasBackedUp = false

    var isInstalled: Bool {
        guard let script = scriptPath else { return false }
        guard let json = readSettings() else { return false }
        guard let hooks = json["hooks"] as? [String: Any] else { return false }
        return containsEntry(in: hooks, scriptPath: script)
    }

    func install() throws {
        guard let script = scriptPath else {
            throw HookInstallerError.scriptNotFound
        }
        var json = readSettings() ?? [:]
        backup(json: json)
        var hooks = json["hooks"] as? [String: Any] ?? [:]
        for eventName in ["Notification", "Stop"] {
            hooks[eventName] = updatedEntries(for: eventName, in: hooks, scriptPath: script, adding: true)
        }
        hooks["PreToolUse"] = updatedEntries(for: "PreToolUse", in: hooks, scriptPath: script, adding: AppSettings.permissionApprovalEnabled, matcher: "Bash|mcp__.*")
        json["hooks"] = hooks
        try writeSettings(json)
    }

    func uninstall() throws {
        guard let script = scriptPath else { return }
        guard var json = readSettings() else { return }
        guard var hooks = json["hooks"] as? [String: Any] else { return }
        for eventName in ["Notification", "Stop", "PreToolUse"] {
            hooks[eventName] = updatedEntries(for: eventName, in: hooks, scriptPath: script, adding: false)
        }
        json["hooks"] = hooks
        try writeSettings(json)
    }

    func updatePermissionApprovalEntry(enabled: Bool) throws {
        guard let script = scriptPath else { return }
        guard var json = readSettings() else { return }
        var hooks = json["hooks"] as? [String: Any] ?? [:]
        hooks["PreToolUse"] = updatedEntries(for: "PreToolUse", in: hooks, scriptPath: script, adding: enabled, matcher: "Bash|mcp__.*")
        json["hooks"] = hooks
        try writeSettings(json)
    }

    // MARK: - Private

    private func readSettings() -> [String: Any]? {
        guard let data = try? Data(contentsOf: settingsURL),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return obj
    }

    private func writeSettings(_ json: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        let tmp = settingsURL.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        _ = try FileManager.default.replaceItemAt(settingsURL, withItemAt: tmp)
    }

    private func backup(json: [String: Any]) {
        guard !hasBackedUp, !json.isEmpty else { return }
        hasBackedUp = true
        let ts = Int(Date().timeIntervalSince1970)
        let backupURL = settingsURL.appendingPathExtension("bak.\(ts)")
        try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            .write(to: backupURL)
    }

    private func isClaudeWatchCommand(_ cmd: String) -> Bool {
        cmd.hasSuffix("/claudewatch-hook.sh")
    }

    private func updatedEntries(for eventName: String,
                                in hooks: [String: Any],
                                scriptPath: String,
                                adding: Bool,
                                matcher: String? = nil) -> [[String: Any]] {
        var entries = hooks[eventName] as? [[String: Any]] ?? []
        entries.removeAll { entry in
            guard let innerHooks = entry["hooks"] as? [[String: Any]] else { return false }
            return innerHooks.contains { ($0["command"] as? String).map(isClaudeWatchCommand) == true }
        }
        if adding {
            var newEntry: [String: Any] = ["hooks": [["type": "command", "command": scriptPath]]]
            if let matcher { newEntry["matcher"] = matcher }
            entries.append(newEntry)
        }
        return entries
    }

    private func containsEntry(in hooks: [String: Any], scriptPath: String) -> Bool {
        for eventName in ["Notification", "Stop"] {
            guard let entries = hooks[eventName] as? [[String: Any]] else { return false }
            let found = entries.contains { entry in
                guard let innerHooks = entry["hooks"] as? [[String: Any]] else { return false }
                return innerHooks.contains { ($0["command"] as? String).map(isClaudeWatchCommand) == true }
            }
            if !found { return false }
        }
        return true
    }
}

enum HookInstallerError: LocalizedError {
    case scriptNotFound

    var errorDescription: String? {
        switch self {
        case .scriptNotFound:
            return "Hook script not found in app bundle. Reinstall ClaudeWatch."
        }
    }
}
