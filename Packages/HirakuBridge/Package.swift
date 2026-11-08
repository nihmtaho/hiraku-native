// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HirakuBridge",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "HirakuBridge", targets: ["HirakuBridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.0"),
    ],
    targets: [
        .target(
            name: "CHirakuBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "HirakuBridge",
            dependencies: [
                "CHirakuBridge",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            linkerSettings: [
                // hk_* comes from the Go archive linked into the app.
                .unsafeFlags(["-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"]),
            ]
        ),
    ]
)
