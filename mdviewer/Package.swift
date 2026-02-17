// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mdviewer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mdviewer", targets: ["mdviewer"])
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0")
    ],
    targets: [
        .executableTarget(
            name: "mdviewer",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "Splash", package: "Splash")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "mdviewerTests",
            dependencies: ["mdviewer"]
        )
    ]
)
