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
    /// with configurable options for block and inline rendering.
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
