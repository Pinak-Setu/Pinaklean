
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PinakleanIOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PinakleanIOSCore",
            targets: ["PinakleanIOSCore"]),
    ],
    dependencies: [
        // Dependencies will be added here as per the master plan
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
    ],
    targets: [
        .target(
            name: "PinakleanIOSCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/PinakleanIOSCore"
        ),
        .testTarget(
            name: "PinakleanIOSCoreTests",
            dependencies: [
                "PinakleanIOSCore",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
            ],
            path: "Tests/PinakleanIOSCoreTests"
        ),
    ]
)
