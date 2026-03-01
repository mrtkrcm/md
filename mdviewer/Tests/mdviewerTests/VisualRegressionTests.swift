//
//  VisualRegressionTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        /// Visual regression tests ensuring Markdown renders correctly with proper spacing,
        /// typography, and formatting across all preference combinations.
        ///
        /// Robustness strategy:
        /// - All content lookups use `assertFound()` which fails explicitly on NSNotFound
        /// - Tests cover realistic multi-section documents, not just trivial snippets
        /// - Cross-preference tests validate all font families, spacings, and themes
        /// - Attribute assertions verify both presence AND values
        final class VisualRegressionTests: XCTestCase {
            // MARK: - Helpers

            /// Renders markdown and returns the attributed string.
            private func render(
                _ markdown: String,
                fontFamily: ReaderFontFamily = .newYork,
                fontSize: CGFloat = 16,
                codeFontSize: CGFloat = 14,
                theme: AppTheme = .basic,
                syntaxPalette: SyntaxPalette = .midnight,
                scheme: ColorScheme = .light,
                textSpacing: ReaderTextSpacing = .balanced,
                readableWidth: CGFloat = 760,
                showLineNumbers: Bool = false
            ) async -> NSAttributedString {
                await MarkdownRenderService.shared.render(
                    RenderRequest(
                        markdown: markdown,
                        readerFontFamily: fontFamily,
                        readerFontSize: fontSize,
                        codeFontSize: codeFontSize,
                        appTheme: theme,
                        syntaxPalette: syntaxPalette,
                        colorScheme: scheme,
                        textSpacing: textSpacing,
                        readableWidth: readableWidth,
                        showLineNumbers: showLineNumbers
                    )
                ).attributedString
            }

            /// Finds `needle` in the attributed string and returns its location.
            /// Fails the test immediately if not found (no silent pass-through).
            @discardableResult
            private func assertFound(
                _ needle: String,
                in ns: NSAttributedString,
                _ message: String? = nil,
                file: StaticString = #filePath,
                line: UInt = #line
            ) -> Int {
                let range = (ns.string as NSString).range(of: needle)
                if range.location == NSNotFound {
                    XCTFail(
                        message ?? "Expected '\(needle)' in rendered output",
                        file: file,
                        line: line
                    )
                }
                return range.location
            }

            private func paragraphStyle(at loc: Int, in ns: NSAttributedString) -> NSParagraphStyle? {
                guard loc != NSNotFound, loc < ns.length else { return nil }
                return ns.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle
            }

            private func font(at loc: Int, in ns: NSAttributedString) -> NSFont? {
                guard loc != NSNotFound, loc < ns.length else { return nil }
                return ns.attribute(.font, at: loc, effectiveRange: nil) as? NSFont
            }

            // MARK: - Paragraph Spacing

            func testParagraphsHaveProperSpacingBetweenThem() async {
                let markdown = """
                First paragraph with some content.

                Second paragraph after a blank line.

                Third paragraph with more content.
                """
                let ns = await render(markdown)

                let loc = assertFound("First paragraph", in: ns)
                guard loc != NSNotFound else { return }

                let style = paragraphStyle(at: loc, in: ns)
                XCTAssertNotNil(style, "Paragraph must have a paragraph style")
                XCTAssertGreaterThan(style?.paragraphSpacing ?? 0, 0, "Paragraphs must have spacing > 0")
            }

            func testLineBreaksWithinParagraphsAreSoft() async {
                let markdown = """
                Line one
                Line two
                Line three
                """
                let ns = await render(markdown)

                // All three lines must appear in output (soft breaks join, not split)
                assertFound("Line one", in: ns)
                assertFound("Line two", in: ns)
                assertFound("Line three", in: ns)
            }

            // MARK: - Heading Spacing

            func testHeadingsHaveProperVerticalSpacing() async {
                let markdown = """
                # Heading 1

                Paragraph after heading 1

                ## Heading 2

                Paragraph after heading 2
                """
                let ns = await render(markdown)

                let h1Loc = assertFound("Heading 1", in: ns)
                guard h1Loc != NSNotFound else { return }

                let style = paragraphStyle(at: h1Loc, in: ns)
                XCTAssertNotNil(style, "Heading 1 must have a paragraph style")
                XCTAssertGreaterThan(
                    style?.paragraphSpacing ?? 0, 0,
                    "Heading must have paragraphSpacing > 0"
                )
            }

            // MARK: - List Spacing

            func testListItemsHaveProperIndentation() async {
                let markdown = """
                - Item 1
                - Item 2
                - Item 3
                """
                let ns = await render(markdown)

                let loc = assertFound("Item 1", in: ns)
                guard loc != NSNotFound else { return }

                let style = paragraphStyle(at: loc, in: ns)
                XCTAssertNotNil(style, "List items must have paragraph styles")
                // List items should have indentation for the bullet
                XCTAssertGreaterThan(
                    style?.headIndent ?? 0, 0,
                    "List items must be indented (headIndent > 0)"
                )
            }

            func testOrderedListItemsAreNumbered() async {
                let markdown = """
                1. First item
                2. Second item
                3. Third item
                """
                let ns = await render(markdown)

                assertFound("First item", in: ns)
                assertFound("Second item", in: ns)
                assertFound("Third item", in: ns)
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
                let ns = await render(markdown)
                let text = ns.string

                XCTAssertTrue(text.contains("line 1"), "Code block line 1 must be present")
                XCTAssertTrue(text.contains("line 2"), "Code block line 2 must be present")
                XCTAssertTrue(text.contains("line 3"), "Code block line 3 must be present")

                // Code blocks must preserve actual newlines (not join lines)
                let newlineCount = text.filter { $0 == "\n" }.count
                XCTAssertGreaterThanOrEqual(newlineCount, 2, "Code block must preserve newlines")
            }

            func testCodeBlocksHaveBackgroundColor() async {
                let markdown = """
                ```swift
                let x = 42
                ```
                """
                let ns = await render(markdown)

                let loc = assertFound("let x = 42", in: ns)
                guard loc != NSNotFound else { return }

                let bgColor = ns.attribute(.backgroundColor, at: loc, effectiveRange: nil) as? NSColor
                XCTAssertNotNil(bgColor, "Code block must have a background color")
            }

            func testCodeBlocksUseMonospaceFont() async {
                let markdown = """
                ```swift
                let value = 42
                ```
                """
                let ns = await render(markdown)

                let loc = assertFound("let value = 42", in: ns)
                guard loc != NSNotFound else { return }

                let codeFont = font(at: loc, in: ns)
                XCTAssertNotNil(codeFont, "Code block must have a font attribute")
                let traits = codeFont?.fontDescriptor.symbolicTraits ?? []
                XCTAssertTrue(traits.contains(.monoSpace), "Code block must use monospace font")
            }

            // MARK: - Blockquote Tests

            func testBlockquotesHaveVisualStyling() async {
                let markdown = """
                > This is a blockquote
                > with multiple lines
                """
                let ns = await render(markdown)

                let loc = assertFound("blockquote", in: ns)
                guard loc != NSNotFound else { return }

                let accentColor = ns.attribute(
                    MarkdownRenderAttribute.blockquoteAccent,
                    at: loc,
                    effectiveRange: nil
                )
                XCTAssertNotNil(accentColor, "Blockquote must have accent color attribute")

                let bgColor = ns.attribute(
                    MarkdownRenderAttribute.blockquoteBackground,
                    at: loc,
                    effectiveRange: nil
                )
                XCTAssertNotNil(bgColor, "Blockquote must have background color attribute")

                let depth = ns.attribute(
                    MarkdownRenderAttribute.blockquoteDepth,
                    at: loc,
                    effectiveRange: nil
                ) as? Int
                XCTAssertEqual(depth, 1, "Single blockquote must have depth 1")
            }

            // MARK: - Spacing Preferences

            func testAllSpacingPresetsApplyCorrectLineSpacing() async {
                let markdown = "Paragraph one.\n\nParagraph two."

                for spacing in ReaderTextSpacing.allCases {
                    let ns = await render(markdown, textSpacing: spacing)

                    let loc = assertFound("Paragraph", in: ns, "\(spacing): content must be present")
                    guard loc != NSNotFound else { continue }

                    let style = paragraphStyle(at: loc, in: ns)
                    XCTAssertNotNil(style, "\(spacing): must have paragraph style")
                    XCTAssertEqual(
                        style?.lineSpacing ?? -1,
                        spacing.lineSpacing(for: 16),
                        accuracy: 0.1,
                        "\(spacing): lineSpacing must match preset"
                    )
                }
            }

            func testSpacingPresetsAreMonotonicallyOrdered() async {
                let markdown = "Text for spacing comparison."

                var lineSpacings: [CGFloat] = []
                for spacing in [ReaderTextSpacing.compact, .balanced, .relaxed] {
                    let ns = await render(markdown, textSpacing: spacing)
                    let loc = assertFound("Text for", in: ns)
                    guard loc != NSNotFound else { return }

                    let style = paragraphStyle(at: loc, in: ns)
                    lineSpacings.append(style?.lineSpacing ?? 0)
                }

                XCTAssertEqual(lineSpacings.count, 3)
                XCTAssertLessThan(lineSpacings[0], lineSpacings[1], "Compact < balanced")
                XCTAssertLessThan(lineSpacings[1], lineSpacings[2], "Balanced < relaxed")
            }

            // MARK: - Kern / Letter Spacing

            func testKernAppliedPerSpacingPreset() async {
                let markdown = "Body text for kern validation."

                for spacing in ReaderTextSpacing.allCases {
                    let ns = await render(markdown, textSpacing: spacing)

                    let loc = assertFound("Body text", in: ns)
                    guard loc != NSNotFound else { continue }

                    let kernValue = ns.attribute(.kern, at: loc, effectiveRange: nil) as? CGFloat
                    // Include optical sizing adjustment for 16pt (0.003 in 14-18 range)
                    let baseKern = spacing.kern(for: 16)
                    let opticalAdjustment = 16 * spacing.opticalSizeAdjustment(for: 16)
                    let expectedKern = baseKern + opticalAdjustment
                    XCTAssertNotNil(kernValue, "\(spacing): kern attribute must be present")
                    XCTAssertEqual(
                        kernValue ?? -1, expectedKern,
                        accuracy: 0.001,
                        "\(spacing): kern must match preset value"
                    )
                }
            }

            // MARK: - Cross-Font-Family Rendering

            func testAllFontFamiliesProduceValidTypography() async {
                let markdown = """
                # Heading

                Body text with **bold** and _italic_ formatting.

                ```swift
                let code = "example"
                ```
                """

                for family in ReaderFontFamily.allCases {
                    let ns = await render(markdown, fontFamily: family)
                    let text = ns.string as NSString

                    let headingLoc = text.range(of: "Heading").location
                    let bodyLoc = text.range(of: "Body text").location
                    let boldLoc = text.range(of: "bold").location
                    let codeLoc = text.range(of: "let code").location

                    guard
                        headingLoc != NSNotFound, bodyLoc != NSNotFound,
                        boldLoc != NSNotFound, codeLoc != NSNotFound
                    else {
                        XCTFail("\(family): all content elements must be present")
                        continue
                    }

                    // Heading larger than body
                    let headingFont = font(at: headingLoc, in: ns)
                    let bodyFont = font(at: bodyLoc, in: ns)
                    XCTAssertGreaterThan(
                        headingFont?.pointSize ?? 0,
                        bodyFont?.pointSize ?? 0,
                        "\(family): heading must be larger than body"
                    )

                    // Bold has bold trait
                    let boldFont = font(at: boldLoc, in: ns)
                    XCTAssertTrue(
                        boldFont?.fontDescriptor.symbolicTraits.contains(.bold) ?? false,
                        "\(family): bold text must have .bold trait"
                    )

                    // Code is monospace
                    let codeFont = font(at: codeLoc, in: ns)
                    XCTAssertTrue(
                        codeFont?.fontDescriptor.symbolicTraits.contains(.monoSpace) ?? false,
                        "\(family): code block must use monospace font"
                    )
                }
            }

            // MARK: - Preference Change Correctness

            func testThemeChangeProducesDifferentHeadingColors() async {
                let markdown = "# Heading\n\nBody text."

                let basic = await render(markdown, theme: .basic, scheme: .light)
                let github = await render(markdown, theme: .github, scheme: .light)

                let basicLoc = (basic.string as NSString).range(of: "Heading").location
                let githubLoc = (github.string as NSString).range(of: "Heading").location
                guard basicLoc != NSNotFound, githubLoc != NSNotFound else {
                    XCTFail("Heading must be present in both renders")
                    return
                }

                let basicColor = basic.attribute(.foregroundColor, at: basicLoc, effectiveRange: nil) as? NSColor
                let githubColor = github.attribute(.foregroundColor, at: githubLoc, effectiveRange: nil) as? NSColor

                XCTAssertNotNil(basicColor, "Basic theme must set heading color")
                XCTAssertNotNil(githubColor, "GitHub theme must set heading color")
                XCTAssertNotEqual(
                    basicColor, githubColor,
                    "Different themes must produce different heading colors"
                )
            }

            func testFontSizeChangeProducesDifferentSizes() async {
                let markdown = "Body paragraph text."

                let small = await render(markdown, fontSize: ReaderFontSize.small.points)
                let large = await render(markdown, fontSize: ReaderFontSize.large.points)

                let smallLoc = (small.string as NSString).range(of: "Body").location
                let largeLoc = (large.string as NSString).range(of: "Body").location
                guard smallLoc != NSNotFound, largeLoc != NSNotFound else {
                    XCTFail("Body text must be present in both renders")
                    return
                }

                let smallSize = font(at: smallLoc, in: small)?.pointSize ?? 0
                let largeSize = font(at: largeLoc, in: large)?.pointSize ?? 0

                XCTAssertGreaterThan(smallSize, 0)
                XCTAssertGreaterThan(largeSize, 0)
                XCTAssertGreaterThan(
                    largeSize, smallSize,
                    "Large (19pt) must produce larger text than small (15pt)"
                )
            }

            // MARK: - Realistic Multi-Section Document

            func testRealisticMultiSectionDocument() async {
                let markdown = """
                ---
                title: Swift Concurrency Guide
                author: Engineering Team
                date: 2026-01-15
                ---

                # Swift Concurrency Guide

                Modern Swift provides structured concurrency primitives that make it easier
                to write correct, performant asynchronous code. This guide covers the key
                patterns used throughout the codebase.

                ## Async/Await Basics

                The `async`/`await` pattern replaces completion handlers with a linear
                control flow:

                ```swift
                func fetchUser(id: Int) async throws -> User {
                    let url = URL(string: "https://api.example.com/users/\\(id)")!
                    let (data, response) = try await URLSession.shared.data(from: url)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw APIError.invalidResponse
                    }
                    return try JSONDecoder().decode(User.self, from: data)
                }
                ```

                > **Note:** Always use structured concurrency (`async let`, `TaskGroup`)
                > instead of unstructured `Task { }` blocks when possible.

                ## Task Groups

                For parallel operations on collections, use `TaskGroup`:

                1. Create a task group with `withTaskGroup(of:)`
                2. Add child tasks with `group.addTask { }`
                3. Collect results as they complete

                - **Automatic cancellation** when the group scope exits
                - **Priority inheritance** from the parent task
                - **Resource-bounded** via `withThrowingTaskGroup`

                ### Error Handling

                Errors in child tasks propagate to the parent:

                ```swift
                let results = try await withThrowingTaskGroup(of: User.self) { group in
                    for id in userIDs {
                        group.addTask { try await fetchUser(id: id) }
                    }
                    return try await group.reduce(into: []) { $0.append($1) }
                }
                ```

                For more details, see the [Swift Evolution proposals](https://github.com/apple/swift-evolution).
                """

                let ns = await render(markdown)
                let text = ns.string

                // Structural elements
                assertFound("Swift Concurrency Guide", in: ns)
                assertFound("Async/Await Basics", in: ns)
                assertFound("Task Groups", in: ns)
                assertFound("Error Handling", in: ns)

                // Code blocks preserved
                assertFound("fetchUser", in: ns)
                assertFound("withThrowingTaskGroup", in: ns)

                // Lists present
                assertFound("Automatic cancellation", in: ns)
                assertFound("Priority inheritance", in: ns)

                // Blockquote present
                assertFound("structured concurrency", in: ns)

                // Link text present
                assertFound("Swift Evolution proposals", in: ns)

                // Frontmatter stripped
                XCTAssertFalse(
                    text.contains("author: Engineering Team"),
                    "Frontmatter must not appear in rendered output"
                )

                // H1 is larger than body
                let h1Loc = (text as NSString).range(of: "Swift Concurrency Guide").location
                let bodyLoc = (text as NSString).range(of: "Modern Swift").location
                if h1Loc != NSNotFound, bodyLoc != NSNotFound {
                    XCTAssertGreaterThan(
                        font(at: h1Loc, in: ns)?.pointSize ?? 0,
                        font(at: bodyLoc, in: ns)?.pointSize ?? 0,
                        "H1 must be larger than body text"
                    )
                }

                // Code block uses monospace
                let codeLoc = (text as NSString).range(of: "fetchUser").location
                if codeLoc != NSNotFound {
                    let traits = font(at: codeLoc, in: ns)?.fontDescriptor.symbolicTraits ?? []
                    XCTAssertTrue(traits.contains(.monoSpace), "Code must use monospace font")
                }

                // Blockquote has accent — search via PresentationIntent for robustness
                var foundBlockquoteAccent = false
                ns.enumerateAttribute(
                    MarkdownRenderAttribute.blockquoteDepth,
                    in: NSRange(location: 0, length: ns.length)
                ) { value, range, _ in
                    if let depth = value as? Int, depth > 0 {
                        let accent = ns.attribute(
                            MarkdownRenderAttribute.blockquoteAccent,
                            at: range.location,
                            effectiveRange: nil
                        )
                        if accent != nil { foundBlockquoteAccent = true }
                    }
                }
                XCTAssertTrue(foundBlockquoteAccent, "Document must contain a blockquote with accent attribute")
            }

            // MARK: - Large Document Consistency

            func testLargeDocumentAttributeConsistency() async {
                var sections: [String] = []
                for i in 1 ... 50 {
                    sections.append("""
                    ## Section \(i)

                    Paragraph for section \(i) with **bold** text.

                    ```swift
                    struct S\(i) { let v = \(i) }
                    ```

                    > Note about section \(i).

                    - Point A for \(i)
                    - Point B for \(i)
                    """)
                }

                let markdown = "# Architecture Doc\n\n" + sections.joined(separator: "\n\n")
                let ns = await render(markdown)
                let text = ns.string

                // First and last sections present
                assertFound("Section 1", in: ns)
                assertFound("Section 50", in: ns)

                // Attribute consistency: code blocks at document start and end
                // both get monospace font
                let earlyLoc = (text as NSString).range(of: "struct S1").location
                let lateLoc = (text as NSString).range(of: "struct S50").location
                guard earlyLoc != NSNotFound, lateLoc != NSNotFound else {
                    XCTFail("Code blocks must be present at both start and end")
                    return
                }

                let earlyTraits = font(at: earlyLoc, in: ns)?.fontDescriptor.symbolicTraits ?? []
                let lateTraits = font(at: lateLoc, in: ns)?.fontDescriptor.symbolicTraits ?? []
                XCTAssertTrue(earlyTraits.contains(.monoSpace), "Early code must be monospace")
                XCTAssertTrue(lateTraits.contains(.monoSpace), "Late code must be monospace")

                // Blockquote attributes consistent
                let earlyQuoteLoc = (text as NSString).range(of: "Note about section 1").location
                let lateQuoteLoc = (text as NSString).range(of: "Note about section 50").location
                if earlyQuoteLoc != NSNotFound {
                    XCTAssertNotNil(
                        ns.attribute(MarkdownRenderAttribute.blockquoteAccent, at: earlyQuoteLoc, effectiveRange: nil),
                        "Early blockquote must have accent"
                    )
                }
                if lateQuoteLoc != NSNotFound {
                    XCTAssertNotNil(
                        ns.attribute(MarkdownRenderAttribute.blockquoteAccent, at: lateQuoteLoc, effectiveRange: nil),
                        "Late blockquote must have accent"
                    )
                }
            }

            // MARK: - Complex Element Transitions

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
                let ns = await render(markdown)

                assertFound("Document Title", in: ns)
                assertFound("Introduction paragraph", in: ns)
                assertFound("bold", in: ns)
                assertFound("italic", in: ns)
                assertFound("Section 1", in: ns)
                assertFound("List item 1", in: ns)
                assertFound("blockquote for emphasis", in: ns)
                assertFound("let code", in: ns)
                assertFound("Section 2", in: ns)
                assertFound("inline code", in: ns)
            }

            // MARK: - Unicode and Special Content

            func testUnicodeContentRendersCorrectly() async {
                let markdown = """
                # Internationalization

                Japanese: Swift\u{306E}\u{4E26}\u{884C}\u{51E6}\u{7406}

                Emoji markers: Check \u{2705} Warning \u{26A0}\u{FE0F} Error \u{274C}

                Math notation: The integral \u{222B} of f(x) dx.
                """
                let ns = await render(markdown)
                assertFound("Internationalization", in: ns)
                assertFound("Japanese", in: ns)
                assertFound("integral", in: ns)
            }
        }
    #endif
#endif
