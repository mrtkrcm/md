//
//  NativeThemePalette.swift
//  mdviewer
//

internal import AppKit
internal import SwiftUI

// MARK: - Palette Cache

/// Thread-safe cache for theme palettes using dispatch queue for synchronization.
/// Palettes are immutable value types keyed by (theme, colorScheme).
private final class PaletteCache: @unchecked Sendable {
    static let shared = PaletteCache()
    private var cache: [String: NativeThemePalette] = [:]
    private let queue = DispatchQueue(label: "com.mdviewer.paletteCache", attributes: .concurrent)

    func palette(for theme: AppTheme, scheme: ColorScheme) -> NativeThemePalette {
        let key = "\(theme.rawValue)_\(scheme)"

        // Fast path: concurrent read
        if let cached = queue.sync(execute: { cache[key] }) {
            return cached
        }

        // Slow path: create with barrier write
        let palette = NativeThemePalette(theme: theme, scheme: scheme)
        queue.async(flags: .barrier) { [weak self] in
            self?.cache[key] = palette
        }
        return palette
    }

    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
        }
    }
}

// MARK: - Native Theme Palette

/// Color palette for rendering Markdown in the native NSTextView.
/// Each property maps to a semantic role; concrete values are provided
/// per-theme in `ThemeDefinitions.swift`.
struct NativeThemePalette {
    // MARK: - Theme Context

    let theme: AppTheme
    let scheme: ColorScheme

    // MARK: - Cached Factory

    /// Returns a cached palette for the given theme and scheme.
    /// Uses a thread-safe cache to avoid recreating palettes on every render.
    static func cached(theme: AppTheme, scheme: ColorScheme) -> NativeThemePalette {
        PaletteCache.shared.palette(for: theme, scheme: scheme)
    }

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
    var heading1: NSColor
    var heading2: NSColor
    var heading3: NSColor

    // MARK: - Code Colors

    let codeBackground: NSColor
    let codeBorder: NSColor
    let inlineCodeBackground: NSColor
    let codeText: NSColor

    // MARK: - Blockquote Colors

    var blockquoteAccent: NSColor
    var blockquoteBackground: NSColor
    var blockquoteText: NSColor

    // MARK: - Table Colors

    var tableHeaderBackground: NSColor
    var tableBorder: NSColor
    var tableRowAlternating: NSColor

    // MARK: - List Colors

    let listMarker: NSColor
    let taskListUnchecked: NSColor
    let taskListChecked: NSColor

    // MARK: - Rule Color

    let horizontalRule: NSColor

    // MARK: - Selection Color

    let selectionBackground: NSColor
    let selectionText: NSColor

    // MARK: - Derived Formatting Tokens

    var formattedHeading: NSColor
    var formattedHeading1: NSColor
    var formattedHeading2: NSColor
    var formattedHeading3: NSColor
    var formattedTableHeaderSurface: NSColor
    var formattedTableHeaderText: NSColor
    var formattedTableBodySurface: NSColor
    var formattedTableRowSurface: NSColor
    var formattedTableBorderStroke: NSColor
    var formattedLinkUnderline: NSColor

    // MARK: - Helpers

    /// Creates a color in the Display P3 color space for consistent rendering across devices.
    /// Falls back to sRGB on older displays automatically.
    static func p3Color(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> NSColor {
        NSColor(displayP3Red: r, green: g, blue: b, alpha: a)
    }
}
