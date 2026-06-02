// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DebugPanel",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "DebugPanel",
            targets: ["DebugPanel"]
        ),
    ],
    targets: [
        .target(
            name: "DebugPanel"
        ),
        .testTarget(
            name: "DebugPanelTests",
            dependencies: ["DebugPanel"]
        ),
    ]
)
