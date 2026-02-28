//
//  ReaderFontSize.swift
//  mdviewer
//

internal import Foundation

// MARK: - Reader Font Size

enum ReaderFontSize: Int, CaseIterable, Identifiable, Sendable {
    case compact = 15
    case standard = 17
    case comfortable = 19

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Standard"
        case .comfortable: return "Comfortable"
        }
    }

    var points: CGFloat {
        CGFloat(rawValue)
    }

    static func from(rawValue: Int) -> ReaderFontSize {
        ReaderFontSize(rawValue: rawValue) ?? .standard
    }
}

// MARK: - StoredPreference Conformance

extension ReaderFontSize: StoredPreference {}
