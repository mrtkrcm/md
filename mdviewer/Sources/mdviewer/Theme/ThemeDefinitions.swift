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
        self.theme = theme
        self.scheme = scheme
        switch (theme, scheme) {
        // MARK: - Apple Ecosystem Themes

        case (.basic, .light):
            textPrimary = .labelColor
            textSecondary = .secondaryLabelColor
            textTertiary = .tertiaryLabelColor
            link = .linkColor
            linkHover = .linkColor
            accent = .linkColor
            heading = .labelColor
            heading1 = .labelColor
            heading2 = .labelColor
            heading3 = .labelColor
            codeBackground = Self.p3Color(r: 0.95, g: 0.95, b: 0.95)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.88)
            inlineCodeBackground = Self.p3Color(r: 0.55, g: 0.55, b: 0.55, a: 0.08)
            codeText = .secondaryLabelColor
            blockquoteAccent = Self.p3Color(r: 0.55, g: 0.55, b: 0.55)
            blockquoteBackground = Self.p3Color(r: 0.00, g: 0.00, b: 0.00, a: 0.04)
            blockquoteText = .secondaryLabelColor
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = .linkColor
            taskListUnchecked = .secondaryLabelColor
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.basic, .dark):
            textPrimary = .labelColor
            textSecondary = .secondaryLabelColor
            textTertiary = .tertiaryLabelColor
            link = .linkColor
            linkHover = .linkColor
            accent = .linkColor
            heading = .labelColor
            heading1 = .labelColor
            heading2 = .labelColor
            heading3 = .labelColor
            codeBackground = Self.p3Color(r: 0.20, g: 0.20, b: 0.20)
            codeBorder = Self.p3Color(r: 0.30, g: 0.30, b: 0.30)
            inlineCodeBackground = Self.p3Color(r: 0.45, g: 0.45, b: 0.45, a: 0.08)
            codeText = .secondaryLabelColor
            blockquoteAccent = Self.p3Color(r: 0.45, g: 0.45, b: 0.45)
            blockquoteBackground = Self.p3Color(r: 1.00, g: 1.00, b: 1.00, a: 0.05)
            blockquoteText = .secondaryLabelColor
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = .linkColor
            taskListUnchecked = .secondaryLabelColor
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        case (.github, .light):
            textPrimary = Self.p3Color(r: 0.14, g: 0.16, b: 0.20)
            textSecondary = Self.p3Color(r: 0.40, g: 0.42, b: 0.46)
            textTertiary = Self.p3Color(r: 0.40, g: 0.42, b: 0.46, a: 0.7)
            link = Self.p3Color(r: 0.10, g: 0.46, b: 0.82)
            linkHover = Self.p3Color(r: 0.10, g: 0.46, b: 0.82)
            accent = Self.p3Color(r: 0.10, g: 0.46, b: 0.82)
            heading = Self.p3Color(r: 0.06, g: 0.08, b: 0.12)
            heading1 = Self.p3Color(r: 0.06, g: 0.08, b: 0.12)
            heading2 = Self.p3Color(r: 0.06, g: 0.08, b: 0.12)
            heading3 = Self.p3Color(r: 0.06, g: 0.08, b: 0.12)
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.96)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.88)
            inlineCodeBackground = Self.p3Color(r: 0.22, g: 0.51, b: 0.82, a: 0.08)
            codeText = Self.p3Color(r: 0.40, g: 0.42, b: 0.46)
            blockquoteAccent = Self.p3Color(r: 0.22, g: 0.51, b: 0.82)
            blockquoteBackground = Self.p3Color(r: 0.22, g: 0.51, b: 0.82, a: 0.06)
            blockquoteText = Self.p3Color(r: 0.40, g: 0.42, b: 0.46)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.10, g: 0.46, b: 0.82)
            taskListUnchecked = Self.p3Color(r: 0.40, g: 0.42, b: 0.46)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.github, .dark):
            textPrimary = Self.p3Color(r: 0.90, g: 0.90, b: 0.90)
            textSecondary = Self.p3Color(r: 0.60, g: 0.62, b: 0.66)
            textTertiary = Self.p3Color(r: 0.60, g: 0.62, b: 0.66, a: 0.7)
            link = Self.p3Color(r: 0.53, g: 0.75, b: 0.98)
            linkHover = Self.p3Color(r: 0.53, g: 0.75, b: 0.98)
            accent = Self.p3Color(r: 0.53, g: 0.75, b: 0.98)
            heading = Self.p3Color(r: 0.95, g: 0.96, b: 0.98)
            heading1 = Self.p3Color(r: 0.95, g: 0.96, b: 0.98)
            heading2 = Self.p3Color(r: 0.95, g: 0.96, b: 0.98)
            heading3 = Self.p3Color(r: 0.95, g: 0.96, b: 0.98)
            codeBackground = Self.p3Color(r: 0.17, g: 0.18, b: 0.20)
            codeBorder = Self.p3Color(r: 0.28, g: 0.29, b: 0.32)
            inlineCodeBackground = Self.p3Color(r: 0.35, g: 0.62, b: 0.90, a: 0.10)
            codeText = Self.p3Color(r: 0.60, g: 0.62, b: 0.66)
            blockquoteAccent = Self.p3Color(r: 0.35, g: 0.62, b: 0.90)
            blockquoteBackground = Self.p3Color(r: 0.35, g: 0.62, b: 0.90, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.60, g: 0.62, b: 0.66)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.53, g: 0.75, b: 0.98)
            taskListUnchecked = Self.p3Color(r: 0.60, g: 0.62, b: 0.66)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        case (.docC, .light):
            textPrimary = Self.p3Color(r: 0.12, g: 0.12, b: 0.14)
            textSecondary = Self.p3Color(r: 0.38, g: 0.38, b: 0.42)
            textTertiary = Self.p3Color(r: 0.38, g: 0.38, b: 0.42, a: 0.7)
            link = Self.p3Color(r: 0.00, g: 0.48, b: 1.00)
            linkHover = Self.p3Color(r: 0.00, g: 0.48, b: 1.00)
            accent = Self.p3Color(r: 0.00, g: 0.48, b: 1.00)
            heading = Self.p3Color(r: 0.05, g: 0.05, b: 0.08)
            heading1 = Self.p3Color(r: 0.05, g: 0.05, b: 0.08)
            heading2 = Self.p3Color(r: 0.05, g: 0.05, b: 0.08)
            heading3 = Self.p3Color(r: 0.05, g: 0.05, b: 0.08)
            codeBackground = Self.p3Color(r: 0.95, g: 0.95, b: 0.96)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            inlineCodeBackground = Self.p3Color(r: 0.00, g: 0.48, b: 1.00, a: 0.08)
            codeText = Self.p3Color(r: 0.38, g: 0.38, b: 0.42)
            blockquoteAccent = Self.p3Color(r: 0.00, g: 0.48, b: 1.00)
            blockquoteBackground = Self.p3Color(r: 0.00, g: 0.48, b: 1.00, a: 0.05)
            blockquoteText = Self.p3Color(r: 0.38, g: 0.38, b: 0.42)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.00, g: 0.48, b: 1.00)
            taskListUnchecked = Self.p3Color(r: 0.38, g: 0.38, b: 0.42)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.docC, .dark):
            textPrimary = Self.p3Color(r: 0.93, g: 0.93, b: 0.94)
            textSecondary = Self.p3Color(r: 0.60, g: 0.60, b: 0.64)
            textTertiary = Self.p3Color(r: 0.60, g: 0.60, b: 0.64, a: 0.7)
            link = Self.p3Color(r: 0.25, g: 0.60, b: 1.00)
            linkHover = Self.p3Color(r: 0.25, g: 0.60, b: 1.00)
            accent = Self.p3Color(r: 0.25, g: 0.60, b: 1.00)
            heading = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            heading1 = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            heading2 = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            heading3 = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            codeBackground = Self.p3Color(r: 0.14, g: 0.15, b: 0.17)
            codeBorder = Self.p3Color(r: 0.26, g: 0.27, b: 0.30)
            inlineCodeBackground = Self.p3Color(r: 0.25, g: 0.60, b: 1.00, a: 0.10)
            codeText = Self.p3Color(r: 0.60, g: 0.60, b: 0.64)
            blockquoteAccent = Self.p3Color(r: 0.25, g: 0.60, b: 1.00)
            blockquoteBackground = Self.p3Color(r: 0.25, g: 0.60, b: 1.00, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.60, g: 0.60, b: 0.64)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.25, g: 0.60, b: 1.00)
            taskListUnchecked = Self.p3Color(r: 0.60, g: 0.60, b: 0.64)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        // MARK: - Solarized Theme

        case (.solarized, .light):
            textPrimary = Self.p3Color(r: 0.40, g: 0.48, b: 0.51)
            textSecondary = Self.p3Color(r: 0.58, g: 0.63, b: 0.67)
            textTertiary = Self.p3Color(r: 0.58, g: 0.63, b: 0.67, a: 0.7)
            link = Self.p3Color(r: 0.16, g: 0.63, b: 0.60)
            linkHover = Self.p3Color(r: 0.16, g: 0.63, b: 0.60)
            accent = Self.p3Color(r: 0.16, g: 0.63, b: 0.60)
            heading = Self.p3Color(r: 0.27, g: 0.51, b: 0.71)
            heading1 = Self.p3Color(r: 0.27, g: 0.51, b: 0.71)
            heading2 = Self.p3Color(r: 0.27, g: 0.51, b: 0.71)
            heading3 = Self.p3Color(r: 0.27, g: 0.51, b: 0.71)
            codeBackground = Self.p3Color(r: 0.93, g: 0.91, b: 0.84)
            codeBorder = Self.p3Color(r: 0.88, g: 0.86, b: 0.78)
            inlineCodeBackground = Self.p3Color(r: 0.40, g: 0.48, b: 0.51, a: 0.10)
            codeText = Self.p3Color(r: 0.58, g: 0.63, b: 0.67)
            blockquoteAccent = Self.p3Color(r: 0.40, g: 0.48, b: 0.51)
            blockquoteBackground = Self.p3Color(r: 0.40, g: 0.48, b: 0.51, a: 0.06)
            blockquoteText = Self.p3Color(r: 0.58, g: 0.63, b: 0.67)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.16, g: 0.63, b: 0.60)
            taskListUnchecked = Self.p3Color(r: 0.58, g: 0.63, b: 0.67)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.solarized, .dark):
            textPrimary = Self.p3Color(r: 0.83, g: 0.86, b: 0.88)
            textSecondary = Self.p3Color(r: 0.65, g: 0.68, b: 0.70)
            textTertiary = Self.p3Color(r: 0.65, g: 0.68, b: 0.70, a: 0.7)
            link = Self.p3Color(r: 0.16, g: 0.63, b: 0.60)
            linkHover = Self.p3Color(r: 0.16, g: 0.63, b: 0.60)
            accent = Self.p3Color(r: 0.16, g: 0.63, b: 0.60)
            heading = Self.p3Color(r: 0.35, g: 0.70, b: 0.82)
            heading1 = Self.p3Color(r: 0.35, g: 0.70, b: 0.82)
            heading2 = Self.p3Color(r: 0.35, g: 0.70, b: 0.82)
            heading3 = Self.p3Color(r: 0.35, g: 0.70, b: 0.82)
            codeBackground = Self.p3Color(r: 0.01, g: 0.15, b: 0.22)
            codeBorder = Self.p3Color(r: 0.06, g: 0.20, b: 0.26)
            inlineCodeBackground = Self.p3Color(r: 0.35, g: 0.70, b: 0.82, a: 0.10)
            codeText = Self.p3Color(r: 0.65, g: 0.68, b: 0.70)
            blockquoteAccent = Self.p3Color(r: 0.35, g: 0.70, b: 0.82)
            blockquoteBackground = Self.p3Color(r: 0.35, g: 0.70, b: 0.82, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.65, g: 0.68, b: 0.70)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.16, g: 0.63, b: 0.60)
            taskListUnchecked = Self.p3Color(r: 0.65, g: 0.68, b: 0.70)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        // MARK: - Gruvbox Theme

        case (.gruvbox, .light):
            textPrimary = Self.p3Color(r: 0.29, g: 0.25, b: 0.18)
            textSecondary = Self.p3Color(r: 0.59, g: 0.54, b: 0.44)
            textTertiary = Self.p3Color(r: 0.59, g: 0.54, b: 0.44, a: 0.7)
            link = Self.p3Color(r: 0.16, g: 0.53, b: 0.36)
            linkHover = Self.p3Color(r: 0.16, g: 0.53, b: 0.36)
            accent = Self.p3Color(r: 0.16, g: 0.53, b: 0.36)
            heading = Self.p3Color(r: 0.48, g: 0.33, b: 0.16)
            heading1 = Self.p3Color(r: 0.48, g: 0.33, b: 0.16)
            heading2 = Self.p3Color(r: 0.48, g: 0.33, b: 0.16)
            heading3 = Self.p3Color(r: 0.48, g: 0.33, b: 0.16)
            codeBackground = Self.p3Color(r: 0.92, g: 0.91, b: 0.85)
            codeBorder = Self.p3Color(r: 0.88, g: 0.87, b: 0.80)
            inlineCodeBackground = Self.p3Color(r: 0.56, g: 0.27, b: 0.27, a: 0.10)
            codeText = Self.p3Color(r: 0.59, g: 0.54, b: 0.44)
            blockquoteAccent = Self.p3Color(r: 0.56, g: 0.27, b: 0.27)
            blockquoteBackground = Self.p3Color(r: 0.56, g: 0.27, b: 0.27, a: 0.06)
            blockquoteText = Self.p3Color(r: 0.59, g: 0.54, b: 0.44)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.16, g: 0.53, b: 0.36)
            taskListUnchecked = Self.p3Color(r: 0.59, g: 0.54, b: 0.44)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.gruvbox, .dark):
            textPrimary = Self.p3Color(r: 0.92, g: 0.91, b: 0.85)
            textSecondary = Self.p3Color(r: 0.73, g: 0.73, b: 0.68)
            textTertiary = Self.p3Color(r: 0.73, g: 0.73, b: 0.68, a: 0.7)
            link = Self.p3Color(r: 0.56, g: 0.74, b: 0.27)
            linkHover = Self.p3Color(r: 0.56, g: 0.74, b: 0.27)
            accent = Self.p3Color(r: 0.56, g: 0.74, b: 0.27)
            heading = Self.p3Color(r: 1.00, g: 0.59, b: 0.10)
            heading1 = Self.p3Color(r: 1.00, g: 0.59, b: 0.10)
            heading2 = Self.p3Color(r: 1.00, g: 0.59, b: 0.10)
            heading3 = Self.p3Color(r: 1.00, g: 0.59, b: 0.10)
            codeBackground = Self.p3Color(r: 0.16, g: 0.15, b: 0.13)
            codeBorder = Self.p3Color(r: 0.24, g: 0.23, b: 0.21)
            inlineCodeBackground = Self.p3Color(r: 0.98, g: 0.48, b: 0.43, a: 0.10)
            codeText = Self.p3Color(r: 0.73, g: 0.73, b: 0.68)
            blockquoteAccent = Self.p3Color(r: 0.98, g: 0.48, b: 0.43)
            blockquoteBackground = Self.p3Color(r: 0.98, g: 0.48, b: 0.43, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.73, g: 0.73, b: 0.68)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.56, g: 0.74, b: 0.27)
            taskListUnchecked = Self.p3Color(r: 0.73, g: 0.73, b: 0.68)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        // MARK: - Dracula Theme

        case (.dracula, .light):
            textPrimary = Self.p3Color(r: 0.25, g: 0.26, b: 0.35)
            textSecondary = Self.p3Color(r: 0.58, g: 0.59, b: 0.67)
            textTertiary = Self.p3Color(r: 0.58, g: 0.59, b: 0.67, a: 0.7)
            link = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            linkHover = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            accent = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            heading = Self.p3Color(r: 0.25, g: 0.26, b: 0.35)
            heading1 = Self.p3Color(r: 0.25, g: 0.26, b: 0.35)
            heading2 = Self.p3Color(r: 0.25, g: 0.26, b: 0.35)
            heading3 = Self.p3Color(r: 0.25, g: 0.26, b: 0.35)
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.97)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            inlineCodeBackground = Self.p3Color(r: 0.64, g: 0.48, b: 0.96, a: 0.08)
            codeText = Self.p3Color(r: 0.58, g: 0.59, b: 0.67)
            blockquoteAccent = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            blockquoteBackground = Self.p3Color(r: 0.64, g: 0.48, b: 0.96, a: 0.06)
            blockquoteText = Self.p3Color(r: 0.58, g: 0.59, b: 0.67)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            taskListUnchecked = Self.p3Color(r: 0.58, g: 0.59, b: 0.67)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.dracula, .dark):
            textPrimary = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            textSecondary = Self.p3Color(r: 0.70, g: 0.71, b: 0.73)
            textTertiary = Self.p3Color(r: 0.70, g: 0.71, b: 0.73, a: 0.7)
            link = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            linkHover = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            accent = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            heading = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            heading1 = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            heading2 = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            heading3 = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            codeBackground = Self.p3Color(r: 0.28, g: 0.28, b: 0.38)
            codeBorder = Self.p3Color(r: 0.44, g: 0.44, b: 0.53)
            inlineCodeBackground = Self.p3Color(r: 0.64, g: 0.48, b: 0.96, a: 0.10)
            codeText = Self.p3Color(r: 0.70, g: 0.71, b: 0.73)
            blockquoteAccent = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            blockquoteBackground = Self.p3Color(r: 0.64, g: 0.48, b: 0.96, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.70, g: 0.71, b: 0.73)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.64, g: 0.48, b: 0.96)
            taskListUnchecked = Self.p3Color(r: 0.70, g: 0.71, b: 0.73)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        // MARK: - Monokai Theme

        case (.monokai, .light):
            textPrimary = Self.p3Color(r: 0.20, g: 0.20, b: 0.20)
            textSecondary = Self.p3Color(r: 0.60, g: 0.60, b: 0.60)
            textTertiary = Self.p3Color(r: 0.60, g: 0.60, b: 0.60, a: 0.7)
            link = Self.p3Color(r: 0.06, g: 0.47, b: 0.76)
            linkHover = Self.p3Color(r: 0.06, g: 0.47, b: 0.76)
            accent = Self.p3Color(r: 0.06, g: 0.47, b: 0.76)
            heading = Self.p3Color(r: 0.80, g: 0.14, b: 0.14)
            heading1 = Self.p3Color(r: 0.80, g: 0.14, b: 0.14)
            heading2 = Self.p3Color(r: 0.80, g: 0.14, b: 0.14)
            heading3 = Self.p3Color(r: 0.80, g: 0.14, b: 0.14)
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.96)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.88)
            inlineCodeBackground = Self.p3Color(r: 0.80, g: 0.14, b: 0.14, a: 0.08)
            codeText = Self.p3Color(r: 0.60, g: 0.60, b: 0.60)
            blockquoteAccent = Self.p3Color(r: 0.80, g: 0.14, b: 0.14)
            blockquoteBackground = Self.p3Color(r: 0.80, g: 0.14, b: 0.14, a: 0.06)
            blockquoteText = Self.p3Color(r: 0.60, g: 0.60, b: 0.60)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.06, g: 0.47, b: 0.76)
            taskListUnchecked = Self.p3Color(r: 0.60, g: 0.60, b: 0.60)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.monokai, .dark):
            textPrimary = Self.p3Color(r: 0.97, g: 0.97, b: 0.97)
            textSecondary = Self.p3Color(r: 0.70, g: 0.70, b: 0.70)
            textTertiary = Self.p3Color(r: 0.70, g: 0.70, b: 0.70, a: 0.7)
            link = Self.p3Color(r: 0.27, g: 0.75, b: 0.98)
            linkHover = Self.p3Color(r: 0.27, g: 0.75, b: 0.98)
            accent = Self.p3Color(r: 0.27, g: 0.75, b: 0.98)
            heading = Self.p3Color(r: 0.98, g: 0.26, b: 0.28)
            heading1 = Self.p3Color(r: 0.98, g: 0.26, b: 0.28)
            heading2 = Self.p3Color(r: 0.98, g: 0.26, b: 0.28)
            heading3 = Self.p3Color(r: 0.98, g: 0.26, b: 0.28)
            codeBackground = Self.p3Color(r: 0.27, g: 0.27, b: 0.27)
            codeBorder = Self.p3Color(r: 0.39, g: 0.39, b: 0.39)
            inlineCodeBackground = Self.p3Color(r: 0.98, g: 0.26, b: 0.28, a: 0.10)
            codeText = Self.p3Color(r: 0.70, g: 0.70, b: 0.70)
            blockquoteAccent = Self.p3Color(r: 0.98, g: 0.26, b: 0.28)
            blockquoteBackground = Self.p3Color(r: 0.98, g: 0.26, b: 0.28, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.70, g: 0.70, b: 0.70)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.27, g: 0.75, b: 0.98)
            taskListUnchecked = Self.p3Color(r: 0.70, g: 0.70, b: 0.70)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        // MARK: - Nord Theme

        case (.nord, .light):
            textPrimary = Self.p3Color(r: 0.29, g: 0.32, b: 0.38)
            textSecondary = Self.p3Color(r: 0.54, g: 0.58, b: 0.68)
            textTertiary = Self.p3Color(r: 0.54, g: 0.58, b: 0.68, a: 0.7)
            link = Self.p3Color(r: 0.36, g: 0.63, b: 0.78)
            linkHover = Self.p3Color(r: 0.36, g: 0.63, b: 0.78)
            accent = Self.p3Color(r: 0.36, g: 0.63, b: 0.78)
            heading = Self.p3Color(r: 0.29, g: 0.32, b: 0.38)
            heading1 = Self.p3Color(r: 0.29, g: 0.32, b: 0.38)
            heading2 = Self.p3Color(r: 0.29, g: 0.32, b: 0.38)
            heading3 = Self.p3Color(r: 0.29, g: 0.32, b: 0.38)
            codeBackground = Self.p3Color(r: 0.94, g: 0.95, b: 0.96)
            codeBorder = Self.p3Color(r: 0.88, g: 0.89, b: 0.90)
            inlineCodeBackground = Self.p3Color(r: 0.36, g: 0.63, b: 0.78, a: 0.08)
            codeText = Self.p3Color(r: 0.54, g: 0.58, b: 0.68)
            blockquoteAccent = Self.p3Color(r: 0.36, g: 0.63, b: 0.78)
            blockquoteBackground = Self.p3Color(r: 0.36, g: 0.63, b: 0.78, a: 0.06)
            blockquoteText = Self.p3Color(r: 0.54, g: 0.58, b: 0.68)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.36, g: 0.63, b: 0.78)
            taskListUnchecked = Self.p3Color(r: 0.54, g: 0.58, b: 0.68)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.nord, .dark):
            textPrimary = Self.p3Color(r: 0.92, g: 0.93, b: 0.95)
            textSecondary = Self.p3Color(r: 0.76, g: 0.77, b: 0.79)
            textTertiary = Self.p3Color(r: 0.76, g: 0.77, b: 0.79, a: 0.7)
            link = Self.p3Color(r: 0.51, g: 0.81, b: 0.92)
            linkHover = Self.p3Color(r: 0.51, g: 0.81, b: 0.92)
            accent = Self.p3Color(r: 0.51, g: 0.81, b: 0.92)
            heading = Self.p3Color(r: 0.92, g: 0.93, b: 0.95)
            heading1 = Self.p3Color(r: 0.92, g: 0.93, b: 0.95)
            heading2 = Self.p3Color(r: 0.92, g: 0.93, b: 0.95)
            heading3 = Self.p3Color(r: 0.92, g: 0.93, b: 0.95)
            codeBackground = Self.p3Color(r: 0.19, g: 0.21, b: 0.26)
            codeBorder = Self.p3Color(r: 0.27, g: 0.29, b: 0.35)
            inlineCodeBackground = Self.p3Color(r: 0.51, g: 0.81, b: 0.92, a: 0.10)
            codeText = Self.p3Color(r: 0.76, g: 0.77, b: 0.79)
            blockquoteAccent = Self.p3Color(r: 0.51, g: 0.81, b: 0.92)
            blockquoteBackground = Self.p3Color(r: 0.51, g: 0.81, b: 0.92, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.76, g: 0.77, b: 0.79)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.51, g: 0.81, b: 0.92)
            taskListUnchecked = Self.p3Color(r: 0.76, g: 0.77, b: 0.79)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        // MARK: - One Dark Theme

        case (.onedark, .light):
            textPrimary = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            textSecondary = Self.p3Color(r: 0.55, g: 0.55, b: 0.57)
            textTertiary = Self.p3Color(r: 0.55, g: 0.55, b: 0.57, a: 0.7)
            link = Self.p3Color(r: 0.09, g: 0.53, b: 0.81)
            linkHover = Self.p3Color(r: 0.09, g: 0.53, b: 0.81)
            accent = Self.p3Color(r: 0.09, g: 0.53, b: 0.81)
            heading = Self.p3Color(r: 0.56, g: 0.30, b: 0.00)
            heading1 = Self.p3Color(r: 0.56, g: 0.30, b: 0.00)
            heading2 = Self.p3Color(r: 0.56, g: 0.30, b: 0.00)
            heading3 = Self.p3Color(r: 0.56, g: 0.30, b: 0.00)
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.97)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            inlineCodeBackground = Self.p3Color(r: 0.09, g: 0.53, b: 0.81, a: 0.08)
            codeText = Self.p3Color(r: 0.55, g: 0.55, b: 0.57)
            blockquoteAccent = Self.p3Color(r: 0.09, g: 0.53, b: 0.81)
            blockquoteBackground = Self.p3Color(r: 0.09, g: 0.53, b: 0.81, a: 0.06)
            blockquoteText = Self.p3Color(r: 0.55, g: 0.55, b: 0.57)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.09, g: 0.53, b: 0.81)
            taskListUnchecked = Self.p3Color(r: 0.55, g: 0.55, b: 0.57)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.onedark, .dark):
            textPrimary = Self.p3Color(r: 0.97, g: 0.97, b: 0.98)
            textSecondary = Self.p3Color(r: 0.69, g: 0.69, b: 0.70)
            textTertiary = Self.p3Color(r: 0.69, g: 0.69, b: 0.70, a: 0.7)
            link = Self.p3Color(r: 0.40, g: 0.67, b: 0.98)
            linkHover = Self.p3Color(r: 0.40, g: 0.67, b: 0.98)
            accent = Self.p3Color(r: 0.40, g: 0.67, b: 0.98)
            heading = Self.p3Color(r: 0.99, g: 0.61, b: 0.19)
            heading1 = Self.p3Color(r: 0.99, g: 0.61, b: 0.19)
            heading2 = Self.p3Color(r: 0.99, g: 0.61, b: 0.19)
            heading3 = Self.p3Color(r: 0.99, g: 0.61, b: 0.19)
            codeBackground = Self.p3Color(r: 0.21, g: 0.21, b: 0.23)
            codeBorder = Self.p3Color(r: 0.32, g: 0.32, b: 0.35)
            inlineCodeBackground = Self.p3Color(r: 0.40, g: 0.67, b: 0.98, a: 0.10)
            codeText = Self.p3Color(r: 0.69, g: 0.69, b: 0.70)
            blockquoteAccent = Self.p3Color(r: 0.40, g: 0.67, b: 0.98)
            blockquoteBackground = Self.p3Color(r: 0.40, g: 0.67, b: 0.98, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.69, g: 0.69, b: 0.70)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.40, g: 0.67, b: 0.98)
            taskListUnchecked = Self.p3Color(r: 0.69, g: 0.69, b: 0.70)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        // MARK: - Tokyo Night Theme

        case (.tokyonight, .light):
            textPrimary = Self.p3Color(r: 0.22, g: 0.21, b: 0.30)
            textSecondary = Self.p3Color(r: 0.56, g: 0.54, b: 0.65)
            textTertiary = Self.p3Color(r: 0.56, g: 0.54, b: 0.65, a: 0.7)
            link = Self.p3Color(r: 0.00, g: 0.46, b: 0.84)
            linkHover = Self.p3Color(r: 0.00, g: 0.46, b: 0.84)
            accent = Self.p3Color(r: 0.00, g: 0.46, b: 0.84)
            heading = Self.p3Color(r: 0.63, g: 0.32, b: 0.25)
            heading1 = Self.p3Color(r: 0.63, g: 0.32, b: 0.25)
            heading2 = Self.p3Color(r: 0.63, g: 0.32, b: 0.25)
            heading3 = Self.p3Color(r: 0.63, g: 0.32, b: 0.25)
            codeBackground = Self.p3Color(r: 0.96, g: 0.96, b: 0.97)
            codeBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            inlineCodeBackground = Self.p3Color(r: 0.00, g: 0.46, b: 0.84, a: 0.08)
            codeText = Self.p3Color(r: 0.56, g: 0.54, b: 0.65)
            blockquoteAccent = Self.p3Color(r: 0.00, g: 0.46, b: 0.84)
            blockquoteBackground = Self.p3Color(r: 0.00, g: 0.46, b: 0.84, a: 0.06)
            blockquoteText = Self.p3Color(r: 0.56, g: 0.54, b: 0.65)
            tableHeaderBackground = Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = Self.p3Color(r: 0.00, g: 0.46, b: 0.84)
            taskListUnchecked = Self.p3Color(r: 0.56, g: 0.54, b: 0.65)
            taskListChecked = Self.p3Color(r: 0.2, g: 0.6, b: 0.3)
            horizontalRule = Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .black

        case (.tokyonight, .dark):
            textPrimary = Self.p3Color(r: 0.96, g: 0.96, b: 0.98)
            textSecondary = Self.p3Color(r: 0.68, g: 0.67, b: 0.76)
            textTertiary = Self.p3Color(r: 0.68, g: 0.67, b: 0.76, a: 0.7)
            link = Self.p3Color(r: 0.41, g: 0.75, b: 0.98)
            linkHover = Self.p3Color(r: 0.41, g: 0.75, b: 0.98)
            accent = Self.p3Color(r: 0.41, g: 0.75, b: 0.98)
            heading = Self.p3Color(r: 0.98, g: 0.40, b: 0.38)
            heading1 = Self.p3Color(r: 0.98, g: 0.40, b: 0.38)
            heading2 = Self.p3Color(r: 0.98, g: 0.40, b: 0.38)
            heading3 = Self.p3Color(r: 0.98, g: 0.40, b: 0.38)
            codeBackground = Self.p3Color(r: 0.16, g: 0.16, b: 0.22)
            codeBorder = Self.p3Color(r: 0.29, g: 0.29, b: 0.37)
            inlineCodeBackground = Self.p3Color(r: 0.41, g: 0.75, b: 0.98, a: 0.10)
            codeText = Self.p3Color(r: 0.68, g: 0.67, b: 0.76)
            blockquoteAccent = Self.p3Color(r: 0.41, g: 0.75, b: 0.98)
            blockquoteBackground = Self.p3Color(r: 0.41, g: 0.75, b: 0.98, a: 0.08)
            blockquoteText = Self.p3Color(r: 0.68, g: 0.67, b: 0.76)
            tableHeaderBackground = Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
            tableBorder = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            tableRowAlternating = Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
            listMarker = Self.p3Color(r: 0.41, g: 0.75, b: 0.98)
            taskListUnchecked = Self.p3Color(r: 0.68, g: 0.67, b: 0.76)
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
            selectionBackground = Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
            selectionText = .white

        @unknown default:
            textPrimary = .labelColor
            textSecondary = .secondaryLabelColor
            textTertiary = .tertiaryLabelColor
            link = .linkColor
            linkHover = .linkColor
            accent = .linkColor
            heading = .labelColor
            heading1 = .labelColor
            heading2 = .labelColor
            heading3 = .labelColor
            codeBackground = scheme == .dark
                ? Self.p3Color(r: 0.20, g: 0.20, b: 0.20)
                : Self.p3Color(r: 0.95, g: 0.95, b: 0.95)
            codeBorder = scheme == .dark
                ? Self.p3Color(r: 0.30, g: 0.30, b: 0.30)
                : Self.p3Color(r: 0.88, g: 0.88, b: 0.88)
            inlineCodeBackground = scheme == .dark
                ? Self.p3Color(r: 0.45, g: 0.45, b: 0.45, a: 0.08)
                : Self.p3Color(r: 0.55, g: 0.55, b: 0.55, a: 0.08)
            codeText = .secondaryLabelColor
            blockquoteAccent = scheme == .dark
                ? Self.p3Color(r: 0.45, g: 0.45, b: 0.45)
                : Self.p3Color(r: 0.55, g: 0.55, b: 0.55)
            blockquoteBackground = scheme == .dark
                ? Self.p3Color(r: 1.00, g: 1.00, b: 1.00, a: 0.05)
                : Self.p3Color(r: 0.00, g: 0.00, b: 0.00, a: 0.04)
            blockquoteText = .secondaryLabelColor
            tableHeaderBackground = scheme == .dark
                ? Self.p3Color(r: 0.25, g: 0.25, b: 0.27)
                : Self.p3Color(r: 0.94, g: 0.94, b: 0.96)
            tableBorder = scheme == .dark
                ? Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
                : Self.p3Color(r: 0.88, g: 0.88, b: 0.90)
            tableRowAlternating = scheme == .dark
                ? Self.p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03)
                : Self.p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02)
            listMarker = .linkColor
            taskListUnchecked = .secondaryLabelColor
            taskListChecked = Self.p3Color(r: 0.3, g: 0.7, b: 0.4)
            horizontalRule = scheme == .dark
                ? Self.p3Color(r: 0.35, g: 0.35, b: 0.38)
                : Self.p3Color(r: 0.85, g: 0.85, b: 0.88)
            selectionBackground = scheme == .dark
                ? Self.p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4)
                : Self.p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25)
            selectionText = .labelColor
        }

        // Normalize explicit raw heading level tokens for every theme.
        // This keeps level tokens differentiated at the definition layer.
        let rawHeadingLevels = Self.rawHeadingLevels(
            base: heading,
            accent: accent,
            primary: textPrimary,
            scheme: scheme
        )
        heading1 = rawHeadingLevels.h1
        heading2 = rawHeadingLevels.h2
        heading3 = rawHeadingLevels.h3

        let rawBlockquote = Self.rawBlockquoteTokens(
            accent: blockquoteAccent,
            background: blockquoteBackground,
            text: blockquoteText,
            link: link,
            textSecondary: textSecondary,
            scheme: scheme
        )
        blockquoteAccent = rawBlockquote.accent
        blockquoteBackground = rawBlockquote.background
        blockquoteText = rawBlockquote.text

        let rawTable = Self.rawTableTokens(
            header: tableHeaderBackground,
            border: tableBorder,
            rowAlternating: tableRowAlternating,
            accent: accent,
            codeBackground: codeBackground,
            inlineCodeBackground: inlineCodeBackground,
            scheme: scheme
        )
        tableHeaderBackground = rawTable.header
        tableBorder = rawTable.border
        tableRowAlternating = rawTable.rowAlternating

        // Cache derived formatting tokens so render passes avoid repeated blending.
        formattedHeading = Self.derivedHeadingColor(
            base: heading,
            accent: accent,
            link: link,
            textPrimary: textPrimary,
            theme: theme,
            scheme: scheme,
            level: 0
        )
        formattedHeading1 = Self.derivedHeadingColor(
            base: heading1,
            accent: accent,
            link: link,
            textPrimary: textPrimary,
            theme: theme,
            scheme: scheme,
            level: 1
        )
        formattedHeading2 = Self.derivedHeadingColor(
            base: heading2,
            accent: accent,
            link: link,
            textPrimary: textPrimary,
            theme: theme,
            scheme: scheme,
            level: 2
        )
        formattedHeading3 = Self.derivedHeadingColor(
            base: heading3,
            accent: accent,
            link: link,
            textPrimary: textPrimary,
            theme: theme,
            scheme: scheme,
            level: 3
        )
        formattedTableHeaderSurface = Self.derivedTableHeaderBackground(
            base: tableHeaderBackground,
            codeBackground: codeBackground,
            scheme: scheme
        )
        formattedTableRowSurface = Self.derivedTableRowBackground(
            base: tableRowAlternating,
            inlineCodeBackground: inlineCodeBackground,
            scheme: scheme
        )
        formattedTableBorderStroke = Self.derivedTableBorder(
            base: tableBorder,
            accent: accent,
            theme: theme,
            scheme: scheme
        )
        formattedLinkUnderline = Self.derivedLinkUnderline(
            link: link,
            textPrimary: textPrimary,
            scheme: scheme
        )
    }
}

