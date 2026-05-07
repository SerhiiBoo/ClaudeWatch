import XCTest
@testable import ClaudeWatch

final class ToolSummaryBuilderTests: XCTestCase {

    // MARK: - Bash

    func testBashShortCommand() {
        let result = ToolSummaryBuilder.summary(toolName: "Bash", toolInput: ["command": "ls -la"])
        XCTAssertEqual(result, "ls -la")
    }

    func testBashCommandTruncatedAt60() {
        let long = String(repeating: "x", count: 70)
        let result = ToolSummaryBuilder.summary(toolName: "Bash", toolInput: ["command": long])
        XCTAssertEqual(result, String(repeating: "x", count: 60) + "…")
    }

    func testBashCommandExactly60NotTruncated() {
        let exact = String(repeating: "x", count: 60)
        let result = ToolSummaryBuilder.summary(toolName: "Bash", toolInput: ["command": exact])
        XCTAssertEqual(result, exact)
    }

    func testBashCommandTrimsWhitespace() {
        let result = ToolSummaryBuilder.summary(toolName: "Bash", toolInput: ["command": "  npm test  "])
        XCTAssertEqual(result, "npm test")
    }

    func testBashMissingCommandKey() {
        let result = ToolSummaryBuilder.summary(toolName: "Bash", toolInput: [:])
        XCTAssertEqual(result, "")
    }

    // MARK: - Edit / Write / MultiEdit

    func testEditWithFilePathAndContent() {
        let result = ToolSummaryBuilder.summary(
            toolName: "Edit",
            toolInput: ["file_path": "/foo/bar/AppDelegate.swift", "new_content": "line1\nline2\nline3"]
        )
        XCTAssertEqual(result, "AppDelegate.swift (3 lines)")
    }

    func testWriteWithPathKey() {
        let result = ToolSummaryBuilder.summary(
            toolName: "Write",
            toolInput: ["path": "/foo/README.md", "content": "hello"]
        )
        XCTAssertEqual(result, "README.md (1 lines)")
    }

    func testMultiEditNoContent() {
        let result = ToolSummaryBuilder.summary(
            toolName: "MultiEdit",
            toolInput: ["file_path": "/foo/Service.swift"]
        )
        XCTAssertEqual(result, "Service.swift")
    }

    func testEditWithFilePathNoContent() {
        let result = ToolSummaryBuilder.summary(
            toolName: "Edit",
            toolInput: ["file_path": "/src/Service.swift"]
        )
        XCTAssertEqual(result, "Service.swift")
    }

    func testEditNoKeys() {
        let result = ToolSummaryBuilder.summary(toolName: "Edit", toolInput: [:])
        // empty path resolves to a non-empty lastPathComponent — just verify no crash and not empty
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - NotebookEdit

    func testNotebookEditWithPath() {
        let result = ToolSummaryBuilder.summary(
            toolName: "NotebookEdit",
            toolInput: ["notebook_path": "/work/analysis.ipynb"]
        )
        XCTAssertEqual(result, "analysis.ipynb")
    }

    func testNotebookEditMissingPath() {
        // No notebook_path key → falls back to empty string → no crash
        let result = ToolSummaryBuilder.summary(toolName: "NotebookEdit", toolInput: [:])
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - MCP

    func testMcpThreePartName() {
        let result = ToolSummaryBuilder.summary(
            toolName: "mcp__filesystem__read_file",
            toolInput: ["path": "/tmp/x"]
        )
        XCTAssertEqual(result, "filesystem: read_file")
    }

    func testMcpFourPartName() {
        let result = ToolSummaryBuilder.summary(
            toolName: "mcp__server__ns__tool",
            toolInput: [:]
        )
        XCTAssertEqual(result, "server: ns__tool")
    }

    func testMcpTwoPartFallsBack() {
        let result = ToolSummaryBuilder.summary(toolName: "mcp__only", toolInput: [:])
        XCTAssertEqual(result, "mcp__only")
    }

    // MARK: - Unknown tool

    func testUnknownToolReturnsName() {
        let result = ToolSummaryBuilder.summary(toolName: "Glob", toolInput: ["pattern": "**/*.swift"])
        XCTAssertEqual(result, "Glob")
    }
}
