#if canImport(XCTest)
    internal import XCTest
    @testable internal import mdviewer

    final class mdviewerTests: XCTestCase {
        // MARK: - Stable raw-value contracts

        func testAppThemeRawValuesRemainStable() {
            XCTAssertEqual(AppTheme.basic.rawValue, "Basic")
            XCTAssertEqual(AppTheme.github.rawValue, "GitHub")
            XCTAssertEqual(AppTheme.docC.rawValue, "DocC")
        }

        func testSyntaxPalettesRemainStable() {
            XCTAssertEqual(SyntaxPalette.sundellsColors.rawValue, "Sundell's Colors")
            XCTAssertEqual(SyntaxPalette.midnight.rawValue, "Midnight")
            XCTAssertEqual(SyntaxPalette.sunset.rawValue, "Sunset")
        }

        // MARK: - SyntaxPalette.from()

        func testSyntaxPaletteFromExactMatch() {
            XCTAssertEqual(SyntaxPalette.from(rawValue: "Midnight"), .midnight)
            XCTAssertEqual(SyntaxPalette.from(rawValue: "Sunset"), .sunset)
        }

        func testSyntaxPaletteFromCaseInsensitiveFallback() {
            XCTAssertEqual(SyntaxPalette.from(rawValue: "midnight"), .midnight)
            XCTAssertEqual(SyntaxPalette.from(rawValue: "SUNSET"), .sunset)
        }

        func testSyntaxPaletteFromSmartQuoteNormalization() {
            // Persisted preferences may contain a typographic apostrophe instead of straight one.
            XCTAssertEqual(SyntaxPalette.from(rawValue: "Sundell\u{2019}s Colors"), .sundellsColors)
        }

        func testSyntaxPaletteFromUnknownDefaultsMidnight() {
            XCTAssertEqual(SyntaxPalette.from(rawValue: "NonExistent"), .midnight)
            XCTAssertEqual(SyntaxPalette.from(rawValue: ""), .midnight)
        }

        // MARK: - AppearanceMode

        func testAppearanceModePreferredColorScheme() {
            XCTAssertNil(AppearanceMode.auto.preferredColorScheme)
            XCTAssertEqual(AppearanceMode.light.preferredColorScheme, .light)
            XCTAssertEqual(AppearanceMode.dark.preferredColorScheme, .dark)
        }

        func testAppearanceModeFromUnknownDefaultsAuto() {
            XCTAssertEqual(AppearanceMode.from(rawValue: "unknown"), .auto)
            XCTAssertEqual(AppearanceMode.from(rawValue: ""), .auto)
        }

        // MARK: - Factory fallbacks

        func testReaderFontFamilyFromUnknownDefaultsNewYork() {
            XCTAssertEqual(ReaderFontFamily.from(rawValue: "unknown"), .newYork)
        }

        func testReaderFontSizeFromUnknownDefaultsStandard() {
            XCTAssertEqual(ReaderFontSize.from(rawValue: 0), .standard)
        }

        func testReaderTextSpacingFromUnknownDefaultsBalanced() {
            XCTAssertEqual(ReaderTextSpacing.from(rawValue: "unknown"), .balanced)
        }

        func testReaderColumnWidthFromUnknownDefaultsBalanced() {
            XCTAssertEqual(ReaderColumnWidth.from(rawValue: "unknown"), .balanced)
        }
    }
#endif
