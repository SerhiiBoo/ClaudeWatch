// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeWatch",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeWatch",
            path: "Sources/ClaudeWatch"
        )
    ]
)
