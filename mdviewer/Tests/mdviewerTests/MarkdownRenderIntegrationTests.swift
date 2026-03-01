//
//  MarkdownRenderIntegrationTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        final class MarkdownRenderIntegrationTests: XCTestCase {
            // MARK: - Private helpers

            private func render(
                _ markdown: String,
                family: ReaderFontFamily = .newYork,
                fontSize: ReaderFontSize = .standard,
                codeFontSize: CodeFontSize = .medium,
                theme: AppTheme = .basic,
                palette: SyntaxPalette = .midnight,
                scheme: ColorScheme = .light,
                spacing: ReaderTextSpacing = .balanced,
                readableWidth: CGFloat = ReaderColumnWidth.balanced.points
            ) async -> NSAttributedString {
                await MarkdownRenderService.shared.render(
                    RenderRequest(
                        markdown: markdown,
                        readerFontFamily: family,
                        readerFontSize: fontSize.points,
                        codeFontSize: CGFloat(codeFontSize.rawValue),
                        appTheme: theme,
                        syntaxPalette: palette,
                        colorScheme: scheme,
                        textSpacing: spacing,
                        readableWidth: readableWidth,
                        showLineNumbers: false
                    )
                ).attributedString
            }

            // MARK: - Robustness

            func testEmptyDocumentRendersWithoutCrash() async {
                let result = await render("")
                XCTAssertGreaterThanOrEqual(result.length, 0)
            }

            func testWhitespaceOnlyDocumentRendersWithoutCrash() async {
                let result = await render("   \n\n\t\n   ")
                XCTAssertGreaterThanOrEqual(result.length, 0)
            }

            func testVeryLongLineRendersWithoutCrash() async {
                let longLine = String(repeating: "word ", count: 200)
                let result = await render(longLine)
                XCTAssertTrue(
                    result.string.contains("word"),
                    "Rendered output should contain the repeated word"
                )
            }

            func testAllFontFamiliesRenderWithoutCrash() async {
                let markdown = "# Heading\n\nParagraph **bold** _italic_"
                for family in ReaderFontFamily.allCases {
                    let result = await render(markdown, family: family)
                    XCTAssertTrue(
                        result.string.contains("Heading"),
                        "\(family.rawValue): output should contain 'Heading'"
                    )
                    XCTAssertTrue(
                        result.string.contains("Paragraph"),
                        "\(family.rawValue): output should contain 'Paragraph'"
                    )
                }
            }

            func testAllSyntaxPalettesRenderSwiftCode() async {
                let markdown = "```swift\nlet x = 42\n```"
                for palette in SyntaxPalette.allCases {
                    let result = await render(markdown, palette: palette)
                    XCTAssertTrue(
                        result.string.contains("let x = 42"),
                        "\(palette.rawValue): output should contain 'let x = 42'"
                    )
                }
            }

            func testAllThemesRenderWithoutCrash() async {
                let markdown = "# Heading\n\n> Blockquote\n\n```\ncode\n```"
                for theme in AppTheme.allCases {
                    for scheme in [ColorScheme.light, ColorScheme.dark] {
                        let result = await render(markdown, theme: theme, scheme: scheme)
                        XCTAssertTrue(
                            result.string.contains("Heading"),
                            "\(theme.rawValue)/\(scheme == .dark ? "dark" : "light"): output should contain 'Heading'"
                        )
                    }
                }
            }

            func testAllSpacingPresetsRenderWithoutCrash() async {
                let markdown = "Paragraph text for spacing test."
                for spacing in ReaderTextSpacing.allCases {
                    let result = await render(markdown, spacing: spacing)
                    XCTAssertTrue(
                        result.string.contains("Paragraph"),
                        "\(spacing.rawValue): output should contain expected text"
                    )
                }
            }

            func testAllFontSizesRenderWithoutCrash() async {
                let markdown = "Sample text for font size test."
                for fontSize in ReaderFontSize.allCases {
                    let result = await render(markdown, fontSize: fontSize)
                    XCTAssertTrue(
                        result.string.contains("Sample"),
                        "\(fontSize.rawValue)pt: output should contain expected text"
                    )
                }
            }

            // MARK: - Ordered list

            func testOrderedListAppearsInOutput() async {
                let markdown = "1. First\n2. Second\n3. Third"
                let result = await render(markdown)
                XCTAssertTrue(result.string.contains("First"), "Output should contain 'First'")
                XCTAssertTrue(result.string.contains("Second"), "Output should contain 'Second'")
                XCTAssertTrue(result.string.contains("Third"), "Output should contain 'Third'")
            }

            func testOrderedListItemsAreIndented() async {
                let markdown = "1. First ordered item\n2. Second ordered item"
                let result = await render(markdown)
                let ns = result.string as NSString
                let loc = ns.range(of: "First ordered item").location
                XCTAssertNotEqual(loc, NSNotFound, "Ordered list item text should appear in output")

                if loc != NSNotFound {
                    let style = result.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle
                    XCTAssertNotNil(style, "Ordered list item should have a paragraph style")
                    XCTAssertGreaterThan(
                        style?.headIndent ?? 0,
                        0,
                        "Ordered list item should have positive headIndent"
                    )
                }
            }

            func testTaskListBreaksLinesAndIndentsNestedItems() async {
                let markdown = """
                - [ ] Top task
                - [x] Done task
                  - [ ] Nested task
                    - [x] Deep nested task
                """

                let result = await render(markdown)
                let text = result.string

                XCTAssertTrue(text.contains("[ ] Top task\n"), "Top-level task items should be line-broken")
                XCTAssertTrue(text.contains("[x] Done task\n\t"), "Nested item should begin on a new indented line")
                XCTAssertTrue(
                    text.contains("\n\t[ ] Nested task\n\t\t"),
                    "Second-level nesting should use tab indentation"
                )
                XCTAssertTrue(text.contains("\n\t\t[x] Deep nested task"), "Deep nested task should be tab-indented")
            }

            // MARK: - Full document pipeline

            func testFullDocumentPipelineProducesAllBlocks() async {
                let markdown = """
                ---
                title: My Document
                author: Test Author
                ---
                # Main Heading

                A paragraph of text here.

                > A blockquote with content.

                - Bullet one
                - Bullet two

                1. Ordered one
                2. Ordered two

                ```swift
                let value = 99
                ```

                Check out [this link](https://example.com) for more.
                """

                let result = await render(markdown)
                let text = result.string

                // Content elements present
                XCTAssertTrue(text.contains("Main Heading"), "H1 heading should appear")
                XCTAssertTrue(text.contains("A paragraph"), "Paragraph should appear")
                XCTAssertTrue(text.contains("A blockquote"), "Blockquote should appear")
                XCTAssertTrue(text.contains("Bullet one"), "First bullet should appear")
                XCTAssertTrue(text.contains("Bullet two"), "Second bullet should appear")
                XCTAssertTrue(text.contains("Ordered one"), "First ordered item should appear")
                XCTAssertTrue(text.contains("Ordered two"), "Second ordered item should appear")
                XCTAssertTrue(text.contains("let value = 99"), "Code block should appear")
                XCTAssertTrue(text.contains("this link"), "Link text should appear")

                // Frontmatter should NOT appear
                XCTAssertFalse(text.contains("My Document"), "Frontmatter title should not appear in rendered output")
                XCTAssertFalse(text.contains("Test Author"), "Frontmatter author should not appear in rendered output")
            }

            // MARK: - Cache key correctness

            func testDifferentThemesProduceDifferentCacheKeys() {
                let base = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                let github = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .github,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                XCTAssertNotEqual(
                    base.cacheKey,
                    github.cacheKey,
                    "Different themes should produce different cache keys"
                )
            }

            func testDifferentPalettesProduceDifferentCacheKeys() {
                let midnight = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                let sunset = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .sunset,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                XCTAssertNotEqual(
                    midnight.cacheKey,
                    sunset.cacheKey,
                    "Different palettes should produce different cache keys"
                )
            }

            func testDifferentColorSchemesProduceDifferentCacheKeys() {
                let light = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                let dark = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .dark,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                XCTAssertNotEqual(
                    light.cacheKey,
                    dark.cacheKey,
                    "Different color schemes should produce different cache keys"
                )
            }

            func testDifferentFontFamiliesProduceDifferentCacheKeys() {
                let newYork = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                let sfPro = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .sfPro,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                XCTAssertNotEqual(
                    newYork.cacheKey,
                    sfPro.cacheKey,
                    "Different font families should produce different cache keys"
                )
            }

            // MARK: - Maple Mono body-font background regression

            /// Regression: when body font is Maple Mono NF (monospaced), applyCodeStyling must NOT
            /// stamp .backgroundColor on regular body text.  The old font-trait detection treated
            /// every monospaced-body paragraph as "code".
            func testMapleMono_bodyTextHasNoBackgroundColor() async {
                let markdown = "Plain body text with no code whatsoever."
                let result = await render(markdown, family: .mapleMonoNF)

                var foundBackground = false
                result.enumerateAttribute(
                    .backgroundColor,
                    in: NSRange(location: 0, length: result.length),
                    options: []
                ) { value, _, _ in
                    if value != nil { foundBackground = true }
                }
                XCTAssertFalse(
                    foundBackground,
                    "Body text with Maple Mono NF font must not receive a .backgroundColor attribute"
                )
            }

            func testMapleMono_inlineCodeHasBackgroundColor() async {
                let markdown = "Use `let x = 42` in your code."
                let result = await render(markdown, family: .mapleMonoNF)

                let loc = (result.string as NSString).range(of: "let x = 42").location
                XCTAssertNotEqual(loc, NSNotFound, "Inline code should appear in rendered output")

                if loc != NSNotFound {
                    let bg = result.attribute(.backgroundColor, at: loc, effectiveRange: nil)
                    XCTAssertNotNil(
                        bg,
                        "Inline code must have .backgroundColor even when body font is Maple Mono NF"
                    )
                }
            }

            func testMapleMono_fencedCodeHasBackgroundColor() async {
                let markdown = "```swift\nlet x = 42\n```"
                let result = await render(markdown, family: .mapleMonoNF)

                let loc = (result.string as NSString).range(of: "let x = 42").location
                XCTAssertNotEqual(loc, NSNotFound, "Fenced code text should appear in rendered output")

                if loc != NSNotFound {
                    let bg = result.attribute(.backgroundColor, at: loc, effectiveRange: nil)
                    XCTAssertNotNil(
                        bg,
                        "Fenced code block must have .backgroundColor even when body font is Maple Mono NF"
                    )
                }
            }

            /// Body text must not receive backgroundColor for any font family.
            func testNoFontFamilyStampsBackgroundOnBodyText() async {
                let markdown = "Just a plain paragraph with no inline code."
                for family in ReaderFontFamily.allCases {
                    let result = await render(markdown, family: family)
                    var foundBackground = false
                    result.enumerateAttribute(
                        .backgroundColor,
                        in: NSRange(location: 0, length: result.length),
                        options: []
                    ) { value, _, _ in
                        if value != nil { foundBackground = true }
                    }
                    XCTAssertFalse(
                        foundBackground,
                        "\(family.rawValue): body text must not receive .backgroundColor"
                    )
                }
            }

            func testDifferentReadableWidthsProduceDifferentCacheKeys() {
                let narrow = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
                let wide = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 860,
                    showLineNumbers: false
                )
                XCTAssertNotEqual(
                    narrow.cacheKey,
                    wide.cacheKey,
                    "Different readable widths should produce different cache keys"
                )
            }
        }
    #endif
#endif
