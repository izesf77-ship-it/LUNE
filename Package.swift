// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LUNE",
    defaultLocalization: "ru",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LUNE",
            targets: ["LUNE"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LUNE",
            dependencies: [],
            path: "."
        ),
        .testTarget(
            name: "LUNETests",
            dependencies: ["LUNE"],
            path: "Tests"
        )
    ]
)
