// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AnvilSettings",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "AnvilSettings", targets: ["AnvilSettings"])
    ],
    targets: [
        .target(
            name: "AnvilSettings"
        ),
        .testTarget(
            name: "AnvilSettingsTests",
            dependencies: ["AnvilSettings"]
        )
    ],
    swiftLanguageModes: [.v6]
)
