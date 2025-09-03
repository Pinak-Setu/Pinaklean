// swift-tools-version: 5.9
import PackageDescription

#if os(Linux)
let package = Package(
    name: "PinakleanCore",
    products: [
        .library(
            name: "PinakleanCore",
            targets: ["PinakleanCore"]
        )
    ],
    targets: [
        .target(
            name: "PinakleanCore",
            path: "CoreLinux"
        ),
        .testTarget(
            name: "PinakleanCoreTests",
            dependencies: ["PinakleanCore"],
            path: "Tests/LinuxTests"
        )
    ]
)
#else
let package = Package(
    name: "PinakleanCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PinakleanCore",
            targets: ["PinakleanCore"]
        ),
        .executable(
            name: "pinaklean-cli",
            targets: ["PinakleanCLI"]
        ),
        .executable(
            name: "Pinaklean",
            targets: ["PinakleanApp"]
        )
    ],
    dependencies: [
        // Database
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.0"),
        // CLI
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
        // Async algorithms
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        // Logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        // Metrics
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.4.0"),
        // Testing
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0")
        // Auto-updates (temporarily disabled)
        // .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0"),
    ],
    targets: [
        .target(
            name: "PinakleanCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics")
            ],
            path: "Core",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "PinakleanCLI",
            dependencies: [
                "PinakleanCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "CLI"
        ),
        .executableTarget(
            name: "PinakleanApp",
            dependencies: [
                "PinakleanCore"
                // .product(name: "Sparkle", package: "Sparkle") // Temporarily disabled
            ]
        ),
        .testTarget(
            name: "PinakleanAppTests",
            dependencies: [
                "PinakleanApp",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble")
            ],
            path: "Tests"
        )
    ]
)
#endif
