// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "mdviewer",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "mdviewer", targets: ["mdviewer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.58.7"),
        .package(url: "https://github.com/kyle-n/HighlightedTextEditor", from: "2.1.0"),
        .package(url: "https://github.com/lukilabs/beautiful-mermaid-swift", from: "0.1.1"),
    ],
    targets: [
        .executableTarget(
            name: "mdviewer",
            dependencies: [
                .product(name: "HighlightedTextEditor", package: "HighlightedTextEditor"),
                .product(name: "BeautifulMermaid", package: "beautiful-mermaid-swift"),
            ],
            exclude: ["Info.plist", "Resources", "Design/DESIGN_SYSTEM.md", "Services/Pipeline/PARSER_ARCHITECTURE.md"],
            swiftSettings: swift6Settings
        ),
        .testTarget(
            name: "mdviewerTests",
            dependencies: ["mdviewer"],
            swiftSettings: swift6Settings
        ),
    ]
)

// MARK: - Swift 6 Language Configuration

/// Swift 6 language settings with strict concurrency and modern features enabled.
/// These settings ensure memory safety, data race prevention, and modern Swift patterns.
let swift6Settings: [SwiftSetting] = [
    // Enable Swift 6 language mode for strict concurrency
    .swiftLanguageMode(.v6),

    // Enable upcoming features for better code quality
    .enableUpcomingFeature("StrictConcurrency"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
]
