// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HirakuModels",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "HirakuModels", targets: ["HirakuModels"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.0"),
    ],
    targets: [
        .target(
            name: "HirakuModels",
            dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf")]
        ),
    ]
)
