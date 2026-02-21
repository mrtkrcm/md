internal import AppKit
internal import SwiftUI

// MARK: - Theme Definitions

/// Concrete color values for each `AppTheme` / `ColorScheme` combination.
extension NativeThemePalette {
    init(theme: AppTheme, scheme: ColorScheme) {
        switch (theme, scheme) {
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
