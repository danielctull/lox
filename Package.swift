// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "lox",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .executable(name: "lox", targets: ["lox"]),
        .library(name: "slox", targets: ["slox"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
    ],
    targets: [

        .target(
            name: "lox",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "slox",
            ]),

        .target(name: "slox"),
    ]
)
