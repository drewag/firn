// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Firn",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Firn", targets: ["Firn"]),
        .executable(name: "ExampleServer", targets: ["ExampleServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.15.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.10.2"),
    ],
    targets: [
        .target(name: "Firn", dependencies: ["NIOSSL","NIO","NIOHTTP1","NIOWebSocket"]),
        .testTarget(name: "FirnTests", dependencies: ["Firn"]),

        .target(name: "ExampleServer", dependencies: ["Firn"]),
    ]
)
