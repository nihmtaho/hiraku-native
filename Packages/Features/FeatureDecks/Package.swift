// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureDecks",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "FeatureDecks", targets: ["FeatureDecks"]),
    ],
    dependencies: [
        .package(path: "../../HirakuModels"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../HirakuTesting"),
    ],
    targets: [
        .target(
            name: "FeatureDecks",
            dependencies: ["HirakuModels", "DesignSystem"]
        ),
        .testTarget(
            name: "FeatureDecksTests",
            dependencies: ["FeatureDecks", "HirakuModels", "HirakuTesting"]
        ),
    ]
)
