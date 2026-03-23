//
//  EditorPreferencesTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        internal import SwiftUI
    #endif
    @testable internal import mdviewer

    final class EditorPreferencesTests: XCTestCase {
        // MARK: - ReaderTextSpacing.lineSpacing(for:)

        func testLineSpacingCompactAt16pt() {
            // compact: 16 * 1.25 - 16 = 4.0
            XCTAssertEqual(ReaderTextSpacing.compact.lineSpacing(for: 16), 4.0, accuracy: 0.001)
        }

        func testLineSpacingBalancedAt16pt() {
            // balanced: 16 * 1.50 - 16 = 8.0
            XCTAssertEqual(ReaderTextSpacing.balanced.lineSpacing(for: 16), 8.0, accuracy: 0.001)
        }

        func testLineSpacingRelaxedAt16pt() {
            // relaxed: 16 * 1.75 - 16 = 12.0
            XCTAssertEqual(ReaderTextSpacing.relaxed.lineSpacing(for: 16), 12.0, accuracy: 0.001)
        }

        func testLineSpacingNeverNegative() {
            for spacing in ReaderTextSpacing.allCases {
                XCTAssertGreaterThanOrEqual(
                    spacing.lineSpacing(for: 0),
                    0,
                    "\(spacing.rawValue) lineSpacing(for: 0) must be >= 0"
                )
                XCTAssertGreaterThanOrEqual(
                    spacing.lineSpacing(for: 1),
                    0,
                    "\(spacing.rawValue) lineSpacing(for: 1) must be >= 0"
                )
            }
        }

        func testLineSpacingScalesProportionally() {
            // lineSpacing(for: 24) == 2 * lineSpacing(for: 12) for all cases
            for spacing in ReaderTextSpacing.allCases {
                let at24 = spacing.lineSpacing(for: 24)
                let at12 = spacing.lineSpacing(for: 12)
                XCTAssertEqual(
                    at24,
                    2.0 * at12,
                    accuracy: 0.001,
                    "\(spacing.rawValue): lineSpacing(24) should equal 2 * lineSpacing(12)"
                )
            }
        }

        // MARK: - ReaderTextSpacing.paragraphSpacing(for:)

        func testParagraphSpacingCompactAt16pt() {
            // 16*1.25=20; 20*0.5=10.0
            XCTAssertEqual(ReaderTextSpacing.compact.paragraphSpacing(for: 16), 10.0, accuracy: 0.001)
        }

        func testParagraphSpacingBalancedAt16pt() {
            // 16*1.50=24; 24*0.75=18.0
            XCTAssertEqual(ReaderTextSpacing.balanced.paragraphSpacing(for: 16), 18.0, accuracy: 0.001)
        }

        func testParagraphSpacingRelaxedAt16pt() {
            // 16*1.75=28; 28*1.0=28.0
            XCTAssertEqual(ReaderTextSpacing.relaxed.paragraphSpacing(for: 16), 28.0, accuracy: 0.001)
        }

        func testParagraphSpacingOrderPreserved() {
            for size in [13.0, 16.0, 17.0] as [CGFloat] {
                let compact = ReaderTextSpacing.compact.paragraphSpacing(for: size)
                let balanced = ReaderTextSpacing.balanced.paragraphSpacing(for: size)
                let relaxed = ReaderTextSpacing.relaxed.paragraphSpacing(for: size)
                XCTAssertLessThan(
                    compact,
                    balanced,
                    "At \(size)pt: compact paragraphSpacing must be less than balanced"
                )
                XCTAssertLessThan(
                    balanced,
                    relaxed,
                    "At \(size)pt: balanced paragraphSpacing must be less than relaxed"
                )
            }
        }

        // MARK: - ReaderTextSpacing kern/hyphenation

        func testKernValues() {
            // Improved typography: minimal negative for compact, slight positive for balanced, generous for relaxed
            XCTAssertEqual(ReaderTextSpacing.compact.kern, -0.005, accuracy: 0.001)
            XCTAssertEqual(ReaderTextSpacing.balanced.kern, 0.008, accuracy: 0.001)
            XCTAssertEqual(ReaderTextSpacing.relaxed.kern, 0.022, accuracy: 0.001)
        }

        func testKernMonotonicallyIncreases() {
            XCTAssertLessThan(ReaderTextSpacing.compact.kern, ReaderTextSpacing.balanced.kern)
            XCTAssertLessThan(ReaderTextSpacing.balanced.kern, ReaderTextSpacing.relaxed.kern)
        }

        func testHyphenationFactorValues() {
            // Professional typography: more hyphenation for compact (narrow columns), less for relaxed
            XCTAssertEqual(ReaderTextSpacing.compact.hyphenationFactor, 0.20, accuracy: 0.001)
            XCTAssertEqual(ReaderTextSpacing.balanced.hyphenationFactor, 0.15, accuracy: 0.001)
            XCTAssertEqual(ReaderTextSpacing.relaxed.hyphenationFactor, 0.10, accuracy: 0.001)
        }

        // MARK: - ReaderColumnWidth

        func testColumnWidthPoints() {
            XCTAssertEqual(ReaderColumnWidth.narrow.points, 640, accuracy: 0.001)
            XCTAssertEqual(ReaderColumnWidth.balanced.points, 720, accuracy: 0.001)
            XCTAssertEqual(ReaderColumnWidth.wide.points, 840, accuracy: 0.001)
            XCTAssertEqual(ReaderColumnWidth.fullWidth.points, CGFloat.greatestFiniteMagnitude)
        }

        func testColumnWidthOrderPreserved() {
            XCTAssertLessThan(ReaderColumnWidth.narrow.points, ReaderColumnWidth.balanced.points)
            XCTAssertLessThan(ReaderColumnWidth.balanced.points, ReaderColumnWidth.wide.points)
            XCTAssertLessThan(ReaderColumnWidth.wide.points, ReaderColumnWidth.fullWidth.points)
        }

        func testFullWidthClampedToWindowWidth() {
            // min(fullWidth.points, windowWidth - padding) should equal windowWidth - padding
            let windowWidth: CGFloat = 1200
            let padding: CGFloat = 24
            let clamped = min(ReaderColumnWidth.fullWidth.points, windowWidth - (padding * 2))
            XCTAssertEqual(clamped, windowWidth - (padding * 2), accuracy: 0.001)
        }

        // MARK: - ReaderContentPadding

        func testContentPaddingPoints() {
            XCTAssertEqual(ReaderContentPadding.compact.points, 16, accuracy: 0.001)
            XCTAssertEqual(ReaderContentPadding.normal.points, 24, accuracy: 0.001)
            XCTAssertEqual(ReaderContentPadding.relaxed.points, 48, accuracy: 0.001)
        }

        func testContentPaddingOrderPreserved() {
            XCTAssertLessThan(ReaderContentPadding.compact.points, ReaderContentPadding.normal.points)
            XCTAssertLessThan(ReaderContentPadding.normal.points, ReaderContentPadding.relaxed.points)
        }

        func testContentPaddingFromUnknownDefaultsNormal() {
            XCTAssertEqual(ReaderContentPadding.from(rawValue: "Unknown"), .normal)
        }

        // MARK: - ReaderFontSize

        func testFontSizePointValues() {
            XCTAssertEqual(ReaderFontSize.extraSmall.points, 13, accuracy: 0.001)
            XCTAssertEqual(ReaderFontSize.small.points, 15, accuracy: 0.001)
            XCTAssertEqual(ReaderFontSize.standard.points, 17, accuracy: 0.001)
            XCTAssertEqual(ReaderFontSize.large.points, 19, accuracy: 0.001)
            XCTAssertEqual(ReaderFontSize.extraLarge.points, 21, accuracy: 0.001)
            XCTAssertEqual(ReaderFontSize.xxl.points, 23, accuracy: 0.001)
        }

        // MARK: - CodeFontSize

        func testCodeFontSizeFromKnown() {
            XCTAssertEqual(CodeFontSize.from(rawValue: 13), .small)
            XCTAssertEqual(CodeFontSize.from(rawValue: 15), .medium)
            XCTAssertEqual(CodeFontSize.from(rawValue: 17), .large)
        }

        func testCodeFontSizeFromUnknownDefaultsMedium() {
            XCTAssertEqual(CodeFontSize.from(rawValue: 0), .medium)
            XCTAssertEqual(CodeFontSize.from(rawValue: 99), .medium)
        }

        func testCodeFontSizePointValues() {
            XCTAssertEqual(CodeFontSize.small.points, 13, accuracy: 0.001)
            XCTAssertEqual(CodeFontSize.medium.points, 15, accuracy: 0.001)
            XCTAssertEqual(CodeFontSize.large.points, 17, accuracy: 0.001)
        }

        func testCodeFontSizePointsMatchRawValue() {
            for size in CodeFontSize.allCases {
                XCTAssertEqual(
                    size.points,
                    CGFloat(size.rawValue),
                    accuracy: 0.001,
                    "\(size.label) points should equal CGFloat(rawValue)"
                )
            }
        }

        #if os(macOS)
            func testAllFontFamiliesResolveToNonNilFont() {
                for family in ReaderFontFamily.allCases {
                    let font = family.nsFont(size: 16)
                    XCTAssertNotNil(font, "\(family.rawValue) should resolve to a non-nil NSFont at 16pt")
                    // NSFont(descriptor:size:) always returns NSFont on macOS; just verify pointSize
                    XCTAssertEqual(
                        font.pointSize,
                        16,
                        accuracy: 0.5,
                        "\(family.rawValue) font point size should be approximately 16pt"
                    )
                }
            }

            func testMonospacedFontHasMonospaceDesign() {
                for family in ReaderFontFamily.allCases {
                    let font = family.nsFont(size: 16, monospaced: true)
                    let traits = font.fontDescriptor.symbolicTraits
                    XCTAssertTrue(
                        traits.contains(.monoSpace),
                        "\(family.rawValue) with monospaced:true should have .monoSpace trait"
                    )
                }
            }

            func testBoldTraitApplied() {
                let sfPro = ReaderFontFamily.sfPro.nsFont(size: 16, traits: .bold)
                XCTAssertTrue(
                    sfPro.fontDescriptor.symbolicTraits.contains(.bold),
                    "SF Pro with bold trait should have .bold symbolic trait"
                )

                let newYork = ReaderFontFamily.newYork.nsFont(size: 16, traits: .bold)
                XCTAssertTrue(
                    newYork.fontDescriptor.symbolicTraits.contains(.bold),
                    "New York with bold trait should have .bold symbolic trait"
                )
            }
        #endif
    }
#endif
