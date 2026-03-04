//
//  E2ERenderingTests.swift
//  mdviewer
//
//  End-to-end tests for the full rendering pipeline.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        /// E2E tests covering the full markdown rendering pipeline.
        final class E2ERenderingTests: XCTestCase {
            // MARK: - Full Pipeline Tests

            func testFullDocumentRendering() async {
                let markdown = """
                ---
                title: Test Document
                author: Test Author
                ---
                # Main Title

                Introduction paragraph with **bold** and *italic* text.

                ## Section 1

                - Bullet item 1
                - Bullet item 2
                - Bullet item 3

                > A blockquote for emphasis

                ```swift
                struct Example {
                    let value: Int
                    func describe() -> String {
                        return "Value is \\(value)"
                    }
                }
                ```

                ## Section 2

                1. Ordered item 1
                2. Ordered item 2

                Final paragraph with `inline code`.

                [Link text](https://example.com)
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let result = await MarkdownRenderService.shared.render(request)
                let text = result.attributedString.string

                // Verify frontmatter is stripped
                XCTAssertFalse(text.contains("title: Test Document"))
                XCTAssertFalse(text.contains("author: Test Author"))

                // Verify all content elements
                XCTAssertTrue(text.contains("Main Title"), "Should contain heading")
                XCTAssertTrue(text.contains("Introduction paragraph"), "Should contain paragraph")
                XCTAssertTrue(text.contains("bold"), "Should contain bold text")
                XCTAssertTrue(text.contains("italic"), "Should contain italic text")
                XCTAssertTrue(text.contains("Bullet item 1"), "Should contain bullet items")
                XCTAssertTrue(text.contains("blockquote"), "Should contain blockquote")
                XCTAssertTrue(text.contains("struct Example"), "Should contain code block")
                XCTAssertTrue(text.contains("Ordered item"), "Should contain ordered list")
                XCTAssertTrue(text.contains("inline code"), "Should contain inline code")
                XCTAssertTrue(text.contains("Link text"), "Should contain link text")
            }

            // MARK: - Edge Cases

            func testEmptyDocumentRendering() async {
                let request = RenderRequest(
                    markdown: "",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let result = await MarkdownRenderService.shared.render(request)
                XCTAssertNotNil(result)
                XCTAssertGreaterThanOrEqual(result.attributedString.length, 0)
            }

            func testDocumentWithOnlyFrontmatter() async {
                let markdown = """
                ---
                title: Only Frontmatter
                ---
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let result = await MarkdownRenderService.shared.render(request)
                let text = result.attributedString.string

                XCTAssertFalse(text.contains("title:"))
                XCTAssertFalse(text.contains("Only Frontmatter"))
            }

            func testDocumentWithSpecialCharacters() async {
                let markdown = """
                # Special Characters Test

                Emoji: 🎉 🚀 💻

                Unicode: ñ 中文 العربية

                Math: ∫ ∑ ∏ √

                Code with special chars: `let π = 3.14159`
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let result = await MarkdownRenderService.shared.render(request)
                let text = result.attributedString.string

                XCTAssertTrue(text.contains("🎉"))
                XCTAssertTrue(text.contains("ñ"))
                XCTAssertTrue(text.contains("π"))
            }

            // MARK: - Theme/Style Tests

            func testAllThemesRenderWithoutErrors() async {
                let markdown = "# Test\n\nParagraph with **bold** and *italic*."

                for theme in AppTheme.allCases {
                    for scheme in [ColorScheme.light, ColorScheme.dark] {
                        let request = RenderRequest(
                            markdown: markdown,
                            readerFontFamily: .newYork,
                            readerFontSize: 16,
                            codeFontSize: 14,
                            appTheme: theme,
                            syntaxPalette: .midnight,
                            colorScheme: scheme,
                            textSpacing: .balanced,
                            readableWidth: 760,
                            showLineNumbers: false,
                            typographyPreferences: TypographyPreferences()
                        )

                        let result = await MarkdownRenderService.shared.render(request)
                        XCTAssertTrue(
                            result.attributedString.string.contains("Test"),
                            "Theme \(theme.rawValue) with \(scheme) should render"
                        )
                    }
                }
            }

            // MARK: - Cache Tests

            func testRenderingIsCached() async {
                let markdown = "# Cached Document\n\nContent here."
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                // First render (cold)
                _ = await MarkdownRenderService.shared.render(request)

                // Second render (should be cached)
                let start = Date()
                _ = await MarkdownRenderService.shared.render(request)
                let elapsed = Date().timeIntervalSince(start) * 1000

                // Cached render should be very fast (< 10ms)
                XCTAssertLessThan(elapsed, 10, "Cached render should be nearly instantaneous")
            }
        }
    #endif
#endif
