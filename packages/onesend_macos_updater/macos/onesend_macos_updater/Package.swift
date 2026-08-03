// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "onesend_macos_updater",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "onesend-macos-updater",
            targets: ["onesend_macos_updater"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            exact: "2.9.5"
        )
    ],
    targets: [
        .target(
            name: "onesend_macos_updater",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Sparkle", package: "Sparkle")
            ]
        )
    ]
)
