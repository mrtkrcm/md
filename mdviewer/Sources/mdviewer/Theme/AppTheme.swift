//
//  AppTheme.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

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
    case catppuccin = "Catppuccin"
    case rosepine = "Rose Pine"

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

        case .catppuccin:
            return "Warm, cozy pastel theme"

        case .rosepine:
            return "Elegant, natural color palette"
        }
    }

    #if os(macOS)
        /// The syntax highlighting style for this theme.
        /// Each theme defines its own curated syntax colors that complement its overall aesthetic.
        var nativeSyntax: NativeSyntaxStyle {
            switch self {
            case .basic, .github, .docC:
                // Clean, professional syntax colors (Sundell's Colors)
                return .init(
                    keyword: p3(r: 0.91, g: 0.2, b: 0.54),
                    string: p3(r: 0.98, g: 0.39, b: 0.12),
                    type: p3(r: 0.51, g: 0.51, b: 0.79),
                    number: p3(r: 0.86, g: 0.44, b: 0.34),
                    comment: p3(r: 0.42, g: 0.54, b: 0.58),
                    call: p3(r: 0.2, g: 0.56, b: 0.9)
                )

            case .solarized:
                // Muted, solarized-compatible tones
                return .init(
                    keyword: p3(r: 0.161, g: 0.259, b: 0.467),
                    string: p3(r: 0.875, g: 0.027, b: 0),
                    type: p3(r: 0.706, g: 0.27, b: 0),
                    number: p3(r: 0.161, g: 0.259, b: 0.467),
                    comment: p3(r: 0.765, g: 0.455, b: 0.11),
                    call: p3(r: 0.278, g: 0.415, b: 0.593)
                )

            case .gruvbox:
                // Retro warm tones
                return .init(
                    keyword: p3(r: 0.992, g: 0.791, b: 0.45),
                    string: p3(r: 0.966, g: 0.517, b: 0.29),
                    type: p3(r: 0.431, g: 0.714, b: 0.533),
                    number: p3(r: 0.559, g: 0.504, b: 0.745),
                    comment: p3(r: 0.484, g: 0.483, b: 0.504),
                    call: p3(r: 0.431, g: 0.714, b: 0.533)
                )

            case .dracula, .nord, .onedark, .tokyonight:
                // Dark theme favorites - vibrant on dark backgrounds
                return .init(
                    keyword: p3(r: 0.828, g: 0.095, b: 0.583),
                    string: p3(r: 1.0, g: 0.171, b: 0.219),
                    type: p3(r: 0.137, g: 1.0, b: 0.512),
                    number: p3(r: 0.469, g: 0.426, b: 1.0),
                    comment: p3(r: 0.255, g: 0.801, b: 0.27),
                    call: p3(r: 0.137, g: 1.0, b: 0.512)
                )

            case .monokai, .catppuccin:
                // Vibrant, playful colors
                return .init(
                    keyword: p3(r: 0.948, g: 0.140, b: 0.547),
                    string: p3(r: 0.988, g: 0.273, b: 0.317),
                    type: p3(r: 0.584, g: 0.898, b: 0.361),
                    number: p3(r: 0.587, g: 0.517, b: 0.974),
                    comment: p3(r: 0.424, g: 0.475, b: 0.529),
                    call: p3(r: 0.584, g: 0.898, b: 0.361)
                )

            case .rosepine:
                // Elegant, soft pastel tones
                return .init(
                    keyword: p3(r: 0.706, g: 0.0, b: 0.384),
                    string: p3(r: 0.729, g: 0.0, b: 0.067),
                    type: p3(r: 0.267, g: 0.537, b: 0.576),
                    number: p3(r: 0.0, g: 0.043, b: 1.0),
                    comment: p3(r: 0.336, g: 0.376, b: 0.42),
                    call: p3(r: 0.267, g: 0.537, b: 0.576)
                )
            }
        }

        private func p3(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> NSColor {
            NSColor(displayP3Red: r, green: g, blue: b, alpha: a)
        }
    #endif
}

extension AppTheme: StoredPreference {
    static func from(rawValue: String) -> AppTheme {
        AppTheme(rawValue: rawValue) ?? .basic
    }
}
