import XCTest
@testable import ClaudeWatch

final class ClaudePermissionsCheckerTests: XCTestCase {

    // MARK: - Helpers

    private var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let claudeDir = tmpDir.appendingPathComponent(".claude")
        try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func writeSettings(_ json: [String: Any], name: String = "settings.json") throws {
        let url = tmpDir.appendingPathComponent(".claude/\(name)")
        let data = try JSONSerialization.data(withJSONObject: json)
        try data.write(to: url)
    }

    private func check(
        toolName: String,
        toolInput: [String: Any] = [:],
        cwd: String? = nil,
        permissionMode: String? = nil
    ) -> ClaudePermissionsChecker.Result {
        ClaudePermissionsChecker.check(
            toolName: toolName,
            toolInput: toolInput,
            cwd: cwd ?? tmpDir.path,
            permissionMode: permissionMode
        )
    }

    // MARK: - No settings → noMatch

    func testNoSettingsFileReturnsNoMatch() {
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"]), .noMatch)
    }

    // MARK: - Exact tool name matching

    func testBareAllowRule() throws {
        try writeSettings(["permissions": ["allow": ["Bash"], "deny": []]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"]), .allow)
    }

    func testBareDenyRule() throws {
        try writeSettings(["permissions": ["allow": [], "deny": ["Bash"]]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"]), .deny)
    }

    func testBareRuleDoesNotMatchDifferentTool() throws {
        try writeSettings(["permissions": ["allow": ["Read"], "deny": []]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"]), .noMatch)
    }

    // MARK: - Allow takes precedence over deny in same file

    func testAllowBeforeDenyWins() throws {
        try writeSettings(["permissions": ["allow": ["Bash"], "deny": ["Bash"]]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"]), .allow)
    }

    // MARK: - Bash prefix:glob rules

    func testBashPrefixGlobAllows() throws {
        try writeSettings(["permissions": ["allow": ["Bash(npm:*)", "Bash(ls:*)"], "deny": []]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "npm install"]), .allow)
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls -la"]), .allow)
    }

    func testBashPrefixGlobDenies() throws {
        try writeSettings(["permissions": ["allow": [], "deny": ["Bash(rm:*)"]]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "rm -rf /"]), .deny)
    }

    func testBashPrefixGlobNoMatchWrongPrefix() throws {
        try writeSettings(["permissions": ["allow": ["Bash(npm:*)"], "deny": []]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "yarn install"]), .noMatch)
    }

    func testBashPrefixStarMatchesAnything() throws {
        try writeSettings(["permissions": ["allow": ["Bash(git:*)"], "deny": []]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "git status"]), .allow)
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "git push origin main"]), .allow)
    }

    func testBashGlobWithoutPrefix() throws {
        try writeSettings(["permissions": ["allow": ["Bash(ls*)"], "deny": []]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls -la"]), .allow)
    }

    // MARK: - MCP tool matching

    func testMcpExactNameAllow() throws {
        try writeSettings(["permissions": ["allow": ["mcp__filesystem__read_file"], "deny": []]])
        let result = check(toolName: "mcp__filesystem__read_file", toolInput: [:])
        XCTAssertEqual(result, .allow)
    }

    func testMcpDifferentNameNoMatch() throws {
        try writeSettings(["permissions": ["allow": ["mcp__filesystem__read_file"], "deny": []]])
        let result = check(toolName: "mcp__filesystem__write_file", toolInput: [:])
        XCTAssertEqual(result, .noMatch)
    }

    // MARK: - Settings file priority (cwd settings.json > global)

    func testLocalSettingsOverridesGlobal() throws {
        // Write cwd settings.local.json that allows, global that denies
        try writeSettings(["permissions": ["allow": ["Bash"], "deny": []]], name: "settings.local.json")
        // Global settings would need real home dir — just verify local file wins
        let result = check(toolName: "Bash", toolInput: ["command": "ls"])
        XCTAssertEqual(result, .allow)
    }

    func testLocalJsonTakesPriorityOverSettingsJson() throws {
        // settings.local.json: allow; settings.json: deny → local wins
        try writeSettings(["permissions": ["allow": ["Bash"], "deny": []]], name: "settings.local.json")
        try writeSettings(["permissions": ["allow": [], "deny": ["Bash"]]])
        let result = check(toolName: "Bash", toolInput: ["command": "ls"])
        XCTAssertEqual(result, .allow)
    }

    func testCwdSettingsJsonUsedWhenNoLocal() throws {
        try writeSettings(["permissions": ["allow": [], "deny": ["Bash"]]])
        let result = check(toolName: "Bash", toolInput: ["command": "ls"])
        XCTAssertEqual(result, .deny)
    }

    // MARK: - Malformed settings

    func testMalformedJsonReturnsNoMatch() throws {
        let url = tmpDir.appendingPathComponent(".claude/settings.json")
        try "not json {{{".write(to: url, atomically: true, encoding: .utf8)
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"]), .noMatch)
    }

    func testEmptyPermissionsReturnsNoMatch() throws {
        try writeSettings(["permissions": [:]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"]), .noMatch)
    }

    func testNoPermissionsKeyReturnsNoMatch() throws {
        try writeSettings(["hooks": []])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"]), .noMatch)
    }

    // MARK: - permissionMode: bypassPermissions

    func testBypassPermissionsAlwaysAllows() {
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "rm -rf /"], permissionMode: "bypassPermissions"), .allow)
        XCTAssertEqual(check(toolName: "mcp__fs__write", toolInput: [:], permissionMode: "bypassPermissions"), .allow)
    }

    func testBypassPermissionsIgnoresStaticDenyRules() throws {
        try writeSettings(["permissions": ["allow": [], "deny": ["Bash"]]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "ls"], permissionMode: "bypassPermissions"), .allow)
    }

    func testNilPermissionModeUsesStaticRules() throws {
        try writeSettings(["permissions": ["allow": ["Bash"], "deny": []]])
        XCTAssertEqual(check(toolName: "Bash", toolInput: ["command": "rm -rf /"], permissionMode: nil), .allow)
    }

    // MARK: - nil cwd falls back to global (no crash)

    func testNilCwdDoesNotCrash() {
        let result = ClaudePermissionsChecker.check(
            toolName: "Bash",
            toolInput: ["command": "ls"],
            cwd: nil,
            permissionMode: nil
        )
        // Smoke test: must not crash when cwd is nil (falls back to global settings).
        // Result varies by machine, so we don't assert a specific value.
        _ = result
    }
}
