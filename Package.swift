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
        .library(
            name: "DebugPanelAlamofire",
            targets: ["DebugPanelAlamofire"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.12.0"),
    ],
    targets: [
        .target(
            name: "DebugPanel"
        ),
        .target(
            name: "DebugPanelAlamofire",
            dependencies: [
                "DebugPanel",
                .product(name: "Alamofire", package: "Alamofire"),
            ]
        ),
        .testTarget(
            name: "DebugPanelTests",
            dependencies: ["DebugPanel"]
        ),
        .testTarget(
            name: "DebugPanelAlamofireTests",
            dependencies: ["DebugPanelAlamofire"]
        ),
    ]
)
