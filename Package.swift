// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CQSatellites",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/gavineadie/SatelliteKit", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "CQSatellites",
            dependencies: ["SatelliteKit"],
            path: "CQSatellites",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CQSatellitesTests",
            dependencies: ["CQSatellites"],
            path: "CQSatellitesTests"
        ),
    ]
)
