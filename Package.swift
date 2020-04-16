// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-lox",
    products: [
        .executable(name: "slox", targets: ["slox"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
    ],
    targets: [

        .target(
            name: "slox",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
    ]
)
