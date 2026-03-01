//
//  DesignTokens.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Design Tokens

/// Centralized design system values for consistent liquid design throughout the app.
/// All corner radii, animations, spacing, and opacity values should reference these tokens.
enum DesignTokens {
    // MARK: - Corner Radius

    enum CornerRadius {
        /// Small radius for buttons, icons (8pt)
        static let small: CGFloat = 8
        /// Medium radius for input fields, cards (10pt)
        static let medium: CGFloat = 10
        /// Standard radius for panels, toolbars (14pt)
        static let standard: CGFloat = 14
        /// Large radius for modals, welcome screens (20pt)
        static let large: CGFloat = 20
    }

    // MARK: - Animation Duration

    enum Animation {
        /// Fast animation for micro-interactions (0.15s)
        static let fast: TimeInterval = 0.15
        /// Normal animation for standard transitions (0.22s)
        static let normal: TimeInterval = 0.22
        /// Medium animation for content changes (0.25s)
        static let medium: TimeInterval = 0.25
        /// Slow animation for emphasis (0.3s)
        static let slow: TimeInterval = 0.3
        /// Top bar reveal/hide duration
        static let topBar: TimeInterval = 0.22
        /// Idle delay before hiding top bar (2.2s)
        static let idleDelay: TimeInterval = 2.2
    }

    // MARK: - Spacing

    enum Spacing {
        /// Tight spacing (4pt)
        static let tight: CGFloat = 4
        /// Compact spacing (6pt)
        static let compact: CGFloat = 6
        /// Standard spacing (8pt)
        static let standard: CGFloat = 8
        /// Comfortable spacing (10pt)
        static let comfortable: CGFloat = 10
        /// Relaxed spacing (12pt)
        static let relaxed: CGFloat = 12
        /// Wide spacing (14pt)
        static let wide: CGFloat = 14
        /// Extra wide spacing (16pt)
        static let extraWide: CGFloat = 16
        /// Large spacing (18pt)
        static let large: CGFloat = 18
        /// Extra large spacing (24pt)
        static let extraLarge: CGFloat = 24
        /// XXL spacing (28pt)
        static let xxl: CGFloat = 28
        /// Top bar top padding (10pt)
        static let topBarTop: CGFloat = 10
        /// Top bar horizontal padding (14pt)
        static let topBarHorizontal: CGFloat = 14
    }

    // MARK: - Opacity

    enum Opacity {
        /// Very subtle (0.04)
        static let verySubtle: Double = 0.04
        /// Subtle (0.05)
        static let subtle: Double = 0.05
        /// Light (0.06)
        static let light: Double = 0.06
        /// Medium light (0.08)
        static let mediumLight: Double = 0.08
        /// Medium (0.10)
        static let medium: Double = 0.10
        /// Medium high (0.12)
        static let mediumHigh: Double = 0.12
        /// High (0.15)
        static let high: Double = 0.15
        /// Very high (0.5)
        static let veryHigh: Double = 0.5
    }

    // MARK: - Shadow

    enum Shadow {
        /// Standard shadow radius (12pt)
        static let radius: CGFloat = 12
        /// Standard shadow Y offset (4pt)
        static let yOffset: CGFloat = 4
        /// Standard shadow opacity (0.10)
        static let opacity: Double = 0.10
    }

    // MARK: - Layout

    enum Layout {
        /// Metadata panel width (280pt)
        static let metadataWidth: CGFloat = 280
        /// Metadata panel max height (280pt)
        static let metadataMaxHeight: CGFloat = 280
        /// Appearance popover width (300pt)
        static let appearancePopoverWidth: CGFloat = 300
        /// Settings view width (460pt)
        static let settingsWidth: CGFloat = 460
        /// Settings view height (320pt)
        static let settingsHeight: CGFloat = 320
        /// Minimum content height (480pt)
        static let minContentHeight: CGFloat = 480
        /// Welcome view max width (380pt)
        static let welcomeMaxWidth: CGFloat = 380
    }

    // MARK: - Typography

