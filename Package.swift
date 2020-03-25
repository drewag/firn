// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Firn",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Firn", targets: ["Firn"]),
        .library(name: "SQLBuilder", targets: ["SQLBuilder"]),
        .executable(name: "ExampleServer", targets: ["ExampleServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.9.0"),
        .package(url: "https://github.com/vapor/postgres-kit", from: "1.5.0"),
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "Firn", dependencies: ["NIO","NIOHTTP1","SQLBuilder","PostgreSQL"]),
        .testTarget(name: "FirnTests", dependencies: ["Firn"]),

        .target(name: "SQLBuilder", dependencies: ["Core"]),
        .testTarget(name: "SQLBuilderTests", dependencies: ["SQLBuilder"]),

        .target(name: "ExampleServer", dependencies: ["Firn"]),
    ]
)
