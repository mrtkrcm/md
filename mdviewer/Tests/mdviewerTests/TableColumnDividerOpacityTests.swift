//
//  TableColumnDividerOpacityTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        // MARK: - Table Column Divider Opacity Tests

        /// Validates the per-theme column divider opacity attribute introduced to give
        /// interior column guides a lighter visual weight than the outer table border.
        final class TableColumnDividerOpacityTests: XCTestCase {
            // MARK: - Helpers

            private let dividerOpacityKey = NSAttributedString.Key("mdv.tableColumnDividerOpacity")

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

            // MARK: - Attribute presence

            func testTableHeaderRowCarriesColumnDividerOpacityAttribute() async {
                let markdown = """
                | A | B | C |
                | - | - | - |
                | 1 | 2 | 3 |
                """
                let result = await rendered(markdown, theme: .github, scheme: .light)
                let ns = result.string as NSString
                let headerLoc = ns.range(of: "A").location
                XCTAssertNotEqual(headerLoc, NSNotFound, "Table header text must appear in rendered output")
                let value = result.attribute(dividerOpacityKey, at: headerLoc, effectiveRange: nil)
                XCTAssertNotNil(value, "Header row must carry mdv.tableColumnDividerOpacity attribute")
                if let multiplier = value as? CGFloat {
                    XCTAssertGreaterThan(multiplier, 0, "Multiplier must be positive")
                    XCTAssertLessThanOrEqual(multiplier, 1, "Multiplier must not exceed 1")
                }
            }

            func testTableBodyRowCarriesColumnDividerOpacityAttribute() async {
                let markdown = """
                | Name | Value |
                | ---- | ----- |
                | Foo  | Bar   |
                """
                let result = await rendered(markdown, theme: .dracula, scheme: .dark)
                let ns = result.string as NSString
                let rowLoc = ns.range(of: "Foo").location
                XCTAssertNotEqual(rowLoc, NSNotFound, "Table body text must appear in rendered output")
                let value = result.attribute(dividerOpacityKey, at: rowLoc, effectiveRange: nil)
                XCTAssertNotNil(value, "Body row must carry mdv.tableColumnDividerOpacity attribute")
                if let multiplier = value as? CGFloat {
                    XCTAssertGreaterThan(multiplier, 0)
                    XCTAssertLessThanOrEqual(multiplier, 1)
                }
            }

            // MARK: - Hierarchy contract

            func testColumnDividerOpacityIsHigherForVividDarkThemes() async {
                // Vivid dark-first themes must exceed minimal themes so column guides
                // remain legible on dark surfaces without competing with the outer border.
                let markdown = "| X | Y |\n| - | - |\n| a | b |"

                let vividResult = await rendered(markdown, theme: .dracula, scheme: .dark)
                let minimalResult = await rendered(markdown, theme: .basic, scheme: .light)

                let vividNS = vividResult.string as NSString
                let vividLoc = vividNS.range(of: "X").location
                guard vividLoc != NSNotFound else { XCTFail("Header not found in vivid result"); return }
                let vividMultiplier = vividResult.attribute(
                    dividerOpacityKey, at: vividLoc, effectiveRange: nil
                ) as? CGFloat ?? 0

                let minimalNS = minimalResult.string as NSString
                let minimalLoc = minimalNS.range(of: "X").location
                guard minimalLoc != NSNotFound else { XCTFail("Header not found in minimal result"); return }
                let minimalMultiplier = minimalResult.attribute(
                    dividerOpacityKey, at: minimalLoc, effectiveRange: nil
                ) as? CGFloat ?? 0

                XCTAssertGreaterThan(
                    vividMultiplier,
                    minimalMultiplier,
                    "Vivid dark theme (\(vividMultiplier)) must exceed minimal light theme (\(minimalMultiplier))"
                )
            }

            func testDarkModeHasHigherMultiplierThanLightModeForSameTheme() {
                // Dark mode adds +0.08 boost so dividers remain visible against dark surfaces.
                for theme in AppTheme.allCases {
                    let lightPalette = NativeThemePalette(theme: theme, scheme: .light)
                    let darkPalette = NativeThemePalette(theme: theme, scheme: .dark)
                    XCTAssertGreaterThan(
                        darkPalette.tableColumnDividerOpacityMultiplier(),
                        lightPalette.tableColumnDividerOpacityMultiplier(),
                        "\(theme): dark multiplier must exceed light multiplier"
                    )
                }
            }

            // MARK: - Safety bounds

            func testColumnDividerOpacityMultiplierIsValidRangeForAllThemes() {
                // Every theme+scheme combination must stay in the 0–1 range the layout
                // manager passes to withAlphaComponent(_:). Out-of-range values would be
                // clamped defensively but indicate a misconfigured token.
                let schemes: [ColorScheme] = [.light, .dark]
                for theme in AppTheme.allCases {
                    for scheme in schemes {
                        let palette = NativeThemePalette(theme: theme, scheme: scheme)
                        let multiplier = palette.tableColumnDividerOpacityMultiplier()
                        XCTAssertGreaterThan(
                            multiplier, 0,
                            "\(theme)/\(scheme): multiplier must be positive"
                        )
                        XCTAssertLessThanOrEqual(
                            multiplier, 1,
                            "\(theme)/\(scheme): multiplier must not exceed 1"
                        )
                    }
                }
            }

            // MARK: - Cell spacing

            func testTableRowParagraphSpacingIsScaledWithFontSize() async {
                // Cell spacing must scale with font size and exceed the legacy fixed 5pt value.
                let markdown = "| Col |\n| --- |\n| Cell |"
                let result = await rendered(markdown, theme: .github, scheme: .light)
                let ns = result.string as NSString
                let loc = ns.range(of: "Cell").location
                XCTAssertNotEqual(loc, NSNotFound, "Cell text must appear in rendered output")

                let style = result.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle
                XCTAssertNotNil(style, "Table rows must carry a paragraph style attribute")
                // Standard font size (17pt): cellSpacing = max(6, 17 × 0.36) ≈ 6.12pt
                XCTAssertGreaterThan(
                    style?.paragraphSpacing ?? 0,
                    5,
                    "paragraphSpacing must exceed the previous fixed 5pt value"
                )
                XCTAssertGreaterThan(
                    style?.paragraphSpacingBefore ?? 0,
                    0,
                    "paragraphSpacingBefore must be positive — cells need symmetric top cushion"
                )
            }
        }
    #endif
#endif
