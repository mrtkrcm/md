//
//  ReaderContentPadding.swift
//  mdviewer
//

internal import Foundation

// MARK: - Reader Content Padding

/// Controls the horizontal (and vertical) inset applied around the reader content.
enum ReaderContentPadding: String, CaseIterable, Identifiable, Sendable {
    case compact = "Compact"
    case normal = "Normal"
    case relaxed = "Relaxed"

    var id: String { rawValue }

    static func from(rawValue: String) -> Self {
        Self(rawValue: rawValue) ?? .normal
    }

    /// Inset in points applied on each side of the content area.
    var points: CGFloat {
        switch self {
        case .compact: return 16
        case .normal: return 24
        case .relaxed: return 48
        }
    }
}

// MARK: - StoredPreference Conformance

extension ReaderContentPadding: StoredPreference {}
