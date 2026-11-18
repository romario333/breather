// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BreatherCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "BreatherCore", targets: ["BreatherCore"]),
    ],
    targets: [
        .target(name: "BreatherCore"),
        .testTarget(name: "BreatherCoreTests", dependencies: ["BreatherCore"]),
    ]
)
