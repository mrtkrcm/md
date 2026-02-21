internal import Foundation

// MARK: - Code Font Size

enum CodeFontSize: Int, CaseIterable, Identifiable, Sendable {
    case small = 12
    case medium = 14
    case large = 16

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    static func from(rawValue: Int) -> CodeFontSize {
        CodeFontSize(rawValue: rawValue) ?? .medium
    }
}

// MARK: - StoredPreference Conformance

extension CodeFontSize: StoredPreference {}
