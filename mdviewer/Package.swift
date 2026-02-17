// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "mdviewer",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .executable(name: "mdviewer", targets: ["mdviewer"])
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "mdviewer",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ]
        ),
        .testTarget(
            name: "mdviewerTests",
            dependencies: ["mdviewer"]
        )
    ]
)
