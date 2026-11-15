// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            resources: [.copy("Resources")]
        ),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
    ]
)
