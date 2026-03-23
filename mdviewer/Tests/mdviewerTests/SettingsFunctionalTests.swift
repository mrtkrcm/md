//
//  SettingsFunctionalTests.swift
//  mdviewer
//
//  Functional tests for Settings view - verifies each option works as expected.
//

#if canImport(XCTest)
    #if os(macOS)
        @testable internal import mdviewer
        internal import SwiftUI
        internal import XCTest

        /// Functional tests for Settings view - verifies each option works as expected.
        @MainActor
        final class SettingsFunctionalTests: XCTestCase {
            private var preferences: AppPreferences { AppPreferences.shared }

            // MARK: - General Settings Tests

            @MainActor
            func testAppearanceModeSetting() {
                // Test all appearance modes can be set
                for mode in AppearanceMode.allCases {
                    preferences.appearanceMode = mode
                    XCTAssertEqual(preferences.appearanceMode, mode)
                    XCTAssertEqual(preferences.effectiveColorScheme, mode.preferredColorScheme)
                }
            }

            @MainActor
            func testThemeSetting() {
                // Test all themes can be set
                for theme in AppTheme.allCases {
                    preferences.theme = theme
                    XCTAssertEqual(preferences.theme, theme)
                }
            }

            // MARK: - Typography Settings Tests

            @MainActor
            func testFontFamilySetting() {
                // Test all font families can be set
                for family in ReaderFontFamily.allCases {
                    preferences.readerFontFamily = family
                    XCTAssertEqual(preferences.readerFontFamily, family)

                    // Verify font resolves correctly
                    let font = family.nsFont(size: 16)
                    XCTAssertNotNil(font)
                    XCTAssertEqual(font.pointSize, 16, accuracy: 0.5)
                }
            }

            @MainActor
            func testFontSizeSetting() {
                // Test all font sizes can be set
                for size in ReaderFontSize.allCases {
                    preferences.readerFontSize = size
                    XCTAssertEqual(preferences.readerFontSize, size)
                    XCTAssertEqual(preferences.readerFontSize.points, size.points)
                }
            }

            @MainActor
            func testFontSizeIncreaseDecrease() {
                // Set to standard first
                preferences.readerFontSize = .standard

                // Test increase
                XCTAssertTrue(preferences.canIncreaseFontSize)
                preferences.increaseFontSize()
                XCTAssertEqual(preferences.readerFontSize, .large)

                // Test decrease
                XCTAssertTrue(preferences.canDecreaseFontSize)
                preferences.decreaseFontSize()
                XCTAssertEqual(preferences.readerFontSize, .standard)

                // Test reset
                preferences.readerFontSize = .extraLarge
                preferences.resetFontSize()
                XCTAssertEqual(preferences.readerFontSize, .standard)
            }

            @MainActor
            func testTextSpacingSetting() {
                // Test all text spacing options can be set
                for spacing in ReaderTextSpacing.allCases {
                    preferences.readerTextSpacing = spacing
                    XCTAssertEqual(preferences.readerTextSpacing, spacing)

                    // Verify line spacing calculation works
                    let lineSpacing = spacing.lineSpacing(for: 16)
                    XCTAssertGreaterThanOrEqual(lineSpacing, 0)

                    // Verify paragraph spacing calculation works
                    let paragraphSpacing = spacing.paragraphSpacing(for: 16)
                    XCTAssertGreaterThanOrEqual(paragraphSpacing, 0)
                }
            }

            @MainActor
            func testColumnWidthSetting() {
                // Test all column width options can be set
                for width in ReaderColumnWidth.allCases {
                    preferences.readerColumnWidth = width
                    XCTAssertEqual(preferences.readerColumnWidth, width)
                    XCTAssertGreaterThan(width.points, 0)
                }
            }

            // MARK: - Reading Settings Tests

            @MainActor
            func testReaderModeSetting() {
                // Test all reader modes can be set
                for mode in ReaderMode.allCases {
                    preferences.readerMode = mode
                    XCTAssertEqual(preferences.readerMode, mode)
                }

                // Test convenience methods
                preferences.setRenderedMode()
                XCTAssertEqual(preferences.readerMode, .rendered)

                preferences.setRawMode()
                XCTAssertEqual(preferences.readerMode, .raw)
            }

            @MainActor
            func testSidebarModeSetting() {
                for mode in SidebarMode.allCases {
                    preferences.sidebarMode = mode
                    XCTAssertEqual(preferences.sidebarMode, mode)
                }
            }

            // MARK: - Code Settings Tests

            @MainActor
            func testCodeFontSizeSetting() {
                // Test all code font sizes can be set
                for size in CodeFontSize.allCases {
                    preferences.codeFontSize = size
                    XCTAssertEqual(preferences.codeFontSize, size)
                    XCTAssertEqual(preferences.codeFontSize.points, CGFloat(size.rawValue))
                }
            }

            // MARK: - System Settings Tests

            @MainActor
            func testLargeFileThresholdSetting() {
                // Test all threshold options can be set
                for threshold in LargeFileThreshold.allCases {
                    preferences.largeFileThreshold = threshold
                    XCTAssertEqual(preferences.largeFileThreshold, threshold)

                    // Verify bytes property works (nil for .never, positive for others)
                    if threshold == .never {
                        XCTAssertNil(threshold.bytes)
                    } else {
                        XCTAssertGreaterThan(threshold.bytes ?? 0, 0)
                    }

                    // Verify shouldWarn works correctly
                    XCTAssertFalse(threshold.shouldWarn(for: 0))
                    if threshold != .never {
                        XCTAssertTrue(threshold.shouldWarn(for: Int64.max))
                    }
                }
            }

            // MARK: - Persistence Tests

            @MainActor
            func testSettingsPersistence() {
                // Set all settings to non-default values
                preferences.appearanceMode = .dark
                preferences.theme = .basic
                preferences.readerFontFamily = .sfPro
                preferences.readerFontSize = .large
                preferences.readerTextSpacing = .relaxed
                preferences.readerColumnWidth = .wide
                preferences.readerMode = .raw
                preferences.sidebarMode = .folder
                preferences.codeFontSize = .large
                preferences.largeFileThreshold = .mb10

                // Verify all values are set correctly
                XCTAssertEqual(preferences.appearanceMode, .dark)
                XCTAssertEqual(preferences.theme, .basic)
                XCTAssertEqual(preferences.readerFontFamily, .sfPro)
                XCTAssertEqual(preferences.readerFontSize, .large)
                XCTAssertEqual(preferences.readerTextSpacing, .relaxed)
                XCTAssertEqual(preferences.readerColumnWidth, .wide)
                XCTAssertEqual(preferences.readerMode, .raw)
                XCTAssertEqual(preferences.sidebarMode, .folder)
                XCTAssertEqual(preferences.codeFontSize, .large)
                XCTAssertEqual(preferences.largeFileThreshold, .mb10)
            }

            // MARK: - Typography Rendering Tests

            @MainActor
            func testTypographySpacingOrder() {
                // Verify spacing increases in correct order
                let compactSpacing = ReaderTextSpacing.compact.lineSpacing(for: 16)
                let balancedSpacing = ReaderTextSpacing.balanced.lineSpacing(for: 16)
                let relaxedSpacing = ReaderTextSpacing.relaxed.lineSpacing(for: 16)

                XCTAssertLessThan(compactSpacing, balancedSpacing)
                XCTAssertLessThan(balancedSpacing, relaxedSpacing)
            }

            @MainActor
            func testColumnWidthOrder() {
                // Verify column widths increase in correct order
                XCTAssertLessThan(ReaderColumnWidth.narrow.points, ReaderColumnWidth.balanced.points)
                XCTAssertLessThan(ReaderColumnWidth.balanced.points, ReaderColumnWidth.wide.points)
            }

            @MainActor
            func testFontSizeOrder() {
                // Verify font sizes increase in correct order
                let sizes = ReaderFontSize.allCases.sorted { $0.rawValue < $1.rawValue }
                for i in 0 ..< (sizes.count - 1) {
                    XCTAssertLessThan(sizes[i].points, sizes[i + 1].points)
                }
            }
        }
    #endif
#endif
