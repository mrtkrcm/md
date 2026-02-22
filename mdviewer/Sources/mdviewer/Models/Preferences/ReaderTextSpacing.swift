//
//  ReaderTextSpacing.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    @preconcurrency internal import AppKit
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

    /// Line height multiplier for ratio-based leading.
    /// Returns the line height as a multiple of font size.
    /// - Compact: 1.4x (tight, code-like)
    /// - Balanced: 1.55x (classic book typography)
    /// - Relaxed: 1.7x (airy, accessible)
    var lineHeightMultiplier: CGFloat {
        switch self {
        case .compact: return 1.4
        case .balanced: return 1.55
        case .relaxed: return 1.7
        }
    }

    /// Calculates line spacing for a given font size.
    /// This ensures consistent vertical rhythm regardless of font size.
    func lineSpacing(for fontSize: CGFloat) -> CGFloat {
        let targetLineHeight = fontSize * lineHeightMultiplier
        return max(0, targetLineHeight - fontSize)
    }

    /// Calculates paragraph spacing as a multiple of line height.
    /// This maintains visual separation proportional to text size.
    func paragraphSpacing(for fontSize: CGFloat) -> CGFloat {
        let lineHeight = fontSize * lineHeightMultiplier
        switch self {
        case .compact: return lineHeight * 0.5
        case .balanced: return lineHeight * 0.75
        case .relaxed: return lineHeight * 1.0
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

    /// Letter spacing (tracking) for fine-tuning text density.
    var kern: CGFloat {
        switch self {
        case .compact: return 0.04
        case .balanced: return 0.10
        case .relaxed: return 0.16
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

    /// Returns kerning value scaled for the specified font size.
    func kern(for fontSize: CGFloat) -> CGFloat {
        kern
    }

    /// Creates a paragraph style configured for this spacing preference.
    func paragraphStyle(fontSize: CGFloat) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing(for: fontSize)
        style.paragraphSpacing = paragraphSpacing(for: fontSize)
        style.hyphenationFactor = hyphenationFactor
        return style
    }
}

// MARK: - StoredPreference Conformance

extension ReaderTextSpacing: StoredPreference {}
