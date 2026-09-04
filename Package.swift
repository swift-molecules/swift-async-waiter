// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-async-waiter",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Async Waiter",
            targets: ["Async Waiter"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-molecules/swift-async", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-buffer", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-buffer-ring", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-column", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-memory-allocation", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-memory", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-queue", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-tagged", branch: "main"),
    ],
    targets: [
        .target(
            name: "Async Waiter",
            dependencies: [
                .product(name: "Async", package: "swift-async"),
                .product(name: "Buffer", package: "swift-buffer"),
                .product(name: "Buffer Ring Bounded", package: "swift-buffer-ring"),
                .product(name: "Buffer Ring", package: "swift-buffer-ring"),
                .product(name: "Column", package: "swift-column"),
                .product(name: "Memory Allocator", package: "swift-memory-allocation"),
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Queue", package: "swift-queue"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Async Waiter Tests",
            dependencies: [
                "Async Waiter",
                .product(name: "Async", package: "swift-async"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("RawLayout")
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
