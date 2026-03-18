// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HourlyChime",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HourlyChimeCore", targets: ["HourlyChimeCore"]),
        .executable(name: "HourlyChime", targets: ["HourlyChime"])
    ],
    targets: [
        .target(
            name: "HourlyChimeCore",
            path: "Sources",
            exclude: ["HourlyChime"]
        ),
        .executableTarget(
            name: "HourlyChime",
            dependencies: ["HourlyChimeCore"],
            path: "Sources/HourlyChime",
            sources: ["main.swift"]
        ),
        .executableTarget(
            name: "HourlyChimeChecks",
            dependencies: ["HourlyChimeCore"],
            path: "Tests/HourlyChimeChecks"
        )
    ]
)
