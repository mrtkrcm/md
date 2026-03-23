//
//  mdviewerTests.swift
//  mdviewer
//

#if canImport(XCTest)
    @testable internal import mdviewer
    internal import XCTest

    final class mdviewerTests: XCTestCase {
        // MARK: - Stable raw-value contracts

        func testAppThemeRawValuesRemainStable() {
            XCTAssertEqual(AppTheme.basic.rawValue, "Basic")
            XCTAssertEqual(AppTheme.github.rawValue, "GitHub")
            XCTAssertEqual(AppTheme.docC.rawValue, "DocC")
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
