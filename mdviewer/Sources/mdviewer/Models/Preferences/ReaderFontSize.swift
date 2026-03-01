//
//  ReaderFontSize.swift
//  mdviewer
//

internal import Foundation

// MARK: - Reader Font Size

/// Extended font size options for optimal reading experience.
/// Range: 13pt (XS) to 23pt (XXL) with 2pt increments for fine-grained control.
enum ReaderFontSize: Int, CaseIterable, Identifiable, Sendable {
    case extraSmall = 13
    case small = 15
    case standard = 17
    case large = 19
    case extraLarge = 21
    case xxl = 23

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .standard: return "Standard"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        case .xxl: return "XXL"
        }
    }

    /// Point size as `CGFloat` for use in UI rendering.
    var points: CGFloat {
        CGFloat(rawValue)
    }

    /// Short label for compact UI displays.
    var shortLabel: String {
        switch self {
        case .extraSmall: return "XS"
        case .small: return "S"
        case .standard: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        case .xxl: return "XXL"
        }
    }

    static func from(rawValue: Int) -> Self {
        Self(rawValue: rawValue) ?? .standard
    }

    // MARK: - Typography Scale

    /// Returns a scale factor relative to the standard size (17pt).
    /// Useful for proportional sizing of related elements.
    var scaleFactor: CGFloat {
        points / Self.standard.points
    }
}

// MARK: - StoredPreference Conformance

extension ReaderFontSize: StoredPreference {}
