//
//  MarkdownRenderLineBreakTests.swift
//  mdviewer
//

//
//  MarkdownRenderLineBreakTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        @testable internal import mdviewer

        /// Suppress deprecation warnings for testing legacy properties
        @available(*, deprecated)

        final class MarkdownRenderLineBreakTests: XCTestCase {
            func testRenderMergesSoftWrappedLinesIntoOneParagraph() async {
                // CommonMark: a single newline within a paragraph is a soft break — the parser
                // joins the lines with a space. Hard breaks require trailing "  " or "\".
                let markdown = "Line one\nLine two"
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString.string
                XCTAssertTrue(
                    text.contains("Line one") && text.contains("Line two"),
                    "Both lines must appear in output"
                )
                XCTAssertFalse(
                    text.contains("Line one\nLine two"),
                    "Soft-wrapped lines must not produce a hard newline in rendered output"
                )
            }

            func testRenderDoesNotForceLineBreaksBeforeListItems() async {
                let markdown = """
                Intro line

                - Item one
                - Item two
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
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString.string
                XCTAssertTrue(text.contains("Item one"))
                XCTAssertTrue(text.contains("Item two"))
                // No spurious blank lines injected before list items
                XCTAssertFalse(
                    text.contains("\n\n- "),
                    "preserveAuthorLineBreaks must not inject hard breaks before list markers"
                )
            }

            func testRenderBlockquoteLinesArePresentInOutput() async {
                // CommonMark: "> line1\n> line2" is a single blockquote paragraph; the parser
                // joins them with a space, not a newline. Both lines must appear in output.
                let markdown = """
                > First quoted line
                > Second quoted line
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
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString.string
                XCTAssertTrue(text.contains("First quoted line"), "First blockquote line must appear")
                XCTAssertTrue(text.contains("Second quoted line"), "Second blockquote line must appear")
            }

            func testTrailingSpacesRenderHardLineBreak() async {
                let markdown = "Line one  \nLine two"
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString.string
                XCTAssertTrue(text.contains("Line one\nLine two"))
                XCTAssertFalse(text.contains("<br>"), "Hard breaks must not render as literal HTML")
            }

            func testBackslashRendersHardLineBreak() async {
                let markdown = "Line one\\\nLine two"
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString.string
                XCTAssertTrue(text.contains("Line one\nLine two"))
                XCTAssertFalse(text.contains("<br>"), "Backslash hard breaks must not render as literal HTML")
            }

            func testHardBreakNotInjectedInsideCodeFence() async {
                // Lines inside a fenced code block must not receive trailing "  " injection.
                let markdown = """
                ```
                line one
                line two
                ```
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
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString.string
                XCTAssertTrue(
                    text.contains("line one\nline two"),
                    "Code fence lines must not have hard breaks injected between them"
                )
            }

            func testHardBreakNotInjectedInsideTildeFence() async {
                // Tilde fences must be tracked independently from backtick fences.
                let markdown = """
                ~~~
                alpha
                beta
                ~~~
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
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString.string
                XCTAssertTrue(
                    text.contains("alpha\nbeta"),
                    "Tilde-fenced code lines must not have hard breaks injected between them"
                )
            }

            func testKernAppliedToAllSpacingPreferences() async {
                // kern is applied with element-specific adjustments — body text uses base value,
                // headings use 80%, code uses 30%, blockquotes get extra 0.3%
                // Test with plain body text to verify base kerning is applied
                let markdown = "Plain body text without any special formatting."

                for spacing in ReaderTextSpacing.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .newYork,
                        readerFontSize: 16,
                        codeFontSize: 14,
                        appTheme: .basic,
                        syntaxPalette: .midnight,
                        colorScheme: .light,
                        textSpacing: spacing,
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )

                    let rendered = await MarkdownRenderService.shared.render(request)
                    let ns = rendered.attributedString
                    let fullRange = NSRange(location: 0, length: ns.length)

                    ns.enumerateAttribute(.kern, in: fullRange) { value, range, _ in
                        let actual = (value as? CGFloat) ?? 0
                        // Plain body text should have base kerning + optical adjustment
                        // For 16pt: optical adjustment is 0.003 (medium range 14-18)
                        let baseKern = spacing.kern(for: 16)
                        let opticalAdjustment = 16 * spacing.opticalSizeAdjustment(for: 16)
                        let expectedKern = baseKern + opticalAdjustment
                        XCTAssertEqual(
                            actual, expectedKern, accuracy: 0.001,
                            "kern mismatch in range \(range) for spacing=\(spacing.rawValue)"
                        )
                    }
                }
            }

            func testLineSpacingAppliedToBodyText() async {
                let markdown = "Body text for spacing validation."
                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .relaxed,
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let ns = rendered.attributedString
                let loc = (ns.string as NSString).range(of: "Body").location
                XCTAssertNotEqual(loc, NSNotFound)

                let style = ns.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle
                XCTAssertNotNil(style, "Body text must have a paragraph style")
                XCTAssertEqual(style?.lineSpacing ?? 0, ReaderTextSpacing.relaxed.lineSpacing(for: 16), accuracy: 0.1)
                XCTAssertEqual(
                    style?.paragraphSpacing ?? 0,
                    ReaderTextSpacing.relaxed.paragraphSpacing(for: 16),
                    accuracy: 0.1
                )
            }
        }
    #endif
#endif
