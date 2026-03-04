//
//  ThemeSpacingTests.swift
//  mdviewer
//
//  Tests for theme + paragraph spacing compatibility across all 10 themes.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        final class ThemeSpacingTests: XCTestCase {
            // MARK: - Theme + Spacing Compatibility

            /// Test that all 10 themes render with correct paragraph spacing in light mode.
            func testAllThemesRenderWithProperSpacingLight() async {
                let markdown = """
                # Heading 1

                First paragraph with content.

                Second paragraph follows.

                - List item 1
                - List item 2

                > A blockquote

                Final paragraph.
                """

                for theme in AppTheme.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .newYork,
                        readerFontSize: 16,
                        codeFontSize: 12,
                        appTheme: theme,
                        syntaxPalette: .midnight,
                        colorScheme: .light,
                        textSpacing: .balanced,
                        readableWidth: 760,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )

                    let rendered = await MarkdownRenderService.shared.render(request)
                    let text = rendered.attributedString

                    // Verify that spacing is applied for this theme
                    var foundSpacedContent = false
                    text.enumerateAttribute(.paragraphStyle, in: NSRange(
                        location: 0,
                        length: text.length
                    )) { value, _, _ in
                        if let style = value as? NSParagraphStyle, style.paragraphSpacing > 0 {
                            foundSpacedContent = true
                        }
                    }

                    XCTAssertTrue(
                        foundSpacedContent,
                        "Theme \(theme.rawValue) should have paragraph spacing in light mode"
                    )
                }
            }

            /// Test that all 10 themes render with correct paragraph spacing in dark mode.
            func testAllThemesRenderWithProperSpacingDark() async {
                let markdown = """
                # Heading 1

                Content paragraph.

                Another paragraph.
                """

                for theme in AppTheme.allCases {
                    let request = RenderRequest(
                        markdown: markdown,
                        readerFontFamily: .newYork,
                        readerFontSize: 16,
                        codeFontSize: 12,
                        appTheme: theme,
                        syntaxPalette: .midnight,
                        colorScheme: .dark,
                        textSpacing: .balanced,
                        readableWidth: 760,
                        showLineNumbers: false,
                        typographyPreferences: TypographyPreferences()
                    )

                    let rendered = await MarkdownRenderService.shared.render(request)
                    let text = rendered.attributedString

                    // Verify that spacing is applied for this theme
                    var foundSpacedContent = false
                    text.enumerateAttribute(.paragraphStyle, in: NSRange(
                        location: 0,
                        length: text.length
                    )) { value, _, _ in
                        if let style = value as? NSParagraphStyle, style.paragraphSpacing > 0 {
                            foundSpacedContent = true
                        }
                    }

                    XCTAssertTrue(
                        foundSpacedContent,
                        "Theme \(theme.rawValue) should have paragraph spacing in dark mode"
                    )
                }
            }

            /// Test that all themes work with all spacing preferences.
            func testAllThemesWithAllSpacingPreferences() async {
                let markdown = "Para 1\n\nPara 2"

                for theme in AppTheme.allCases {
                    for spacing in ReaderTextSpacing.allCases {
                        let request = RenderRequest(
                            markdown: markdown,
                            readerFontFamily: .newYork,
                            readerFontSize: 16,
                            codeFontSize: 12,
                            appTheme: theme,
                            syntaxPalette: .midnight,
                            colorScheme: .light,
                            textSpacing: spacing,
                            readableWidth: 760,
                            showLineNumbers: false,
                            typographyPreferences: TypographyPreferences()
                        )

                        let rendered = await MarkdownRenderService.shared.render(request)
                        XCTAssertNotNil(
                            rendered,
                            "Theme \(theme.rawValue) should render with spacing \(spacing.rawValue)"
                        )
                    }
                }
            }

            /// Test that code blocks have proper background colors across themes.
            func testCodeBlockColorsAcrossThemes() async {
                let markdown = "```swift\nlet x = 1\n```"

                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let request = RenderRequest(
                            markdown: markdown,
                            readerFontFamily: .newYork,
                            readerFontSize: 16,
                            codeFontSize: 12,
                            appTheme: theme,
                            syntaxPalette: .midnight,
                            colorScheme: scheme,
                            textSpacing: .balanced,
                            readableWidth: 760,
                            showLineNumbers: false,
                            typographyPreferences: TypographyPreferences()
                        )

                        let rendered = await MarkdownRenderService.shared.render(request)
                        let text = rendered.attributedString

                        // Verify code background is applied
                        var hasCodeBackground = false
                        text.enumerateAttribute(
                            NSAttributedString.Key.backgroundColor,
                            in: NSRange(location: 0, length: text.length)
                        ) { value, _, _ in
                            if let _ = value as? NSColor {
                                hasCodeBackground = true
                            }
                        }

                        XCTAssertTrue(
                            hasCodeBackground,
                            "Theme \(theme.rawValue) in \(scheme) should have code background"
                        )
                    }
                }
            }

            /// Test that blockquotes have proper styling across themes.
            func testBlockquoteStylingAcrossThemes() async {
                let markdown = "> This is a blockquote"

                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let request = RenderRequest(
                            markdown: markdown,
                            readerFontFamily: .newYork,
                            readerFontSize: 16,
                            codeFontSize: 12,
                            appTheme: theme,
                            syntaxPalette: .midnight,
                            colorScheme: scheme,
                            textSpacing: .balanced,
                            readableWidth: 760,
                            showLineNumbers: false,
                            typographyPreferences: TypographyPreferences()
                        )

                        let rendered = await MarkdownRenderService.shared.render(request)
                        let text = rendered.attributedString

                        // Verify blockquote attributes are applied
                        var hasBlockquoteAttrs = false
                        text.enumerateAttribute(
                            MarkdownRenderAttribute.blockquoteBackground,
                            in: NSRange(location: 0, length: text.length)
                        ) { value, _, _ in
                            if let _ = value as? NSColor {
                                hasBlockquoteAttrs = true
                            }
                        }

                        XCTAssertTrue(
                            hasBlockquoteAttrs,
                            "Theme \(theme.rawValue) in \(scheme) should have blockquote styling"
                        )
                    }
                }
            }

            /// Test that all themes are properly registered and accessible.
            func testAllThemesAreRegistered() {
                let themes = AppTheme.allCases
                XCTAssertEqual(themes.count, 10, "Should have exactly 10 themes")

                let expectedThemes = [
                    "Basic", "GitHub", "DocC",
                    "Solarized", "Gruvbox", "Dracula", "Monokai", "Nord",
                    "One Dark", "Tokyo Night",
                ]

                let registeredNames = themes.map(\.rawValue)
                for expectedName in expectedThemes {
                    XCTAssertTrue(
                        registeredNames.contains(expectedName),
                        "Theme '\(expectedName)' should be registered"
                    )
                }
            }

            /// Test that all themes have descriptions.
            func testAllThemesHaveDescriptions() {
                for theme in AppTheme.allCases {
                    let description = theme.description
                    XCTAssertFalse(description.isEmpty, "Theme \(theme.rawValue) should have a description")
                    XCTAssertGreaterThan(description.count, 5, "Description for \(theme.rawValue) should be meaningful")
                }
            }
        }
    #endif
#endif
