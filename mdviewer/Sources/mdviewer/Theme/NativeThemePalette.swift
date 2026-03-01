//
//  NativeThemePalette.swift
//  mdviewer
//

internal import AppKit
internal import SwiftUI

// MARK: - Native Theme Palette

/// Color palette for rendering Markdown in the native NSTextView.
/// Each property maps to a semantic role; concrete values are provided
/// per-theme in `ThemeDefinitions.swift`.
struct NativeThemePalette {
    // MARK: - Text Colors
    let textPrimary: NSColor
    let textSecondary: NSColor
    let textTertiary: NSColor

    // MARK: - Interactive Colors
    let link: NSColor
    let linkHover: NSColor
    let accent: NSColor

    // MARK: - Heading Colors
    let heading: NSColor
    let heading1: NSColor
    let heading2: NSColor
    let heading3: NSColor

    // MARK: - Code Colors
    let codeBackground: NSColor
    let codeBorder: NSColor
    let inlineCodeBackground: NSColor
    let codeText: NSColor

    // MARK: - Blockquote Colors
    let blockquoteAccent: NSColor
    let blockquoteBackground: NSColor
    let blockquoteText: NSColor

    // MARK: - Table Colors
    let tableHeaderBackground: NSColor
    let tableBorder: NSColor
    let tableRowAlternating: NSColor

    // MARK: - List Colors
    let listMarker: NSColor
    let taskListUnchecked: NSColor
    let taskListChecked: NSColor

    // MARK: - Rule Color
    let horizontalRule: NSColor

    // MARK: - Selection Color
    let selectionBackground: NSColor
    let selectionText: NSColor

    // MARK: - Helpers

    /// Creates a color in the Display P3 color space for consistent rendering across devices.
    /// Falls back to sRGB on older displays automatically.
    static func p3Color(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> NSColor {
        NSColor(displayP3Red: r, green: g, blue: b, alpha: a)
    }
}
