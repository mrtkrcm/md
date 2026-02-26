//
//  MarkdownParser.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - Markdown Parser

    /// Parses Markdown text using the system's NSAttributedString parser.
    ///
    /// This implementation uses macOS's built-in Markdown parsing capabilities
    /// for standards-compliant CommonMark + GFM parsing with native NSAttributedString output.
    ///
    /// ## Architecture
    /// Part of the rendering pipeline:
    /// 1. MarkdownParser (this component) → NSAttributedString with PresentationIntent
    /// 2. BlockSeparatorInjector → Mark block boundaries
    /// 3. TypographyApplier → Apply fonts, colors, spacing
    /// 4. SyntaxHighlighter → Apply syntax coloring
    ///
    /// ## Future Enhancement
    /// For advanced markdown processing (tables, custom rendering, AST manipulation),
    /// consider swift-markdown based implementation. See:
    /// - `PARSER_ARCHITECTURE.md` - Detailed design and extension points
    /// - `PARSER_EVALUATION.md` - Library comparison and roadmap
    /// - `SwiftMarkdownRenderer.swift` - Placeholder for future implementation
    ///
    /// The built-in parser is stable and performant for current needs.
    /// Migration path exists for when advanced features become necessary.
    ///
    /// ## Compatibility Notes
    /// - Down library: NOT viable (Swift 6 incompatible, fatal NSAttributedString errors)
    /// - CocoaMarkdown: Legacy, unmaintained
    /// - swift-markdown: Recommended future choice if extensibility needed
    struct MarkdownParser: MarkdownParsing {
        func parse(_ markdown: String) throws -> NSAttributedString {
            guard !markdown.isEmpty else {
                return NSAttributedString()
            }

            do {
                return try NSAttributedString(
                    markdown: markdown,
                    baseURL: nil
                )
            } catch {
                throw MarkdownParsingError.parsingFailed(underlying: error)
            }
        }
    }

#endif
