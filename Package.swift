// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XCUITestControl",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "XCUITestControl", targets: ["XCUITestControl"]),
    ],
    targets: [
        .target(
            name: "XCUITestControl",
            path: "Sources/XCUITestControl",
            linkerSettings: [.linkedFramework("XCTest")]
        ),
    ]
)
