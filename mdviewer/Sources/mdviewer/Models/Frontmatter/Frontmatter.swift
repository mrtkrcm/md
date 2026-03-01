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
    /// The type of value for a frontmatter entry.
    enum ValueType: Equatable, Sendable {
        case text(String)
        case url(URL)
        case date(Date)
        case list([String])
        case boolean(Bool)
        case number(Double)
    }

    /// A single key-value entry in the frontmatter.
    struct Entry: Equatable, Sendable {
        let key: String
        let rawValue: String
        let typedValue: ValueType

        /// Returns the display string for the entry value.
        var displayValue: String {
            switch typedValue {
            case .text(let text):
                return text

            case .url(let url):
                return url.absoluteString

            case .date(let date):
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: date)

            case .list(let items):
                return items.joined(separator: ", ")

            case .boolean(let bool):
                return bool ? "Yes" : "No"

            case .number(let number):
                if number == floor(number) {
                    return String(format: "%.0f", number)
                }
                return String(number)
            }
        }

        /// Returns a formatted display name for the key.
        var displayKey: String {
            key
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }

        /// Returns true if this entry contains a URL.
        var isURL: Bool {
            if case .url = typedValue { return true }
            return false
        }

        /// Returns the URL if this entry is a URL type.
        var urlValue: URL? {
            if case .url(let url) = typedValue { return url }
            return nil
        }

        /// Returns true if this entry is a list.
        var isList: Bool {
            if case .list = typedValue { return true }
            return false
        }

        /// Returns list items if this entry is a list type.
        var listItems: [String]? {
            if case .list(let items) = typedValue { return items }
            return nil
        }
    }

    /// Raw YAML content between the --- delimiters.
    let rawYAML: String
    /// Ordered array of key-value entries.
    let entries: [Entry]
    /// Dictionary of metadata for quick lookups.
    let metadata: [String: String]
}
