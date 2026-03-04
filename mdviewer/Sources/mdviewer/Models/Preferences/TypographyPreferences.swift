//
//  TypographyPreferences.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Typography Preferences

/// Typography preferences that are actually applied to rendered text.
/// Only includes settings that have working implementations in TypographyApplier.
struct TypographyPreferences: Codable, Equatable, Hashable, Sendable {
    // MARK: - Font Rendering

    /// Enable font smoothing for crisper text on Retina displays.
    var fontSmoothing: Bool = true

    /// Enable ligatures for better character combinations.
    var ligatures: Bool = true

    // MARK: - Paragraph Layout

    /// Text justification behavior.
    var justification: TextJustification = .natural

    /// Enable automatic hyphenation.
    var hyphenation: Bool = true

    // MARK: - Factory Methods

    /// Conservative typography settings for maximum compatibility.
    static var conservative: TypographyPreferences {
        TypographyPreferences(
            fontSmoothing: true,
            ligatures: false,
            justification: .left,
            hyphenation: false
        )
    }

    /// Maximum typography settings for premium rendering.
    static var premium: TypographyPreferences {
        TypographyPreferences(
            fontSmoothing: true,
            ligatures: true,
            justification: .natural,
            hyphenation: true
        )
    }
}

// MARK: - Text Justification

/// Text justification options.
enum TextJustification: String, Codable, CaseIterable, Identifiable, Sendable {
    case left = "Left"
    case natural = "Natural"
    case full = "Full"

    var id: String { rawValue }

    var nsAlignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .natural: return .natural
        case .full: return .justified
        }
    }
}
