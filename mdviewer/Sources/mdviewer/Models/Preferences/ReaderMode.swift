internal import Foundation

// MARK: - Reader Mode

enum ReaderMode: String, CaseIterable, Identifiable, Sendable {
    case rendered = "Rendered"
    case raw = "Raw"

    var id: String { rawValue }

    static func from(rawValue: String) -> ReaderMode {
        ReaderMode(rawValue: rawValue) ?? .rendered
    }
}

// MARK: - StoredPreference Conformance

extension ReaderMode: StoredPreference {}
