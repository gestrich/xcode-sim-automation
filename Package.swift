// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XCUITestControl",
    platforms: [.iOS(.v17), .macOS(.v15)],
    products: [
        .library(name: "XCUITestControl", targets: ["XCUITestControl"]),
        .library(name: "XCUITestControlModels", targets: ["XCUITestControlModels"]),
        .executable(name: "xcuitest-control", targets: ["xcuitest-control"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "XCUITestControlModels",
            path: "Sources/XCUITestControlModels"
        ),
        .target(
            name: "XCUITestControl",
            dependencies: ["XCUITestControlModels"],
            path: "Sources/XCUITestControl",
            linkerSettings: [.linkedFramework("XCTest")]
        ),
        .executableTarget(
            name: "xcuitest-control",
            dependencies: [
                "XCUITestControlModels",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/xcuitest-control"
        ),
    ]
)
