//
//  ThemeApplicationTests.swift
//  mdviewer
//
//  Comprehensive tests for theme application, caching, and color validation.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        /// Comprehensive tests for theme application, caching, and validation.
        @MainActor
        final class ThemeApplicationTests: XCTestCase {
            // MARK: - Palette Cache Tests

            /// Test that palette caching returns the same instance for same theme/scheme.
            func testPaletteCachingReturnsSameInstance() {
                let theme = AppTheme.github
                let scheme = ColorScheme.light

                let palette1 = NativeThemePalette.cached(theme: theme, scheme: scheme)
                let palette2 = NativeThemePalette.cached(theme: theme, scheme: scheme)

                // Both should be equal (struct equality)
                XCTAssertEqual(palette1.theme, palette2.theme)
                XCTAssertEqual(palette1.scheme, palette2.scheme)
            }

            /// Test that different themes return different palettes.
            func testDifferentThemesReturnDifferentPalettes() {
                let lightPalette = NativeThemePalette.cached(theme: .github, scheme: .light)
                let darkPalette = NativeThemePalette.cached(theme: .github, scheme: .dark)

                // Light and dark should have different colors
                XCTAssertNotEqual(
                    lightPalette.textPrimary.hexString,
                    darkPalette.textPrimary.hexString,
                    "Light and dark text colors should differ"
                )
            }

            /// Test that all theme/scheme combinations can be cached.
            func testAllThemeSchemeCombinationsCanBeCached() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)
                        XCTAssertEqual(palette.theme, theme)
                        XCTAssertEqual(palette.scheme, scheme)
                    }
                }
            }

            // MARK: - Color Validation Tests

            /// Test that all themes have non-transparent text colors.
            func testAllThemesHaveOpaqueTextColors() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)

                        XCTAssertGreaterThan(
                            palette.textPrimary.alphaComponent,
                            0.5,
                            "\(theme.rawValue) \(scheme) textPrimary should be mostly opaque"
                        )
                        XCTAssertGreaterThan(
                            palette.textSecondary.alphaComponent,
                            0.3,
                            "\(theme.rawValue) \(scheme) textSecondary should have reasonable opacity"
                        )
                    }
                }
            }

            /// Test that all themes have valid background colors for code blocks.
            func testAllThemesHaveValidCodeBackgrounds() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)

                        XCTAssertGreaterThan(
                            palette.codeBackground.alphaComponent,
                            0.1,
                            "\(theme.rawValue) \(scheme) codeBackground should be visible"
                        )
                    }
                }
            }

            /// Test that link colors are distinct from text colors.
            func testLinkColorsAreDistinctFromText() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)

                        // Link should be different from primary text
                        XCTAssertNotEqual(
                            palette.link.hexString,
                            palette.textPrimary.hexString,
                            "\(theme.rawValue) \(scheme) link should differ from textPrimary"
                        )
                    }
                }
            }

            /// Test that accent colors are valid.
            func testAllThemesHaveValidAccentColors() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)

                        XCTAssertGreaterThan(
                            palette.accent.alphaComponent,
                            0.5,
                            "\(theme.rawValue) \(scheme) accent should be visible"
                        )
                    }
                }
            }

            /// Test that heading colors are valid across all themes.
            func testAllThemesHaveValidHeadingColors() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)

                        XCTAssertGreaterThan(
                            palette.heading.alphaComponent,
                            0.5,
                            "\(theme.rawValue) \(scheme) heading should be visible"
                        )
                        XCTAssertGreaterThan(
                            palette.heading1.alphaComponent,
                            0.5,
                            "\(theme.rawValue) \(scheme) heading1 should be visible"
                        )
                    }
                }
            }

            /// Test that selection colors are valid.
            func testAllThemesHaveValidSelectionColors() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)

                        XCTAssertGreaterThan(
                            palette.selectionBackground.alphaComponent,
                            0.1,
                            "\(theme.rawValue) \(scheme) selectionBackground should be visible"
                        )
                    }
                }
            }

            // MARK: - Theme Application Tests

            /// Test that theme colors are actually applied to rendered text.
            func testThemeColorsAreAppliedToRenderedText() async {
                let markdown = "Hello **world**"
                let theme = AppTheme.dracula
                let scheme = ColorScheme.dark

                let request = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: theme,
                    colorScheme: scheme,
                    textSpacing: .balanced,
                    readableWidth: 720,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let result = await MarkdownRenderService.shared.render(request)
                let text = result.attributedString

                // Verify foreground color is applied
                var foundForegroundColor = false
                text.enumerateAttribute(
                    .foregroundColor,
                    in: NSRange(location: 0, length: text.length)
                ) { value, _, _ in
                    if let _ = value as? NSColor {
                        foundForegroundColor = true
                    }
                }

                XCTAssertTrue(foundForegroundColor, "Theme foreground color should be applied")
            }

            /// Test that switching themes produces different output.
            func testThemeSwitchProducesDifferentColors() async {
                let markdown = "Test paragraph"

                let lightRequest = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .github,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 720,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let darkRequest = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .github,
                    colorScheme: .dark,
                    textSpacing: .balanced,
                    readableWidth: 720,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                let lightResult = await MarkdownRenderService.shared.render(lightRequest)
                let darkResult = await MarkdownRenderService.shared.render(darkRequest)

                // Extract colors from both renders
                var lightColors: [String] = []
                var darkColors: [String] = []

                lightResult.attributedString.enumerateAttribute(
                    .foregroundColor,
                    in: NSRange(location: 0, length: lightResult.attributedString.length)
                ) { value, _, _ in
                    if let color = value as? NSColor {
                        lightColors.append(color.hexString)
                    }
                }

                darkResult.attributedString.enumerateAttribute(
                    .foregroundColor,
                    in: NSRange(location: 0, length: darkResult.attributedString.length)
                ) { value, _, _ in
                    if let color = value as? NSColor {
                        darkColors.append(color.hexString)
                    }
                }

                // Colors should be different
                XCTAssertNotEqual(lightColors, darkColors, "Light and dark themes should produce different colors")
            }

            /// Test that all themes can be rendered without errors.
            func testAllThemesRenderWithoutErrors() async {
                let markdown = """
                # Heading

                Paragraph with **bold** and *italic* text.

                - List item
                - Another item

                > Blockquote

                ```swift
                let code = true
                ```
                """

                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let request = RenderRequest(
                            markdown: markdown,
                            readerFontFamily: .newYork,
                            readerFontSize: 16,
                            codeFontSize: 14,
                            appTheme: theme,
                            colorScheme: scheme,
                            textSpacing: .balanced,
                            readableWidth: 720,
                            showLineNumbers: false,
                            typographyPreferences: TypographyPreferences()
                        )

                        let result = await MarkdownRenderService.shared.render(request)
                        XCTAssertFalse(
                            result.attributedString.string.isEmpty,
                            "\(theme.rawValue) \(scheme) should render non-empty content"
                        )
                    }
                }
            }

            // MARK: - Derived Colors Tests

            /// Test that formatted heading colors are computed.
            func testFormattedHeadingColorsExist() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)

                        XCTAssertGreaterThan(
                            palette.formattedHeading.alphaComponent,
                            0.5,
                            "\(theme.rawValue) \(scheme) formattedHeading should be visible"
                        )
                    }
                }
            }

            /// Test that table formatting colors are computed.
            func testTableFormattingColorsExist() {
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette.cached(theme: theme, scheme: scheme)

                        XCTAssertGreaterThan(
                            palette.formattedTableHeaderSurface.alphaComponent,
                            0.1,
                            "\(theme.rawValue) \(scheme) formattedTableHeaderSurface should be visible"
                        )
                        XCTAssertGreaterThan(
                            palette.formattedTableHeaderText.alphaComponent,
                            0.5,
                            "\(theme.rawValue) \(scheme) formattedTableHeaderText should be visible"
                        )
                        XCTAssertGreaterThan(
                            palette.formattedTableBodySurface.alphaComponent,
                            0.1,
                            "\(theme.rawValue) \(scheme) formattedTableBodySurface should be visible"
                        )
                        XCTAssertGreaterThan(
                            palette.formattedTableRowSurface.alphaComponent,
                            0.1,
                            "\(theme.rawValue) \(scheme) formattedTableRowSurface should be visible"
                        )
                        XCTAssertGreaterThan(
                            palette.formattedTableBorderStroke.alphaComponent,
                            0.1,
                            "\(theme.rawValue) \(scheme) formattedTableBorderStroke should be visible"
                        )
                    }
                }
            }

            // MARK: - Performance Tests

            /// Test that palette caching improves performance.
            func testPaletteCachingPerformance() {
                let theme = AppTheme.github
                let scheme = ColorScheme.light

                // Warm up cache
                _ = NativeThemePalette.cached(theme: theme, scheme: scheme)

                // Measure cached access
                measure {
                    for _ in 0 ..< 1000 {
                        _ = NativeThemePalette.cached(theme: theme, scheme: scheme)
                    }
                }
            }
        }

        // MARK: - NSColor Extensions for Testing

        extension NSColor {
            /// Returns a hex string representation for comparison.
            var hexString: String {
                guard let rgb = usingColorSpace(.deviceRGB) else {
                    return "invalid"
                }
                let r = Int(rgb.redComponent * 255)
                let g = Int(rgb.greenComponent * 255)
                let b = Int(rgb.blueComponent * 255)
                return String(format: "#%02X%02X%02X", r, g, b)
            }
        }
    #endif
#endif
