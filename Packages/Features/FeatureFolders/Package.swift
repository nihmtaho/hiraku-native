// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureFolders",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "FeatureFolders", targets: ["FeatureFolders"]),
    ],
    dependencies: [
        .package(path: "../../HirakuModels"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../HirakuTesting"),
    ],
    targets: [
        .target(
            name: "FeatureFolders",
            dependencies: ["HirakuModels", "DesignSystem"]
        ),
        .testTarget(
            name: "FeatureFoldersTests",
            dependencies: ["FeatureFolders", "HirakuModels", "HirakuTesting"]
        ),
    ]
)