// MARK: - Formatting Integration

extension NativeThemePalette {
    fileprivate static func rawHeadingLevels(
        base: NSColor,
        accent: NSColor,
        primary: NSColor,
        scheme: ColorScheme
    ) -> (h1: NSColor, h2: NSColor, h3: NSColor) {
        let h1AccentMix: CGFloat = scheme == .dark ? 0.14 : 0.02
        let h2AccentMix: CGFloat = scheme == .dark ? 0.09 : 0.06
        let h3AccentMix: CGFloat = scheme == .dark ? 0.05 : 0.03
        let h2TextMix: CGFloat = scheme == .dark ? 0.06 : 0.03
        let h3TextMix: CGFloat = scheme == .dark ? 0.10 : 0.06

        let h1 = base.blended(withFraction: h1AccentMix, of: accent) ?? base
        let h2Accent = base.blended(withFraction: h2AccentMix, of: accent) ?? base
        let h2 = h2Accent.blended(withFraction: h2TextMix, of: primary) ?? h2Accent
        let h3Accent = base.blended(withFraction: h3AccentMix, of: accent) ?? base
        let h3 = h3Accent.blended(withFraction: h3TextMix, of: primary) ?? h3Accent

        return (h1, h2, h3)
    }

    fileprivate static func rawBlockquoteTokens(
        accent: NSColor,
        background: NSColor,
        text: NSColor,
        link: NSColor,
        textSecondary: NSColor,
        scheme: ColorScheme
    ) -> (accent: NSColor, background: NSColor, text: NSColor) {
        let accentMix: CGFloat = scheme == .dark ? 0.10 : 0.06
        let bgLinkMix: CGFloat = scheme == .dark ? 0.08 : 0.05
        let textMix: CGFloat = scheme == .dark ? 0.14 : 0.08

        let normalizedAccent = accent.blended(withFraction: accentMix, of: link) ?? accent
        let normalizedBackground = background.blended(withFraction: bgLinkMix, of: normalizedAccent) ?? background
        let normalizedText = text.blended(withFraction: textMix, of: textSecondary) ?? text

        return (normalizedAccent, normalizedBackground, normalizedText)
    }

