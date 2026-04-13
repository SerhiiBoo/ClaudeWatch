// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeWatch",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeWatch",
            path: "Sources/ClaudeWatch",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ClaudeWatchTests",
            dependencies: ["ClaudeWatch"],
            path: "Tests/ClaudeWatchTests"
        )
    ]
)
