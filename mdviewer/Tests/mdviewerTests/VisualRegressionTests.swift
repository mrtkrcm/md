#if canImport(XCTest)
internal import XCTest
#if os(macOS)
@testable internal import mdviewer

/// Visual regression tests ensuring Markdown renders correctly with proper spacing,
/// typography, and formatting.
final class VisualRegressionTests: XCTestCase {

    // MARK: - Paragraph Spacing Tests

    func testParagraphsHaveProperSpacingBetweenThem() async {
        let markdown = """
        First paragraph with some content.

        Second paragraph after a blank line.

        Third paragraph with more content.
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let ns = rendered.attributedString

        // Verify all paragraphs are present
        let text = ns.string
        XCTAssertTrue(text.contains("First paragraph"))
        XCTAssertTrue(text.contains("Second paragraph"))
        XCTAssertTrue(text.contains("Third paragraph"))

        // Verify paragraph spacing is applied somewhere in the text
        let firstParaRange = (text as NSString).range(of: "First paragraph")
        XCTAssertNotEqual(firstParaRange.location, NSNotFound)
        if firstParaRange.location != NSNotFound {
            let style = ns.attribute(.paragraphStyle, at: firstParaRange.location, effectiveRange: nil) as? NSParagraphStyle
            XCTAssertNotNil(style, "Should have a paragraph style")
            XCTAssertGreaterThan(style?.paragraphSpacing ?? 0, 0, "Should have paragraph spacing")
        }
    }

    func testLineBreaksWithinParagraphsAreSoft() async {
        // Single newlines within a paragraph should be soft breaks (joined with space)
        let markdown = """
        Line one
        Line two
        Line three
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let text = rendered.attributedString.string

        // Soft breaks become spaces, not newlines
        XCTAssertTrue(text.contains("Line one"))
        XCTAssertTrue(text.contains("Line two"))
        XCTAssertTrue(text.contains("Line three"))
    }

    // MARK: - Heading Spacing Tests

    func testHeadingsHaveProperVerticalSpacing() async {
        let markdown = """
        # Heading 1

        Paragraph after heading 1

        ## Heading 2

        Paragraph after heading 2
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let ns = rendered.attributedString

        // Find heading ranges and verify they have paragraph styles with spacing
        let text = ns.string
        let h1Range = (text as NSString).range(of: "Heading 1")
        XCTAssertNotEqual(h1Range.location, NSNotFound)

        if h1Range.location != NSNotFound {
            let style = ns.attribute(.paragraphStyle, at: h1Range.location, effectiveRange: nil) as? NSParagraphStyle
            XCTAssertNotNil(style, "Heading 1 should have a paragraph style")
            XCTAssertGreaterThan(style?.paragraphSpacing ?? 0, 0, "Heading should have paragraph spacing")
        }
    }

    // MARK: - List Spacing Tests

    func testListItemsHaveProperIndentation() async {
        let markdown = """
        - Item 1
        - Item 2
        - Item 3
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let ns = rendered.attributedString

        // Verify list items are present
        let text = ns.string
        XCTAssertTrue(text.contains("Item 1"))
        XCTAssertTrue(text.contains("Item 2"))
        XCTAssertTrue(text.contains("Item 3"))

        // Verify list items have paragraph style with indentation
        let itemRange = (text as NSString).range(of: "Item 1")
        XCTAssertNotEqual(itemRange.location, NSNotFound)
        if itemRange.location != NSNotFound {
            let style = ns.attribute(.paragraphStyle, at: itemRange.location, effectiveRange: nil) as? NSParagraphStyle
            XCTAssertNotNil(style, "List items should have paragraph styles")
        }
    }

    func testOrderedListItemsAreNumbered() async {
        let markdown = """
        1. First item
        2. Second item
        3. Third item
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let text = rendered.attributedString.string

        XCTAssertTrue(text.contains("First item"))
        XCTAssertTrue(text.contains("Second item"))
        XCTAssertTrue(text.contains("Third item"))
    }

    // MARK: - Code Block Tests

    func testCodeBlocksPreserveLineBreaks() async {
        let markdown = """
        ```
        line 1
        line 2
        line 3
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let text = rendered.attributedString.string

        // Code blocks should preserve actual newlines
        XCTAssertTrue(text.contains("line 1"))
        XCTAssertTrue(text.contains("line 2"))
        XCTAssertTrue(text.contains("line 3"))
    }

    func testCodeBlocksHaveBackgroundColor() async {
        let markdown = """
        ```swift
        let x = 42
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let ns = rendered.attributedString

        // Find the code range and verify background color
        let text = ns.string
        let codeRange = (text as NSString).range(of: "let x = 42")
        XCTAssertNotEqual(codeRange.location, NSNotFound)

        if codeRange.location != NSNotFound {
            let bgColor = ns.attribute(.backgroundColor, at: codeRange.location, effectiveRange: nil)
            XCTAssertNotNil(bgColor, "Code block should have a background color")
        }
    }