    fileprivate static func rawTableTokens(
        header: NSColor,
        border: NSColor,
        rowAlternating: NSColor,
        accent: NSColor,
        codeBackground: NSColor,
        inlineCodeBackground: NSColor,
        scheme: ColorScheme
    ) -> (header: NSColor, border: NSColor, rowAlternating: NSColor) {
        let headerCodeMix: CGFloat = scheme == .dark ? 0.12 : 0.08
        let borderAccentMix: CGFloat = scheme == .dark ? 0.14 : 0.08
        let rowInlineMix: CGFloat = scheme == .dark ? 0.07 : 0.04

        let normalizedHeader = header.blended(withFraction: headerCodeMix, of: codeBackground) ?? header
        let normalizedBorder = border.blended(withFraction: borderAccentMix, of: accent) ?? border
        let normalizedRow = rowAlternating
            .blended(withFraction: rowInlineMix, of: inlineCodeBackground) ?? rowAlternating

        return (normalizedHeader, normalizedBorder, normalizedRow)
    }

    fileprivate static func derivedHeadingColor(
        base: NSColor,
        accent: NSColor,
        link: NSColor,
        textPrimary: NSColor,
        theme: AppTheme,
        scheme: ColorScheme,
        level: Int
    ) -> NSColor {
        let accentMix: CGFloat
        let textMix: CGFloat
        switch level {
        case 1:
            accentMix = scheme == .dark ? 0.20 : 0.14
            textMix = 0

        case 2:
            accentMix = scheme == .dark ? 0.12 : 0.08
            textMix = scheme == .dark ? 0.08 : 0.04

        case 3:
            accentMix = scheme == .dark ? 0.06 : 0.03
            textMix = scheme == .dark ? 0.14 : 0.08

        default:
            accentMix = 0
            textMix = scheme == .dark ? 0.10 : 0.06
        }

        let themeBias: CGFloat
        switch theme {
        case .docC:
            themeBias = 0.14

        case .github:
            themeBias = 0.04

        case .solarized, .gruvbox, .dracula, .monokai, .nord, .onedark, .tokyonight:
            themeBias = 0.08

        default:
            themeBias = 0.05
        }

        let accented = base.blended(withFraction: accentMix, of: accent) ?? base
        let themed = accented.blended(withFraction: themeBias, of: link) ?? accented
        return themed.blended(withFraction: textMix, of: textPrimary) ?? themed
    }

