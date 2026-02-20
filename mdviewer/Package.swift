// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mdviewer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "mdviewer", targets: ["mdviewer"])
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.58.7")
    ],
    targets: [
        .executableTarget(
            name: "mdviewer",
            dependencies: [],
            exclude: ["Info.plist"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "mdviewerTests",
            dependencies: ["mdviewer"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
