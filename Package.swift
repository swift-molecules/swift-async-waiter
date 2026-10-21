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
        .library(name: "Async Waiter", targets: ["Async Waiter"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-async.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-buffer.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-buffer-ring.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-memory.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-memory-allocation.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-queue.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-tagged.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-storage.git", branch: "main", traits: ["Generational", "Memory"]),
        .package(url: "https://github.com/swift-molecules/swift-buffer-linear.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-ownership-shared.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-store.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Async Waiter",
            dependencies: [
                .product(name: "Async Continuation", package: "swift-async"),
                .product(name: "Async Primitive", package: "swift-async"),
                .product(name: "Buffer", package: "swift-buffer"),
                .product(name: "Buffer Ring Bounded Primitive", package: "swift-buffer-ring"),
                .product(name: "Buffer Ring Primitive", package: "swift-buffer-ring"),
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Memory Allocator", package: "swift-memory-allocation"),
                .product(name: "Memory Allocator Protocol", package: "swift-memory-allocation"),
                .product(name: "Queue", package: "swift-queue"),
                .product(name: "Queue Primitive", package: "swift-queue"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Storage", package: "swift-storage"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear"),
                .product(name: "Memory Allocator Pool", package: "swift-memory-allocation"),
                .product(name: "Memory Pool", package: "swift-memory-allocation"),
                .product(name: "Ownership Shared Primitive", package: "swift-ownership-shared"),
                .product(name: "Store", package: "swift-store"),
            ],
            path: "Sources/Async Waiter"
        ),
        .testTarget(
            name: "Async Waiter Tests",
            dependencies: [
                .product(name: "Async", package: "swift-async"),
                .target(name: "Async Waiter"),
                .product(name: "Queue", package: "swift-queue"),
                .product(name: "Queue Primitive", package: "swift-queue"),
            ],
            path: "Tests/Async Waiter Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