    fileprivate static func derivedTableHeaderBackground(
        base: NSColor,
        codeBackground: NSColor,
        scheme: ColorScheme
    ) -> NSColor {
        let blendFraction: CGFloat = scheme == .dark ? 0.28 : 0.12
        return base.blended(withFraction: blendFraction, of: codeBackground) ?? base
    }

    fileprivate static func derivedTableRowBackground(
        base: NSColor,
        inlineCodeBackground: NSColor,
        scheme: ColorScheme
    ) -> NSColor {
        let blendFraction: CGFloat = scheme == .dark ? 0.10 : 0.06
        return base.blended(withFraction: blendFraction, of: inlineCodeBackground) ?? base
    }

    fileprivate static func derivedTableBorder(
        base: NSColor,
        accent: NSColor,
        theme: AppTheme,
        scheme: ColorScheme
    ) -> NSColor {
        let accentForwardThemes: Set<AppTheme> = [
            .dracula, .monokai, .onedark, .tokyonight, .nord, .gruvbox, .solarized,
        ]
        var accentBlend: CGFloat = accentForwardThemes.contains(theme) ? 0.18 : 0.08
        if scheme == .dark {
            accentBlend += 0.05
        }
        return base.blended(withFraction: accentBlend, of: accent) ?? base
    }

