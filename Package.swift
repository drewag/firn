// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Firn",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Firn", targets: ["Firn"]),
        .library(name: "SQL", targets: ["SQL"]),
        .executable(name: "ExampleServer", targets: ["ExampleServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.9.0"),
    ],
    targets: [
        .target(name: "Firn", dependencies: ["NIO","NIOHTTP1"]),
        .testTarget(name: "FirnTests", dependencies: ["Firn"]),

        .target(name: "SQL", dependencies: []),
        .testTarget(name: "SQLTests", dependencies: ["SQL"]),

        .target(name: "ExampleServer", dependencies: ["Firn"]),
    ]
)