    enum Typography {
        /// Caption size (10pt)
        static let caption: CGFloat = 10
        /// Small size (11pt)
        static let small: CGFloat = 11
        /// Body small size (12pt)
        static let bodySmall: CGFloat = 12
        /// Standard size (13pt)
        static let standard: CGFloat = 13
        /// Body size (15pt)
        static let body: CGFloat = 15
        /// Title size (28pt)
        static let title: CGFloat = 28
        /// Icon small (11pt)
        static let iconSmall: CGFloat = 11
        /// Icon standard (13pt)
        static let iconStandard: CGFloat = 13
        /// Icon large (40pt)
        static let iconLarge: CGFloat = 40
    }

    // MARK: - Semantic Colors

    /// Semantic color values for common UI states
    enum SemanticColors {
        /// Success/positive state color
        static let success = Color(red: 0.2, green: 0.7, blue: 0.3)
        /// Warning/caution state color
        static let warning = Color(red: 0.9, green: 0.6, blue: 0.1)
        /// Error/danger state color
        static let error = Color(red: 0.9, green: 0.25, blue: 0.2)
        /// Informational state color
        static let info = Color(red: 0.1, green: 0.6, blue: 0.9)
    }

    // MARK: - Component Tokens

    enum Component {
        enum Button {
            /// Minimum tap target size (44pt)
            static let minTapTarget: CGFloat = 44
            /// Standard button height (36pt)
            static let height: CGFloat = 36
            /// Large button height (48pt)
            static let heightLarge: CGFloat = 48
            /// Small button height (28pt)
            static let heightSmall: CGFloat = 28
            /// Button content padding (16pt)
            static let paddingHorizontal: CGFloat = 16
            /// Icon button size (36pt)
            static let iconSize: CGFloat = 36
        }

        enum Card {
            /// Standard card padding (16pt)
            static let padding: CGFloat = 16
            /// Card elevation shadow opacity (0.08)
            static let shadowOpacity: Double = 0.08
            /// Card elevation shadow radius (8pt)
            static let shadowRadius: CGFloat = 8
        }

        enum Input {
            /// Standard input field height (36pt)
            static let height: CGFloat = 36
            /// Input field padding (12pt)
            static let paddingHorizontal: CGFloat = 12
            /// Text area minimum height (100pt)
            static let textAreaMinHeight: CGFloat = 100
        }

        enum List {
            /// Standard list item height (44pt)
            static let itemHeight: CGFloat = 44
            /// Compact list item height (32pt)
            static let itemHeightCompact: CGFloat = 32
            /// List item indentation (20pt)
            static let indentation: CGFloat = 20
        }

        enum Toolbar {
            /// Toolbar item spacing (8pt)
            static let itemSpacing: CGFloat = 8
            /// Toolbar padding (12pt)
            static let padding: CGFloat = 12
        }

        enum Modal {
            /// Modal corner radius (12pt)
            static let cornerRadius: CGFloat = 12
            /// Modal shadow radius (16pt)
            static let shadowRadius: CGFloat = 16
            /// Modal backdrop opacity (0.4)
            static let backdropOpacity: Double = 0.4
        }
    }

    // MARK: - Animation Presets

    /// Predefined animation configurations for consistent motion design
    enum AnimationPreset {
        /// Instant transition (no animation)
        static let instant: SwiftUI.Animation = .linear(duration: 0)
        /// Very fast interaction (0.1s)
        static let veryFast: SwiftUI.Animation = .easeInOut(duration: 0.1)
        /// Fast interaction (0.15s)
        static let fast: SwiftUI.Animation = .easeInOut(duration: 0.15)
        /// Standard interaction (0.2s)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.2)
        /// Medium transition (0.25s)
        static let medium: SwiftUI.Animation = .easeInOut(duration: 0.25)
        /// Slow transition (0.35s)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.35)
        /// Very slow transition (0.5s)
        static let verySlow: SwiftUI.Animation = .easeInOut(duration: 0.5)

