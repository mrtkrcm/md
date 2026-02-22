//
//  Frontmatter.swift
//  mdviewer
//
//  Data structures for YAML frontmatter in markdown documents.
//

internal import Foundation

/// A markdown document parsed into its frontmatter and body components.
struct ParsedMarkdown: Equatable, Sendable {
    /// Original source text.
    let source: String
    /// Markdown content with frontmatter stripped.
    let renderedMarkdown: String
    /// Parsed frontmatter, if present.
    let frontmatter: Frontmatter?
}

/// YAML frontmatter extracted from a markdown document.
struct Frontmatter: Equatable, Sendable {
    /// A single key-value entry in the frontmatter.
    struct Entry: Equatable, Sendable {
        let key: String
        let value: String
    }

    /// Raw YAML content between the --- delimiters.
    let rawYAML: String
    /// Ordered array of key-value entries.
    let entries: [Entry]
    /// Dictionary of metadata for quick lookups.
    let metadata: [String: String]
}