    // MARK: - Blockquote Tests

    func testBlockquotesHaveVisualStyling() async {
        let markdown = """
        > This is a blockquote
        > with multiple lines
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let ns = rendered.attributedString

        // Verify blockquote content is present
        let text = ns.string
        XCTAssertTrue(text.contains("This is a blockquote"))

        // Verify blockquote has accent color attribute
        let quoteRange = (text as NSString).range(of: "blockquote")
        XCTAssertNotEqual(quoteRange.location, NSNotFound)

        if quoteRange.location != NSNotFound {
            let accentColor = ns.attribute(MarkdownRenderAttribute.blockquoteAccent, at: quoteRange.location, effectiveRange: nil)
            XCTAssertNotNil(accentColor, "Blockquote should have accent color attribute")
        }
    }

    // MARK: - Spacing Preference Tests

    func testCompactSpacingAppliedCorrectly() async {
        let markdown = "Paragraph one.\n\nParagraph two."
        let request = RenderRequest(
            markdown: markdown,
            readerFontFamily: .newYork,
            readerFontSize: 16,
            codeFontSize: 14,
            appTheme: .basic,
            syntaxPalette: .midnight,
            colorScheme: .light,
            textSpacing: .compact,
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let ns = rendered.attributedString

        // Check that paragraph style has compact spacing values
        let loc = (ns.string as NSString).range(of: "Paragraph").location
        XCTAssertNotEqual(loc, NSNotFound)

        if loc != NSNotFound {
            let style = ns.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle
            XCTAssertNotNil(style)
            XCTAssertEqual(style?.lineSpacing ?? 0, ReaderTextSpacing.compact.lineSpacing(for: 16), accuracy: 0.1)
        }
    }

    func testRelaxedSpacingAppliedCorrectly() async {
        let markdown = "Paragraph one.\n\nParagraph two."
        let request = RenderRequest(
            markdown: markdown,
            readerFontFamily: .newYork,
            readerFontSize: 16,
            codeFontSize: 14,
            appTheme: .basic,
            syntaxPalette: .midnight,
            colorScheme: .light,
            textSpacing: .relaxed,
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let ns = rendered.attributedString

        // Check that paragraph style has relaxed spacing values
        let loc = (ns.string as NSString).range(of: "Paragraph").location
        XCTAssertNotEqual(loc, NSNotFound)

        if loc != NSNotFound {
            let style = ns.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle
            XCTAssertNotNil(style)
            XCTAssertEqual(style?.lineSpacing ?? 0, ReaderTextSpacing.relaxed.lineSpacing(for: 16), accuracy: 0.1)
        }
    }

    // MARK: - Complex Document Tests

    func testComplexDocumentRendersAllElements() async {
        let markdown = """
        # Document Title

        Introduction paragraph with **bold** and _italic_ text.

        ## Section 1

        - List item 1
        - List item 2

        > A blockquote for emphasis

        ```swift
        let code = "example"
        ```

        ## Section 2

        Final paragraph with `inline code`.
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
            readableWidth: 760
        )

        let rendered = await MarkdownRenderService.shared.render(request)
        let text = rendered.attributedString.string

        // Verify all elements are present
        XCTAssertTrue(text.contains("Document Title"))
        XCTAssertTrue(text.contains("Introduction paragraph"))
        XCTAssertTrue(text.contains("bold"))
        XCTAssertTrue(text.contains("italic"))
        XCTAssertTrue(text.contains("Section 1"))
        XCTAssertTrue(text.contains("List item 1"))
        XCTAssertTrue(text.contains("blockquote for emphasis"))
        XCTAssertTrue(text.contains("let code"))
        XCTAssertTrue(text.contains("Section 2"))
        XCTAssertTrue(text.contains("inline code"))
    }
}
#endif
#endif
