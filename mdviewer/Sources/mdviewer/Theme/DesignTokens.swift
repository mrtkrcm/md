//
//  DesignTokens.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    @preconcurrency internal import AppKit
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
        /// Top bar reveal zone height (10pt)
        static let revealZoneHeight: CGFloat = 10
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
        /// Reader mode picker width (148pt)
        static let readerModePickerWidth: CGFloat = 148
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
            self.animation(.smooth(duration: duration), value: value)
        } else {
            self.animation(.easeInOut(duration: duration), value: value)
        }
    }

    /// Applies a bouncy spring animation for playful interactions.
    @ViewBuilder
    func bouncyAnimation<Value: Equatable>(_ value: Value) -> some View {
        if #available(macOS 15.0, iOS 17.0, *) {
            self.animation(.bouncy, value: value)
        } else {
            self.animation(.spring(response: 0.35, dampingFraction: 0.7), value: value)
        }
    }
}
