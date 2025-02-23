// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppDependenciesSwift",
    platforms: [
        .macOS(.v13),
        .tvOS(.v16),
        .visionOS(.v1),
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "AppDependencies",
            targets: ["AppDependencies"]),
    ],
    targets: [
        .target(
            name: "AppDependencies"),
        .testTarget(
            name: "AppDependenciesTests",
            dependencies: ["AppDependencies"]
        ),
    ]
)
