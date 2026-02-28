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
            // compact: 16 * 1.6 - 16 = 9.6
            XCTAssertEqual(ReaderTextSpacing.compact.lineSpacing(for: 16), 9.6, accuracy: 0.001)
        }

        func testLineSpacingBalancedAt16pt() {
            // balanced: 16 * 1.75 - 16 = 12.0
            XCTAssertEqual(ReaderTextSpacing.balanced.lineSpacing(for: 16), 12.0, accuracy: 0.001)
        }

        func testLineSpacingRelaxedAt16pt() {
            // relaxed: 16 * 1.9 - 16 = 14.4
            XCTAssertEqual(ReaderTextSpacing.relaxed.lineSpacing(for: 16), 14.4, accuracy: 0.001)
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
            // 16*1.6=25.6; 25.6*0.6=15.36 (improved for readability)
            XCTAssertEqual(ReaderTextSpacing.compact.paragraphSpacing(for: 16), 15.36, accuracy: 0.001)
        }

        func testParagraphSpacingBalancedAt16pt() {
            // 16*1.75=28.0; 28.0*0.9=25.2 (improved for readability)
            XCTAssertEqual(ReaderTextSpacing.balanced.paragraphSpacing(for: 16), 25.2, accuracy: 0.001)
        }

        func testParagraphSpacingRelaxedAt16pt() {
            // 16*1.9=30.4; 30.4*1.2=36.48 (improved for readability)
            XCTAssertEqual(ReaderTextSpacing.relaxed.paragraphSpacing(for: 16), 36.48, accuracy: 0.001)
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
            // Improved for readability: neutral for compact, slight positive for balanced and relaxed
            XCTAssertEqual(ReaderTextSpacing.compact.kern, 0.0, accuracy: 0.001)
            XCTAssertEqual(ReaderTextSpacing.balanced.kern, 0.01, accuracy: 0.001)
            XCTAssertEqual(ReaderTextSpacing.relaxed.kern, 0.025, accuracy: 0.001)
        }

        func testKernMonotonicallyIncreases() {
            XCTAssertLessThan(ReaderTextSpacing.compact.kern, ReaderTextSpacing.balanced.kern)
            XCTAssertLessThan(ReaderTextSpacing.balanced.kern, ReaderTextSpacing.relaxed.kern)
        }

        func testHyphenationFactorValues() {
            XCTAssertEqual(ReaderTextSpacing.compact.hyphenationFactor, 0.15, accuracy: 0.001)
            XCTAssertEqual(ReaderTextSpacing.balanced.hyphenationFactor, 0.20, accuracy: 0.001)
            XCTAssertEqual(ReaderTextSpacing.relaxed.hyphenationFactor, 0.25, accuracy: 0.001)
        }

        // MARK: - ReaderColumnWidth

        func testColumnWidthPoints() {
            XCTAssertEqual(ReaderColumnWidth.narrow.points, 640, accuracy: 0.001)
            XCTAssertEqual(ReaderColumnWidth.balanced.points, 720, accuracy: 0.001)
            XCTAssertEqual(ReaderColumnWidth.wide.points, 840, accuracy: 0.001)
        }

        func testColumnWidthOrderPreserved() {
            XCTAssertLessThan(ReaderColumnWidth.narrow.points, ReaderColumnWidth.balanced.points)
            XCTAssertLessThan(ReaderColumnWidth.balanced.points, ReaderColumnWidth.wide.points)
        }

        // MARK: - ReaderFontSize

        func testFontSizePointValues() {
            XCTAssertEqual(ReaderFontSize.compact.points, 15, accuracy: 0.001)
            XCTAssertEqual(ReaderFontSize.standard.points, 17, accuracy: 0.001)
            XCTAssertEqual(ReaderFontSize.comfortable.points, 19, accuracy: 0.001)
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

        // MARK: - SyntaxPalette exhaustive

        func testSyntaxPaletteFromAllRawValues() {
            XCTAssertEqual(SyntaxPalette.from(rawValue: "Sundell's Colors"), .sundellsColors)
            XCTAssertEqual(SyntaxPalette.from(rawValue: "Midnight"), .midnight)
            XCTAssertEqual(SyntaxPalette.from(rawValue: "Sunset"), .sunset)
            XCTAssertEqual(SyntaxPalette.from(rawValue: "Presentation"), .presentation)
            XCTAssertEqual(SyntaxPalette.from(rawValue: "WWDC 2017"), .wwdc17)
            XCTAssertEqual(SyntaxPalette.from(rawValue: "WWDC 2018"), .wwdc18)
        }

        func testWWDCPaletteRawValuesAreStable() {
            XCTAssertEqual(SyntaxPalette.wwdc17.rawValue, "WWDC 2017")
            XCTAssertEqual(SyntaxPalette.wwdc18.rawValue, "WWDC 2018")
            XCTAssertEqual(SyntaxPalette.presentation.rawValue, "Presentation")
        }

        #if os(macOS)
            func testAllPalettesProduceNonTransparentColors() {
                for palette in SyntaxPalette.allCases {
                    let style = palette.nativeSyntax
                    let colors: [NSColor] = [
                        style.keyword, style.string, style.type,
                        style.number, style.comment, style.call,
                    ]
                    for color in colors {
                        var alpha: CGFloat = 0
                        color.getRed(nil, green: nil, blue: nil, alpha: &alpha)
                        XCTAssertGreaterThan(
                            alpha,
                            0,
                            "\(palette.rawValue) palette produced a fully transparent color"
                        )
                    }
                }
            }

            func testPalettesHaveDistinctKeywordColors() {
                let keywordColors = SyntaxPalette.allCases.map(\.nativeSyntax.keyword)
                // Convert to device RGB for comparison
                var distinctColors: [NSColor] = []
                for color in keywordColors {
                    guard let rgb = color.usingColorSpace(.deviceRGB) else {
                        distinctColors.append(color)
                        continue
                    }
                    let isDuplicate = distinctColors.contains { existing in
                        guard let existingRGB = existing.usingColorSpace(.deviceRGB) else { return false }
                        return abs(existingRGB.redComponent - rgb.redComponent) < 0.01
                            && abs(existingRGB.greenComponent - rgb.greenComponent) < 0.01
                            && abs(existingRGB.blueComponent - rgb.blueComponent) < 0.01
                    }
                    if !isDuplicate {
                        distinctColors.append(rgb)
                    }
                }
                XCTAssertGreaterThanOrEqual(
                    distinctColors.count,
                    4,
                    "At least 4 distinct keyword colors expected across all palettes, got \(distinctColors.count)"
                )
            }

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
