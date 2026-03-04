//
//  ListRenderingStabilityTests.swift
//  mdviewer
//
//  Tests for list marker and content rendering stability.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        // MARK: - List Rendering Stability Tests

        /// Validates that list markers are properly separated from content.
        final class ListRenderingStabilityTests: XCTestCase {
            // MARK: - Helpers

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
                        syntaxPalette: .midnight,
                        colorScheme: scheme,
                        textSpacing: .balanced,
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )
                ).attributedString
            }

            // MARK: - Marker Separation

            /// Test that list items have markers properly separated from content.
            /// This validates the fix for marker/content overlap issues.
            func testUnorderedListMarkersAreSeparatedFromContent() async {
                let text = await rendered("- Item 1\n- Item 2\n- Item 3")

                // Check that the bullet character is present
                XCTAssertTrue(text.string.contains("•"), "Bullet marker should be present")

                // Find the position of each bullet and the content after it
                let itemTexts = ["Item 1", "Item 2", "Item 3"]
                for itemText in itemTexts {
                    guard let itemRange = text.string.range(of: itemText) else {
                        XCTFail("Expected to find '\(itemText)' in rendered output")
                        continue
                    }

                    let nsRange = NSRange(itemRange, in: text.string)

                    // Check that the content has proper paragraph style with headIndent
                    if
                        let style = text.attribute(
                            NSAttributedString.Key.paragraphStyle,
                            at: nsRange.location,
                            effectiveRange: nil
                        ) as? NSParagraphStyle
                    {
                        // List items should have headIndent > 0 for proper indentation
                        XCTAssertGreaterThan(
                            style.headIndent,
                            0,
                            "List item content should have headIndent > 0"
                        )
                    }
                }
            }

            /// Test that ordered list numbers are properly separated from content.
            func testOrderedListNumbersAreSeparatedFromContent() async {
                let text = await rendered("1. First\n2. Second\n3. Third")
                let ns = text.string as NSString

                // Check that numbered markers are present
                XCTAssertTrue(text.string.contains("1."), "Number 1 marker should be present")
                XCTAssertTrue(text.string.contains("2."), "Number 2 marker should be present")
                XCTAssertTrue(text.string.contains("3."), "Number 3 marker should be present")

                // Find positions and check separation
                let firstRange = ns.range(of: "First")
                XCTAssertNotEqual(firstRange.location, NSNotFound, "Should find 'First'")

                if firstRange.location > 0 {
                    // Check the character before "First"
                    let beforeFirst = ns.character(at: firstRange.location - 1)
                    // Should be a tab character separating marker from content
                    XCTAssertEqual(
                        beforeFirst,
                        unichar(0x09),
                        "There should be a tab character between marker and 'First'"
                    )
                }
            }

            /// Test that list items don't overlap with each other.
            func testListItemsDoNotOverlap() async {
                let text = await rendered("- Alpha\n- Beta\n- Gamma")

                // Get ranges of each item's content
                let ns = text.string as NSString
                let alphaRange = ns.range(of: "Alpha")
                let betaRange = ns.range(of: "Beta")
                let gammaRange = ns.range(of: "Gamma")

                XCTAssertNotEqual(alphaRange.location, NSNotFound)
                XCTAssertNotEqual(betaRange.location, NSNotFound)
                XCTAssertNotEqual(gammaRange.location, NSNotFound)

                // Ranges should not overlap
                let alphaEnd = alphaRange.location + alphaRange.length
                let betaEnd = betaRange.location + betaRange.length

                XCTAssertLessThan(
                    alphaEnd,
                    betaRange.location,
                    "Alpha and Beta should not overlap"
                )
                XCTAssertLessThan(
                    betaEnd,
                    gammaRange.location,
                    "Beta and Gamma should not overlap"
                )
            }

            // MARK: - Tab Stops

            /// Test that list items have proper tab stops configured.
            func testListItemsHaveTabStops() async {
                let text = await rendered("- Item content")

                // Find the content and check its tab stops
                guard let itemRange = text.string.range(of: "Item content") else {
                    XCTFail("Should find 'Item content'")
                    return
                }

                let nsRange = NSRange(itemRange, in: text.string)
                guard
                    let style = text.attribute(
                        NSAttributedString.Key.paragraphStyle,
                        at: nsRange.location,
                        effectiveRange: nil
                    ) as? NSParagraphStyle
                else {
                    XCTFail("Should have paragraph style")
                    return
                }

                // Should have at least one tab stop
                XCTAssertFalse(style.tabStops.isEmpty, "List item should have tab stops")

                // Tab stop should be at a reasonable position (e.g., 24pt)
                if let firstTab = style.tabStops.first {
                    XCTAssertGreaterThan(firstTab.location, 0, "Tab stop should be at positive location")
                }
            }

            // MARK: - Nested Lists

            /// Test that nested list items are properly indented.
            func testNestedListIndentation() async {
                let markdown = """
                - Parent 1
                  - Child 1
                  - Child 2
                - Parent 2
                """

                let text = await rendered(markdown)
                let ns = text.string as NSString

                // All items should be present
                XCTAssertTrue(text.string.contains("Parent 1"), "Should find Parent 1")
                XCTAssertTrue(text.string.contains("Child 1"), "Should find Child 1")
                XCTAssertTrue(text.string.contains("Child 2"), "Should find Child 2")
                XCTAssertTrue(text.string.contains("Parent 2"), "Should find Parent 2")

                // Child items should appear after parent items in the string
                let parent1Range = ns.range(of: "Parent 1")
                let child1Range = ns.range(of: "Child 1")

                XCTAssertNotEqual(parent1Range.location, NSNotFound)
                XCTAssertNotEqual(child1Range.location, NSNotFound)

                // Child should come after parent
                XCTAssertGreaterThan(
                    child1Range.location,
                    parent1Range.location,
                    "Child 1 should come after Parent 1"
                )
            }

            // MARK: - Content Interference

            /// Test that code blocks inside lists are handled properly.
            func testCodeBlocksInLists() async {
                let markdown = """
                - Item with code: `code()`
                - Normal item
                """

                let text = await rendered(markdown)

                // Both items should be present
                XCTAssertTrue(text.string.contains("Item with code"))
                XCTAssertTrue(text.string.contains("code()"))
                XCTAssertTrue(text.string.contains("Normal item"))
            }

            /// Regression test: fenced code blocks nested inside unordered list items must
            /// not receive a bullet marker on each line of the code block.
            ///
            /// Before the fix, `insertListMarkers` injected "•\t" at every PresentationIntent
            /// range that had a `listItem` component — including ranges that were simultaneously
            /// tagged `codeBlock`. The result was rendered output like "1 •  quality: {".
            func testFencedCodeBlockInsideUnorderedListHasNoBulletMarkers() async {
                let markdown = """
                - First item

                  ```swift
                  let x = 1
                  let y = 2
                  ```

                - Second item
                """

                let text = await rendered(markdown)
                let ns = text.string as NSString

                // The code content must be present.
                XCTAssertTrue(text.string.contains("let x = 1"), "Code block content must appear in output")
                XCTAssertTrue(text.string.contains("let y = 2"), "Code block content must appear in output")

                // Each line of the code block must NOT be immediately preceded by a bullet.
                for codeLine in ["let x = 1", "let y = 2"] {
                    let lineRange = ns.range(of: codeLine)
                    guard lineRange.location != NSNotFound else {
                        XCTFail("Expected to find '\(codeLine)' in output")
                        continue
                    }
                    // Walk back past whitespace to find the nearest non-whitespace character.
                    var pos = lineRange.location
                    while pos > 0 {
                        pos -= 1
                        let ch = ns.character(at: pos)
                        // Skip tabs (indent) and newlines (line separator).
                        if ch == 0x09 || ch == 0x0A { continue }
                        // The character must not be a bullet.
                        XCTAssertNotEqual(
                            ch,
                            unichar(("•" as Unicode.Scalar).value),
                            "Code block line '\(codeLine)' must not be preceded by a bullet marker"
                        )
                        break
                    }
                }
            }

            /// Regression test: fenced code blocks nested inside ordered list items must
            /// not receive an ordinal marker ("1.\t") on each line of the code block.
            func testFencedCodeBlockInsideOrderedListHasNoOrdinalMarkers() async {
                let markdown = """
                1. First item

                   ```ts
                   const a = true
                   const b = false
                   ```

                2. Second item
                """

                let text = await rendered(markdown)
                let ns = text.string as NSString

                XCTAssertTrue(text.string.contains("const a = true"), "Code block content must appear in output")
                XCTAssertTrue(text.string.contains("const b = false"), "Code block content must appear in output")

                // Ordinal markers ("1.", "2.", …) must not appear immediately before code lines.
                for codeLine in ["const a = true", "const b = false"] {
                    let lineRange = ns.range(of: codeLine)
                    guard lineRange.location != NSNotFound else {
                        XCTFail("Expected to find '\(codeLine)' in output")
                        continue
                    }
                    // The text before each code line (after stripping indent whitespace) must not
                    // end with a digit followed by a period — i.e. an injected ordinal marker.
                    var pos = lineRange.location
                    while pos > 0 {
                        pos -= 1
                        let ch = ns.character(at: pos)
                        if ch == 0x09 || ch == 0x0A { continue }
                        // The character must not be "." (end of an ordinal "N.").
                        XCTAssertNotEqual(
                            ch,
                            unichar(".".unicodeScalars.first!.value),
                            "Code block line '\(codeLine)' must not be preceded by an ordinal marker"
                        )
                        break
                    }
                }
            }

            /// Test that paragraphs following lists don't inherit list styling.
            func testParagraphAfterList() async {
                let markdown = """
                - List item

                Paragraph after list.
                """

                let text = await rendered(markdown)

                XCTAssertTrue(text.string.contains("List item"))
                XCTAssertTrue(text.string.contains("Paragraph after list"))

                // Find the paragraph and check it doesn't have list headIndent
                guard let paraRange = text.string.range(of: "Paragraph after list") else {
                    XCTFail("Should find paragraph")
                    return
                }

                let nsRange = NSRange(paraRange, in: text.string)
                if
                    let style = text.attribute(
                        NSAttributedString.Key.paragraphStyle,
                        at: nsRange.location,
                        effectiveRange: nil
                    ) as? NSParagraphStyle
                {
                    // Paragraphs after lists should have smaller headIndent than list items
                    // (or the default 0)
                    XCTAssertLessThanOrEqual(
                        style.headIndent,
                        24,
                        "Paragraph after list should not have large headIndent"
                    )
                }
            }
        }
    #endif
#endif
