//
//  AppearanceMode.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case auto = "Auto"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    static func from(rawValue: String) -> Self {
        Self(rawValue: rawValue) ?? .auto
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .auto:
            return nil

        case .light:
            return .light

        case .dark:
            return .dark
        }
    }
}

// MARK: - StoredPreference Conformance

extension AppearanceMode: StoredPreference {}
