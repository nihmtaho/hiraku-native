// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureWords",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "FeatureWords", targets: ["FeatureWords"]),
    ],
    dependencies: [
        .package(path: "../../HirakuModels"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../HirakuTesting"),
    ],
    targets: [
        .target(
            name: "FeatureWords",
            dependencies: ["HirakuModels", "DesignSystem"]
        ),
        .testTarget(
            name: "FeatureWordsTests",
            dependencies: ["FeatureWords", "HirakuModels", "HirakuTesting"]
        ),
    ]
)
