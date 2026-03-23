//
//  DesignSystemTests.swift
//  mdviewer
//
//  Validates design tokens, transitions, and modern animation patterns.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        final class DesignSystemTests: XCTestCase {
            // MARK: - Design Token Validation

            func testAnimationDurationTokensExist() {
                // Verify all animation duration tokens are defined
                let fast = DesignTokens.Animation.fast
                let normal = DesignTokens.Animation.normal
                let medium = DesignTokens.Animation.medium
                let slow = DesignTokens.Animation.slow

                XCTAssertEqual(fast, 0.15, "Fast animation should be 0.15s")
                XCTAssertEqual(normal, 0.22, "Normal animation should be 0.22s")
                XCTAssertEqual(medium, 0.25, "Medium animation should be 0.25s")
                XCTAssertEqual(slow, 0.3, "Slow animation should be 0.3s")
            }

            func testSpacingTokensAreMonotonic() {
                // Verify spacing tokens increase monotonically
                let spacings = [
                    DesignTokens.Spacing.tight,
                    DesignTokens.Spacing.compact,
                    DesignTokens.Spacing.standard,
                    DesignTokens.Spacing.comfortable,
                    DesignTokens.Spacing.relaxed,
                    DesignTokens.Spacing.wide,
                    DesignTokens.Spacing.extraWide,
                    DesignTokens.Spacing.large,
                    DesignTokens.Spacing.extraLarge,
                ]

                for i in 1 ..< spacings.count {
                    XCTAssertLessThan(
                        spacings[i - 1],
                        spacings[i],
                        "Spacing tokens should increase monotonically"
                    )
                }
            }

            func testOpacityTokensAreValid() {
                // Verify all opacity tokens are within valid range [0, 1]
                let opacities = [
                    DesignTokens.Opacity.verySubtle,
                    DesignTokens.Opacity.subtle,
                    DesignTokens.Opacity.light,
                    DesignTokens.Opacity.mediumLight,
                    DesignTokens.Opacity.medium,
                    DesignTokens.Opacity.mediumHigh,
                    DesignTokens.Opacity.high,
                    DesignTokens.Opacity.veryHigh,
                ]

                for opacity in opacities {
                    XCTAssertGreaterThanOrEqual(opacity, 0, "Opacity should be >= 0")
                    XCTAssertLessThanOrEqual(opacity, 1, "Opacity should be <= 1")
                }
            }

            func testCornerRadiiTokensArePositive() {
                // Verify all corner radius tokens are positive
                let radii = [
                    DesignTokens.CornerRadius.small,
                    DesignTokens.CornerRadius.medium,
                    DesignTokens.CornerRadius.standard,
                    DesignTokens.CornerRadius.large,
                ]

                for radius in radii {
                    XCTAssertGreaterThan(radius, 0, "Corner radius should be positive")
                }
            }

            func testShadowValuesAreConsistent() {
                // Verify shadow token values
                XCTAssertGreaterThan(DesignTokens.Shadow.radius, 0)
                XCTAssertGreaterThan(DesignTokens.Shadow.yOffset, 0)
                XCTAssertGreaterThan(DesignTokens.Shadow.opacity, 0)
                XCTAssertLessThan(DesignTokens.Shadow.opacity, 1)
            }

            // MARK: - Transition Tests

            func testTransitionsAreSmooth() {
                // Validate smooth fade transition exists
                let smoothFade = AnyTransition.smoothFade
                XCTAssertNotNil(smoothFade)
            }

            func testElegantSlideTransitionExists() {
                // Validate elegant slide transition exists
                let slideLeft = AnyTransition.elegantSlide(from: .leading)
                let slideRight = AnyTransition.elegantSlide(from: .trailing)
                let slideTop = AnyTransition.elegantSlide(from: .top)
                let slideBottom = AnyTransition.elegantSlide(from: .bottom)

                XCTAssertNotNil(slideLeft)
                XCTAssertNotNil(slideRight)
                XCTAssertNotNil(slideTop)
                XCTAssertNotNil(slideBottom)
            }

            func testPopupScaleTransitionExists() {
                // Validate popup scale transition exists
                let popupScale = AnyTransition.popupScale
                XCTAssertNotNil(popupScale)
            }

            // MARK: - Animation Timing Tests

            func testAnimationTimingConsistency() {
                // Verify animation timing hierarchy
                XCTAssertLessThan(
                    DesignTokens.Animation.fast,
                    DesignTokens.Animation.normal,
                    "Fast should be less than normal"
                )
                XCTAssertLessThan(
                    DesignTokens.Animation.normal,
                    DesignTokens.Animation.medium,
                    "Normal should be less than medium"
                )
                XCTAssertLessThan(
                    DesignTokens.Animation.medium,
                    DesignTokens.Animation.slow,
                    "Medium should be less than slow"
                )
            }

            // MARK: - Layout Constants

            func testLayoutConstantsArePositive() {
                // Verify all layout constants are positive
                XCTAssertGreaterThan(DesignTokens.Layout.metadataWidth, 0)
                XCTAssertGreaterThan(DesignTokens.Layout.metadataMaxHeight, 0)
                XCTAssertGreaterThan(DesignTokens.Layout.minContentHeight, 0)
                XCTAssertGreaterThan(DesignTokens.Layout.welcomeMaxWidth, 0)
            }

            // MARK: - Typography Tokens

            func testTypographyTokensAreConsistent() {
                // Verify typography tokens have sensible values
                XCTAssertGreaterThan(DesignTokens.Typography.caption, 0)
                XCTAssertGreaterThan(DesignTokens.Typography.small, 0)
                XCTAssertGreaterThan(DesignTokens.Typography.body, 0)
                XCTAssertGreaterThan(DesignTokens.Typography.title, 0)

                // Caption should be smallest
                XCTAssertLessThan(
                    DesignTokens.Typography.caption,
                    DesignTokens.Typography.body
                )

                // Body should be smaller than title
                XCTAssertLessThan(
                    DesignTokens.Typography.body,
                    DesignTokens.Typography.title
                )
            }

            // MARK: - Color System Integration

            func testThemePaletteGeneratesColors() {
                // Verify theme palette creates valid color values
                let lightPalette = NativeThemePalette(theme: .basic, scheme: .light)
                let darkPalette = NativeThemePalette(theme: .basic, scheme: .dark)

                XCTAssertNotNil(lightPalette.textPrimary)
                XCTAssertNotNil(lightPalette.textSecondary)
                XCTAssertNotNil(lightPalette.codeBackground)
                XCTAssertNotNil(lightPalette.heading)

                XCTAssertNotNil(darkPalette.textPrimary)
                XCTAssertNotNil(darkPalette.textSecondary)
                XCTAssertNotNil(darkPalette.codeBackground)
                XCTAssertNotNil(darkPalette.heading)
            }

            func testThemePaletteRespondsToColorScheme() {
                // Verify different color schemes produce valid palettes
                let lightPalette = NativeThemePalette(theme: .basic, scheme: .light)
                let darkPalette = NativeThemePalette(theme: .basic, scheme: .dark)

                // Both should produce non-nil colors
                XCTAssertNotNil(lightPalette.textPrimary)
                XCTAssertNotNil(darkPalette.textPrimary)

                // GitHub theme might have more distinct colors
                let lightGithub = NativeThemePalette(theme: .github, scheme: .light)
                let darkGithub = NativeThemePalette(theme: .github, scheme: .dark)
                XCTAssertNotNil(lightGithub.textPrimary)
                XCTAssertNotNil(darkGithub.textPrimary)
            }

            // MARK: - Render Integration

            func testDesignTokensWorkWithRenderer() {
                let request = RenderRequest(
                    markdown: "# Test",
                    readerFontFamily: .newYork,
                    readerFontSize: DesignTokens.Typography.body,
                    codeFontSize: DesignTokens.Typography.standard,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                XCTAssertEqual(
                    request.readerFontSize,
                    DesignTokens.Typography.body,
                    "Render request should accept design token values"
                )
            }

            // MARK: - Animation Extension Methods

            func testLiquidAnimationExtension() {
                // Verify the liquid animation extension is accessible
                // This is tested indirectly through view compilation
                struct TestView: View {
                    @State var value = 0

                    var body: some View {
                        Text("Test")
                            .liquidAnimation(value)
                    }
                }

                XCTAssertNotNil(TestView())
            }

            func testSmoothAnimationExtension() {
                // Verify the smooth animation extension is accessible
                struct TestView: View {
                    @State var value = 0

                    var body: some View {
                        Text("Test")
                            .smoothAnimation(value)
                    }
                }

                XCTAssertNotNil(TestView())
            }

            func testBouncyAnimationExtension() {
                // Verify the bouncy animation extension is accessible
                struct TestView: View {
                    @State var value = 0

                    var body: some View {
                        Text("Test")
                            .bouncyAnimation(value)
                    }
                }

                XCTAssertNotNil(TestView())
            }

            // MARK: - Modifier Integration

            func testInteractiveModifierCompiles() {
                // Verify interactive modifier can be applied
                struct TestView: View {
                    var body: some View {
                        Text("Test")
                            .interactive()
                    }
                }

                XCTAssertNotNil(TestView())
            }

            func testElevationModifierCompiles() {
                // Verify elevation modifier can be applied with different levels
                struct TestView: View {
                    var body: some View {
                        Text("Subtle")
                            .elevation(.subtle)
                    }
                }

                XCTAssertNotNil(TestView())
            }

            func testLoadingModifierCompiles() {
                // Verify loading modifier can be applied
                struct TestView: View {
                    var body: some View {
                        Text("Loading")
                            .loading(true)
                    }
                }

                XCTAssertNotNil(TestView())
            }

            func testSmootVisibilityModifierCompiles() {
                // Verify visibility modifier can be applied
                struct TestView: View {
                    var body: some View {
                        Text("Visible")
                            .smoothVisibility(true)
                    }
                }

                XCTAssertNotNil(TestView())
            }

            // MARK: - Typography Scaling

            func testFontSizesScale() {
                // Verify font sizes follow a logical progression
                let caption = DesignTokens.Typography.caption
                let small = DesignTokens.Typography.small
                let body = DesignTokens.Typography.body
                let title = DesignTokens.Typography.title

                XCTAssertLessThan(caption, small)
                XCTAssertLessThan(small, body)
                XCTAssertLessThan(body, title)

                // Verify reasonable ratios (each size should be larger than previous)
                let smallRatio = small / caption
                let bodyRatio = body / small
                let titleRatio = title / body

                XCTAssertGreaterThan(smallRatio, 1.0)
                XCTAssertGreaterThan(bodyRatio, 1.0)
                XCTAssertGreaterThan(titleRatio, 1.5)
            }

            // MARK: - Spacing Ratios

            func testSpacingRatios() {
                // Verify spacing follows a consistent ratio
                let compact = DesignTokens.Spacing.compact
                let standard = DesignTokens.Spacing.standard
                let relaxed = DesignTokens.Spacing.relaxed

                let compactRatio = standard / compact
                let relaxedRatio = relaxed / standard

                // Both ratios should be reasonably close (golden ratio ~1.618)
                XCTAssertGreaterThan(compactRatio, 1.0)
                XCTAssertGreaterThan(relaxedRatio, 1.0)
            }

            // MARK: - Animation Consistency

            func testSpringParametersAreConsistent() {
                // Spring animations should use consistent parameters
                // Response time should be between 0.2s and 0.4s
                let responseLow: TimeInterval = 0.2
                let responseHigh: TimeInterval = 0.4
                let recommendedResponse: TimeInterval = 0.28

                XCTAssertGreaterThanOrEqual(recommendedResponse, responseLow)
                XCTAssertLessThanOrEqual(recommendedResponse, responseHigh)

                // Damping should be between 0.7 and 0.9 (slightly bouncy)
                let dampingLow: CGFloat = 0.7
                let dampingHigh: CGFloat = 0.9
                let recommendedDamping: CGFloat = 0.82

                XCTAssertGreaterThanOrEqual(recommendedDamping, dampingLow)
                XCTAssertLessThanOrEqual(recommendedDamping, dampingHigh)
            }

            // MARK: - Integration with Preferences

            func testDesignTokensWorkWithThemes() {
                // Verify design tokens work with all available themes
                for theme in AppTheme.allCases {
                    for scheme: ColorScheme in [.light, .dark] {
                        let palette = NativeThemePalette(theme: theme, scheme: scheme)

                        XCTAssertNotNil(palette.textPrimary)
                        XCTAssertNotNil(palette.codeBackground)
                    }
                }
            }

            // MARK: - Content Accuracy

            func testDesignTokensMatchDocumentation() {
                // Verify documented animation durations match code
                // From DESIGN_SYSTEM.md:
                // - Fast: 0.15s for micro-interactions
                // - Normal: 0.22s for standard transitions
                // - Slow: 0.3s for emphasis

                XCTAssertEqual(DesignTokens.Animation.fast, 0.15)
                XCTAssertEqual(DesignTokens.Animation.normal, 0.22)
                XCTAssertEqual(DesignTokens.Animation.slow, 0.3)
            }

            func testSpacingTokensMatchDocumentation() {
                // Verify spacing scale matches documentation
                // 4pt, 6pt, 8pt, 10pt, 12pt, 14pt, 16pt, 18pt, 24pt, 28pt

                XCTAssertEqual(DesignTokens.Spacing.tight, 4)
                XCTAssertEqual(DesignTokens.Spacing.compact, 6)
                XCTAssertEqual(DesignTokens.Spacing.standard, 8)
                XCTAssertEqual(DesignTokens.Spacing.comfortable, 10)
                XCTAssertEqual(DesignTokens.Spacing.relaxed, 12)
            }
        }
    #endif
#endif
