import Foundation

enum TerminalAppCategory: String, CaseIterable, Identifiable {
    case terminals = "Terminals"
    case editors   = "Editors & IDEs"

    var id: String { rawValue }
}

enum TerminalApp: String, CaseIterable, Identifiable {
    // Terminals
    case terminal  = "Terminal"
    case iterm     = "iTerm"
    case warp      = "Warp"
    case ghostty   = "Ghostty"
    case kitty     = "Kitty"
    case alacritty = "Alacritty"
    case hyper     = "Hyper"
    // Editors & IDEs
    case vscode    = "VS Code"
    case cursor    = "Cursor"
    case zed       = "Zed"
    case phpstorm  = "PhpStorm"
    case windsurf  = "Windsurf"

    var id: String          { rawValue }
    var displayName: String { rawValue }

    var category: TerminalAppCategory {
        switch self {
        case .terminal, .iterm, .warp, .ghostty, .kitty, .alacritty, .hyper:
            return .terminals
        case .vscode, .cursor, .zed, .phpstorm, .windsurf:
            return .editors
        }
    }

    /// Whether this app has a built-in terminal where we can run `claude`.
    var isTerminal: Bool { category == .terminals }
}
