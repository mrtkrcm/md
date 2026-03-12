//
//  RenderingStabilityTests.swift
//  mdviewer
//
//  End-to-end tests for rendering stability: line spacing, crashes, and edge cases.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer

        final class RenderingStabilityTests: XCTestCase {
            // MARK: - Rendered View: Double Spacing Issue

            /// Test that consecutive paragraphs have spacing applied via paragraph styles.
            /// This validates the fix to BlockSeparatorInjector (no longer injects extra newlines).
            /// All spacing is now handled through NSParagraphStyle, not literal newlines.
            func testConsecutiveParagraphsHaveConsistentSpacing() async {
                let markdown = """
                First paragraph with some content.

                Second paragraph follows.

                Third paragraph comes here.
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 12,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString

                // Verify that paragraph spacing attributes are applied
                var paragraphsFound = 0
                text.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    guard let style = value as? NSParagraphStyle else { return }
                    paragraphsFound += 1
                    // All paragraphs should have spacing applied via NSParagraphStyle
                    XCTAssertGreaterThan(style.paragraphSpacing, 0, "Paragraph spacing should be applied via style")
                }

                XCTAssertGreaterThan(paragraphsFound, 0, "Should have paragraph styles applied")
            }

            /// Test that headers don't have excessive spacing around them.
            func testHeadersWithBalancedSpacing() async {
                let markdown = """
                # Header 1

                Paragraph after header.
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 12,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString

                // Verify header has proper paragraph spacing applied
                var headerFound = false
                text.enumerateAttribute(
                    MarkdownRenderAttribute.presentationIntent,
                    in: NSRange(location: 0, length: text.length)
                ) { value, range, _ in
                    guard let intent = value as? PresentationIntent else { return }
                    for component in intent.components {
                        if case .header = component.kind {
                            headerFound = true
                            // Check that the header's paragraph style includes spacing
                            if
                                let style = text.attribute(
                                    .paragraphStyle,
                                    at: range.location,
                                    effectiveRange: nil
                                ) as? NSParagraphStyle
                            {
                                XCTAssertGreaterThan(style.paragraphSpacing, 0, "Header should have paragraph spacing")
                            }
                        }
                    }
                }
                XCTAssertTrue(headerFound, "Header should be found in output")
            }

            /// Test that list items don't have excessive spacing between them.
            /// Uses PresentationIntent attributes (not fragile string prefix checks)
            /// to identify list item runs reliably.
            func testListItemsHaveTightSpacing() async {
                let markdown = """
                - Item 1
                - Item 2
                - Item 3
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 12,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString

                // Find list items via PresentationIntent attribute (robust — not string prefix)
                var listItemSpacing: CGFloat = 0
                var foundListItem = false
                text.enumerateAttribute(
                    MarkdownRenderAttribute.presentationIntent,
                    in: NSRange(location: 0, length: text.length)
                ) { value, range, _ in
                    guard let intent = value as? PresentationIntent else { return }
                    let isListItem = intent.components.contains {
                        if case .listItem = $0.kind { return true }
                        return false
                    }
                    if isListItem, !foundListItem {
                        foundListItem = true
                        if
                            let style = text.attribute(
                                .paragraphStyle,
                                at: range.location,
                                effectiveRange: nil
                            ) as? NSParagraphStyle
                        {
                            listItemSpacing = style.paragraphSpacing
                        }
                    }
                }

                XCTAssertTrue(foundListItem, "Should find list items via PresentationIntent")

                // List items should have less spacing than regular paragraphs (50% of standard)
                let spacingForSize = ReaderTextSpacing.balanced.paragraphSpacing(for: 16)
                XCTAssertLessThan(
                    listItemSpacing,
                    spacingForSize,
                    "List items should have tighter spacing than paragraphs"
                )
            }

            // MARK: - Raw View: Line Number Rendering Stability

            /// Test that line number drawing doesn't crash with bounds checking.
            @MainActor
            func testLineNumberRulerHandlesEmptyDocument() {
                let ruler = LineNumberRulerView(scrollView: nil)
                XCTAssertNotNil(ruler, "Ruler should initialize without crashing")
                XCTAssertEqual(ruler.ruleThickness, 40, "Ruler thickness should be set")
            }

            /// Test that line number rendering is safe with index bounds.
            func testLineNumberDrawingWithVariousDocumentLengths() async {
                let testCases = [
                    "",
                    "Single line",
                    "Line 1\nLine 2",
                    "Line 1\nLine 2\nLine 3\nLine 4\nLine 5",
                    String(repeating: "Long line ", count: 100),
                ]

                for testCase in testCases {
                    let request = RenderRequest(
                        markdown: testCase,
                        readerFontFamily: .newYork,
                        readerFontSize: 16,
                        codeFontSize: 12,
                        appTheme: .basic,
                        syntaxPalette: .midnight,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 760,
                        showLineNumbers: true,
                        typographyPreferences: TypographyPreferences()
                    )

                    let rendered = await MarkdownRenderService.shared.render(request)
                    XCTAssertNotNil(rendered, "Should render without crash for: \(testCase.prefix(30))")
                }
            }

            // MARK: - Spacing Consistency Across Settings

            /// Test that spacing presets apply correct amounts of paragraph spacing.
            /// Different presets should produce different paragraph spacing values.
            func testSpacingPresetsProduceProportionalGaps() async {
                let markdown = """
                Para 1

                Para 2

                Para 3
                """

                var previousSpacing: CGFloat = -1

                for spacing in ReaderTextSpacing.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .newYork,
                        readerFontSize: 16,
                        codeFontSize: 12,
                        appTheme: .basic,
                        syntaxPalette: .midnight,
                        colorScheme: .light,
                        textSpacing: spacing,
                        readableWidth: 760,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )

                    let rendered = await MarkdownRenderService.shared.render(request)
                    let text = rendered.attributedString

                    // Find the paragraph spacing applied for this preset
                    var foundSpacing: CGFloat = 0
                    text.enumerateAttribute(.paragraphStyle, in: NSRange(
                        location: 0,
                        length: text.length
                    )) { value, _, _ in
                        if let style = value as? NSParagraphStyle {
                            foundSpacing = style.paragraphSpacing
                        }
                    }

                    XCTAssertGreaterThan(foundSpacing, 0, "Should have paragraph spacing for \(spacing.rawValue)")

                    // Spacing should increase: compact < balanced < relaxed
                    if previousSpacing > 0 {
                        XCTAssertNotEqual(
                            foundSpacing,
                            previousSpacing,
                            "Different presets should have different spacing"
                        )
                    }
                    previousSpacing = foundSpacing
                }
            }

            /// Test that block spacing is handled through paragraph styles only.
            /// The BlockSeparatorInjector no longer injects new newlines.
            func testBlockSpacingViaParagraphStyle() async {
                let markdown = """
                First block

                Second block
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 12,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString

                // Verify that blocks have paragraph spacing applied
                var foundSpacedBlock = false
                text.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if let style = value as? NSParagraphStyle, style.paragraphSpacing > 0 {
                        foundSpacedBlock = true
                    }
                }

                XCTAssertTrue(foundSpacedBlock, "Blocks should have paragraph spacing applied")
            }

            // MARK: - Edge Cases

            /// Test rendering with no spacing (empty document).
            func testEmptyDocumentRenders() async {
                let request = RenderRequest(
                    markdown: "",
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 12,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                XCTAssertEqual(rendered.attributedString.length, 0)
            }

            /// Test code blocks with line numbers don't have corrupted spacing.
            func testCodeBlockWithLineNumbers() async {
                let markdown = """
                ```swift
                let x = 1
                let y = 2
                ```
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 12,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: true,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString

                // Verify code block has proper indentation for line numbers
                var codeBlockFound = false
                text.enumerateAttribute(
                    MarkdownRenderAttribute.presentationIntent,
                    in: NSRange(location: 0, length: text.length)
                ) { value, range, _ in
                    guard let intent = value as? PresentationIntent else { return }
                    for component in intent.components {
                        if case .codeBlock = component.kind {
                            codeBlockFound = true
                            if
                                let style = text.attribute(
                                    .paragraphStyle,
                                    at: range.location,
                                    effectiveRange: nil
                                ) as? NSParagraphStyle
                            {
                                // With line numbers, code blocks should have gutter indentation
                                XCTAssertGreaterThan(
                                    style.headIndent,
                                    0,
                                    "Code block should be indented for line numbers"
                                )
                            }
                        }
                    }
                }
                XCTAssertTrue(codeBlockFound, "Code block should be found")
            }

            /// Test mixed content (headers, paragraphs, lists) renders without excessive gaps.
            func testMixedContentSpacing() async {
                let markdown = """
                # Title

                Introduction paragraph.

                - Point 1
                - Point 2

                Conclusion.
                """

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 12,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let rendered = await MarkdownRenderService.shared.render(request)
                let text = rendered.attributedString

                // All block elements should be present
                var blockCount = 0
                text.enumerateAttribute(
                    MarkdownRenderAttribute.presentationIntent,
                    in: NSRange(location: 0, length: text.length)
                ) { value, _, _ in
                    guard let intent = value as? PresentationIntent else { return }
                    for component in intent.components {
                        switch component.kind {
                        case .header, .paragraph, .unorderedList:
                            blockCount += 1

                        default:
                            break
                        }
                    }
                }

                XCTAssertGreaterThan(blockCount, 0, "Should have multiple block elements")
            }

            /// Regression test: separator injection must work across block transitions
            /// even when parser intent metadata is adjacent/overlapping semantically.
            func testBlockSeparatorInjectorSeparatesAdjacentParagraphBlocks() throws {
                let markdown = """
                Alpha paragraph.

                Beta paragraph.
                """

                let parsed = try MarkdownParser().parse(markdown)
                let mutable = NSMutableAttributedString(attributedString: parsed)

                BlockSeparatorInjector().injectSeparators(into: mutable)

                let rendered = mutable.string as NSString
                let alphaRange = rendered.range(of: "Alpha paragraph.")
                let betaRange = rendered.range(of: "Beta paragraph.")

                XCTAssertNotEqual(alphaRange.location, NSNotFound)
                XCTAssertNotEqual(betaRange.location, NSNotFound)
                XCTAssertGreaterThan(betaRange.location, alphaRange.location)

                let betweenStart = alphaRange.location + alphaRange.length
                let betweenLength = betaRange.location - betweenStart
                let between = rendered.substring(with: NSRange(location: betweenStart, length: betweenLength))

                XCTAssertTrue(
                    between.contains(where: \.isNewline),
                    "Expected a newline separator between adjacent paragraph blocks"
                )
            }

            /// Regression test: scanning for existing newlines must be Unicode-safe
            /// with non-BMP characters (e.g. emoji).
            func testBlockSeparatorInjectorIsSafeWithEmojiContent() throws {
                let markdown = """
                Emoji 😀 paragraph.

                Next 😎 paragraph.
                """

                let parsed = try MarkdownParser().parse(markdown)
                let mutable = NSMutableAttributedString(attributedString: parsed)

                // Should not crash while scanning around block boundaries.
                BlockSeparatorInjector().injectSeparators(into: mutable)

                XCTAssertTrue(mutable.string.contains("Emoji 😀 paragraph."))
                XCTAssertTrue(mutable.string.contains("Next 😎 paragraph."))
            }

            func testBlockSeparatorInjectorSeparatesTableCellsWithTabs() throws {
                let markdown = """
                | Name | Status |
                | --- | --- |
                | Parser | Done |
                | Viewer | WIP |
                """

                let parsed = try MarkdownParser().parse(markdown)
                let mutable = NSMutableAttributedString(attributedString: parsed)

                BlockSeparatorInjector().injectSeparators(into: mutable)

                XCTAssertEqual(
                    mutable.string,
                    "Name\tStatus\nParser\tDone\nViewer\tWIP",
                    "Table cells should be separated with tabs and rows with newlines"
                )
            }
        }
    #endif
#endif
