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
            // MARK: - Integration Tests

            func testAllFontFamiliesRenderWithoutCrash() async {
                let markdown = "# Hello World\nThis is some **bold** text."
                for family in ReaderFontFamily.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: family,
                        readerFontSize: 14,
                        codeFontSize: 14,
                        appTheme: .basic,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                    let result = await MarkdownRenderService.shared.render(request)
                    XCTAssertGreaterThan(result.attributedString.length, 0)
                }
            }

            func testAllFontSizesRenderWithoutCrash() async {
                let markdown = "# Hello World\nThis is some **bold** text."
                for size in [10.0, 14.0, 18.0, 24.0, 32.0] {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .sfPro,
                        readerFontSize: CGFloat(size),
                        codeFontSize: CGFloat(size),
                        appTheme: .basic,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                    let result = await MarkdownRenderService.shared.render(request)
                    XCTAssertGreaterThan(result.attributedString.length, 0)
                }
            }

            func testAllSpacingPresetsRenderWithoutCrash() async {
                let markdown = "# Hello World\nThis is some **bold** text."
                for spacing in ReaderTextSpacing.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .sfPro,
                        readerFontSize: 14,
                        codeFontSize: 14,
                        appTheme: .basic,
                        colorScheme: .light,
                        textSpacing: spacing,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                    let result = await MarkdownRenderService.shared.render(request)
                    XCTAssertGreaterThan(result.attributedString.length, 0)
                }
            }

            func testAllThemesRenderWithoutCrash() async {
                let markdown = "# Hello World\nThis is some **bold** text."
                for theme in AppTheme.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .sfPro,
                        readerFontSize: 14,
                        codeFontSize: 14,
                        appTheme: theme,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                    let result = await MarkdownRenderService.shared.render(request)
                    XCTAssertGreaterThan(result.attributedString.length, 0)
                }
            }

            func testAllThemesRenderSwiftCode() async {
                let markdown = "```swift\nlet x = 1\n```"
                for theme in AppTheme.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .sfPro,
                        readerFontSize: 14,
                        codeFontSize: 14,
                        appTheme: theme,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                    let result = await MarkdownRenderService.shared.render(request)
                    XCTAssertGreaterThan(result.attributedString.length, 0)
                }
            }

            func testEmptyDocumentRendersWithoutCrash() async {
                let request = RenderRequest(
                    markdown: "",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 14,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )
                let result = await MarkdownRenderService.shared.render(request)
                XCTAssertEqual(result.attributedString.length, 0)
            }

            func testWhitespaceOnlyDocumentRendersWithoutCrash() async {
                let request = RenderRequest(
                    markdown: "   \n\n  ",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 14,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )
                let result = await MarkdownRenderService.shared.render(request)
                XCTAssertEqual(result.attributedString.length, 0)
            }

            func testVeryLongLineRendersWithoutCrash() async {
                let markdown = String(repeating: "a", count: 10000)
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 14,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )
                let result = await MarkdownRenderService.shared.render(request)
                XCTAssertGreaterThan(result.attributedString.length, 0)
            }

            func testOrderedListAppearsInOutput() async {
                let markdown = "1. Item 1\n2. Item 2"
                let result = await MarkdownRenderService.shared.render(
                    RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .sfPro,
                        readerFontSize: 14,
                        codeFontSize: 14,
                        appTheme: .basic,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                ).attributedString
                XCTAssertTrue(result.string.contains("1."))
                XCTAssertTrue(result.string.contains("2."))
            }

            func testOrderedListItemsAreIndented() async {
                let markdown = "1. First\n   1. Second"
                let result = await MarkdownRenderService.shared.render(
                    RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .sfPro,
                        readerFontSize: 14,
                        codeFontSize: 14,
                        appTheme: .basic,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                ).attributedString

                // Indentation is added via tabs in BlockSeparatorInjector
                XCTAssertTrue(result.string.contains("\t1."))
            }

            func testTaskListBreaksLinesAndIndentsNestedItems() async {
                let markdown = """
                - [ ] Top task
                - [x] Done task
                  - [ ] Nested task
                    - [x] Deep nested task
                """
                let result = await MarkdownRenderService.shared.render(
                    RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .newYork,
                        readerFontSize: 14,
                        codeFontSize: 14,
                        appTheme: .basic,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                ).attributedString

                let text = result.string

                // insertListMarkers prepends "•\t" to each list item paragraph.
                // BSI adds "\n" between items and "\t" per nesting level before each item.
                XCTAssertTrue(
                    text.contains("•\t[ ] Top task\n"),
                    "Top-level task items should have bullet and line-break"
                )

                // Verified literal diagnostic output:
                // "•\t[ ] Top task\n•\t[x] Done task\n\t•\t[ ] Nested task\n\t\t•\t[x] Deep nested task"

                XCTAssertTrue(
                    text.contains("•\t[x] Done task\n\t•\t[ ] Nested task"),
                    "Done task followed by newline and indented nested task"
                )
                XCTAssertTrue(
                    text.contains("•\t[ ] Nested task\n\t\t•\t[x] Deep nested task"),
                    "Nested task followed by newline and double-indented deep nested task"
                )
            }

            // MARK: - Full document pipeline

            func testFullDocumentPipelineProducesAllBlocks() async {
                let markdown = """
                ---
                title: Test
                ---
                # Heading

                Paragraph with **bold**.

                - List item

                ```swift
                let code = 1
                ```

                > Quote

                ---
                """
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                let result = await MarkdownRenderService.shared.render(request)
                let text = result.attributedString.string

                XCTAssertTrue(text.contains("Heading"))
                XCTAssertTrue(text.contains("Paragraph"))
                XCTAssertTrue(text.contains("List item"))
                XCTAssertTrue(text.contains("let code = 1"))
                XCTAssertTrue(text.contains("Quote"))
            }

            // MARK: - Font specific rendering

            func testMapleMono_bodyTextHasNoBackgroundColor() async {
                let markdown = "This is some plain text without a background."
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .mapleMonoNF,
                    readerFontSize: 14,
                    codeFontSize: 14,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )
                let result = await MarkdownRenderService.shared.render(request)
                let attrString = result.attributedString
                let range = NSRange(location: 0, length: attrString.length)

                attrString.enumerateAttribute(.backgroundColor, in: range, options: []) { value, _, _ in
                    XCTAssertNil(value, "Body text should not have a background color with Maple Mono family")
                }
            }

            func testMapleMono_fencedCodeHasBackgroundColor() async {
                let markdown = "```swift\nlet x = 1\n```"
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .mapleMonoNF,
                    readerFontSize: 14,
                    codeFontSize: 14,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )
                let result = await MarkdownRenderService.shared.render(request)
                let attrString = result.attributedString
                let range = NSRange(location: 0, length: attrString.length)

                var foundBackground = false
                attrString.enumerateAttribute(.backgroundColor, in: range, options: []) { value, _, _ in
                    if value != nil { foundBackground = true }
                }
                XCTAssertTrue(foundBackground, "Fenced code should have a background color even with Maple Mono")
            }

            func testMapleMono_inlineCodeHasBackgroundColor() async {
                let markdown = "Here is `inline code` with Maple Mono."
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .mapleMonoNF,
                    readerFontSize: 14,
                    codeFontSize: 14,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )
                let result = await MarkdownRenderService.shared.render(request)
                let attrString = result.attributedString

                let range = (attrString.string as NSString).range(of: "inline code")
                XCTAssertNotEqual(range.location, NSNotFound)

                let bgColor = attrString.attribute(.backgroundColor, at: range.location, effectiveRange: nil)
                XCTAssertNotNil(bgColor, "Inline code should have a background color with Maple Mono")
            }

            func testNoFontFamilyStampsBackgroundOnBodyText() async {
                let markdown = "Standard paragraph text."
                for family in ReaderFontFamily.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: family,
                        readerFontSize: 14,
                        codeFontSize: 14,
                        appTheme: .basic,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 600,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                    let result = await MarkdownRenderService.shared.render(request)
                    let attrString = result.attributedString

                    attrString.enumerateAttribute(
                        .backgroundColor,
                        in: NSRange(location: 0, length: attrString.length),
                        options: []
                    ) { value, _, _ in
                        XCTAssertNil(value, "Body text should not have background for font family: \(family)")
                    }
                }
            }

            // MARK: - Cache Keys

            func testDifferentThemesProduceDifferentCacheKeys() {
                let base = RenderRequest(
                    markdown: "test",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                let alt = RenderRequest(
                    markdown: "test",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .monokai,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                XCTAssertNotEqual(base.cacheKey, alt.cacheKey)
            }

            func testDifferentColorSchemesProduceDifferentCacheKeys() {
                let base = RenderRequest(
                    markdown: "test",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                let alt = RenderRequest(
                    markdown: "test",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .basic,
                    colorScheme: .dark,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                XCTAssertNotEqual(base.cacheKey, alt.cacheKey)
            }

            func testDifferentFontFamiliesProduceDifferentCacheKeys() {
                let base = RenderRequest(
                    markdown: "test",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                let alt = RenderRequest(
                    markdown: "test",
                    readerFontFamily: .newYork,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 600,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                XCTAssertNotEqual(base.cacheKey, alt.cacheKey)
            }

            func testDifferentReadableWidthsProduceDifferentCacheKeys() {
                let narrow = RenderRequest(
                    markdown: "test",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 400,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                let wide = RenderRequest(
                    markdown: "test",
                    readerFontFamily: .sfPro,
                    readerFontSize: 14,
                    codeFontSize: 12,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 800,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )
                XCTAssertNotEqual(narrow.cacheKey, wide.cacheKey)
            }
        }
    #endif
#endif
