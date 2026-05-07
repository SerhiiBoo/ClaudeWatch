import Foundation

enum ToolSummaryBuilder {
    static func summary(toolName: String, toolInput: [String: Any]) -> String {
        switch toolName {
        case "Bash":
            let cmd = (toolInput["command"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return cmd.count > 60 ? String(cmd.prefix(60)) + "…" : cmd
        case "Edit", "Write", "MultiEdit":
            let path = toolInput["file_path"] as? String ?? toolInput["path"] as? String ?? ""
            let name = URL(fileURLWithPath: path).lastPathComponent
            if let content = toolInput["new_content"] as? String ?? toolInput["content"] as? String {
                let lines = content.components(separatedBy: .newlines).count
                return name.isEmpty ? "\(lines) lines" : "\(name) (\(lines) lines)"
            }
            return name.isEmpty ? toolName : name
        case "NotebookEdit":
            let path = toolInput["notebook_path"] as? String ?? ""
            let name = URL(fileURLWithPath: path).lastPathComponent
            return name.isEmpty ? toolName : name
        default:
            if toolName.hasPrefix("mcp__") {
                let parts = toolName.components(separatedBy: "__").filter { !$0.isEmpty }
                if parts.count >= 3 {
                    let server = parts[1]
                    let tool = parts.dropFirst(2).joined(separator: "__")
                    return "\(server): \(tool)"
                }
            }
            return toolName
        }
    }
}
