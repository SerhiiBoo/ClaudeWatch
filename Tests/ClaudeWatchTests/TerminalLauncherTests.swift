import XCTest
@testable import ClaudeWatch

final class TerminalLauncherTests: XCTestCase {

    // MARK: - shellLaunchCommand: empty directory

    func testKittyNoDirectoryContainsClaude() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .kitty))
        XCTAssertTrue(cmd.contains("claude"), "kitty command without dir should run claude")
        XCTAssertFalse(cmd.contains("-d "), "kitty command without dir should omit -d flag")
    }

    func testAlacrittyNoDirectoryContainsClaude() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .alacritty))
        XCTAssertTrue(cmd.contains("-e claude"))
        XCTAssertFalse(cmd.contains("--working-directory"))
    }

    func testGhosttyNoDirectoryContainsClaude() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .ghostty))
        XCTAssertTrue(cmd.contains("-e claude"))
        XCTAssertFalse(cmd.contains("--working-directory"))
    }

    func testTerminalNoDirectoryUsesOsascript() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .terminal))
        XCTAssertTrue(cmd.contains("osascript"))
        XCTAssertTrue(cmd.contains("Terminal"))
        XCTAssertTrue(cmd.contains("claude"))
    }

    func testVSCodeNoDirectoryUsesOpenFlag() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .vscode))
        XCTAssertTrue(cmd.hasPrefix("open -a"))
        XCTAssertTrue(cmd.contains("Visual Studio Code"))
    }

    // MARK: - shellLaunchCommand: valid directory

    func testKittyWithValidDirectoryIncludesDFlag() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/Users/serge/code"))
        XCTAssertTrue(cmd.contains("-d "))
        XCTAssertTrue(cmd.contains("serge"))
    }

    func testAlacrittyWithValidDirectoryIncludesWorkingDirectory() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .alacritty, directory: "/tmp/foo"))
        XCTAssertTrue(cmd.contains("--working-directory"))
        XCTAssertTrue(cmd.contains("foo"))
    }

    func testTerminalWithValidDirectoryIncludesCd() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .terminal, directory: "/tmp/myproject"))
        XCTAssertTrue(cmd.contains("cd"))
        XCTAssertTrue(cmd.contains("myproject"))
        XCTAssertTrue(cmd.contains("claude"))
    }

    func testVSCodeWithValidDirectoryIncludesPath() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .vscode, directory: "/Users/serge/code"))
        XCTAssertTrue(cmd.contains("serge"))
    }

    // MARK: - shellLaunchCommand: path validation (injection prevention)

    func testPathWithSemicolonReturnsNil() {
        XCTAssertNil(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/tmp/foo;open -a Calculator"))
    }

    func testPathWithDollarSignReturnsNil() {
        XCTAssertNil(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/tmp/$HOME"))
    }

    func testPathWithBacktickReturnsNil() {
        XCTAssertNil(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/tmp/`id`"))
    }

    func testPathWithPipeReturnsNil() {
        XCTAssertNil(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/tmp/foo|bar"))
    }

    func testPathWithAmpersandReturnsNil() {
        XCTAssertNil(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/tmp/foo&&bar"))
    }

    func testPathWithNewlineReturnsNil() {
        XCTAssertNil(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/tmp/foo\nbar"))
    }

    func testPathWithParenthesisReturnsNil() {
        XCTAssertNil(TerminalLauncher.shellLaunchCommand(for: .terminal, directory: "/tmp/foo(bar)"))
    }

    func testPathWithRedirectReturnsNil() {
        XCTAssertNil(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/tmp/foo>bar"))
    }

    // MARK: - shellLaunchCommand: allowlisted characters

    func testPathWithSpaceAllowed() throws {
        // Space is in the allowlist ("/_. ~-" contains a literal space), so paths
        // with spaces in directory names should be accepted and shell-escaped safely.
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/Users/my user/code"))
        XCTAssertTrue(cmd.contains("my user"))
    }

    func testPathWithDotAllowed() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/Users/serge/my.project"))
        XCTAssertTrue(cmd.contains("my.project"))
    }

    func testPathWithHyphenAllowed() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/Users/serge/my-project"))
        XCTAssertTrue(cmd.contains("my-project"))
    }

    func testPathWithTildeAllowed() throws {
        // Tilde in the middle of a path (not shell expansion context)
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/Users/serge/~backup"))
        XCTAssertTrue(cmd.contains("backup"))
    }

    func testPathWithUnderscoreAllowed() throws {
        let cmd = try XCTUnwrap(TerminalLauncher.shellLaunchCommand(for: .kitty, directory: "/Users/serge/my_project"))
        XCTAssertTrue(cmd.contains("my_project"))
    }
}
