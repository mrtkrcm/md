internal import Foundation
#if os(macOS)
internal import AppKit
#endif

// MARK: - Markdown Rendering Protocol

/// Protocol defining the interface for Markdown rendering services.
///
/// Implementations provide thread-safe, cached rendering of Markdown content
/// with support for themes, typography, and syntax highlighting.
///
/// ## Concurrency
/// All methods are actor-isolated and safe to call from any context.
///
/// ## Usage
/// ```swift
/// let renderer: MarkdownRendering = MarkdownRenderService.shared
/// let rendered = await renderer.render(request)
/// ```
protocol MarkdownRendering: Actor {
    /// Renders a Markdown document according to the provided request.
    ///
    /// - Parameter request: The render request containing markdown content and styling options
    /// - Returns: A rendered markdown result with attributed string
    func render(_ request: RenderRequest) -> RenderedMarkdown

    /// Returns current cache statistics for monitoring performance.
    ///
    /// - Returns: Statistics including cache hits, misses, and entry count
    func snapshotStats() -> MarkdownRenderService.Stats
}

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
protocol TypographyApplying {
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

// MARK: - Rendering Errors

/// Errors that can occur during Markdown rendering.
enum MarkdownRenderError: Error, LocalizedError {
    case parsingFailed(underlying: Error)
    case emptyResult
    case invalidConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .parsingFailed(let error):
            return "Failed to parse Markdown: \(error.localizedDescription)"
        case .emptyResult:
            return "Rendering produced empty output"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}

/// Errors that can occur during Markdown parsing.
enum MarkdownParsingError: Error, LocalizedError {
    case invalidInput
    case systemParserUnavailable
    case parsingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid Markdown input"
        case .systemParserUnavailable:
            return "System Markdown parser is unavailable"
        case .parsingFailed(let error):
            return "Parsing failed: \(error.localizedDescription)"
        }
    }
}
