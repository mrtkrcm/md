//
//  ThemeData.swift
//  mdviewer
//

internal import AppKit

// MARK: - Color Helper

/// Creates a color in the Display P3 color space using NativeThemePalette's helper
private func p3Color(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> NSColor {
    NativeThemePalette.p3Color(r: r, g: g, b: b, a: a)
}

// MARK: - Theme Color Data Structure

/// Raw color data for a single theme variant
struct ThemeColorData {
    let textPrimary: NSColor
    let textSecondary: NSColor
    let textTertiary: NSColor
    let link: NSColor
    let linkHover: NSColor
    let accent: NSColor
    let heading: NSColor
    let codeBackground: NSColor
    let codeBorder: NSColor
    let inlineCodeBackground: NSColor
    let codeText: NSColor
    let blockquoteAccent: NSColor
    let blockquoteBackground: NSColor
    let blockquoteText: NSColor
    let tableHeaderBackground: NSColor
    let tableBorder: NSColor
    let tableRowAlternating: NSColor
    let listMarker: NSColor
    let taskListUnchecked: NSColor
    let taskListChecked: NSColor
    let horizontalRule: NSColor
    let selectionBackground: NSColor
    let selectionText: NSColor
}

/// Complete theme data with both light and dark variants
struct ThemeData {
    let name: String
    let light: ThemeColorData
    let dark: ThemeColorData
}

// MARK: - Theme Registry

/// Registry of all available themes with their color data
enum ThemeRegistry {
    // MARK: - Apple Ecosystem Themes

    static let basic = ThemeData(
        name: "Basic",
        light: ThemeColorData(
            textPrimary: .labelColor,
            textSecondary: .secondaryLabelColor,
            textTertiary: .tertiaryLabelColor,
            link: .linkColor,
            linkHover: .linkColor,
            accent: .linkColor,
            heading: .labelColor,
            codeBackground: p3Color(r: 0.95, g: 0.95, b: 0.95),
            codeBorder: p3Color(r: 0.88, g: 0.88, b: 0.88),
            inlineCodeBackground: p3Color(r: 0.55, g: 0.55, b: 0.55, a: 0.08),
            codeText: .secondaryLabelColor,
            blockquoteAccent: p3Color(r: 0.55, g: 0.55, b: 0.55),
            blockquoteBackground: p3Color(r: 0.00, g: 0.00, b: 0.00, a: 0.04),
            blockquoteText: .secondaryLabelColor,
            tableHeaderBackground: p3Color(r: 0.94, g: 0.94, b: 0.96),
            tableBorder: p3Color(r: 0.88, g: 0.88, b: 0.90),
            tableRowAlternating: p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02),
            listMarker: .linkColor,
            taskListUnchecked: .secondaryLabelColor,
            taskListChecked: p3Color(r: 0.2, g: 0.6, b: 0.3),
            horizontalRule: p3Color(r: 0.85, g: 0.85, b: 0.88),
            selectionBackground: p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25),
            selectionText: .black
        ),
        dark: ThemeColorData(
            textPrimary: .labelColor,
            textSecondary: .secondaryLabelColor,
            textTertiary: .tertiaryLabelColor,
            link: .linkColor,
            linkHover: .linkColor,
            accent: .linkColor,
            heading: .labelColor,
            codeBackground: p3Color(r: 0.20, g: 0.20, b: 0.20),
            codeBorder: p3Color(r: 0.30, g: 0.30, b: 0.30),
            inlineCodeBackground: p3Color(r: 0.45, g: 0.45, b: 0.45, a: 0.08),
            codeText: .secondaryLabelColor,
            blockquoteAccent: p3Color(r: 0.45, g: 0.45, b: 0.45),
            blockquoteBackground: p3Color(r: 1.00, g: 1.00, b: 1.00, a: 0.05),
            blockquoteText: .secondaryLabelColor,
            tableHeaderBackground: p3Color(r: 0.25, g: 0.25, b: 0.27),
            tableBorder: p3Color(r: 0.35, g: 0.35, b: 0.38),
            tableRowAlternating: p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03),
            listMarker: .linkColor,
            taskListUnchecked: .secondaryLabelColor,
            taskListChecked: p3Color(r: 0.3, g: 0.7, b: 0.4),
            horizontalRule: p3Color(r: 0.35, g: 0.35, b: 0.38),
            selectionBackground: p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4),
            selectionText: .white
        )
    )

    static let github = ThemeData(
        name: "GitHub",
        light: ThemeColorData(
            textPrimary: p3Color(r: 0.14, g: 0.16, b: 0.20),
            textSecondary: p3Color(r: 0.40, g: 0.42, b: 0.46),
            textTertiary: p3Color(r: 0.40, g: 0.42, b: 0.46, a: 0.7),
            link: p3Color(r: 0.10, g: 0.46, b: 0.82),
            linkHover: p3Color(r: 0.10, g: 0.46, b: 0.82),
            accent: p3Color(r: 0.10, g: 0.46, b: 0.82),
            heading: p3Color(r: 0.06, g: 0.08, b: 0.12),
            codeBackground: p3Color(r: 0.96, g: 0.96, b: 0.96),
            codeBorder: p3Color(r: 0.88, g: 0.88, b: 0.88),
            inlineCodeBackground: p3Color(r: 0.22, g: 0.51, b: 0.82, a: 0.08),
            codeText: p3Color(r: 0.40, g: 0.42, b: 0.46),
            blockquoteAccent: p3Color(r: 0.22, g: 0.51, b: 0.82),
            blockquoteBackground: p3Color(r: 0.22, g: 0.51, b: 0.82, a: 0.06),
            blockquoteText: p3Color(r: 0.40, g: 0.42, b: 0.46),
            tableHeaderBackground: p3Color(r: 0.94, g: 0.94, b: 0.96),
            tableBorder: p3Color(r: 0.88, g: 0.88, b: 0.90),
            tableRowAlternating: p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02),
            listMarker: p3Color(r: 0.10, g: 0.46, b: 0.82),
            taskListUnchecked: p3Color(r: 0.40, g: 0.42, b: 0.46),
            taskListChecked: p3Color(r: 0.2, g: 0.6, b: 0.3),
            horizontalRule: p3Color(r: 0.85, g: 0.85, b: 0.88),
            selectionBackground: p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25),
            selectionText: .black
        ),
        dark: ThemeColorData(
            textPrimary: p3Color(r: 0.90, g: 0.90, b: 0.90),
            textSecondary: p3Color(r: 0.60, g: 0.62, b: 0.66),
            textTertiary: p3Color(r: 0.60, g: 0.62, b: 0.66, a: 0.7),
            link: p3Color(r: 0.53, g: 0.75, b: 0.98),
            linkHover: p3Color(r: 0.53, g: 0.75, b: 0.98),
            accent: p3Color(r: 0.53, g: 0.75, b: 0.98),
            heading: p3Color(r: 0.95, g: 0.96, b: 0.98),
            codeBackground: p3Color(r: 0.17, g: 0.18, b: 0.20),
            codeBorder: p3Color(r: 0.28, g: 0.29, b: 0.32),
            inlineCodeBackground: p3Color(r: 0.35, g: 0.62, b: 0.90, a: 0.10),
            codeText: p3Color(r: 0.60, g: 0.62, b: 0.66),
            blockquoteAccent: p3Color(r: 0.35, g: 0.62, b: 0.90),
            blockquoteBackground: p3Color(r: 0.35, g: 0.62, b: 0.90, a: 0.08),
            blockquoteText: p3Color(r: 0.60, g: 0.62, b: 0.66),
            tableHeaderBackground: p3Color(r: 0.25, g: 0.25, b: 0.27),
            tableBorder: p3Color(r: 0.35, g: 0.35, b: 0.38),
            tableRowAlternating: p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03),
            listMarker: p3Color(r: 0.53, g: 0.75, b: 0.98),
            taskListUnchecked: p3Color(r: 0.60, g: 0.62, b: 0.66),
            taskListChecked: p3Color(r: 0.3, g: 0.7, b: 0.4),
            horizontalRule: p3Color(r: 0.35, g: 0.35, b: 0.38),
            selectionBackground: p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4),
            selectionText: .white
        )
    )

    static let docC = ThemeData(
        name: "DocC",
        light: ThemeColorData(
            textPrimary: p3Color(r: 0.12, g: 0.12, b: 0.14),
            textSecondary: p3Color(r: 0.38, g: 0.38, b: 0.42),
            textTertiary: p3Color(r: 0.38, g: 0.38, b: 0.42, a: 0.7),
            link: p3Color(r: 0.00, g: 0.48, b: 1.00),
            linkHover: p3Color(r: 0.00, g: 0.48, b: 1.00),
            accent: p3Color(r: 0.00, g: 0.48, b: 1.00),
            heading: p3Color(r: 0.05, g: 0.05, b: 0.08),
            codeBackground: p3Color(r: 0.95, g: 0.95, b: 0.96),
            codeBorder: p3Color(r: 0.88, g: 0.88, b: 0.90),
            inlineCodeBackground: p3Color(r: 0.00, g: 0.48, b: 1.00, a: 0.08),
            codeText: p3Color(r: 0.38, g: 0.38, b: 0.42),
            blockquoteAccent: p3Color(r: 0.00, g: 0.48, b: 1.00),
            blockquoteBackground: p3Color(r: 0.00, g: 0.48, b: 1.00, a: 0.05),
            blockquoteText: p3Color(r: 0.38, g: 0.38, b: 0.42),
            tableHeaderBackground: p3Color(r: 0.94, g: 0.94, b: 0.96),
            tableBorder: p3Color(r: 0.88, g: 0.88, b: 0.90),
            tableRowAlternating: p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02),
            listMarker: p3Color(r: 0.00, g: 0.48, b: 1.00),
            taskListUnchecked: p3Color(r: 0.38, g: 0.38, b: 0.42),
            taskListChecked: p3Color(r: 0.2, g: 0.6, b: 0.3),
            horizontalRule: p3Color(r: 0.85, g: 0.85, b: 0.88),
            selectionBackground: p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25),
            selectionText: .black
        ),
        dark: ThemeColorData(
            textPrimary: p3Color(r: 0.93, g: 0.93, b: 0.94),
            textSecondary: p3Color(r: 0.60, g: 0.60, b: 0.64),
            textTertiary: p3Color(r: 0.60, g: 0.60, b: 0.64, a: 0.7),
            link: p3Color(r: 0.25, g: 0.60, b: 1.00),
            linkHover: p3Color(r: 0.25, g: 0.60, b: 1.00),
            accent: p3Color(r: 0.25, g: 0.60, b: 1.00),
            heading: p3Color(r: 0.97, g: 0.97, b: 0.98),
            codeBackground: p3Color(r: 0.14, g: 0.15, b: 0.17),
            codeBorder: p3Color(r: 0.26, g: 0.27, b: 0.30),
            inlineCodeBackground: p3Color(r: 0.25, g: 0.60, b: 1.00, a: 0.10),
            codeText: p3Color(r: 0.60, g: 0.60, b: 0.64),
            blockquoteAccent: p3Color(r: 0.25, g: 0.60, b: 1.00),
            blockquoteBackground: p3Color(r: 0.25, g: 0.60, b: 1.00, a: 0.08),
            blockquoteText: p3Color(r: 0.60, g: 0.60, b: 0.64),
            tableHeaderBackground: p3Color(r: 0.25, g: 0.25, b: 0.27),
            tableBorder: p3Color(r: 0.35, g: 0.35, b: 0.38),
            tableRowAlternating: p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03),
            listMarker: p3Color(r: 0.25, g: 0.60, b: 1.00),
            taskListUnchecked: p3Color(r: 0.60, g: 0.60, b: 0.64),
            taskListChecked: p3Color(r: 0.3, g: 0.7, b: 0.4),
            horizontalRule: p3Color(r: 0.35, g: 0.35, b: 0.38),
            selectionBackground: p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4),
            selectionText: .white
        )
    )

    // MARK: - Third-Party Themes

    static let solarized = createTheme(
        name: "Solarized",
        lightBase: (r: 0.40, g: 0.48, b: 0.51),
        lightAccent: (r: 0.16, g: 0.63, b: 0.60),
        lightHeading: (r: 0.27, g: 0.51, b: 0.71),
        lightCodeBg: (r: 0.93, g: 0.91, b: 0.84),
        darkBase: (r: 0.83, g: 0.86, b: 0.88),
        darkAccent: (r: 0.16, g: 0.63, b: 0.60),
        darkHeading: (r: 0.35, g: 0.70, b: 0.82),
        darkCodeBg: (r: 0.01, g: 0.15, b: 0.22)
    )

    static let gruvbox = createTheme(
        name: "Gruvbox",
        lightBase: (r: 0.29, g: 0.25, b: 0.18),
        lightAccent: (r: 0.16, g: 0.53, b: 0.36),
        lightHeading: (r: 0.48, g: 0.33, b: 0.16),
        lightCodeBg: (r: 0.92, g: 0.91, b: 0.85),
        darkBase: (r: 0.92, g: 0.91, b: 0.85),
        darkAccent: (r: 0.56, g: 0.74, b: 0.27),
        darkHeading: (r: 1.00, g: 0.59, b: 0.10),
        darkCodeBg: (r: 0.16, g: 0.15, b: 0.13)
    )

    static let dracula = createTheme(
        name: "Dracula",
        lightBase: (r: 0.25, g: 0.26, b: 0.35),
        lightAccent: (r: 0.64, g: 0.48, b: 0.96),
        lightHeading: (r: 0.25, g: 0.26, b: 0.35),
        lightCodeBg: (r: 0.96, g: 0.96, b: 0.97),
        darkBase: (r: 0.97, g: 0.97, b: 0.98),
        darkAccent: (r: 0.64, g: 0.48, b: 0.96),
        darkHeading: (r: 0.97, g: 0.97, b: 0.98),
        darkCodeBg: (r: 0.28, g: 0.28, b: 0.38)
    )

    static let monokai = createTheme(
        name: "Monokai",
        lightBase: (r: 0.20, g: 0.20, b: 0.20),
        lightAccent: (r: 0.06, g: 0.47, b: 0.76),
        lightHeading: (r: 0.80, g: 0.14, b: 0.14),
        lightCodeBg: (r: 0.96, g: 0.96, b: 0.96),
        darkBase: (r: 0.97, g: 0.97, b: 0.97),
        darkAccent: (r: 0.27, g: 0.75, b: 0.98),
        darkHeading: (r: 0.98, g: 0.26, b: 0.28),
        darkCodeBg: (r: 0.27, g: 0.27, b: 0.27)
    )

    static let nord = createTheme(
        name: "Nord",
        lightBase: (r: 0.29, g: 0.32, b: 0.38),
        lightAccent: (r: 0.36, g: 0.63, b: 0.78),
        lightHeading: (r: 0.29, g: 0.32, b: 0.38),
        lightCodeBg: (r: 0.94, g: 0.95, b: 0.96),
        darkBase: (r: 0.92, g: 0.93, b: 0.95),
        darkAccent: (r: 0.51, g: 0.81, b: 0.92),
        darkHeading: (r: 0.92, g: 0.93, b: 0.95),
        darkCodeBg: (r: 0.19, g: 0.21, b: 0.26)
    )

    static let onedark = createTheme(
        name: "One Dark",
        lightBase: (r: 0.25, g: 0.25, b: 0.27),
        lightAccent: (r: 0.09, g: 0.53, b: 0.81),
        lightHeading: (r: 0.56, g: 0.30, b: 0.00),
        lightCodeBg: (r: 0.96, g: 0.96, b: 0.97),
        darkBase: (r: 0.97, g: 0.97, b: 0.98),
        darkAccent: (r: 0.40, g: 0.67, b: 0.98),
        darkHeading: (r: 0.99, g: 0.61, b: 0.19),
        darkCodeBg: (r: 0.21, g: 0.21, b: 0.23)
    )

    static let tokyonight = createTheme(
        name: "Tokyo Night",
        lightBase: (r: 0.22, g: 0.21, b: 0.30),
        lightAccent: (r: 0.00, g: 0.46, b: 0.84),
        lightHeading: (r: 0.63, g: 0.32, b: 0.25),
        lightCodeBg: (r: 0.96, g: 0.96, b: 0.97),
        darkBase: (r: 0.96, g: 0.96, b: 0.98),
        darkAccent: (r: 0.41, g: 0.75, b: 0.98),
        darkHeading: (r: 0.98, g: 0.40, b: 0.38),
        darkCodeBg: (r: 0.16, g: 0.16, b: 0.22)
    )

    // MARK: - Helper Functions

    /// Creates a theme with consistent color relationships
    private static func createTheme(
        name: String,
        lightBase: (r: CGFloat, g: CGFloat, b: CGFloat),
        lightAccent: (r: CGFloat, g: CGFloat, b: CGFloat),
        lightHeading: (r: CGFloat, g: CGFloat, b: CGFloat),
        lightCodeBg: (r: CGFloat, g: CGFloat, b: CGFloat),
        darkBase: (r: CGFloat, g: CGFloat, b: CGFloat),
        darkAccent: (r: CGFloat, g: CGFloat, b: CGFloat),
        darkHeading: (r: CGFloat, g: CGFloat, b: CGFloat),
        darkCodeBg: (r: CGFloat, g: CGFloat, b: CGFloat)
    ) -> ThemeData {
        let light = ThemeColorData(
            textPrimary: p3Color(r: lightBase.r, g: lightBase.g, b: lightBase.b),
            textSecondary: p3Color(r: lightBase.r + 0.2, g: lightBase.g + 0.2, b: lightBase.b + 0.2),
            textTertiary: p3Color(r: lightBase.r + 0.2, g: lightBase.g + 0.2, b: lightBase.b + 0.2, a: 0.7),
            link: p3Color(r: lightAccent.r, g: lightAccent.g, b: lightAccent.b),
            linkHover: p3Color(r: lightAccent.r, g: lightAccent.g, b: lightAccent.b),
            accent: p3Color(r: lightAccent.r, g: lightAccent.g, b: lightAccent.b),
            heading: p3Color(r: lightHeading.r, g: lightHeading.g, b: lightHeading.b),
            codeBackground: p3Color(r: lightCodeBg.r, g: lightCodeBg.g, b: lightCodeBg.b),
            codeBorder: p3Color(r: lightCodeBg.r - 0.08, g: lightCodeBg.g - 0.08, b: lightCodeBg.b - 0.08),
            inlineCodeBackground: p3Color(r: lightAccent.r, g: lightAccent.g, b: lightAccent.b, a: 0.08),
            codeText: p3Color(r: lightBase.r + 0.2, g: lightBase.g + 0.2, b: lightBase.b + 0.2),
            blockquoteAccent: p3Color(r: lightAccent.r, g: lightAccent.g, b: lightAccent.b),
            blockquoteBackground: p3Color(r: lightAccent.r, g: lightAccent.g, b: lightAccent.b, a: 0.06),
            blockquoteText: p3Color(r: lightBase.r + 0.2, g: lightBase.g + 0.2, b: lightBase.b + 0.2),
            tableHeaderBackground: p3Color(r: 0.94, g: 0.94, b: 0.96),
            tableBorder: p3Color(r: 0.88, g: 0.88, b: 0.90),
            tableRowAlternating: p3Color(r: 0.0, g: 0.0, b: 0.0, a: 0.02),
            listMarker: p3Color(r: lightAccent.r, g: lightAccent.g, b: lightAccent.b),
            taskListUnchecked: p3Color(r: lightBase.r + 0.2, g: lightBase.g + 0.2, b: lightBase.b + 0.2),
            taskListChecked: p3Color(r: 0.2, g: 0.6, b: 0.3),
            horizontalRule: p3Color(r: 0.85, g: 0.85, b: 0.88),
            selectionBackground: p3Color(r: 0.20, g: 0.50, b: 0.90, a: 0.25),
            selectionText: .black
        )

        let dark = ThemeColorData(
            textPrimary: p3Color(r: darkBase.r, g: darkBase.g, b: darkBase.b),
            textSecondary: p3Color(r: darkBase.r - 0.2, g: darkBase.g - 0.2, b: darkBase.b - 0.2),
            textTertiary: p3Color(r: darkBase.r - 0.2, g: darkBase.g - 0.2, b: darkBase.b - 0.2, a: 0.7),
            link: p3Color(r: darkAccent.r, g: darkAccent.g, b: darkAccent.b),
            linkHover: p3Color(r: darkAccent.r, g: darkAccent.g, b: darkAccent.b),
            accent: p3Color(r: darkAccent.r, g: darkAccent.g, b: darkAccent.b),
            heading: p3Color(r: darkHeading.r, g: darkHeading.g, b: darkHeading.b),
            codeBackground: p3Color(r: darkCodeBg.r, g: darkCodeBg.g, b: darkCodeBg.b),
            codeBorder: p3Color(r: darkCodeBg.r + 0.12, g: darkCodeBg.g + 0.12, b: darkCodeBg.b + 0.12),
            inlineCodeBackground: p3Color(r: darkAccent.r, g: darkAccent.g, b: darkAccent.b, a: 0.10),
            codeText: p3Color(r: darkBase.r - 0.2, g: darkBase.g - 0.2, b: darkBase.b - 0.2),
            blockquoteAccent: p3Color(r: darkAccent.r, g: darkAccent.g, b: darkAccent.b),
            blockquoteBackground: p3Color(r: darkAccent.r, g: darkAccent.g, b: darkAccent.b, a: 0.08),
            blockquoteText: p3Color(r: darkBase.r - 0.2, g: darkBase.g - 0.2, b: darkBase.b - 0.2),
            tableHeaderBackground: p3Color(r: 0.25, g: 0.25, b: 0.27),
            tableBorder: p3Color(r: 0.35, g: 0.35, b: 0.38),
            tableRowAlternating: p3Color(r: 1.0, g: 1.0, b: 1.0, a: 0.03),
            listMarker: p3Color(r: darkAccent.r, g: darkAccent.g, b: darkAccent.b),
            taskListUnchecked: p3Color(r: darkBase.r - 0.2, g: darkBase.g - 0.2, b: darkBase.b - 0.2),
            taskListChecked: p3Color(r: 0.3, g: 0.7, b: 0.4),
            horizontalRule: p3Color(r: 0.35, g: 0.35, b: 0.38),
            selectionBackground: p3Color(r: 0.25, g: 0.50, b: 0.90, a: 0.4),
            selectionText: .white
        )

        return ThemeData(name: name, light: light, dark: dark)
    }

    /// All available themes
    static let allThemes: [ThemeData] = [
        basic, github, docC, solarized, gruvbox, dracula, monokai, nord, onedark, tokyonight,
    ]
}
