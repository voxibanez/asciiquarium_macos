// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsciiFishtank",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AsciiFishtank",
            type: .dynamic,
            targets: ["AsciiFishtank"]
        ),
    ],
    targets: [
        .target(
            name: "AsciiFishtank",
            dependencies: [],
            path: "Sources/AsciiFishtank",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Resources/Art")
            ],
            linkerSettings: [
                .linkedFramework("ScreenSaver"),
                .linkedFramework("AppKit"),
                .linkedFramework("QuartzCore")
            ]
        ),
        .testTarget(
            name: "AsciiFishtankTests",
            dependencies: ["AsciiFishtank"],
            path: "Tests/AsciiFishtankTests"
        ),
    ]
)
