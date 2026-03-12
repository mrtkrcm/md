//
//  MarkdownRenderVisualTests.swift
//  mdviewer
//

//
//  MarkdownRenderVisualTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        final class MarkdownRenderVisualTests: XCTestCase {
            // MARK: - Private helpers

            private func rendered(
                _ markdown: String,
                fontSize: ReaderFontSize = .standard,
                codeFontSize: CGFloat = 14,
                theme: AppTheme = .basic,
                syntaxPalette: SyntaxPalette = .midnight,
                scheme: ColorScheme = .light,
                textSpacing: ReaderTextSpacing = .balanced
            ) async -> NSAttributedString {
                await MarkdownRenderService.shared.render(
                    RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .newYork,
                        readerFontSize: fontSize.points,
                        codeFontSize: codeFontSize,
                        appTheme: theme,
                        syntaxPalette: syntaxPalette,
                        colorScheme: scheme,
                        textSpacing: textSpacing,
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                ).attributedString
            }

            private func font(at location: Int, in text: NSAttributedString) -> NSFont? {
                text.attribute(.font, at: location, effectiveRange: nil) as? NSFont
            }

            private func pointSize(at location: Int, in text: NSAttributedString) -> CGFloat {
                font(at: location, in: text)?.pointSize ?? 0
            }

            private func backgroundColor(at location: Int, in text: NSAttributedString) -> NSColor? {
                text.attribute(.backgroundColor, at: location, effectiveRange: nil) as? NSColor
            }

            private func paragraphStyle(at location: Int, in text: NSAttributedString) -> NSParagraphStyle? {
                text.attribute(.paragraphStyle, at: location, effectiveRange: nil) as? NSParagraphStyle
            }

            private func foregroundColor(at location: Int, in text: NSAttributedString) -> NSColor? {
                text.attribute(.foregroundColor, at: location, effectiveRange: nil) as? NSColor
            }

            private func colorsApproxEqual(
                _ lhs: NSColor,
                _ rhs: NSColor,
                tolerance: CGFloat = 0.02
            ) -> Bool {
                guard
                    let a = lhs.usingColorSpace(.deviceRGB),
                    let b = rhs.usingColorSpace(.deviceRGB)
                else { return lhs == rhs }
                return abs(a.redComponent - b.redComponent) <= tolerance
                    && abs(a.greenComponent - b.greenComponent) <= tolerance
                    && abs(a.blueComponent - b.blueComponent) <= tolerance
                    && abs(a.alphaComponent - b.alphaComponent) <= tolerance
            }

            // MARK: - Typography

            func testHeadingFontSizeProgression() async {
                let markdown = """
                # Heading One

                ## Heading Two

                ### Heading Three

                Body paragraph text.
                """

                let result = await rendered(markdown)
                let ns = result.string as NSString

                let h1Loc = ns.range(of: "Heading One").location
                let h2Loc = ns.range(of: "Heading Two").location
                let h3Loc = ns.range(of: "Heading Three").location
                let bodyLoc = ns.range(of: "Body").location

                XCTAssertNotEqual(h1Loc, NSNotFound)
                XCTAssertNotEqual(h2Loc, NSNotFound)
                XCTAssertNotEqual(h3Loc, NSNotFound)
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let h1Size = pointSize(at: h1Loc, in: result)
                let h2Size = pointSize(at: h2Loc, in: result)
                let h3Size = pointSize(at: h3Loc, in: result)
                let bodySize = pointSize(at: bodyLoc, in: result)

                XCTAssertGreaterThan(h1Size, h2Size, "H1 should be larger than H2")
                XCTAssertGreaterThan(h2Size, h3Size, "H2 should be larger than H3")
                XCTAssertGreaterThan(h3Size, bodySize, "H3 should be larger than body text")
            }

            func testBoldTextHasBoldFontTrait() async {
                let markdown = "Normal text **bold text** normal again."
                let result = await rendered(markdown)
                let ns = result.string as NSString

                let boldLoc = ns.range(of: "bold text").location
                XCTAssertNotEqual(boldLoc, NSNotFound)

                let boldFont = font(at: boldLoc, in: result)
                XCTAssertNotNil(boldFont)
                let traits = boldFont?.fontDescriptor.symbolicTraits ?? []
                XCTAssertTrue(traits.contains(.bold), "Bold text should have the .bold symbolic font trait")
            }

            func testItalicTextHasItalicFontTrait() async {
                let markdown = "Normal text _italic text_ normal again."
                let result = await rendered(markdown)
                let ns = result.string as NSString

                let italicLoc = ns.range(of: "italic text").location
                XCTAssertNotEqual(italicLoc, NSNotFound)

                let italicFont = font(at: italicLoc, in: result)
                XCTAssertNotNil(italicFont)
                let traits = italicFont?.fontDescriptor.symbolicTraits ?? []
                XCTAssertTrue(traits.contains(.italic), "Italic text should have the .italic symbolic font trait")
            }

            func testBoldItalicCombinedTextHasBothTraits() async {
                let markdown = "Normal ***bold italic*** text."
                let result = await rendered(markdown)
                let ns = result.string as NSString

                let loc = ns.range(of: "bold italic").location
                XCTAssertNotEqual(loc, NSNotFound)

                let font = font(at: loc, in: result)
                XCTAssertNotNil(font)
                let traits = font?.fontDescriptor.symbolicTraits ?? []
                XCTAssertTrue(traits.contains(.bold), "Combined emphasis should keep bold trait")
                XCTAssertTrue(traits.contains(.italic), "Combined emphasis should keep italic trait")
            }

            func testFontSizeScalesWithReaderPreference() async {
                let markdown = "Body paragraph text for size comparison."

                let largeResult = await rendered(markdown, fontSize: .large)
                let smallResult = await rendered(markdown, fontSize: .small)

                let ns = largeResult.string as NSString
                let bodyLoc = ns.range(of: "Body").location
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let largeSize = pointSize(at: bodyLoc, in: largeResult)
                let smallSize = pointSize(at: bodyLoc, in: smallResult)

                XCTAssertGreaterThan(
                    largeSize,
                    smallSize,
                    "Large font preference should produce larger body text than small"
                )
                XCTAssertGreaterThan(largeSize, 0)
                XCTAssertGreaterThan(smallSize, 0)
            }

            // MARK: - Code styling

            func testCodeFenceUsesMonospaceFont() async {
                let markdown = """
                ```
                let value = 42
                ```
                """

                let result = await rendered(markdown)
                let ns = result.string as NSString

                let codeLoc = ns.range(of: "let value = 42").location
                XCTAssertNotEqual(codeLoc, NSNotFound)

                let codeFont = font(at: codeLoc, in: result)
                XCTAssertNotNil(codeFont)
                let traits = codeFont?.fontDescriptor.symbolicTraits ?? []
                XCTAssertTrue(traits.contains(.monoSpace), "Code fence content should use a monospace font")
            }

            func testCodeFenceHasBackgroundColor() async {
                // Fenced code block background is applied as .backgroundColor on the character run.
                // ReaderLayoutManager reads this attribute and draws a single unified rounded rect.
                let markdown = """
                ```
                let value = 42
                ```
                """

                let result = await rendered(markdown)
                let ns = result.string as NSString

                let codeLoc = ns.range(of: "let value = 42").location
                XCTAssertNotEqual(codeLoc, NSNotFound)

                let bg = backgroundColor(at: codeLoc, in: result)
                XCTAssertNotNil(bg, "Code fence content should have a background color attribute")
            }

            func testInlineCodeHasBackgroundColor() async {
                let markdown = "Use the `inline snippet` function here."

                let result = await rendered(markdown)
                let ns = result.string as NSString

                let inlineLoc = ns.range(of: "inline snippet").location
                XCTAssertNotEqual(inlineLoc, NSNotFound)

                let bg = backgroundColor(at: inlineLoc, in: result)
                XCTAssertNotNil(bg, "Inline code should have a background color attribute")
            }

            func testFootnoteReferenceRendersAsSuperscriptMarker() async {
                let markdown = """
                Reference a note[^1].

                [^1]: Footnote body.
                """

                let result = await rendered(markdown)
                let ns = result.string as NSString
                let footnoteLoc = ns.range(of: "1").location
                let bodyLoc = ns.range(of: "Reference").location
                XCTAssertNotEqual(footnoteLoc, NSNotFound)
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let footnoteFontSize = pointSize(at: footnoteLoc, in: result)
                let bodyFontSize = pointSize(at: bodyLoc, in: result)
                let baselineOffset = result.attribute(
                    .baselineOffset,
                    at: footnoteLoc,
                    effectiveRange: nil
                ) as? NSNumber

                XCTAssertLessThan(footnoteFontSize, bodyFontSize, "Footnote marker should be smaller than body text")
                XCTAssertGreaterThan(baselineOffset?.doubleValue ?? 0, 0, "Footnote marker should be raised")
                XCTAssertFalse(
                    result.string.contains("[^1]"),
                    "Footnote references must not render raw markdown syntax"
                )
            }

            func testFootnoteDefinitionDoesNotRenderRawSyntax() async {
                let markdown = """
                Reference a note[^1].

                [^1]: Footnote with a [link](https://example.com).
                """

                let result = await rendered(markdown)
                XCTAssertTrue(result.string.contains("Footnote with a link."))
                XCTAssertFalse(
                    result.string.contains("[^1]:"),
                    "Footnote definition syntax must be removed from output"
                )
            }

            func testSwiftSyntaxHighlightingKeywordColor() async {
                let markdown = """
                ```swift
                let answer = 42
                ```
                """

                let result = await rendered(markdown, syntaxPalette: .midnight)
                let ns = result.string as NSString

                let keywordLoc = ns.range(of: "let").location
                XCTAssertNotEqual(keywordLoc, NSNotFound)

                let actual = foregroundColor(at: keywordLoc, in: result)
                let expected = SyntaxPalette.midnight.nativeSyntax.keyword

                XCTAssertNotNil(actual)
                if let actual {
                    XCTAssertTrue(
                        colorsApproxEqual(actual, expected),
                        "Swift 'let' keyword should match the midnight palette keyword color"
                    )
                }
            }

            // MARK: - Paragraph style / line spacing

            func testUserLineSpacingAppliedToBodyText() async {
                let markdown = "Body paragraph text for spacing validation."

                let result = await rendered(markdown, textSpacing: .relaxed)
                let ns = result.string as NSString

                let bodyLoc = ns.range(of: "Body").location
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let style = paragraphStyle(at: bodyLoc, in: result)
                XCTAssertNotNil(style)
                // Use dynamic lineSpacing(for:) with standard font size (17pt)
                let expectedLineSpacing = ReaderTextSpacing.relaxed.lineSpacing(for: 17)
                let expectedParagraphSpacing = ReaderTextSpacing.relaxed.paragraphSpacing(for: 17)
                XCTAssertEqual(style?.lineSpacing ?? 0, expectedLineSpacing, accuracy: 0.1)
                XCTAssertEqual(style?.paragraphSpacing ?? 0, expectedParagraphSpacing, accuracy: 0.1)
            }

            func testUserLineSpacingAppliedToListItems() async {
                // List items use lineSpacing from the user preference and a reduced
                // paragraphSpacing (50% of body) to keep items visually distinct.
                let markdown = """
                - First item
                - Second item
                - Third item
                """

                let result = await rendered(markdown, textSpacing: .compact)
                let ns = result.string as NSString

                let itemLoc = ns.range(of: "First item").location
                XCTAssertNotEqual(itemLoc, NSNotFound)

                let style = paragraphStyle(at: itemLoc, in: result)
                XCTAssertNotNil(style, "List items must have a paragraph style")
                // Use dynamic lineSpacing(for:) with standard font size (17pt)
                let expectedLineSpacing = ReaderTextSpacing.compact.lineSpacing(for: 17)
                XCTAssertEqual(style?.lineSpacing ?? 0, expectedLineSpacing, accuracy: 0.1)
                // paragraphSpacing for list items is 50% of the user value.
                let expectedParagraphSpacing = ReaderTextSpacing.compact.paragraphSpacing(for: 17) * 0.5
                XCTAssertEqual(style?.paragraphSpacing ?? 0, expectedParagraphSpacing, accuracy: 0.1)
                // headIndent must be positive — proves indentation was applied.
                XCTAssertGreaterThan(style?.headIndent ?? 0, 0, "List items must be indented")
            }

            func testUserLineSpacingAppliedToHeadings() async {
                // Headings use level-specific line spacing (tighter than body) and
                // generous paragraphSpacing for visual hierarchy.
                let markdown = "# My Heading\n\nSome body text."

                let result = await rendered(markdown, textSpacing: .relaxed)
                let ns = result.string as NSString

                let headingLoc = ns.range(of: "My Heading").location
                XCTAssertNotEqual(headingLoc, NSNotFound)

                let style = paragraphStyle(at: headingLoc, in: result)
                XCTAssertNotNil(style)
                // H1 uses 1.2x line height multiplier (tighter than body for large text)
                // 16 * 2.0 (H1 size) * 1.2 = 38.4; lineSpacing = 38.4 - 32 = 6.4
                XCTAssertGreaterThan(style?.lineSpacing ?? 0, 0, "Headings must have lineSpacing")
                // paragraphSpacingBefore must be substantial (heading pulls space above it).
                XCTAssertGreaterThan(
                    style?.paragraphSpacingBefore ?? 0,
                    0,
                    "Headings must have paragraphSpacingBefore > 0"
                )
            }

            func testListItemWithHeadingSyntaxDoesNotBecomeRenderedHeading() async {
                let markdown = """
                ## Real Heading

                - ## HTML Entities and Special Characters
                - Plain list item
                """

                let result = await rendered(markdown)
                let ns = result.string as NSString

                let realHeadingLoc = ns.range(of: "Real Heading").location
                let pseudoHeadingLoc = ns.range(of: "## HTML Entities and Special Characters").location
                let plainItemLoc = ns.range(of: "Plain list item").location

                XCTAssertNotEqual(realHeadingLoc, NSNotFound)
                XCTAssertNotEqual(pseudoHeadingLoc, NSNotFound)
                XCTAssertNotEqual(plainItemLoc, NSNotFound)

                let realHeadingLevel = result.attribute(
                    MarkdownRenderAttribute.headingLevel,
                    at: realHeadingLoc,
                    effectiveRange: nil
                ) as? Int
                let pseudoHeadingLevel = result.attribute(
                    MarkdownRenderAttribute.headingLevel,
                    at: pseudoHeadingLoc,
                    effectiveRange: nil
                ) as? Int

                XCTAssertEqual(realHeadingLevel, 2, "Real heading should keep heading metadata")
                XCTAssertNil(
                    pseudoHeadingLevel,
                    "List items that start with '- ##' must not become rendered heading anchors"
                )
                XCTAssertTrue(
                    result.string.contains("## HTML Entities and Special Characters"),
                    "List-contained heading syntax should remain visible as literal text"
                )
                XCTAssertEqual(
                    pointSize(at: pseudoHeadingLoc, in: result),
                    pointSize(at: plainItemLoc, in: result),
                    accuracy: 0.1,
                    "List-contained heading syntax should keep normal list-item typography"
                )
            }

            // MARK: - Themes

            func testDarkModeCodeBackgroundDifferentFromLight() async {
                let markdown = """
                ```
                let x = 1
                ```
                """

                let light = await rendered(markdown, scheme: .light)
                let dark = await rendered(markdown, scheme: .dark)

                let ns = light.string as NSString
                let codeLoc = ns.range(of: "let x = 1").location
                XCTAssertNotEqual(codeLoc, NSNotFound)

                let lightBg = backgroundColor(at: codeLoc, in: light)
                let darkBg = backgroundColor(at: codeLoc, in: dark)

                XCTAssertNotNil(lightBg, "Light mode code block must have a background")
                XCTAssertNotNil(darkBg, "Dark mode code block must have a background")

                if let lightBg, let darkBg {
                    XCTAssertFalse(
                        colorsApproxEqual(lightBg, darkBg),
                        "Dark mode code background should differ from light mode"
                    )
                }
            }

            func testGitHubThemeCodeBackgroundDiffersFromBasic() async {
                let markdown = """
                ```
                let x = 1
                ```
                """

                let basic = await rendered(markdown, theme: .basic, scheme: .light)
                let github = await rendered(markdown, theme: .github, scheme: .light)

                let ns = basic.string as NSString
                let codeLoc = ns.range(of: "let x = 1").location
                XCTAssertNotEqual(codeLoc, NSNotFound)

                let basicBg = backgroundColor(at: codeLoc, in: basic)
                let githubBg = backgroundColor(at: codeLoc, in: github)

                XCTAssertNotNil(basicBg, "Basic theme code block must have a background")
                XCTAssertNotNil(githubBg, "GitHub theme code block must have a background")

                if let basicBg, let githubBg {
                    XCTAssertFalse(
                        colorsApproxEqual(basicBg, githubBg, tolerance: 0.005),
                        "GitHub theme code background should differ from Basic theme"
                    )
                }
            }

            // MARK: - Heading scale ratios

            func testH1FontSizeIs1Point75TimesBody() async {
                // Heading scale for H1 is 1.75× body for clear hierarchy.
                let markdown = "# H1 Heading\n\nBody text."
                let result = await rendered(markdown, fontSize: .standard)
                let ns = result.string as NSString

                let h1Loc = ns.range(of: "H1 Heading").location
                let bodyLoc = ns.range(of: "Body text").location
                XCTAssertNotEqual(h1Loc, NSNotFound)
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let h1Size = pointSize(at: h1Loc, in: result)
                let bodySize = pointSize(at: bodyLoc, in: result)
                XCTAssertGreaterThan(bodySize, 0)
                // Accept ±1 pt tolerance for font rounding.
                XCTAssertEqual(
                    h1Size,
                    bodySize * 1.75,
                    accuracy: 1.0,
                    "H1 should be 1.75× body size (got h1=\(h1Size) body=\(bodySize))"
                )
            }

            func testH2FontSizeIs1Point5TimesBody() async {
                // H2 is 1.5x body for clear visual hierarchy
                let markdown = "## H2 Heading\n\nBody text."
                let result = await rendered(markdown, fontSize: .standard)
                let ns = result.string as NSString

                let h2Loc = ns.range(of: "H2 Heading").location
                let bodyLoc = ns.range(of: "Body text").location
                XCTAssertNotEqual(h2Loc, NSNotFound)
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let h2Size = pointSize(at: h2Loc, in: result)
                let bodySize = pointSize(at: bodyLoc, in: result)
                XCTAssertGreaterThan(bodySize, 0)
                XCTAssertEqual(
                    h2Size,
                    bodySize * 1.5,
                    accuracy: 1.0,
                    "H2 should be 1.5× body size (got h2=\(h2Size) body=\(bodySize))"
                )
            }

            func testH3FontSizeIs1Point3TimesBody() async {
                // H3 is 1.3x body for clear visual hierarchy
                let markdown = "### H3 Heading\n\nBody text."
                let result = await rendered(markdown, fontSize: .standard)
                let ns = result.string as NSString

                let h3Loc = ns.range(of: "H3 Heading").location
                let bodyLoc = ns.range(of: "Body text").location
                XCTAssertNotEqual(h3Loc, NSNotFound)
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let h3Size = pointSize(at: h3Loc, in: result)
                let bodySize = pointSize(at: bodyLoc, in: result)
                XCTAssertGreaterThan(bodySize, 0)
                XCTAssertEqual(
                    h3Size,
                    bodySize * 1.3,
                    accuracy: 1.0,
                    "H3 should be 1.3× body size (got h3=\(h3Size) body=\(bodySize))"
                )
            }

            func testH4FontSizeIs1Point15TimesBody() async {
                // H4 is 1.15x body for clear visual hierarchy
                let markdown = "#### H4 Heading\n\nBody text."
                let result = await rendered(markdown, fontSize: .standard)
                let ns = result.string as NSString

                let h4Loc = ns.range(of: "H4 Heading").location
                let bodyLoc = ns.range(of: "Body text").location
                XCTAssertNotEqual(h4Loc, NSNotFound)
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let h4Size = pointSize(at: h4Loc, in: result)
                let bodySize = pointSize(at: bodyLoc, in: result)
                XCTAssertGreaterThan(bodySize, 0)
                XCTAssertEqual(
                    h4Size,
                    bodySize * 1.15,
                    accuracy: 1.0,
                    "H4 should be 1.15× body size (got h4=\(h4Size) body=\(bodySize))"
                )
            }

            // MARK: - Theme heading colors

            func testHeadingsHaveThemeColor() async {
                let markdown = "# Heading One\n\nBody text."
                let github = await rendered(markdown, theme: .github, scheme: .light)
                let ns = github.string as NSString

                let headingLoc = ns.range(of: "Heading One").location
                let bodyLoc = ns.range(of: "Body text").location
                XCTAssertNotEqual(headingLoc, NSNotFound)
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let headingColor = foregroundColor(at: headingLoc, in: github)
                let bodyColor = foregroundColor(at: bodyLoc, in: github)

                XCTAssertNotNil(headingColor)
                XCTAssertNotNil(bodyColor)

                // GitHub light theme: heading should be darker than body
                if
                    let h = headingColor?.usingColorSpace(.deviceRGB),
                    let b = bodyColor?.usingColorSpace(.deviceRGB)
                {
                    let headingLuma = h.redComponent * 0.299 + h.greenComponent * 0.587 + h.blueComponent * 0.114
                    let bodyLuma = b.redComponent * 0.299 + b.greenComponent * 0.587 + b.blueComponent * 0.114
                    XCTAssertLessThan(headingLuma, bodyLuma, "GitHub light theme headings should be darker than body")
                }
            }

            func testHeadingLevelsUseDistinctColors() async {
                let markdown = """
                # H1
                ## H2
                ### H3
                """
                let result = await rendered(markdown, theme: .dracula, scheme: .dark)
                let ns = result.string as NSString

                let h1Loc = ns.range(of: "H1").location
                let h2Loc = ns.range(of: "H2").location
                let h3Loc = ns.range(of: "H3").location
                XCTAssertNotEqual(h1Loc, NSNotFound)
                XCTAssertNotEqual(h2Loc, NSNotFound)
                XCTAssertNotEqual(h3Loc, NSNotFound)

                let h1 = foregroundColor(at: h1Loc, in: result)
                let h2 = foregroundColor(at: h2Loc, in: result)
                let h3 = foregroundColor(at: h3Loc, in: result)
                XCTAssertNotNil(h1)
                XCTAssertNotNil(h2)
                XCTAssertNotNil(h3)

                if let h1, let h2, let h3 {
                    XCTAssertFalse(colorsApproxEqual(h1, h2), "H1 and H2 should use distinct heading colors")
                    XCTAssertFalse(colorsApproxEqual(h2, h3), "H2 and H3 should use distinct heading colors")
                }
            }

            func testHeadingsDifferentAcrossThemes() async {
                let markdown = "# Test Heading"
                let github = await rendered(markdown, theme: .github, scheme: .light)
                let docC = await rendered(markdown, theme: .docC, scheme: .light)

                let ns = github.string as NSString
                let loc = ns.range(of: "Test Heading").location
                XCTAssertNotEqual(loc, NSNotFound)

                let githubColor = foregroundColor(at: loc, in: github)
                let docCColor = foregroundColor(at: loc, in: docC)

                XCTAssertNotNil(githubColor)
                XCTAssertNotNil(docCColor)

                if let g = githubColor, let d = docCColor {
                    XCTAssertFalse(
                        colorsApproxEqual(g, d),
                        "GitHub and DocC themes should have different heading colors"
                    )
                }
            }

            // MARK: - Theme link colors

            func testLinksHaveThemeColor() async {
                let markdown = "Check out [this link](https://example.com) here."
                let github = await rendered(markdown, theme: .github, scheme: .light)
                let ns = github.string as NSString

                let linkLoc = ns.range(of: "this link").location
                let bodyLoc = ns.range(of: "Check out").location
                XCTAssertNotEqual(linkLoc, NSNotFound)
                XCTAssertNotEqual(bodyLoc, NSNotFound)

                let linkColor = foregroundColor(at: linkLoc, in: github)
                let bodyColor = foregroundColor(at: bodyLoc, in: github)

                XCTAssertNotNil(linkColor)
                XCTAssertNotNil(bodyColor)

                // Link color should be different from body text color (blue-ish in GitHub)
                if let l = linkColor?.usingColorSpace(.deviceRGB) {
                    // GitHub links are blue (higher blue component than red)
                    XCTAssertGreaterThan(l.blueComponent, l.redComponent, "GitHub links should be blue-ish")
                }

                let underlineStyle = github.attribute(.underlineStyle, at: linkLoc, effectiveRange: nil) as? Int
                XCTAssertEqual(
                    underlineStyle,
                    NSUnderlineStyle.single.rawValue,
                    "Links should use single underline styling"
                )
            }

            func testLinksDifferentAcrossThemes() async {
                let markdown = "[Link text](https://example.com)"
                let github = await rendered(markdown, theme: .github, scheme: .light)
                let docC = await rendered(markdown, theme: .docC, scheme: .light)

                let ns = github.string as NSString
                let loc = ns.range(of: "Link text").location
                XCTAssertNotEqual(loc, NSNotFound)

                let githubColor = foregroundColor(at: loc, in: github)
                let docCColor = foregroundColor(at: loc, in: docC)

                XCTAssertNotNil(githubColor)
                XCTAssertNotNil(docCColor)

                if let g = githubColor, let d = docCColor {
                    XCTAssertFalse(
                        colorsApproxEqual(g, d, tolerance: 0.01),
                        "GitHub and DocC themes should have different link colors"
                    )
                }
            }

            // MARK: - Inline code vs fenced code backgrounds

            func testInlineCodeHasDistinctBackgroundFromFenced() async {
                let markdown = "Use `inline code` here.\n\n```\nfenced code\n```"
                let github = await rendered(markdown, theme: .github, scheme: .light)
                let ns = github.string as NSString

                let inlineLoc = ns.range(of: "inline code").location
                let fencedLoc = ns.range(of: "fenced code").location
                XCTAssertNotEqual(inlineLoc, NSNotFound)
                XCTAssertNotEqual(fencedLoc, NSNotFound)

                let inlineBg = backgroundColor(at: inlineLoc, in: github)
                let fencedBg = backgroundColor(at: fencedLoc, in: github)

                XCTAssertNotNil(inlineBg)
                XCTAssertNotNil(fencedBg)

                // Both should have backgrounds
                if let i = inlineBg, let f = fencedBg {
                    // They may be the same or different, but both should exist
                    XCTAssertGreaterThan(i.alphaComponent, 0, "Inline code should have visible background")
                    XCTAssertGreaterThan(f.alphaComponent, 0, "Fenced code should have visible background")
                }
            }

            // MARK: - Theme text color baseline

            func testBodyTextReceivesLabelColor() async {
                // The renderer applies labelColor as the default foreground across the full range.
                // This test verifies plain body text gets a non-nil foreground attribute set.
                let markdown = "Plain body text with no special formatting."
                let result = await rendered(markdown)
                let ns = result.string as NSString

                let loc = ns.range(of: "Plain body").location
                XCTAssertNotEqual(loc, NSNotFound)

                let color = foregroundColor(at: loc, in: result)
                XCTAssertNotNil(color, "Body text must have a foreground color attribute after rendering")
            }

            func testSyntaxColorDoesNotLeakIntoBodyText() async {
                // Keyword colors from code spans must not bleed into adjacent body text.
                let markdown = """
                ```swift
                let x = 1
                ```

                Plain paragraph after code.
                """
                let result = await rendered(markdown, syntaxPalette: .midnight)
                let ns = result.string as NSString

                let paragraphLoc = ns.range(of: "Plain paragraph").location
                XCTAssertNotEqual(paragraphLoc, NSNotFound)

                let paragraphColor = foregroundColor(at: paragraphLoc, in: result)
                let keywordColor = SyntaxPalette.midnight.nativeSyntax.keyword
                XCTAssertNotNil(paragraphColor)
                if let paragraphColor {
                    XCTAssertFalse(
                        colorsApproxEqual(paragraphColor, keywordColor),
                        "Body text after a code block must not inherit keyword syntax color"
                    )
                }
            }

            // MARK: - Content

            func testFrontmatterNotInRenderedOutput() async {
                let markdown = """
                ---
                title: Secret Title
                category: internal
                author: hidden-author
                ---
                # Visible Heading

                This content should appear.
                """

                let result = await rendered(markdown)
                let text = result.string

                XCTAssertTrue(text.contains("Visible Heading"), "Visible heading should appear in rendered output")
                XCTAssertTrue(text.contains("This content"), "Body text should appear in rendered output")
                XCTAssertFalse(
                    text.contains("Secret Title"),
                    "Frontmatter title value should not appear in rendered output"
                )
                XCTAssertFalse(
                    text.contains("category:"),
                    "Frontmatter category key should not appear in rendered output"
                )
                XCTAssertFalse(
                    text.contains("hidden-author"),
                    "Frontmatter author value should not appear in rendered output"
                )
            }

            // MARK: - Blockquote rendering

            //
            // Blockquote decoration (left accent bar + tinted background) is now drawn by
            // ReaderLayoutManager using custom attribute keys rather than NSTextBlock.

            private let bqDepthKey = NSAttributedString.Key("mdv.blockquoteDepth")
            private let bqAccentKey = NSAttributedString.Key("mdv.blockquoteAccent")
            private let bqBgKey = NSAttributedString.Key("mdv.blockquoteBackground")
            private let tableHeaderBgKey = NSAttributedString.Key("mdv.tableHeaderBackground")
            private let tableRowBgKey = NSAttributedString.Key("mdv.tableRowBackground")
            private let tableBorderKey = NSAttributedString.Key("mdv.tableBorder")
            private let tableRowAlternatingKey = NSAttributedString.Key("mdv.tableRowAlternating")
            private let taskListCheckedKey = NSAttributedString.Key("mdv.taskListChecked")

            func testBlockquoteHasDepthAttribute() async {
                let markdown = "> This is a quoted line."
                let result = await rendered(markdown)
                let ns = result.string as NSString
                let loc = ns.range(of: "This is a quoted").location
                XCTAssertNotEqual(loc, NSNotFound, "Blockquote text must appear in output")

                let depth = result.attribute(bqDepthKey, at: loc, effectiveRange: nil) as? Int
                XCTAssertNotNil(depth, "Blockquote run must carry mdv.blockquoteDepth attribute")
                XCTAssertEqual(depth, 1, "Single blockquote must have depth 1")
            }

            func testBlockquoteHasBackground() async {
                let markdown = "> Quoted text with background."
                let result = await rendered(markdown, theme: .github, scheme: .light)
                let ns = result.string as NSString
                let loc = ns.range(of: "Quoted text").location
                XCTAssertNotEqual(loc, NSNotFound)

                let bg = result.attribute(bqBgKey, at: loc, effectiveRange: nil) as? NSColor
                XCTAssertNotNil(bg, "Blockquote must have mdv.blockquoteBackground attribute")
                var a: CGFloat = 0
                bg?.getRed(nil, green: nil, blue: nil, alpha: &a)
                XCTAssertGreaterThan(a, 0, "Blockquote background must not be fully transparent")
            }

            func testBlockquoteHasAccentColor() async {
                let markdown = "> Quoted text with left border."
                let result = await rendered(markdown, theme: .github, scheme: .light)
                let ns = result.string as NSString
                let loc = ns.range(of: "Quoted text with left").location
                XCTAssertNotEqual(loc, NSNotFound)

                let accent = result.attribute(bqAccentKey, at: loc, effectiveRange: nil) as? NSColor
                XCTAssertNotNil(accent, "Blockquote must have mdv.blockquoteAccent attribute")
            }

            // MARK: - Table + task list rendering

            func testTableRowsCarryThemeAttributes() async {
                let markdown = """
                | Name | Status |
                | --- | --- |
                | Parser | Done |
                | Viewer | WIP |
                """

                let result = await rendered(markdown, theme: .github, scheme: .light)
                let ns = result.string as NSString

                let headerLoc = ns.range(of: "Name").location
                let firstRowLoc = ns.range(of: "Parser").location
                let secondRowLoc = ns.range(of: "Viewer").location
                XCTAssertNotEqual(headerLoc, NSNotFound)
                XCTAssertNotEqual(firstRowLoc, NSNotFound)
                XCTAssertNotEqual(secondRowLoc, NSNotFound)

                let headerBg = result.attribute(tableHeaderBgKey, at: headerLoc, effectiveRange: nil) as? NSColor
                let headerBorder = result.attribute(tableBorderKey, at: headerLoc, effectiveRange: nil) as? NSColor
                XCTAssertNotNil(headerBg, "Table header should carry themed header background attribute")
                XCTAssertNotNil(headerBorder, "Table header should carry table border attribute")

                let firstRowHasBorder = result.attribute(
                    tableBorderKey,
                    at: firstRowLoc,
                    effectiveRange: nil
                ) as? NSColor
                let firstRowAlternating = result.attribute(
                    tableRowAlternatingKey,
                    at: firstRowLoc,
                    effectiveRange: nil
                ) as? Bool
                XCTAssertNotNil(firstRowHasBorder, "Table row should carry border attribute")
                XCTAssertEqual(firstRowAlternating, false, "First body row should not be alternating")

                let secondRowBg = result.attribute(tableRowBgKey, at: secondRowLoc, effectiveRange: nil) as? NSColor
                let secondRowAlternating = result.attribute(
                    tableRowAlternatingKey,
                    at: secondRowLoc,
                    effectiveRange: nil
                ) as? Bool
                XCTAssertEqual(secondRowAlternating, true, "Second body row should be alternating")
                XCTAssertNotNil(secondRowBg, "Alternating table row should carry row background attribute")
            }

            func testTableParagraphStyleUsesEnhancedSpacingAndInset() async {
                let markdown = """
                | Name | Status | Notes |
                | --- | --- | --- |
                | Parser | Done | Stable |
                """

                let result = await rendered(markdown, theme: .github, scheme: .light)
                let ns = result.string as NSString
                let rowLoc = ns.range(of: "Parser").location
                XCTAssertNotEqual(rowLoc, NSNotFound)

                let style = paragraphStyle(at: rowLoc, in: result)
                XCTAssertNotNil(style, "Table rows should include paragraph styling")
                XCTAssertEqual(style?.headIndent ?? 0, 16, accuracy: 0.1, "Table rows should use wider inset")
                XCTAssertEqual(style?.firstLineHeadIndent ?? 0, 16, accuracy: 0.1)
                XCTAssertGreaterThanOrEqual(style?.paragraphSpacing ?? 0, 5, "Table rows should have improved spacing")
                XCTAssertGreaterThanOrEqual(
                    style?.tabStops.first?.location ?? 0,
                    120,
                    "First table tab stop should be roomy"
                )
            }

            func testTaskListUsesThemeAwareCheckboxStyling() async {
                let markdown = """
                - [ ] Ship docs
                - [x] Add release notes
                """

                let result = await rendered(markdown, theme: .github, scheme: .light)
                let ns = result.string as NSString

                let uncheckedLoc = ns.range(of: "[ ]").location
                let checkedLoc = ns.range(of: "[x]").location
                let doneTextLoc = ns.range(of: "Add release notes").location
                XCTAssertNotEqual(uncheckedLoc, NSNotFound)
                XCTAssertNotEqual(checkedLoc, NSNotFound)
                XCTAssertNotEqual(doneTextLoc, NSNotFound)

                let palette = NativeThemePalette(theme: .github, scheme: .light)
                let uncheckedColor = foregroundColor(at: uncheckedLoc, in: result)
                let checkedColor = foregroundColor(at: checkedLoc, in: result)
                XCTAssertNotNil(uncheckedColor)
                XCTAssertNotNil(checkedColor)
                if let uncheckedColor, let checkedColor {
                    XCTAssertTrue(
                        colorsApproxEqual(uncheckedColor, palette.taskListUnchecked),
                        "Unchecked marker should use theme unchecked color"
                    )
                    XCTAssertTrue(
                        colorsApproxEqual(checkedColor, palette.taskListChecked),
                        "Checked marker should use theme checked color"
                    )
                }

                let checkedState = result.attribute(taskListCheckedKey, at: checkedLoc, effectiveRange: nil) as? Bool
                XCTAssertEqual(checkedState, true, "Checked marker should carry mdv.taskListChecked=true")

                let doneTextStrike = result.attribute(.strikethroughStyle, at: doneTextLoc, effectiveRange: nil) as? Int
                XCTAssertNotNil(doneTextStrike, "Checked task text should have strikethrough styling")
                let strikeColor = result.attribute(
                    .strikethroughColor,
                    at: doneTextLoc,
                    effectiveRange: nil
                ) as? NSColor
                XCTAssertNotNil(strikeColor, "Checked task text should carry strike color")
            }

            // MARK: - Font family coverage

            func testAllFontFamiliesRenderValidBodyFont() async {
                let markdown = "Body text for font family testing."

                for family in ReaderFontFamily.allCases {
                    let result = await MarkdownRenderService.shared.render(
                        RenderRequest(
                            markdown: markdown,
                            readerFontFamily: family,
                            readerFontSize: ReaderFontSize.standard.points,
                            codeFontSize: 14,
                            appTheme: .basic,
                            syntaxPalette: .midnight,
                            colorScheme: .light,
                            textSpacing: .balanced,
                            readableWidth: ReaderColumnWidth.balanced.points,
                            showLineNumbers: false,
                            typographyPreferences: TypographyPreferences()
                        )
                    ).attributedString
                    let ns = result.string as NSString
                    let loc = ns.range(of: "Body text").location

                    XCTAssertNotEqual(loc, NSNotFound, "\(family): body text must be present")
                    guard loc != NSNotFound else { continue }

                    let bodyFont = font(at: loc, in: result)
                    XCTAssertNotNil(bodyFont, "\(family): must produce a valid font")
                    XCTAssertGreaterThan(
                        bodyFont?.pointSize ?? 0, 0,
                        "\(family): font size must be positive"
                    )
                }
            }

            func testAllFontFamiliesPreserveBoldAndItalicTraits() async {
                let markdown = "Normal **bold** and _italic_ text."

                for family in ReaderFontFamily.allCases {
                    let result = await MarkdownRenderService.shared.render(
                        RenderRequest(
                            markdown: markdown,
                            readerFontFamily: family,
                            readerFontSize: ReaderFontSize.standard.points,
                            codeFontSize: 14,
                            appTheme: .basic,
                            syntaxPalette: .midnight,
                            colorScheme: .light,
                            textSpacing: .balanced,
                            readableWidth: ReaderColumnWidth.balanced.points,
                            showLineNumbers: false,
                            typographyPreferences: TypographyPreferences()
                        )
                    ).attributedString
                    let ns = result.string as NSString

                    let boldLoc = ns.range(of: "bold").location
                    let italicLoc = ns.range(of: "italic").location
                    guard boldLoc != NSNotFound, italicLoc != NSNotFound else {
                        XCTFail("\(family): bold and italic text must be present")
                        continue
                    }

                    let boldTraits = font(at: boldLoc, in: result)?.fontDescriptor.symbolicTraits ?? []
                    XCTAssertTrue(boldTraits.contains(.bold), "\(family): bold text must have .bold trait")

                    let italicTraits = font(at: italicLoc, in: result)?.fontDescriptor.symbolicTraits ?? []
                    XCTAssertTrue(italicTraits.contains(.italic), "\(family): italic text must have .italic trait")
                }
            }

            // MARK: - Kern (letter-spacing) verification

            func testKernAppliedToRenderedBodyText() async {
                let markdown = "Body paragraph for kern verification."

                for spacing in ReaderTextSpacing.allCases {
                    let result = await rendered(markdown, textSpacing: spacing)
                    let ns = result.string as NSString
                    let loc = ns.range(of: "Body paragraph").location

                    XCTAssertNotEqual(loc, NSNotFound, "\(spacing): body text must be present")
                    guard loc != NSNotFound else { continue }

                    let kernValue = result.attribute(.kern, at: loc, effectiveRange: nil) as? CGFloat
                    // Test uses ReaderFontSize.standard (17pt) via rendered() helper
                    // Include optical sizing adjustment for 17pt (0.003 in 14-18 range)
                    let fontSize = ReaderFontSize.standard.points
                    let baseKern = spacing.kern(for: fontSize)
                    let opticalAdjustment = fontSize * spacing.opticalSizeAdjustment(for: fontSize)
                    let expectedKern = baseKern + opticalAdjustment
                    XCTAssertNotNil(kernValue, "\(spacing): kern attribute must be present in rendered output")
                    if let kernValue {
                        XCTAssertEqual(
                            kernValue, expectedKern,
                            accuracy: 0.001,
                            "\(spacing): kern value must match spacing preset"
                        )
                    }
                }
            }

            func testNestedBlockquotesUseSeparateDepths() async {
                let markdown = "> Outer\n>> Inner"
                let result = await rendered(markdown)
                let ns = result.string as NSString

                let outerLoc = ns.range(of: "Outer").location
                let innerLoc = ns.range(of: "Inner").location
                guard outerLoc != NSNotFound, innerLoc != NSNotFound else {
                    XCTFail("Both blockquote runs must appear in output"); return
                }

                let outerDepth = result.attribute(bqDepthKey, at: outerLoc, effectiveRange: nil) as? Int
                let innerDepth = result.attribute(bqDepthKey, at: innerLoc, effectiveRange: nil) as? Int
                XCTAssertNotNil(outerDepth, "Outer blockquote must have depth attribute")
                XCTAssertNotNil(innerDepth, "Inner blockquote must have depth attribute")
                XCTAssertNotEqual(outerDepth, innerDepth, "Nested blockquotes must have different depth values")

                let outerStyle = paragraphStyle(at: outerLoc, in: result)
                let innerStyle = paragraphStyle(at: innerLoc, in: result)
                XCTAssertNotNil(outerStyle, "Outer blockquote should have paragraph style")
                XCTAssertNotNil(innerStyle, "Inner blockquote should have paragraph style")
                XCTAssertGreaterThan(
                    innerStyle?.headIndent ?? 0,
                    outerStyle?.headIndent ?? 0,
                    "Nested blockquote should be more indented than outer blockquote"
                )
            }
        }
    #endif
#endif
