//
//  CodeFontSize.swift
//  mdviewer
//

internal import Foundation

// MARK: - Code Font Size

enum CodeFontSize: Int, CaseIterable, Identifiable, Sendable {
    case small = 13
    case medium = 15
    case large = 17

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    /// Point size as `CGFloat`, matching the `ReaderFontSize.points` API.
    var points: CGFloat {
        CGFloat(rawValue)
    }

    static func from(rawValue: Int) -> CodeFontSize {
        CodeFontSize(rawValue: rawValue) ?? .medium
    }
}

// MARK: - StoredPreference Conformance

extension CodeFontSize: StoredPreference {}
