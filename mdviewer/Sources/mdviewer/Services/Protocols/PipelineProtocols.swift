//
//  PipelineProtocols.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Syntax Highlighting Protocol

/// Protocol for syntax highlighting implementations.
///
/// Implementations apply language-specific syntax highlighting to code blocks
/// within attributed strings.
protocol SyntaxHighlighting {
    /// Applies syntax highlighting to a range of text.
    ///
    /// - Parameters:
    ///   - text: The attributed string to modify
    ///   - range: The character range to highlight
    ///   - syntax: The syntax style defining colors
    func highlight(_ text: NSMutableAttributedString, in range: NSRange, syntax: NativeSyntaxStyle)
}

// MARK: - Markdown Parsing Protocol

/// Protocol for Markdown parsing implementations.
///
/// Implementations convert raw Markdown strings into attributed strings
/// using system or custom parsers.
protocol MarkdownParsing {
    /// Parses a Markdown string into an attributed string.
    ///
    /// - Parameter markdown: The raw Markdown content
    /// - Returns: An attributed string with parsed Markdown
    /// - Throws: MarkdownParsingError if parsing fails
    func parse(_ markdown: String) throws -> NSAttributedString
}

// MARK: - Typography Applying Protocol

/// Protocol for typography application.
///
/// Implementations apply font, spacing, and color styling to parsed Markdown.
protocol TypographyApplying: Sendable {
    /// Applies typography styling to text.
    ///
    /// - Parameters:
    ///   - text: The attributed string to modify
    ///   - request: The render request containing typography preferences
    func applyTypography(to text: NSMutableAttributedString, request: RenderRequest)
}

// MARK: - Block Processing Protocols

/// Protocol for injecting visual separators between block-level elements.
protocol BlockSeparatorInjecting {
    /// Injects separator attributes between block elements.
    ///
    /// - Parameter text: The attributed string to modify
    func injectSeparators(into text: NSMutableAttributedString)
}

/// Protocol for injecting list item markers.
protocol ListMarkerInjecting {
    /// Injects visual markers for list items.
    ///
    /// - Parameter text: The attributed string to modify
    func injectMarkers(into text: NSMutableAttributedString)
}
