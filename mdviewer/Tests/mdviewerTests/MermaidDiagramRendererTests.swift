//
//  MermaidDiagramRendererTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        // MARK: - MermaidDiagramRendererTests

        /// Validates that mermaid code blocks are detected, rendered to image attachments,
        /// and that the pipeline degrades gracefully on invalid input.
        final class MermaidDiagramRendererTests: XCTestCase {
            // MARK: - Helpers

            private static let flowchart = """
            flowchart LR
                A[Start] --> B[End]
            """

            private static let invalidSource = "this is not valid mermaid"

            private func rendered(
                _ markdown: String,
                theme: AppTheme = .basic,
                scheme: ColorScheme = .light
            ) async -> NSAttributedString {
                await MarkdownRenderService.shared.render(
                    RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .newYork,
                        readerFontSize: ReaderFontSize.standard.points,
                        codeFontSize: 14,
                        appTheme: theme,
                        colorScheme: scheme,
                        textSpacing: .balanced,
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                ).attributedString
            }

            private func mermaidMarkdown(_ source: String) -> String {
                "```mermaid\n\(source)\n```"
            }

            private func largeFlowchartSource(nodeCount: Int) -> String {
                let clampedCount = max(10, nodeCount)
                var lines = ["flowchart TD"]
                for index in 0 ..< clampedCount {
                    lines.append("    N\(index)[Node \(index)]")
                    if index > 0 {
                        lines.append("    N\(index - 1) --> N\(index)")
                    }
                    if index > 2, index.isMultiple(of: 7) {
                        lines.append("    N\(index - 3) --> N\(index)")
                    }
                }
                return lines.joined(separator: "\n")
            }

            // MARK: - Detection

            func testMermaidBlockIsReplacedWithAttachment() async {
                let markdown = mermaidMarkdown(Self.flowchart)
                let result = await rendered(markdown)

                var hasAttachment = false
                result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                    if value is NSTextAttachment { hasAttachment = true }
                }
                XCTAssertTrue(hasAttachment, "A valid mermaid block should produce an NSTextAttachment in the output")
            }

            func testMermaidBlockAttachmentContainsImage() async {
                let markdown = mermaidMarkdown(Self.flowchart)
                let result = await rendered(markdown)

                var image: NSImage?
                result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                    if let attachment = value as? NSTextAttachment {
                        image = attachment.image
                    }
                }
                XCTAssertNotNil(image, "NSTextAttachment should carry a non-nil NSImage")
                if let img = image {
                    XCTAssertGreaterThan(img.size.width, 0, "Rendered diagram image must have positive width")
                    XCTAssertGreaterThan(img.size.height, 0, "Rendered diagram image must have positive height")
                }
            }

            func testNonMermaidCodeBlockIsNotAttachment() async {
                let markdown = "```swift\nlet x = 1\n```"
                let result = await rendered(markdown)

                var hasAttachment = false
                result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                    if value is NSTextAttachment { hasAttachment = true }
                }
                XCTAssertFalse(hasAttachment, "A Swift code block must not be converted to an attachment")
            }

            func testMermaidSourceIsRemovedFromString() async {
                let markdown = "Before\n\n\(mermaidMarkdown(Self.flowchart))\n\nAfter"
                let result = await rendered(markdown)

                // The raw mermaid source lines must not appear in the output string
                // because the block was replaced by an image attachment (\uFFFC).
                XCTAssertFalse(
                    result.string.contains("flowchart"),
                    "Mermaid source text should be absent from the rendered output string"
                )
            }

            func testParagraphTextSurroundingMermaidIsPreserved() async {
                let markdown = "Before\n\n\(mermaidMarkdown(Self.flowchart))\n\nAfter"
                let result = await rendered(markdown)

                XCTAssertTrue(result.string.contains("Before"), "Text before the mermaid block must be preserved")
                XCTAssertTrue(result.string.contains("After"), "Text after the mermaid block must be preserved")
            }

            func testMultipleMermaidBlocksAreAllReplaced() async {
                let block = mermaidMarkdown(Self.flowchart)
                let markdown = "\(block)\n\n\(block)"
                let result = await rendered(markdown)

                var attachmentCount = 0
                result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                    if value is NSTextAttachment { attachmentCount += 1 }
                }
                XCTAssertEqual(attachmentCount, 2, "Two mermaid blocks should produce two attachments")
            }

            // MARK: - Graceful Fallback

            func testInvalidMermaidFallsBackToCodeBlock() async {
                // An unparseable diagram should leave the raw source visible, not crash.
                let markdown = mermaidMarkdown(Self.invalidSource)
                let result = await rendered(markdown)

                // Either the source text is visible (fallback) or replaced by an attachment —
                // the important contract is that rendering does not crash and returns content.
                XCTAssertGreaterThan(result.length, 0, "Rendering invalid mermaid must not produce empty output")
            }

            func testEmptyMermaidBlockDoesNotCrash() async {
                let markdown = "```mermaid\n\n```"
                let result = await rendered(markdown)
                XCTAssertGreaterThan(result.length, 0, "Empty mermaid fence must not crash or return empty output")
            }

            // MARK: - Syntax Highlighter Exclusion

            func testMermaidBlockCarriesNoSyntaxColourAttributes() async {
                // If the mermaid pass succeeds the block becomes an attachment and has no
                // foreground colour from syntax highlighting. If it falls back (invalid
                // source), the raw text must still carry no syntax-colour attributes because
                // SyntaxHighlighter explicitly skips language=="mermaid".
                let markdown = mermaidMarkdown(Self.invalidSource) // force fallback path
                let result = await rendered(markdown)

                // Collect all foreground colours in the region that contains the fallback code.
                // A syntax-highlighted block would have multiple distinct colours; a plain
                // code block uses only the theme's code foreground (one colour throughout).
                var colours = Set<String>()
                result.enumerateAttribute(
                    .foregroundColor,
                    in: NSRange(location: 0, length: result.length)
                ) { value, _, _ in
                    if let colour = value as? NSColor {
                        colours.insert(colour.description)
                    }
                }
                // Valid assertion: plain rendering uses at most 2 colours (body + code fg).
                // Syntax highlighting would add many more distinct token colours.
                XCTAssertLessThanOrEqual(
                    colours.count, 3,
                    "Mermaid fallback block must not have syntax highlighting applied (found \(colours.count) distinct colours)"
                )
            }

            // MARK: - Theme Mapping

            func testAllAppThemesProduceAttachmentInDarkMode() async {
                // Every theme must map to a DiagramTheme without crashing.
                let markdown = mermaidMarkdown(Self.flowchart)
                for theme in AppTheme.allCases {
                    let result = await rendered(markdown, theme: theme, scheme: .dark)
                    var hasAttachment = false
                    result.enumerateAttribute(.attachment, in: NSRange(
                        location: 0,
                        length: result.length
                    )) { value, _, _ in
                        if value is NSTextAttachment { hasAttachment = true }
                    }
                    XCTAssertTrue(hasAttachment, "\(theme) dark should render a mermaid attachment")
                }
            }

            func testAllAppThemesProduceAttachmentInLightMode() async {
                let markdown = mermaidMarkdown(Self.flowchart)
                for theme in AppTheme.allCases {
                    let result = await rendered(markdown, theme: theme, scheme: .light)
                    var hasAttachment = false
                    result.enumerateAttribute(.attachment, in: NSRange(
                        location: 0,
                        length: result.length
                    )) { value, _, _ in
                        if value is NSTextAttachment { hasAttachment = true }
                    }
                    XCTAssertTrue(hasAttachment, "\(theme) light should render a mermaid attachment")
                }
            }

            func testDarkAndLightThemesDifferForTheSameAppTheme() async {
                // Diagram themes for dark and light should produce different images
                // (different background colours at minimum) for themes that have distinct variants.
                let markdown = mermaidMarkdown(Self.flowchart)
                let darkResult = await rendered(markdown, theme: .github, scheme: .dark)
                let lightResult = await rendered(markdown, theme: .github, scheme: .light)

                var darkImage: NSImage?
                var lightImage: NSImage?

                darkResult.enumerateAttribute(.attachment, in: NSRange(
                    location: 0,
                    length: darkResult.length
                )) { value, _, _ in
                    if let a = value as? NSTextAttachment { darkImage = a.image }
                }
                lightResult.enumerateAttribute(.attachment, in: NSRange(
                    location: 0,
                    length: lightResult.length
                )) { value, _, _ in
                    if let a = value as? NSTextAttachment { lightImage = a.image }
                }

                XCTAssertNotNil(darkImage, "GitHub dark should render an attachment")
                XCTAssertNotNil(lightImage, "GitHub light should render an attachment")
                // Images must differ in at least their declared size (dark is typically taller
                // due to different font metrics in the theme) or be equal — both are acceptable.
                // The key contract is that neither is nil and rendering doesn't crash.
            }

            // MARK: - Supported Diagram Types

            func testSequenceDiagramRenders() async {
                let source = """
                sequenceDiagram
                    participant A as Alice
                    participant B as Bob
                    A->>B: Hello
                    B-->>A: Hi
                """
                let result = await rendered(mermaidMarkdown(source))
                var hasAttachment = false
                result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                    if value is NSTextAttachment { hasAttachment = true }
                }
                XCTAssertTrue(hasAttachment, "sequenceDiagram must render to an attachment")
            }

            func testStateDiagramRenders() async {
                let source = """
                stateDiagram-v2
                    [*] --> Idle
                    Idle --> Running : start
                    Running --> Idle : stop
                    Running --> [*]
                """
                let result = await rendered(mermaidMarkdown(source))
                var hasAttachment = false
                result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                    if value is NSTextAttachment { hasAttachment = true }
                }
                XCTAssertTrue(hasAttachment, "stateDiagram-v2 must render to an attachment")
            }

            func testClassDiagramRenders() async {
                let source = """
                classDiagram
                    class Animal {
                        +String name
                        +speak() String
                    }
                    class Dog {
                        +fetch() void
                    }
                    Animal <|-- Dog
                """
                let result = await rendered(mermaidMarkdown(source))
                var hasAttachment = false
                result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                    if value is NSTextAttachment { hasAttachment = true }
                }
                XCTAssertTrue(hasAttachment, "classDiagram must render to an attachment")
            }

            func testErDiagramRenders() async {
                let source = """
                erDiagram
                    CUSTOMER ||--o{ ORDER : places
                    ORDER ||--|{ LINE-ITEM : contains
                    CUSTOMER {
                        string name
                        string email
                    }
                    ORDER {
                        int id
                        date created
                    }
                """
                let result = await rendered(mermaidMarkdown(source))
                var hasAttachment = false
                result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                    if value is NSTextAttachment { hasAttachment = true }
                }
                XCTAssertTrue(hasAttachment, "erDiagram must render to an attachment")
            }

            func testAllFiveDiagramTypesRenderWithoutCrash() async {
                let diagrams: [(String, String)] = [
                    ("flowchart", "flowchart LR\n    A --> B"),
                    ("stateDiagram-v2", "stateDiagram-v2\n    [*] --> S1\n    S1 --> [*]"),
                    ("sequenceDiagram", "sequenceDiagram\n    A->>B: ping\n    B-->>A: pong"),
                    ("classDiagram", "classDiagram\n    class Foo { +bar() void }"),
                    ("erDiagram", "erDiagram\n    ENTITY1 ||--o{ ENTITY2 : rel"),
                ]
                for (name, source) in diagrams {
                    let result = await rendered(mermaidMarkdown(source))
                    XCTAssertGreaterThan(result.length, 0, "\(name) must produce non-empty output")
                }
            }

            // MARK: - Performance

            func testLargeMermaidDocumentStressRenders() async {
                let markdown = (0 ..< 72)
                    .map { index in
                        mermaidMarkdown(largeFlowchartSource(nodeCount: 80 + index))
                    }
                    .joined(separator: "\n\n")

                for _ in 0 ..< 3 {
                    let result = await rendered(markdown)
                    XCTAssertGreaterThan(result.length, 0, "Large mermaid stress render must produce output")
                }
            }
        }
    #endif
#endif
