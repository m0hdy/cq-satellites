// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SatPass",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/gavineadie/SatelliteKit", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SatPass",
            dependencies: ["SatelliteKit"],
            path: "SatPass"
        ),
        .testTarget(
            name: "SatPassTests",
            dependencies: ["SatPass"],
            path: "SatPassTests"
        ),
    ]
)
