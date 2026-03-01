//
//  MarkdownParser.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - Markdown Parser

    /// Parses Markdown text using the system's NSAttributedString parser with enhancements.
    ///
    /// This implementation uses the EnhancedMarkdownParser for improved support of:
    /// - Tables (GFM format)
    /// - Task lists (checkbox items)
    /// - Proper line break handling
    ///
    /// ## Architecture
    /// Part of the rendering pipeline:
    /// 1. MarkdownParser (this component) → NSAttributedString with PresentationIntent
    /// 2. BlockSeparatorInjector → Mark block boundaries
    /// 3. TypographyApplier → Apply fonts, colors, spacing
    /// 4. SyntaxHighlighter → Apply syntax coloring
    struct MarkdownParser: MarkdownParsing {
        private let enhancedParser = EnhancedMarkdownParser()

        func parse(_ markdown: String) throws -> NSAttributedString {
            try enhancedParser.parse(markdown)
        }
    }

#endif
