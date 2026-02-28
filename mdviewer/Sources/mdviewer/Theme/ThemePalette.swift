//
//  ThemePalette.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Theme Protocol

/// Protocol defining a color theme for Markdown rendering.
///
/// Implementations provide semantic color values for different text elements.
protocol ThemePalette {
    /// Primary text color for body content
    var textPrimary: NSColor { get }

    /// Secondary text color for muted content
    var textSecondary: NSColor { get }

    /// Color for hyperlinks
    var link: NSColor { get }

    /// Color for headings
    var heading: NSColor { get }

    /// Background color for code blocks
    var codeBackground: NSColor { get }

    /// Border color for code blocks
    var codeBorder: NSColor { get }

    /// Accent color for blockquote left border
    var blockquoteAccent: NSColor { get }

    /// Background color for blockquotes
    var blockquoteBackground: NSColor { get }

    /// Background color for inline code
    var inlineCodeBackground: NSColor { get }
}
