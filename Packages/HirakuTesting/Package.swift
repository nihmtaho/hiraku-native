// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HirakuTesting",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "HirakuTesting", targets: ["HirakuTesting"]),
    ],
    dependencies: [
        .package(path: "../HirakuModels"),
    ],
    targets: [
        .target(
            name: "HirakuTesting",
            dependencies: ["HirakuModels"]
        ),
    ]
)
