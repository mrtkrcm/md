//
//  LargeFileThreshold.swift
//  mdviewer
//
//  User-configurable threshold for large file warnings.
//

internal import Foundation

/// Represents the threshold at which to show large file warnings.
/// Users can configure this based on their system performance and preferences.
enum LargeFileThreshold: Int, CaseIterable, Identifiable, Codable {
    case never = 0 // Never show warnings
    case kb500 = 512_000 // 500 KB
    case mb1 = 1_048_576 // 1 MB (default)
    case mb2 = 2_097_152 // 2 MB
    case mb5 = 5_242_880 // 5 MB
    case mb10 = 10_485_760 // 10 MB

    var id: Int { rawValue }

    /// Human-readable label for UI display
    var label: String {
        switch self {
        case .never:
            return "Never"
        case .kb500:
            return "500 KB"
        case .mb1:
            return "1 MB"
        case .mb2:
            return "2 MB"
        case .mb5:
            return "5 MB"
        case .mb10:
            return "10 MB"
        }
    }

    /// The threshold value in bytes, or nil if never warn
    var bytes: Int64? {
        switch self {
        case .never:
            return nil
        case .kb500, .mb1, .mb2, .mb5, .mb10:
            return Int64(rawValue)
        }
    }

    /// Whether a file of the given size should trigger a warning
    /// - Parameter fileSize: Size in bytes
    /// - Returns: True if warning should be shown
    func shouldWarn(for fileSize: Int64) -> Bool {
        guard let threshold = bytes else { return false }
        return fileSize > threshold
    }
}

// MARK: - UserDefaults Support

extension LargeFileThreshold {
    /// Initialize from a UserDefaults integer value
    /// - Parameter rawValue: The stored integer value
    /// - Returns: The corresponding threshold, or default (1MB) if invalid
    static func from(rawValue: Int) -> LargeFileThreshold {
        LargeFileThreshold(rawValue: rawValue) ?? .mb1
    }
}
