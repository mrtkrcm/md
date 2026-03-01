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
    }
}
