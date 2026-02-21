internal import AppKit
internal import SwiftUI

// MARK: - Native Theme Palette

/// Color palette for rendering Markdown in the native NSTextView.
/// Each property maps to a semantic role; concrete values are provided
/// per-theme in `ThemeDefinitions.swift`.
struct NativeThemePalette {
    let textPrimary: NSColor
    let textSecondary: NSColor
    let link: NSColor
    let heading: NSColor
    let codeBackground: NSColor
    let codeBorder: NSColor
    let blockquoteAccent: NSColor
    let blockquoteBackground: NSColor
    let inlineCodeBackground: NSColor

    // MARK: - Helpers

    /// Creates a color in the Display P3 color space for consistent rendering across devices.
    /// Falls back to sRGB on older displays automatically.
    static func p3Color(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> NSColor {
        NSColor(displayP3Red: r, green: g, blue: b, alpha: a)
    }
}
