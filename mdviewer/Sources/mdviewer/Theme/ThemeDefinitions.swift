//
//  ThemeDefinitions.swift
//  mdviewer
//

internal import AppKit
internal import SwiftUI

// MARK: - Theme Definitions

/// Concrete color values for each `AppTheme` / `ColorScheme` combination.
/// All themes support both light and dark appearance modes with consistent spacing.
extension NativeThemePalette {
    init(theme: AppTheme, scheme: ColorScheme) {
        switch (theme, scheme) {
        // MARK: - Apple Ecosystem Themes

        case (.basic, .light):
            textPrimary = .labelColor
            textSecondary = .secondaryLabelColor
            link = .linkColor
            heading = .labelColor
            codeBackground = Self.p3Color(r: 0.95, g: 0.95, b: 0.95)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.88)
            blockquoteAccent = Self.p3Color(r: 0.55, g: 0.55, b: 0.55)
            blockquoteBackground = Self.p3Color(r: 0.00, g: 0.00, b: 0.00, a: 0.04)
            inlineCodeBackground = Self.p3Color(r: 0.55, g: 0.55, b: 0.55, a: 0.08)

        case (.basic, .dark):
            textPrimary = .labelColor
            textSecondary = .secondaryLabelColor
            link = .linkColor
            heading = .labelColor
            codeBackground = Self.p3Color(r: 0.20, g: 0.20, b: 0.20)
            codeBorder = Self.p3Color(r: 0.30, g: 0.30, b: 0.30)
            blockquoteAccent = Self.p3Color(r: 0.45, g: 0.45, b: 0.45)
            blockquoteBackground = Self.p3Color(r: 1.00, g: 1.00, b: 1.00, a: 0.05)
            inlineCodeBackground = Self.p3Color(r: 0.45, g: 0.45, b: 0.45, a: 0.08)

        case (.github, .light):
            textPrimary = Self.p3Color(r: 0.14, g: 0.16, b: 0.20)
            textSecondary = Self.p3Color(r: 0.40, g: 0.42, b: 0.46)
            link = Self.p3Color(r: 0.10, g: 0.46, b: 0.82)
            heading = Self.p3Color(r: 0.06, g: 0.08, b: 0.12)
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.96)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.88)
            blockquoteAccent = Self.p3Color(r: 0.22, g: 0.51, b: 0.82)
            blockquoteBackground = Self.p3Color(r: 0.22, g: 0.51, b: 0.82, a: 0.06)
            inlineCodeBackground = Self.p3Color(r: 0.22, g: 0.51, b: 0.82, a: 0.08)

        case (.github, .dark):
            textPrimary = Self.p3Color(r: 0.90, g: 0.90, b: 0.90)
            textSecondary = Self.p3Color(r: 0.60, g: 0.62, b: 0.66)
            link = Self.p3Color(r: 0.53, g: 0.75, b: 0.98)
            heading = Self.p3Color(r: 0.95, g: 0.96, b: 0.98)
            codeBackground = Self.p3Color(r: 0.17, g: 0.18, b: 0.20)
            codeBorder = Self.p3Color(r: 0.28, g: 0.29, b: 0.32)
            blockquoteAccent = Self.p3Color(r: 0.35, g: 0.62, b: 0.90)
            blockquoteBackground = Self.p3Color(r: 0.35, g: 0.62, b: 0.90, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.35, g: 0.62, b: 0.90, a: 0.10)

        case (.docC, .light):
            textPrimary = Self.p3Color(r: 0.12, g: 0.12, b: 0.14)
            textSecondary = Self.p3Color(r: 0.38, g: 0.38, b: 0.42)
            link = Self.p3Color(r: 0.00, g: 0.48, b: 1.00)
            heading = Self.p3Color(r: 0.05, g: 0.05, b: 0.08)
            codeBackground = Self.p3Color(r: 0.95, g: 0.95, b: 0.96)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            blockquoteAccent = Self.p3Color(r: 0.00, g: 0.48, b: 1.00)
            blockquoteBackground = Self.p3Color(r: 0.00, g: 0.48, b: 1.00, a: 0.05)
            inlineCodeBackground = Self.p3Color(r: 0.00, g: 0.48, b: 1.00, a: 0.08)

        case (.docC, .dark):
            textPrimary = Self.p3Color(r: 0.93, g: 0.93, b: 0.94)
            textSecondary = Self.p3Color(r: 0.60, g: 0.60, b: 0.64)
            link = Self.p3Color(r: 0.25, g: 0.60, b: 1.00)
            heading = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            codeBackground = Self.p3Color(r: 0.14, g: 0.15, b: 0.17)
            codeBorder = Self.p3Color(r: 0.26, g: 0.27, b: 0.30)
            blockquoteAccent = Self.p3Color(r: 0.25, g: 0.60, b: 1.00)
            blockquoteBackground = Self.p3Color(r: 0.25, g: 0.60, b: 1.00, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.25, g: 0.60, b: 1.00, a: 0.10)

        // MARK: - Solarized Theme

        case (.solarized, .light):
            // Solarized Light: base3 bg, base01 text
            textPrimary = Self.p3Color(r: 0.40, g: 0.48, b: 0.51) // base01
            textSecondary = Self.p3Color(r: 0.58, g: 0.63, b: 0.67) // base1
            link = Self.p3Color(r: 0.16, g: 0.63, b: 0.60) // cyan
            heading = Self.p3Color(r: 0.27, g: 0.51, b: 0.71) // blue
            codeBackground = Self.p3Color(r: 0.93, g: 0.91, b: 0.84) // base2
            codeBorder = Self.p3Color(r: 0.88, g: 0.86, b: 0.78) // base1
            blockquoteAccent = Self.p3Color(r: 0.40, g: 0.48, b: 0.51)
            blockquoteBackground = Self.p3Color(r: 0.40, g: 0.48, b: 0.51, a: 0.06)
            inlineCodeBackground = Self.p3Color(r: 0.40, g: 0.48, b: 0.51, a: 0.10)

        case (.solarized, .dark):
            // Solarized Dark: base03 bg, base0 text
            textPrimary = Self.p3Color(r: 0.83, g: 0.86, b: 0.88) // base0
            textSecondary = Self.p3Color(r: 0.65, g: 0.68, b: 0.70) // base1
            link = Self.p3Color(r: 0.16, g: 0.63, b: 0.60) // cyan
            heading = Self.p3Color(r: 0.35, g: 0.70, b: 0.82) // blue
            codeBackground = Self.p3Color(r: 0.01, g: 0.15, b: 0.22) // base02
            codeBorder = Self.p3Color(r: 0.06, g: 0.20, b: 0.26) // base01
            blockquoteAccent = Self.p3Color(r: 0.35, g: 0.70, b: 0.82)
            blockquoteBackground = Self.p3Color(r: 0.35, g: 0.70, b: 0.82, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.35, g: 0.70, b: 0.82, a: 0.10)

        // MARK: - Gruvbox Theme

        case (.gruvbox, .light):
            // Gruvbox Light
            textPrimary = Self.p3Color(r: 0.29, g: 0.25, b: 0.18) // fg
            textSecondary = Self.p3Color(r: 0.59, g: 0.54, b: 0.44) // fg4
            link = Self.p3Color(r: 0.16, g: 0.53, b: 0.36) // green
            heading = Self.p3Color(r: 0.48, g: 0.33, b: 0.16) // orange
            codeBackground = Self.p3Color(r: 0.92, g: 0.91, b: 0.85) // bg1
            codeBorder = Self.p3Color(r: 0.88, g: 0.87, b: 0.80)
            blockquoteAccent = Self.p3Color(r: 0.56, g: 0.27, b: 0.27) // red
            blockquoteBackground = Self.p3Color(r: 0.56, g: 0.27, b: 0.27, a: 0.06)
            inlineCodeBackground = Self.p3Color(r: 0.56, g: 0.27, b: 0.27, a: 0.10)

        case (.gruvbox, .dark):
            // Gruvbox Dark
            textPrimary = Self.p3Color(r: 0.92, g: 0.91, b: 0.85) // fg
            textSecondary = Self.p3Color(r: 0.73, g: 0.73, b: 0.68) // fg4
            link = Self.p3Color(r: 0.56, g: 0.74, b: 0.27) // green
            heading = Self.p3Color(r: 1.00, g: 0.59, b: 0.10) // orange
            codeBackground = Self.p3Color(r: 0.16, g: 0.15, b: 0.13) // bg1
            codeBorder = Self.p3Color(r: 0.24, g: 0.23, b: 0.21)
            blockquoteAccent = Self.p3Color(r: 0.98, g: 0.48, b: 0.43) // red
            blockquoteBackground = Self.p3Color(r: 0.98, g: 0.48, b: 0.43, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.98, g: 0.48, b: 0.43, a: 0.10)

        // MARK: - Dracula Theme

        case (.dracula, .light):
            // Dracula Light (adapted)
            textPrimary = Self.p3Color(r: 0.25, g: 0.26, b: 0.35) // dark
            textSecondary = Self.p3Color(r: 0.58, g: 0.59, b: 0.67) // medium
            link = Self.p3Color(r: 0.64, g: 0.48, b: 0.96) // purple
            heading = Self.p3Color(r: 0.25, g: 0.26, b: 0.35)
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.97)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            blockquoteAccent = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            blockquoteBackground = Self.p3Color(r: 0.64, g: 0.48, b: 0.96, a: 0.06)
            inlineCodeBackground = Self.p3Color(r: 0.64, g: 0.48, b: 0.96, a: 0.08)

        case (.dracula, .dark):
            // Dracula Dark
            textPrimary = Self.p3Color(r: 0.97, g: 0.97, b: 0.98) // foreground
            textSecondary = Self.p3Color(r: 0.70, g: 0.71, b: 0.73) // comment
            link = Self.p3Color(r: 0.64, g: 0.48, b: 0.96) // purple
            heading = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            codeBackground = Self.p3Color(r: 0.28, g: 0.28, b: 0.38) // background
            codeBorder = Self.p3Color(r: 0.44, g: 0.44, b: 0.53) // selection
            blockquoteAccent = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            blockquoteBackground = Self.p3Color(r: 0.64, g: 0.48, b: 0.96, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.64, g: 0.48, b: 0.96, a: 0.10)

        // MARK: - Monokai Theme

        case (.monokai, .light):
            // Monokai Light
            textPrimary = Self.p3Color(r: 0.20, g: 0.20, b: 0.20)
            textSecondary = Self.p3Color(r: 0.60, g: 0.60, b: 0.60)
            link = Self.p3Color(r: 0.06, g: 0.47, b: 0.76) // blue
            heading = Self.p3Color(r: 0.80, g: 0.14, b: 0.14) // red
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.96)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.88)
            blockquoteAccent = Self.p3Color(r: 0.80, g: 0.14, b: 0.14)
            blockquoteBackground = Self.p3Color(r: 0.80, g: 0.14, b: 0.14, a: 0.06)
            inlineCodeBackground = Self.p3Color(r: 0.80, g: 0.14, b: 0.14, a: 0.08)

        case (.monokai, .dark):
            // Monokai Dark
            textPrimary = Self.p3Color(r: 0.97, g: 0.97, b: 0.97) // white
            textSecondary = Self.p3Color(r: 0.70, g: 0.70, b: 0.70) // gray
            link = Self.p3Color(r: 0.27, g: 0.75, b: 0.98) // cyan
            heading = Self.p3Color(r: 0.98, g: 0.26, b: 0.28) // red
            codeBackground = Self.p3Color(r: 0.27, g: 0.27, b: 0.27) // bg
            codeBorder = Self.p3Color(r: 0.39, g: 0.39, b: 0.39)
            blockquoteAccent = Self.p3Color(r: 0.98, g: 0.26, b: 0.28)
            blockquoteBackground = Self.p3Color(r: 0.98, g: 0.26, b: 0.28, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.98, g: 0.26, b: 0.28, a: 0.10)

        // MARK: - Nord Theme

        case (.nord, .light):
            // Nord Light
            textPrimary = Self.p3Color(r: 0.29, g: 0.32, b: 0.38) // nord3
            textSecondary = Self.p3Color(r: 0.54, g: 0.58, b: 0.68) // nord4
            link = Self.p3Color(r: 0.36, g: 0.63, b: 0.78) // nord8
            heading = Self.p3Color(r: 0.29, g: 0.32, b: 0.38)
            codeBackground = Self.p3Color(r: 0.94, g: 0.95, b: 0.96)
            codeBorder = Self.p3Color(r: 0.88, g: 0.89, b: 0.90)
            blockquoteAccent = Self.p3Color(r: 0.36, g: 0.63, b: 0.78)
            blockquoteBackground = Self.p3Color(r: 0.36, g: 0.63, b: 0.78, a: 0.06)
            inlineCodeBackground = Self.p3Color(r: 0.36, g: 0.63, b: 0.78, a: 0.08)

        case (.nord, .dark):
            // Nord Dark
            textPrimary = Self.p3Color(r: 0.92, g: 0.93, b: 0.95) // nord4
            textSecondary = Self.p3Color(r: 0.76, g: 0.77, b: 0.79) // nord5
            link = Self.p3Color(r: 0.51, g: 0.81, b: 0.92) // nord8
            heading = Self.p3Color(r: 0.92, g: 0.93, b: 0.95)
            codeBackground = Self.p3Color(r: 0.19, g: 0.21, b: 0.26) // nord0
            codeBorder = Self.p3Color(r: 0.27, g: 0.29, b: 0.35) // nord1
            blockquoteAccent = Self.p3Color(r: 0.51, g: 0.81, b: 0.92)
            blockquoteBackground = Self.p3Color(r: 0.51, g: 0.81, b: 0.92, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.51, g: 0.81, b: 0.92, a: 0.10)

        // MARK: - One Dark Theme

        case (.onedark, .light):
            // One Dark Light
            textPrimary = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            textSecondary = Self.p3Color(r: 0.55, g: 0.55, b: 0.57)
            link = Self.p3Color(r: 0.09, g: 0.53, b: 0.81) // blue
            heading = Self.p3Color(r: 0.56, g: 0.30, b: 0.00) // orange
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.97)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            blockquoteAccent = Self.p3Color(r: 0.09, g: 0.53, b: 0.81)
            blockquoteBackground = Self.p3Color(r: 0.09, g: 0.53, b: 0.81, a: 0.06)
            inlineCodeBackground = Self.p3Color(r: 0.09, g: 0.53, b: 0.81, a: 0.08)

        case (.onedark, .dark):
            // One Dark
            textPrimary = Self.p3Color(r: 0.97, g: 0.97, b: 0.98) // fg
            textSecondary = Self.p3Color(r: 0.69, g: 0.69, b: 0.70) // comment
            link = Self.p3Color(r: 0.40, g: 0.67, b: 0.98) // blue
            heading = Self.p3Color(r: 0.99, g: 0.61, b: 0.19) // orange
            codeBackground = Self.p3Color(r: 0.21, g: 0.21, b: 0.23) // bg
            codeBorder = Self.p3Color(r: 0.32, g: 0.32, b: 0.35)
            blockquoteAccent = Self.p3Color(r: 0.40, g: 0.67, b: 0.98)
            blockquoteBackground = Self.p3Color(r: 0.40, g: 0.67, b: 0.98, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.40, g: 0.67, b: 0.98, a: 0.10)

        // MARK: - Tokyo Night Theme

        case (.tokyonight, .light):
            // Tokyo Night Light
            textPrimary = Self.p3Color(r: 0.22, g: 0.21, b: 0.30)
            textSecondary = Self.p3Color(r: 0.56, g: 0.54, b: 0.65)
            link = Self.p3Color(r: 0.00, g: 0.46, b: 0.84) // blue
            heading = Self.p3Color(r: 0.63, g: 0.32, b: 0.25) // red
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.97)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            blockquoteAccent = Self.p3Color(r: 0.00, g: 0.46, b: 0.84)
            blockquoteBackground = Self.p3Color(r: 0.00, g: 0.46, b: 0.84, a: 0.06)
            inlineCodeBackground = Self.p3Color(r: 0.00, g: 0.46, b: 0.84, a: 0.08)

        case (.tokyonight, .dark):
            // Tokyo Night
            textPrimary = Self.p3Color(r: 0.96, g: 0.96, b: 0.98) // foreground
            textSecondary = Self.p3Color(r: 0.68, g: 0.67, b: 0.76) // comment
            link = Self.p3Color(r: 0.41, g: 0.75, b: 0.98) // blue
            heading = Self.p3Color(r: 0.98, g: 0.40, b: 0.38) // red
            codeBackground = Self.p3Color(r: 0.16, g: 0.16, b: 0.22) // bg
            codeBorder = Self.p3Color(r: 0.29, g: 0.29, b: 0.37)
            blockquoteAccent = Self.p3Color(r: 0.41, g: 0.75, b: 0.98)
            blockquoteBackground = Self.p3Color(r: 0.41, g: 0.75, b: 0.98, a: 0.08)
            inlineCodeBackground = Self.p3Color(r: 0.41, g: 0.75, b: 0.98, a: 0.10)

        @unknown default:
            textPrimary = .labelColor
            textSecondary = .secondaryLabelColor
            link = .linkColor
            heading = .labelColor
            codeBackground = scheme == .dark
                ? Self.p3Color(r: 0.20, g: 0.20, b: 0.20)
                : Self.p3Color(r: 0.95, g: 0.95, b: 0.95)
            codeBorder = scheme == .dark
                ? Self.p3Color(r: 0.30, g: 0.30, b: 0.30)
                : Self.p3Color(r: 0.88, g: 0.88, b: 0.88)
            blockquoteAccent = scheme == .dark
                ? Self.p3Color(r: 0.45, g: 0.45, b: 0.45)
                : Self.p3Color(r: 0.55, g: 0.55, b: 0.55)
            blockquoteBackground = scheme == .dark
                ? Self.p3Color(r: 1.00, g: 1.00, b: 1.00, a: 0.05)
                : Self.p3Color(r: 0.00, g: 0.00, b: 0.00, a: 0.04)
            inlineCodeBackground = scheme == .dark
                ? Self.p3Color(r: 0.45, g: 0.45, b: 0.45, a: 0.08)
                : Self.p3Color(r: 0.55, g: 0.55, b: 0.55, a: 0.08)
        }
    }
}
