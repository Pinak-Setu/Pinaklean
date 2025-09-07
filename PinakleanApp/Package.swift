// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PinakleanCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "PinakleanCore",
            targets: ["PinakleanCore"]
        ),
        // .executable(
        //     name: "pinaklean-cli",
        //     targets: ["PinakleanCLI"]
        // ),
        .executable(
            name: "Pinaklean",
            targets: ["PinakleanApp"]
        ),
    ],
    dependencies: [
        // Database
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.6.1"),
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
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        // Snapshots (guarded in CI)
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.11.0"),
        // DocC plugin
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.3.0"),

        // View Hierarchy Testing
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.9.0"),

        // Auto-updates (temporarily disabled)
        // .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0"),
    ],
    targets: [
        // Core Framework
        .target(
            name: "PinakleanCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
            ],
            path: "Core",
            exclude: ["PrivacyInfo.xcprivacy"],
            resources: [ .process("Resources/Models") ]
        ),

        // CLI Tool (temporarily disabled until compile issues are resolved)
        // .executableTarget(
        //     name: "PinakleanCLI",
        //     dependencies: [
        //         "PinakleanCore",
        //         .product(name: "ArgumentParser", package: "swift-argument-parser"),
        //     ],
        //     path: "CLI"
        // ),

        // macOS App
        .executableTarget(
            name: "PinakleanApp",
            dependencies: [
                "PinakleanCore"
                // .product(name: "Sparkle", package: "Sparkle") // Temporarily disabled
            ]
        ),

        // Tests
        .testTarget(
            name: "PinakleanAppTests",
            dependencies: [
                "PinakleanApp",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
            path: "Tests/App",
            exclude: ["PrivacyInfo.xcprivacy"]
        ),
        // CLI tests disabled while CLI is archived
        // .testTarget(
        //     name: "PinakleanCLITests",
        //     dependencies: [
        //         "PinakleanCLI",
        //         .product(name: "Quick", package: "Quick"),
        //         .product(name: "Nimble", package: "Nimble")
        //     ],
        //     path: "Tests/CLI"
        // ),
    ]
)
