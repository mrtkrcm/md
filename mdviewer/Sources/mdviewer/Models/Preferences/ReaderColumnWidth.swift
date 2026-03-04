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
    /// Expands content to fill the full available width (minus content padding).
    case fullWidth = "Full Width"

    var id: String { rawValue }

    static func from(rawValue: String) -> Self {
        Self(rawValue: rawValue) ?? .balanced
    }

    var points: CGFloat {
        switch self {
        case .narrow: return 640
        case .balanced: return 720
        case .wide: return 840
        case .fullWidth: return CGFloat.greatestFiniteMagnitude
        }
    }
}

// MARK: - StoredPreference Conformance

extension ReaderColumnWidth: StoredPreference {}
