//
//  ReaderTextSpacing.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Reader Text Spacing

enum ReaderTextSpacing: String, CaseIterable, Identifiable, Sendable {
    case compact = "Compact"
    case balanced = "Balanced"
    case relaxed = "Relaxed"

    var id: String { rawValue }

    static func from(rawValue: String) -> ReaderTextSpacing {
        ReaderTextSpacing(rawValue: rawValue) ?? .balanced
    }

    // MARK: - Ratio-Based Typography

    /// Line height multiplier for comfortable reading.
    /// Returns the line height as a multiple of font size.
    /// - Compact: 1.6x (tight but readable)
    /// - Balanced: 1.75x (optimal reading with comfortable breathing room)
    /// - Relaxed: 1.9x (airy, accessible, excellent for long-form)
    var lineHeightMultiplier: CGFloat {
        switch self {
        case .compact: return 1.6
        case .balanced: return 1.75
        case .relaxed: return 1.9
        }
    }

    /// Calculates line spacing for a given font size.
    /// This ensures consistent vertical rhythm regardless of font size.
    func lineSpacing(for fontSize: CGFloat) -> CGFloat {
        let targetLineHeight = fontSize * lineHeightMultiplier
        return max(0, targetLineHeight - fontSize)
    }

    /// Calculates paragraph spacing as a multiple of line height.
    /// Uses generous spacing for clear visual separation between paragraphs.
    /// - Compact: 0.6x line height (tight but clear)
    /// - Balanced: 0.9x line height (optimal reading with clear breaks)
    /// - Relaxed: 1.2x line height (maximum breathing room)
    func paragraphSpacing(for fontSize: CGFloat) -> CGFloat {
        let lineHeight = fontSize * lineHeightMultiplier
        switch self {
        case .compact: return lineHeight * 0.6
        case .balanced: return lineHeight * 0.9
        case .relaxed: return lineHeight * 1.2
        }
    }

    /// Spacing before paragraphs for visual hierarchy.
    /// Creates clear separation between content blocks.
    func paragraphSpacingBefore(for fontSize: CGFloat) -> CGFloat {
        let lineHeight = fontSize * lineHeightMultiplier
        switch self {
        case .compact: return lineHeight * 0.35
        case .balanced: return lineHeight * 0.55
        case .relaxed: return lineHeight * 0.75
        }
    }

    // MARK: - Legacy Fixed Spacing (for backward compatibility)

    /// Extra pixels added after each line (fixed value for 16pt body).
    @available(*, deprecated, message: "Use lineSpacing(for:) instead")
    var lineSpacing: CGFloat {
        lineSpacing(for: 16)
    }

    /// Space between paragraph blocks (fixed value for 16pt body).
    @available(*, deprecated, message: "Use paragraphSpacing(for:) instead")
    var paragraphSpacing: CGFloat {
        paragraphSpacing(for: 16)
    }

    /// Letter spacing (tracking) optimized for screen reading.
    /// Uses slight positive tracking for improved readability on modern displays.
    /// - Compact: 0.0 (neutral, tighter for dense content)
    /// - Balanced: 0.01 (slightly open, optimal for body text)
    /// - Relaxed: 0.025 (open, aids readability at distance)
    var kern: CGFloat {
        switch self {
        case .compact: return 0.0
        case .balanced: return 0.01
        case .relaxed: return 0.025
        }
    }

    /// Hyphenation factor for text breaking.
    var hyphenationFactor: Float {
        switch self {
        case .compact: return 0.15
        case .balanced: return 0.20
        case .relaxed: return 0.25
        }
    }

    // MARK: - Convenience Methods

    /// Returns kerning value for the specified font size.
    /// Currently returns the fixed kern value; the parameter exists for
    /// forward compatibility with font-size-proportional tracking.
    func kern(for _: CGFloat) -> CGFloat {
        kern
    }

    /// Creates a paragraph style configured for this spacing preference.
    func paragraphStyle(fontSize: CGFloat) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing(for: fontSize)
        style.paragraphSpacing = paragraphSpacing(for: fontSize)
        style.paragraphSpacingBefore = paragraphSpacingBefore(for: fontSize)
        style.hyphenationFactor = hyphenationFactor
        return style
    }
}

// MARK: - StoredPreference Conformance

extension ReaderTextSpacing: StoredPreference {}