        /// Spring animation for responsive interactions
        static func spring(response: TimeInterval = 0.28, damping: CGFloat = 0.82) -> SwiftUI.Animation {
            .spring(response: response, dampingFraction: damping)
        }

        /// Smooth animation with modern easing
        @available(macOS 15.0, iOS 17.0, *)
        static func smooth(duration: TimeInterval = 0.25) -> SwiftUI.Animation {
            .smooth(duration: duration)
        }

        /// Bouncy spring animation for playful interactions
        @available(macOS 15.0, iOS 17.0, *)
        static let bouncy: SwiftUI.Animation = .bouncy
    }

    // MARK: - Transition Presets

    /// Predefined transitions for consistent view changes
    enum TransitionPreset {
        /// Fade transition
        static var fade: AnyTransition { .opacity }

        /// Slide in from bottom
        static var slideFromBottom: AnyTransition { .move(edge: .bottom).combined(with: .opacity) }

        /// Slide in from top
        static var slideFromTop: AnyTransition { .move(edge: .top).combined(with: .opacity) }

        /// Slide in from leading (left in LTR)
        static var slideFromLeading: AnyTransition { .move(edge: .leading).combined(with: .opacity) }

        /// Slide in from trailing (right in LTR)
        static var slideFromTrailing: AnyTransition { .move(edge: .trailing).combined(with: .opacity) }

        /// Scale with fade
        static var scaleFade: AnyTransition {
            .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                removal: .opacity.combined(with: .scale(scale: 1.02))
            )
        }

        /// Slide in from bottom with scale
        static var slideUpScale: AnyTransition {
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.95)),
                removal: .opacity
            )
        }
    }

    // MARK: - Spacing Scale

    enum SpacingScale {
        /// Extra extra small (2pt)
        static let xxs: CGFloat = 2
        /// Extra small (4pt)
        static let xs: CGFloat = 4
        /// Small (6pt)
        static let small: CGFloat = 6
        /// Medium (8pt)
        static let medium: CGFloat = 8
        /// Large (12pt)
        static let large: CGFloat = 12
        /// Extra large (16pt)
        static let xl: CGFloat = 16
        /// Extra extra large (24pt)
        static let xxl: CGFloat = 24
        /// Extra extra extra large (32pt)
        static let xxxl: CGFloat = 32
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a liquid design animation with standard duration and easing.
    func liquidAnimation<Value: Equatable>(
        _ value: Value,
        duration: TimeInterval = DesignTokens.Animation.normal
    ) -> some View {
        animation(.easeInOut(duration: duration), value: value)
    }

    /// Applies a smooth spring animation for interactive elements.
    func liquidSpring<Value: Equatable>(
        _ value: Value,
        response: TimeInterval = 0.28,
        damping: CGFloat = 0.82
    ) -> some View {
        animation(.spring(response: response, dampingFraction: damping), value: value)
    }

    /// Applies a modern smooth animation (macOS 15+/iOS 17+) with fallback.
    @ViewBuilder
    func smoothAnimation<Value: Equatable>(
        _ value: Value,
        duration: TimeInterval = DesignTokens.Animation.normal
    ) -> some View {
        if #available(macOS 15.0, iOS 17.0, *) {
            animation(.smooth(duration: duration), value: value)
        } else {
            animation(.easeInOut(duration: duration), value: value)
        }
    }

    /// Applies a bouncy spring animation for playful interactions.
    @ViewBuilder
    func bouncyAnimation<Value: Equatable>(_ value: Value) -> some View {
        if #available(macOS 15.0, iOS 17.0, *) {
            animation(.bouncy, value: value)
        } else {
            animation(.spring(response: 0.35, dampingFraction: 0.7), value: value)
        }
    }
}

// MARK: - Transitions

extension AnyTransition {
    /// Smooth fade transition with slight scale
    static var smoothFade: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.995)),
            removal: .opacity.combined(with: .scale(scale: 1.005))
        )
    }

    /// Slide and fade transition for directional changes
    static func slideFade(edge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge).combined(with: .opacity)
        )
    }
}