    fileprivate static func derivedLinkUnderline(
        link: NSColor,
        textPrimary: NSColor,
        scheme: ColorScheme
    ) -> NSColor {
        let underlineBlend: CGFloat = scheme == .dark ? 0.22 : 0.12
        return link.blended(withFraction: underlineBlend, of: textPrimary) ?? link
    }

    /// Returns a hierarchy-aware heading color derived from theme tokens.
    func formattedHeadingColor(level: Int) -> NSColor {
        switch level {
        case 1: return formattedHeading1
        case 2: return formattedHeading2
        case 3: return formattedHeading3
        default: return formattedHeading
        }
    }

    func formattedTableHeaderBackground() -> NSColor {
        formattedTableHeaderSurface
    }

    func formattedTableRowBackground() -> NSColor {
        formattedTableRowSurface
    }

    func formattedTableBorder() -> NSColor {
        formattedTableBorderStroke
    }

    func formattedLinkUnderlineColor() -> NSColor {
        formattedLinkUnderline
    }

    /// Opacity multiplier applied to the border color when drawing interior column
    /// dividers. Tuned per theme so minimal/light themes stay subtle and vivid dark
    /// themes retain enough contrast to be legible.
    func tableColumnDividerOpacityMultiplier() -> CGFloat {
        // Base multiplier by theme character
        let base: CGFloat
        switch theme {
        case .basic, .github, .docC:
            // Minimal / system-integrated — column guides should barely register
            base = 0.35

        case .solarized, .gruvbox:
            // Warm-toned retro palettes — moderate presence
            base = 0.40

        case .dracula, .monokai, .onedark, .tokyonight, .nord:
            // Vivid dark-first themes — borders carry more visual weight
            base = 0.55
        }

        // Dark mode adds a small lift so dividers remain visible against dark surfaces
        let darkBoost: CGFloat = scheme == .dark ? 0.08 : 0.0
        return min(1.0, base + darkBoost)
    }
}
