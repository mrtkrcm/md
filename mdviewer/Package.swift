// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "mdviewer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(name: "mdviewer", targets: ["mdviewer"])
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0")
    ],
    targets: [
        .executableTarget(
            name: "mdviewer",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "Splash", package: "Splash")
            ],
            resources: [
                .process("Info.plist")
            ]
        ),
        .testTarget(
            name: "mdviewerTests",
            dependencies: ["mdviewer"]
        )
    ]
)
