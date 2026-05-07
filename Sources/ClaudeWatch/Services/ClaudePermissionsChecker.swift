import Darwin
import Foundation

/// Reads ~/.claude/settings.json and checks whether a tool call is pre-decided
/// by the user's allow/deny rules or Claude's runtime mode — so we can skip
/// the card and let Claude handle it natively (mimic terminal behavior).
enum ClaudePermissionsChecker {

    enum Result {
        case allow   // auto-allowed → return none, Claude proceeds
        case deny    // auto-denied  → return none, Claude rejects
        case noMatch // no rule covers this call → apply reachability check
    }

    static func check(
        toolName: String,
        toolInput: [String: Any],
        cwd: String?,
        permissionMode: String?
    ) -> Result {
        // Runtime mode takes priority — reflects what Claude is actually doing right now.
        if let mode = permissionMode, !mode.isEmpty {
            if let modeResult = checkPermissionMode(mode) {
                return modeResult
            }
        }
        // Static allow/deny rules from settings files.
        for url in settingsURLs(cwd: cwd) {
            if let result = checkSettings(at: url, toolName: toolName, toolInput: toolInput) {
                return result
            }
        }
        return .noMatch
    }

    // MARK: - Permission mode (from hook payload)

    /// Returns a result when the runtime mode fully decides the call; nil to fall through.
    ///
    // Only bypassPermissions is handled here.
    // - acceptEdits: auto-allows built-in edit tools (Write/Edit/MultiEdit), which never
    //   reach this hook (hook matcher is "Bash|mcp__.*"). Bash + MCP calls are still asked
    //   in acceptEdits mode, so fall-through behavior is correct.
    // - plan: Claude blocks state-mutating tools at its own layer; our response is always
    //   decision:"none" for non-bypassPermissions modes, letting Claude decide natively.
    private static func checkPermissionMode(_ mode: String) -> Result? {
        switch mode {
        case "bypassPermissions":
            // Claude allows everything without prompting — never show card.
            return .allow
        default:
            return nil
        }
    }

    // MARK: - Static settings-based allow/deny

    /// Settings lookup order — most specific first, mirrors Claude Code's own merge order.
    private static func settingsURLs(cwd: String?) -> [URL] {
        var urls: [URL] = []
        if let cwd {
            let cwdURL = URL(fileURLWithPath: cwd)
            urls.append(cwdURL.appendingPathComponent(".claude/settings.local.json"))
            urls.append(cwdURL.appendingPathComponent(".claude/settings.json"))
            urls.append(projectSettingsURL(for: cwd))
        }
        urls.append(globalSettingsURL)
        return urls
    }

    private static func checkSettings(at url: URL, toolName: String, toolInput: [String: Any]) -> Result? {
        guard let json = readSettings(at: url),
              let permissions = json["permissions"] as? [String: Any] else { return nil }
        let allow = permissions["allow"] as? [String] ?? []
        let deny  = permissions["deny"]  as? [String] ?? []
        if allow.contains(where: { ruleMatches($0, toolName: toolName, toolInput: toolInput) }) { return .allow }
        if deny.contains(where:  { ruleMatches($0, toolName: toolName, toolInput: toolInput) }) { return .deny }
        return nil
    }

    // MARK: - Pattern matching

    /// Rule format: "ToolName"  OR  "ToolName(prefix:glob)"
    private static func ruleMatches(_ rule: String, toolName: String, toolInput: [String: Any]) -> Bool {
        guard let parenOpen = rule.firstIndex(of: "(") else {
            return rule == toolName
        }
        guard String(rule[..<parenOpen]) == toolName else { return false }

        let afterOpen  = rule.index(after: parenOpen)
        let parenClose = rule.lastIndex(of: ")") ?? rule.endIndex
        let inner      = String(rule[afterOpen..<parenClose])

        return matchInner(inner, toolName: toolName, toolInput: toolInput)
    }

    /// "prefix:glob"  — command must start with prefix, then glob matches the rest.
    /// "glob"         — glob matched directly against the primary input field.
    private static func matchInner(_ inner: String, toolName: String, toolInput: [String: Any]) -> Bool {
        switch toolName {
        case "Bash":
            guard let command = toolInput["command"] as? String else { return false }
            if let colonIdx = inner.firstIndex(of: ":") {
                let prefix = String(inner[..<colonIdx])
                let glob   = String(inner[inner.index(after: colonIdx)...])
                guard command.hasPrefix(prefix) else { return false }
                let rest = String(command.dropFirst(prefix.count))
                return glob == "*" || glob.isEmpty || globMatch(pattern: glob, string: rest)
            }
            return globMatch(pattern: inner, string: command)

        default:
            // Generic: try matching the glob against any string value in toolInput
            return toolInput.values.compactMap { $0 as? String }.contains {
                globMatch(pattern: inner, string: $0)
            }
        }
    }

    private static func globMatch(pattern: String, string: String) -> Bool {
        fnmatch(pattern, string, 0) == 0
    }

    // MARK: - Settings I/O

    private static var globalSettingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }

    /// Claude encodes the project path by replacing every "/" with "-".
    private static func projectSettingsURL(for cwd: String) -> URL {
        let encoded = cwd.replacingOccurrences(of: "/", with: "-")
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects/\(encoded)/settings.json")
    }

    private static func readSettings(at url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url),
              let obj  = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return obj
    }
}
