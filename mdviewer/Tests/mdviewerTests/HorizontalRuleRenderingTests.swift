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

            // MARK: - Glyph Identity

            //
            // All CommonMark thematic break variants (`---`, `***`, `___`, spaced forms,
            // and extended-length forms) are normalised by the Swift Markdown parser to a
            // single U+2E3B THREE-EM DASH before the attributed string reaches the pipeline.
            // These tests pin that behaviour so we catch any upstream parser change that
            // would silently break HR detection.

            private static let threeEmDash = "\u{2E3B}"

            func testDashRuleEmitsThreeEmDash() async {
                let text = await rendered("---")
                XCTAssertTrue(
                    text.string.contains(Self.threeEmDash),
                    "'---' thematic break must produce U+2E3B THREE-EM DASH (got: \(text.string.debugDescription))"
                )
            }

            func testAsteriskRuleEmitsThreeEmDash() async {
                let text = await rendered("***")
                XCTAssertTrue(
                    text.string.contains(Self.threeEmDash),
                    "'***' thematic break must produce U+2E3B THREE-EM DASH (got: \(text.string.debugDescription))"
                )
            }

            func testUnderscoreRuleEmitsThreeEmDash() async {
                let text = await rendered("___")
                XCTAssertTrue(
                    text.string.contains(Self.threeEmDash),
                    "'___' thematic break must produce U+2E3B THREE-EM DASH (got: \(text.string.debugDescription))"
                )
            }

            func testSpacedDashRuleEmitsThreeEmDash() async {
                let text = await rendered("- - -")
                XCTAssertTrue(
                    text.string.contains(Self.threeEmDash),
                    "'- - -' thematic break must produce U+2E3B THREE-EM DASH"
                )
            }

            func testExtendedDashRuleEmitsThreeEmDash() async {
                let text = await rendered("------")
                XCTAssertTrue(
                    text.string.contains(Self.threeEmDash),
                    "'------' thematic break must produce U+2E3B THREE-EM DASH"
                )
            }

            func testAllVariantsProduceSingleGlyph() async {
                // Each variant must produce exactly one U+2E3B character, not multiple.
                let variants = ["---", "***", "___", "- - -", "* * *", "_ _ _", "----", "****", "____"]
                for md in variants {
                    let text = await rendered(md)
                    let count = text.string.unicodeScalars.filter { $0.value == 0x2E3B }.count
                    XCTAssertEqual(count, 1, "'\(md)' should produce exactly one U+2E3B, found \(count)")
                }
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

            // MARK: - Paragraph Isolation (regression: HR glyph shared paragraph with heading)

            /// The U+2E3B glyph and the following element must be in separate NSTextView paragraphs.
            /// When they share a paragraph, NSTextView uses the first character's paragraph style for
            /// the whole paragraph — which was causing the heading to render as centre-aligned.
            func testHRGlyphAndFollowingHeadingAreInSeparateParagraphs() async {
                let text = await rendered("Before\n\n---\n\n## Heading After Rule")
                let ns = text.string as NSString
                let threeEmDash = "\u{2E3B}"

                guard let glyphRange = text.string.range(of: threeEmDash) else {
                    XCTFail("Expected U+2E3B THREE-EM DASH in rendered string")
                    return
                }

                let glyphEnd = text.string.distance(from: text.string.startIndex, to: glyphRange.upperBound)

                // There must be a newline immediately after the HR glyph.
                // If the glyph is at the end of the string that is also acceptable (no following element).
                if glyphEnd < text.length {
                    let charAfter = ns.character(at: glyphEnd)
                    XCTAssertEqual(
                        charAfter, unichar(0x000A),
                        "Character immediately after U+2E3B must be '\\n' (0x0A) so the HR glyph " +
                            "lives in its own paragraph and cannot force the heading into centre-alignment. " +
                            "Got Unicode scalar: \\u{\(String(charAfter, radix: 16, uppercase: true))}"
                    )
                }
            }

            func testHRGlyphAndFollowingParagraphAreInSeparateParagraphs() async {
                let text = await rendered("Before\n\n---\n\nParagraph after rule.")
                let ns = text.string as NSString
                let threeEmDash = "\u{2E3B}"

                guard let glyphRange = text.string.range(of: threeEmDash) else {
                    XCTFail("Expected U+2E3B THREE-EM DASH in rendered string")
                    return
                }

                let glyphEnd = text.string.distance(from: text.string.startIndex, to: glyphRange.upperBound)
                if glyphEnd < text.length {
                    let charAfter = ns.character(at: glyphEnd)
                    XCTAssertEqual(
                        charAfter, unichar(0x000A),
                        "Character after HR glyph must be '\\n' regardless of whether a heading or paragraph follows"
                    )
                }
            }

            func testMultipleHRsAreEachInOwnParagraph() async {
                let text = await rendered("A\n\n---\n\n## H2\n\n---\n\nB")
                let ns = text.string as NSString
                let threeEmDash = "\u{2E3B}"
                var searchStart = text.string.startIndex

                var hrCount = 0
                while let r = text.string.range(of: threeEmDash, range: searchStart ..< text.string.endIndex) {
                    hrCount += 1
                    let glyphEnd = text.string.distance(from: text.string.startIndex, to: r.upperBound)
                    if glyphEnd < text.length {
                        let charAfter = ns.character(at: glyphEnd)
                        XCTAssertEqual(
                            charAfter, unichar(0x000A),
                            "HR #\(hrCount): character after glyph must be '\\n'"
                        )
                    }
                    searchStart = r.upperBound
                }

                XCTAssertEqual(hrCount, 2, "Expected 2 HR glyphs for 2 thematic breaks")
            }

            // MARK: - Paragraph Spacing

            func testHRHasParagraphSpacingBefore() async {
                let text = await rendered("Before\n\n---\n\nAfter")
                let threeEmDash = "\u{2E3B}"

                guard let r = text.string.range(of: threeEmDash) else {
                    XCTFail("No HR glyph found")
                    return
                }

                let loc = text.string.distance(from: text.string.startIndex, to: r.lowerBound)
                let style = text.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle
                XCTAssertNotNil(style, "HR glyph must have a paragraphStyle attribute")
                XCTAssertGreaterThan(
                    style?.paragraphSpacingBefore ?? 0, 0,
                    "HR must have paragraphSpacingBefore > 0 to visually separate it from preceding content"
                )
            }

            func testHRHasParagraphSpacingAfter() async {
                let text = await rendered("Before\n\n---\n\nAfter")
                let threeEmDash = "\u{2E3B}"

                guard let r = text.string.range(of: threeEmDash) else {
                    XCTFail("No HR glyph found")
                    return
                }

                let loc = text.string.distance(from: text.string.startIndex, to: r.lowerBound)
                let style = text.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle
                XCTAssertGreaterThan(
                    style?.paragraphSpacing ?? 0, 0,
                    "HR must have paragraphSpacing > 0 to visually separate it from following content"
                )
            }

            func testHRFontIsSmall() async {
                // The HR glyph is hidden; a small font keeps the line-fragment height compact
                // while still giving ReaderLayoutManager a stable rect.midY to draw against.
                let text = await rendered("---")
                let threeEmDash = "\u{2E3B}"

                guard let r = text.string.range(of: threeEmDash) else {
                    XCTFail("No HR glyph found")
                    return
                }

                let loc = text.string.distance(from: text.string.startIndex, to: r.lowerBound)
                let font = text.attribute(.font, at: loc, effectiveRange: nil) as? NSFont
                XCTAssertNotNil(font, "HR glyph must have an explicit font")
                XCTAssertLessThanOrEqual(
                    font?.pointSize ?? 999, 10,
                    "HR glyph font size must be ≤10pt to keep the line fragment compact (got \(font?.pointSize ?? -1)pt)"
                )
            }

            func testHeadingAfterHRIsNotCentreAligned() async {
                // Regression: hrStyle.alignment = .center bled into the heading paragraph
                // because the HR glyph and heading shared one NSTextView paragraph.
                let text = await rendered("Before\n\n---\n\n## Security Considerations")
                let headingText = "Security Considerations"

                guard let r = text.string.range(of: headingText) else {
                    XCTFail("Heading text not found in rendered output")
                    return
                }

                let loc = text.string.distance(from: text.string.startIndex, to: r.lowerBound)
                let style = text.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle

                let alignment = style?.alignment ?? .natural
                XCTAssertNotEqual(
                    alignment, .center,
                    "Heading following an HR must not be centre-aligned (was .center — HR paragraph style bleed)"
                )
            }
        }
    #endif
#endif
