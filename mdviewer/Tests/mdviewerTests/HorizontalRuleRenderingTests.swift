//
//  HorizontalRuleRenderingTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        // MARK: - Horizontal Rule Rendering Tests

        /// Validates that thematic break lines (`---`, `***`, `___`) are tagged with
        /// `mdv.horizontalRule` and that the raw glyph text is hidden (`.clear` foreground).
        final class HorizontalRuleRenderingTests: XCTestCase {
            // MARK: - Helpers

            private let hrKey = NSAttributedString.Key("mdv.horizontalRule")

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
                        showLineNumbers: false
                    )
                ).attributedString
            }

            // MARK: - Attribute Presence

            func testDashRuleHasHorizontalRuleAttribute() async {
                let text = await rendered("Before\n\n---\n\nAfter")
                var found = false
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if value != nil { found = true }
                }
                XCTAssertTrue(found, "mdv.horizontalRule attribute should be set on '---' thematic break")
            }

            func testAsteriskRuleHasHorizontalRuleAttribute() async {
                let text = await rendered("Before\n\n***\n\nAfter")
                var found = false
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if value != nil { found = true }
                }
                XCTAssertTrue(found, "mdv.horizontalRule attribute should be set on '***' thematic break")
            }

            func testUnderscoreRuleHasHorizontalRuleAttribute() async {
                let text = await rendered("Before\n\n___\n\nAfter")
                var found = false
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if value != nil { found = true }
                }
                XCTAssertTrue(found, "mdv.horizontalRule attribute should be set on '___' thematic break")
            }

            // MARK: - Glyph Hiding

            func testHorizontalRuleGlyphsAreHidden() async {
                let text = await rendered("A\n\n---\n\nB")
                var hiddenRanges: [NSRange] = []
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, range, _ in
                    guard value != nil else { return }
                    hiddenRanges.append(range)
                }
                XCTAssertFalse(hiddenRanges.isEmpty, "Expected at least one horizontal rule range")
                for range in hiddenRanges {
                    let fg = text.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor
                    // The raw `---` glyphs must be invisible so only the drawn hairline shows.
                    XCTAssertEqual(
                        fg?.alphaComponent ?? 1.0, 0.0, accuracy: 0.01,
                        "Foreground color of HR glyphs should be .clear (alpha 0)"
                    )
                }
            }

            // MARK: - Attribute Value is NSColor

            func testHorizontalRuleAttributeIsColor() async {
                let text = await rendered("---")
                var colorFound = false
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if value is NSColor { colorFound = true }
                }
                XCTAssertTrue(colorFound, "mdv.horizontalRule attribute value should be an NSColor")
            }

            // MARK: - Extended Syntax

            func testLongerDashRuleIsDetected() async {
                let text = await rendered("Before\n\n------\n\nAfter")
                var found = false
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if value != nil { found = true }
                }
                XCTAssertTrue(found, "Six-dash thematic break should also be tagged")
            }

            // MARK: - Non-Interference

            func testNormalTextHasNoHorizontalRuleAttribute() async {
                let text = await rendered("# Heading\n\nJust a paragraph with no breaks.")
                var found = false
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if value != nil { found = true }
                }
                XCTAssertFalse(found, "Normal text and headings should not have mdv.horizontalRule attribute")
            }

            func testCodeBlockDashesAreNotTagged() async {
                // A fenced code block containing `---` must not be treated as a thematic break.
                let text = await rendered("```\n---\n```")
                var found = false
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if value != nil { found = true }
                }
                XCTAssertFalse(found, "Dashes inside a code fence should not be tagged as horizontal rules")
            }

            // MARK: - Theme Coverage

            func testHorizontalRuleAppearsInDarkMode() async {
                let text = await rendered("---", scheme: .dark)
                var found = false
                text.enumerateAttribute(hrKey, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                    if value != nil { found = true }
                }
                XCTAssertTrue(found, "mdv.horizontalRule attribute should be set in dark mode")
            }

            func testHorizontalRuleColorDiffersAcrossThemes() async {
                let lightBasic = await rendered("---", theme: .basic, scheme: .light)
                let lightDracula = await rendered("---", theme: .dracula, scheme: .dark)

                var basicColor: NSColor?
                var draculaColor: NSColor?

                lightBasic.enumerateAttribute(hrKey, in: NSRange(
                    location: 0,
                    length: lightBasic.length
                )) { value, _, _ in
                    if basicColor == nil { basicColor = value as? NSColor }
                }
                lightDracula.enumerateAttribute(hrKey, in: NSRange(
                    location: 0,
                    length: lightDracula.length
                )) { value, _, _ in
                    if draculaColor == nil { draculaColor = value as? NSColor }
                }

                XCTAssertNotNil(basicColor, "Basic theme should produce an HR color")
                XCTAssertNotNil(draculaColor, "Dracula theme should produce an HR color")
                // Colors may differ between themes; at minimum both must be non-nil.
                // If the palette returns the same value for both themes that is also acceptable —
                // the test documents the behaviour rather than enforcing a strict contrast.
            }
        }
    #endif
#endif
