#if canImport(XCTest)
import XCTest
#if os(macOS)
import AppKit
import SwiftUI
@testable import mdviewer

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
                readableWidth: ReaderColumnWidth.balanced.points
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
        return abs(a.redComponent   - b.redComponent)   <= tolerance
            && abs(a.greenComponent - b.greenComponent) <= tolerance
            && abs(a.blueComponent  - b.blueComponent)  <= tolerance
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

        let h1Loc   = ns.range(of: "Heading One").location
        let h2Loc   = ns.range(of: "Heading Two").location
        let h3Loc   = ns.range(of: "Heading Three").location
        let bodyLoc = ns.range(of: "Body").location

        XCTAssertNotEqual(h1Loc,   NSNotFound)
        XCTAssertNotEqual(h2Loc,   NSNotFound)
        XCTAssertNotEqual(h3Loc,   NSNotFound)
        XCTAssertNotEqual(bodyLoc, NSNotFound)

        let h1Size   = pointSize(at: h1Loc,   in: result)
        let h2Size   = pointSize(at: h2Loc,   in: result)
        let h3Size   = pointSize(at: h3Loc,   in: result)
        let bodySize = pointSize(at: bodyLoc, in: result)

        XCTAssertGreaterThan(h1Size, h2Size,   "H1 should be larger than H2")
        XCTAssertGreaterThan(h2Size, h3Size,   "H2 should be larger than H3")
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

    func testFontSizeScalesWithReaderPreference() async {
        let markdown = "Body paragraph text for size comparison."

        let comfortableResult = await rendered(markdown, fontSize: .comfortable)
        let compactResult     = await rendered(markdown, fontSize: .compact)

        let ns      = comfortableResult.string as NSString
        let bodyLoc = ns.range(of: "Body").location
        XCTAssertNotEqual(bodyLoc, NSNotFound)

        let comfortableSize = pointSize(at: bodyLoc, in: comfortableResult)
        let compactSize     = pointSize(at: bodyLoc, in: compactResult)

        XCTAssertGreaterThan(comfortableSize, compactSize,
            "Comfortable font preference should produce larger body text than compact")
        XCTAssertGreaterThan(comfortableSize, 0)
        XCTAssertGreaterThan(compactSize, 0)
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

        let actual   = foregroundColor(at: keywordLoc, in: result)
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
        XCTAssertEqual(style?.lineSpacing      ?? 0, ReaderTextSpacing.relaxed.lineSpacing,      accuracy: 0.1)
        XCTAssertEqual(style?.paragraphSpacing ?? 0, ReaderTextSpacing.relaxed.paragraphSpacing, accuracy: 0.1)
    }

    func testUserLineSpacingAppliedToListItems() async {
        // Regression: spacing must be merged into list-item paragraph styles,
        // not overwrite them (which would strip list indentation).
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
        XCTAssertNotNil(style, "List items should have a paragraph style attribute")
        XCTAssertEqual(style?.lineSpacing      ?? 0, ReaderTextSpacing.compact.lineSpacing,      accuracy: 0.1)
        XCTAssertEqual(style?.paragraphSpacing ?? 0, ReaderTextSpacing.compact.paragraphSpacing, accuracy: 0.1)
    }

    func testUserLineSpacingAppliedToHeadings() async {
        let markdown = "# My Heading\n\nSome body text."

        let result = await rendered(markdown, textSpacing: .relaxed)
        let ns = result.string as NSString

        let headingLoc = ns.range(of: "My Heading").location
        XCTAssertNotEqual(headingLoc, NSNotFound)

        let style = paragraphStyle(at: headingLoc, in: result)
        XCTAssertNotNil(style)
        XCTAssertEqual(style?.lineSpacing      ?? 0, ReaderTextSpacing.relaxed.lineSpacing,      accuracy: 0.1)
        XCTAssertEqual(style?.paragraphSpacing ?? 0, ReaderTextSpacing.relaxed.paragraphSpacing, accuracy: 0.1)
    }

    // MARK: - Themes

    func testDarkModeCodeBackgroundDifferentFromLight() async {
        let markdown = """
        ```
        let x = 1
        ```
        """

        let light = await rendered(markdown, scheme: .light)
        let dark  = await rendered(markdown, scheme: .dark)

        let ns      = light.string as NSString
        let codeLoc = ns.range(of: "let x = 1").location
        XCTAssertNotEqual(codeLoc, NSNotFound)

        let lightBg = backgroundColor(at: codeLoc, in: light)
        let darkBg  = backgroundColor(at: codeLoc, in: dark)

        XCTAssertNotNil(lightBg)
        XCTAssertNotNil(darkBg)

        if let lightBg, let darkBg {
            XCTAssertFalse(
                colorsApproxEqual(lightBg, darkBg),
                "Dark mode code background should differ from light mode background"
            )
        }
    }

    func testGitHubThemeCodeBackgroundDiffersFromBasic() async {
        let markdown = """
        ```
        let x = 1
        ```
        """

        let basic  = await rendered(markdown, theme: .basic,  scheme: .light)
        let github = await rendered(markdown, theme: .github, scheme: .light)

        let ns      = basic.string as NSString
        let codeLoc = ns.range(of: "let x = 1").location
        XCTAssertNotEqual(codeLoc, NSNotFound)

        let basicBg  = backgroundColor(at: codeLoc, in: basic)
        let githubBg = backgroundColor(at: codeLoc, in: github)

        XCTAssertNotNil(basicBg)
        XCTAssertNotNil(githubBg)

        if let basicBg, let githubBg {
            // Basic light: calibratedWhite 0.95 — GitHub light: calibratedWhite 0.96
            // Difference is 0.01, below the default 0.02 tolerance; use 0.005 to distinguish them.
            XCTAssertFalse(
                colorsApproxEqual(basicBg, githubBg, tolerance: 0.005),
                "GitHub theme code background should differ from Basic theme background"
            )
        }
    }

    // MARK: - Heading scale ratios

    func testH1FontSizeIsDoubleBodySize() async {
        // Heading scale for H1 is 2.0× body. Verify the rendered point size matches.
        let markdown = "# H1 Heading\n\nBody text."
        let result = await rendered(markdown, fontSize: .standard)
        let ns = result.string as NSString

        let h1Loc   = ns.range(of: "H1 Heading").location
        let bodyLoc = ns.range(of: "Body text").location
        XCTAssertNotEqual(h1Loc,   NSNotFound)
        XCTAssertNotEqual(bodyLoc, NSNotFound)

        let h1Size   = pointSize(at: h1Loc,   in: result)
        let bodySize = pointSize(at: bodyLoc, in: result)
        XCTAssertGreaterThan(bodySize, 0)
        // Accept ±1 pt tolerance for font rounding.
        XCTAssertEqual(h1Size, bodySize * 2.0, accuracy: 1.0,
            "H1 should be 2× body size (got h1=\(h1Size) body=\(bodySize))")
    }

    func testH2FontSizeIs1Point5TimesBody() async {
        let markdown = "## H2 Heading\n\nBody text."
        let result = await rendered(markdown, fontSize: .standard)
        let ns = result.string as NSString

        let h2Loc   = ns.range(of: "H2 Heading").location
        let bodyLoc = ns.range(of: "Body text").location
        XCTAssertNotEqual(h2Loc,   NSNotFound)
        XCTAssertNotEqual(bodyLoc, NSNotFound)

        let h2Size   = pointSize(at: h2Loc,   in: result)
        let bodySize = pointSize(at: bodyLoc, in: result)
        XCTAssertGreaterThan(bodySize, 0)
        XCTAssertEqual(h2Size, bodySize * 1.5, accuracy: 1.0,
            "H2 should be 1.5× body size (got h2=\(h2Size) body=\(bodySize))")
    }

    func testH3FontSizeIs1Point25TimesBody() async {
        let markdown = "### H3 Heading\n\nBody text."
        let result = await rendered(markdown, fontSize: .standard)
        let ns = result.string as NSString

        let h3Loc   = ns.range(of: "H3 Heading").location
        let bodyLoc = ns.range(of: "Body text").location
        XCTAssertNotEqual(h3Loc,   NSNotFound)
        XCTAssertNotEqual(bodyLoc, NSNotFound)

        let h3Size   = pointSize(at: h3Loc,   in: result)
        let bodySize = pointSize(at: bodyLoc, in: result)
        XCTAssertGreaterThan(bodySize, 0)
        XCTAssertEqual(h3Size, bodySize * 1.25, accuracy: 1.0,
            "H3 should be 1.25× body size (got h3=\(h3Size) body=\(bodySize))")
    }

    func testH4FontSizeIs1Point1TimesBody() async {
        let markdown = "#### H4 Heading\n\nBody text."
        let result = await rendered(markdown, fontSize: .standard)
        let ns = result.string as NSString

        let h4Loc   = ns.range(of: "H4 Heading").location
        let bodyLoc = ns.range(of: "Body text").location
        XCTAssertNotEqual(h4Loc,   NSNotFound)
        XCTAssertNotEqual(bodyLoc, NSNotFound)

        let h4Size   = pointSize(at: h4Loc,   in: result)
        let bodySize = pointSize(at: bodyLoc, in: result)
        XCTAssertGreaterThan(bodySize, 0)
        XCTAssertEqual(h4Size, bodySize * 1.1, accuracy: 1.0,
            "H4 should be 1.1× body size (got h4=\(h4Size) body=\(bodySize))")
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
        let keywordColor   = SyntaxPalette.midnight.nativeSyntax.keyword
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
        let text   = result.string

        XCTAssertTrue(text.contains("Visible Heading"),        "Visible heading should appear in rendered output")
        XCTAssertTrue(text.contains("This content"),           "Body text should appear in rendered output")
        XCTAssertFalse(text.contains("Secret Title"),          "Frontmatter title value should not appear in rendered output")
        XCTAssertFalse(text.contains("category:"),             "Frontmatter category key should not appear in rendered output")
        XCTAssertFalse(text.contains("hidden-author"),         "Frontmatter author value should not appear in rendered output")
    }
}
#endif
#endif
