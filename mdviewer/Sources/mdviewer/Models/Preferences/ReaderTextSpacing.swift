//
//  ReaderTextSpacing.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Reader Text Spacing

/// Text spacing preferences with refined typography calculations.
/// Implements professional typesetting practices for optimal readability.
enum ReaderTextSpacing: String, CaseIterable, Identifiable, Sendable {
    case compact = "Compact"
    case balanced = "Balanced"
    case relaxed = "Relaxed"

    var id: String { rawValue }

    static func from(rawValue: String) -> Self {
        Self(rawValue: rawValue) ?? .balanced
    }

    // MARK: - Line Height (Leading)

    /// Line height multiplier using a refined scale for professional typography.
    /// These values are optimized for screen reading with macOS system fonts.
    /// Uses the "golden ratio" inspired scale for optimal readability.
    ///
    /// - Compact: 1.52x (tight but readable, good for code/dense content)
    /// - Balanced: 1.62x (approaches golden ratio, optimal for body text)
    /// - Relaxed: 1.75x (generous, accessible, extended reading comfort)
    var lineHeightMultiplier: CGFloat {
        switch self {
        case .compact: return 1.52
        case .balanced: return 1.62
        case .relaxed: return 1.75
        }
    }

    /// Calculates line spacing (leading) for a given font size.
    /// Returns the additional space between lines, not the total line height.
    ///
    /// Formula: lineHeight = fontSize * multiplier
    /// lineSpacing = lineHeight - fontSize
    func lineSpacing(for fontSize: CGFloat) -> CGFloat {
        let targetLineHeight = fontSize * lineHeightMultiplier
        return max(0, targetLineHeight - fontSize)
    }

    // MARK: - Paragraph Spacing

    /// Paragraph spacing as a multiple of line height.
    /// Creates clear visual separation between paragraphs.
    ///
    /// - Compact: 0.5x (minimal separation, dense content)
    /// - Balanced: 0.75x (clear separation without excessive whitespace)
    /// - Relaxed: 1.0x (full line height, maximum breathing room)
    func paragraphSpacing(for fontSize: CGFloat) -> CGFloat {
        let lineHeight = fontSize * lineHeightMultiplier
        switch self {
        case .compact: return lineHeight * 0.5
        case .balanced: return lineHeight * 0.75
        case .relaxed: return lineHeight * 1.0
        }
    }

    /// Spacing before paragraphs for visual hierarchy.
    /// Slightly less than paragraphSpacing to create asymmetric flow.
    func paragraphSpacingBefore(for fontSize: CGFloat) -> CGFloat {
        let lineHeight = fontSize * lineHeightMultiplier
        switch self {
        case .compact: return lineHeight * 0.25
        case .balanced: return lineHeight * 0.45
        case .relaxed: return lineHeight * 0.65
        }
    }

    // MARK: - Character Spacing (Tracking)

    /// Letter spacing (tracking) optimized for screen reading.
    /// Uses subtle adjustments for improved legibility and readability.
    ///
    /// - Compact: -0.005em (minimal tightening, maintains readability)
    /// - Balanced: 0.008em (slight openness, optimal for body text)
    /// - Relaxed: 0.022em (generous spacing for accessibility and extended reading)
    var kern: CGFloat {
        switch self {
        case .compact: return -0.005
        case .balanced: return 0.008
        case .relaxed: return 0.022
        }
    }

    /// Returns kerning value scaled for the specified font size.
    /// Ensures tracking remains proportional at all sizes.
    func kern(for fontSize: CGFloat) -> CGFloat {
        fontSize * kern
    }

    // MARK: - Hyphenation

    /// Hyphenation factor for text breaking.
    /// Higher values allow more hyphenation for better line breaking.
    ///
    /// - Compact: 0.2 (more hyphenation acceptable for narrow columns)
    /// - Balanced: 0.15 (moderate hyphenation)
    /// - Relaxed: 0.1 (minimal hyphenation, prefer line breaks)
    var hyphenationFactor: Float {
        switch self {
        case .compact: return 0.20
        case .balanced: return 0.15
        case .relaxed: return 0.10
        }
    }

    // MARK: - Optical Sizing

    /// Returns a font descriptor modification for optical sizing.
    /// Adjusts tracking based on font size for optimal readability.
    ///
    /// - Small fonts (<14pt): Extra openness for legibility
    /// - Medium fonts (14-18pt): Slight adjustment
    /// - Large fonts (>18pt): Reduced adjustment (large text needs less help)
    func opticalSizeAdjustment(for fontSize: CGFloat) -> CGFloat {
        if fontSize < 14 {
            return 0.008 // 0.8% extra tracking for small text
        }
        if fontSize < 18 {
            return 0.003 // 0.3% for medium text
        }
        return 0.0
    }

    // MARK: - Convenience Methods

    /// Creates a paragraph style configured for this spacing preference.
    /// Uses macOS best practices for NSParagraphStyle configuration.
    func paragraphStyle(fontSize: CGFloat) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing(for: fontSize)
        style.paragraphSpacing = paragraphSpacing(for: fontSize)
        style.paragraphSpacingBefore = paragraphSpacingBefore(for: fontSize)
        style.hyphenationFactor = hyphenationFactor

        // Enable optimal character spacing
        style.allowsDefaultTighteningForTruncation = false

        // Use standard line break mode for readability
        style.lineBreakMode = .byWordWrapping

        return style
    }

    /// Returns the ideal measure (line length) for this spacing.
    /// Measured in characters per line for optimal reading.
    var idealMeasure: ClosedRange<Int> {
        switch self {
        case .compact: return 60 ... 80
        case .balanced: return 65 ... 85
        case .relaxed: return 70 ... 90
        }
    }
}

// MARK: - StoredPreference Conformance

extension ReaderTextSpacing: StoredPreference {}
