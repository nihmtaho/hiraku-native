// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HirakuBridge",
    products: [
        .library(name: "HirakuBridge", targets: ["HirakuBridge"]),
    ],
    targets: [
        .target(
            name: "CHirakuBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "HirakuBridge",
            dependencies: ["CHirakuBridge"]
        ),
    ]
)
