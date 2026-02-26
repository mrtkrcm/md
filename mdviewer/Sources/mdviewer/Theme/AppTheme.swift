//
//  AppTheme.swift
//  mdviewer
//

internal import SwiftUI

/// Standard markdown themes with consistent color schemes and typography support.
/// Each theme is optimized for readability and works across light/dark appearance modes.
enum AppTheme: String, CaseIterable, Identifiable {
    // Apple ecosystem themes
    case basic = "Basic"
    case github = "GitHub"
    case docC = "DocC"

    // Popular code editor themes
    case solarized = "Solarized"
    case gruvbox = "Gruvbox"
    case dracula = "Dracula"
    case monokai = "Monokai"
    case nord = "Nord"
    case onedark = "One Dark"
    case tokyonight = "Tokyo Night"

    var id: String { rawValue }

    /// Human-readable description of the theme.
    var description: String {
        switch self {
        case .basic:
            return "Minimal, system-integrated colors"
        case .github:
            return "GitHub's markdown style"
        case .docC:
            return "Apple's documentation compiler style"
        case .solarized:
            return "Solarized: precision colors for machines and people"
        case .gruvbox:
            return "Retro groove color scheme"
        case .dracula:
            return "Dark theme optimized for eyes"
        case .monokai:
            return "Vibrant code editor theme"
        case .nord:
            return "Arctic, north-bluish color palette"
        case .onedark:
            return "Atom's One Dark theme"
        case .tokyonight:
            return "Tokyo neon nights inspired"
        }
    }
}

extension AppTheme: StoredPreference {
    static func from(rawValue: String) -> AppTheme {
        AppTheme(rawValue: rawValue) ?? .basic
    }
}
