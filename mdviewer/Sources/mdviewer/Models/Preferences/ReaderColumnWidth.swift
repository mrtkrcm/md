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

    static func from(rawValue: String) -> Self {
        Self(rawValue: rawValue) ?? .balanced
    }

    var points: CGFloat {
        switch self {
        case .narrow: return 640
        case .balanced: return 720
        case .wide: return 840
        }
    }
}

// MARK: - StoredPreference Conformance

extension ReaderColumnWidth: StoredPreference {}
