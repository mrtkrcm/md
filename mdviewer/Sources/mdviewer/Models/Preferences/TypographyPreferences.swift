//
//  TypographyPreferences.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Typography Preferences

/// Advanced typography preferences for power users.
/// These settings control low-level text rendering and layout behavior.
struct TypographyPreferences: Codable, Equatable, Sendable {
    // MARK: - Font Rendering

    /// Enable font smoothing for crisper text on Retina displays.
    var fontSmoothing: Bool = true

    /// Font smoothing style intensity.
    var fontSmoothingStyle: FontSmoothingStyle = .medium

    /// Enable ligatures for better character combinations.
    var ligatures: Bool = true

    /// Enable contextual alternates for improved readability.
    var contextualAlternates: Bool = true

    // MARK: - Paragraph Layout

    /// Enable hanging punctuation for cleaner paragraph edges.
    var hangingPunctuation: Bool = true

    /// Text justification behavior.
    var justification: TextJustification = .natural

    /// Enable widow and orphan control.
    var widowOrphanControl: Bool = true

    /// Minimum number of lines to keep together at paragraph breaks.
    var minimumLinesInParagraph: Int = 2

    /// Maximum consecutive hyphenated lines.
    var maximumConsecutiveHyphens: Int = 2

    // MARK: - Advanced Features

    /// Use optical sizing for variable fonts.
    var opticalSizing: Bool = true

    /// Enable automatic hyphenation.
    var hyphenation: Bool = true

    /// Use old-style figures (proportional numerals) instead of lining figures.
    var oldStyleFigures: Bool = false

    /// Use small caps for acronyms (when font supports it).
    var smallCaps: Bool = false

    // MARK: - Factory Methods

    /// Conservative typography settings for maximum compatibility.
    static var conservative: TypographyPreferences {
        TypographyPreferences(
            fontSmoothing: true,
            fontSmoothingStyle: .light,
            ligatures: false,
            contextualAlternates: false,
            hangingPunctuation: false,
            justification: .left,
            widowOrphanControl: true,
            minimumLinesInParagraph: 2,
            maximumConsecutiveHyphens: 1,
            opticalSizing: false,
            hyphenation: false,
            oldStyleFigures: false,
            smallCaps: false
        )
    }

    /// Maximum typography settings for premium rendering.
    static var premium: TypographyPreferences {
        TypographyPreferences(
            fontSmoothing: true,
            fontSmoothingStyle: .medium,
            ligatures: true,
            contextualAlternates: true,
            hangingPunctuation: true,
            justification: .natural,
            widowOrphanControl: true,
            minimumLinesInParagraph: 3,
            maximumConsecutiveHyphens: 2,
            opticalSizing: true,
            hyphenation: true,
            oldStyleFigures: true,
            smallCaps: true
        )
    }
}

// MARK: - Supporting Types

/// Font smoothing intensity options.
enum FontSmoothingStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case light = "Light"
    case medium = "Medium"
    case strong = "Strong"

    var id: String { rawValue }

    /// Returns the CoreText font smoothing level.
    var smoothingLevel: Int {
        switch self {
        case .light: return 1
        case .medium: return 2
        case .strong: return 3
        }
    }
}

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
