import os.log

private let logger = Logger(subsystem: "io.github.SerhiiBoo.ClaudeWatch", category: "Sprite")

// MARK: - Shared sprite parser

/// Parse a multi-line string into a [[SpriteColor]] grid.
func parseSprite(_ art: String) -> [[SpriteColor]] {
    art.split(separator: "\n")
        .filter { !$0.isEmpty }
        .map { line in
            line.map { char in
                let colorStr = String(char)
                guard let color = SpriteColor(rawValue: colorStr) else {
                    logger.error("Unknown sprite char '\(colorStr)' — check sprite data")
                    assertionFailure("Unknown sprite char '\(colorStr)' — check sprite data")
                    return SpriteColor.clear
                }
                return color
            }
        }
}
