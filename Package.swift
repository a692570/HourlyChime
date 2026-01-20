// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HourlyChime",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "HourlyChime", targets: ["HourlyChime"])
    ],
    targets: [
        .executableTarget(
            name: "HourlyChime",
            path: "Sources"
        )
    ]
)
