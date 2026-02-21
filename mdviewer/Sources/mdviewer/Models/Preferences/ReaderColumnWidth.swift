//
//  ReaderColumnWidth.swift
//  mdviewer
//

internal import Foundation

// MARK: - Reader Column Width

enum ReaderColumnWidth: String, CaseIterable, Identifiable, Sendable {
    case narrow = "Narrow"
    case balanced = "Balanced"
    case wide = "Wide"

    var id: String { rawValue }

    static func from(rawValue: String) -> ReaderColumnWidth {
        ReaderColumnWidth(rawValue: rawValue) ?? .balanced
    }

    var points: CGFloat {
        switch self {
        case .narrow: return 680
        case .balanced: return 760
        case .wide: return 860
        }
    }
}

// MARK: - StoredPreference Conformance

extension ReaderColumnWidth: StoredPreference {}
