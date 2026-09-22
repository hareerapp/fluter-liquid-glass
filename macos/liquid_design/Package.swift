// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "liquid_design",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "liquid-design", targets: ["liquid_design"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "liquid_design",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [

            ]
        )
    ]
)
