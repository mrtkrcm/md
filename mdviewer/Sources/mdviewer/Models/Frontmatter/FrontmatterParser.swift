//
//  FrontmatterParser.swift
//  mdviewer
//
//  Parser for YAML frontmatter in markdown documents.
//

internal import Foundation

/// Parses YAML frontmatter from markdown documents.
enum FrontmatterParser {
    /// Parses frontmatter from markdown text.
    ///
    /// - Parameter markdown: The markdown text to parse.
    /// - Returns: A `ParsedMarkdown` containing the body and any frontmatter.
    static func parse(_ markdown: String) -> ParsedMarkdown {
        let normalized = stripLeadingUTF8BOM(from: markdown)
        let working = stripLeadingBlankLines(from: normalized)

        guard working.hasPrefix("---") else {
            return ParsedMarkdown(source: markdown, renderedMarkdown: markdown, frontmatter: nil)
        }

        let nsRange = NSRange(working.startIndex ..< working.endIndex, in: working)
        guard let match = openingPattern.firstMatch(in: working, options: [], range: nsRange) else {
            return ParsedMarkdown(source: markdown, renderedMarkdown: markdown, frontmatter: nil)
        }

        guard
            let fullRange = Range(match.range(at: 0), in: working),
            let yamlRange = Range(match.range(at: 1), in: working)
        else {
            return ParsedMarkdown(source: markdown, renderedMarkdown: markdown, frontmatter: nil)
        }

        let yaml = String(working[yamlRange])
        let body = sanitizeRenderedMarkdown(String(working[fullRange.upperBound...]))
        let entries = parseEntries(from: yaml)
        let metadata = Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0.value) })
        let frontmatter = Frontmatter(rawYAML: yaml, entries: entries, metadata: metadata)
        return ParsedMarkdown(source: markdown, renderedMarkdown: body, frontmatter: frontmatter)
    }

    // MARK: - Private Helpers

    private static func stripLeadingUTF8BOM(from markdown: String) -> String {
        guard markdown.unicodeScalars.first?.value == 0xFEFF else { return markdown }
        return String(markdown.unicodeScalars.dropFirst())
    }

    private static func stripLeadingBlankLines(from markdown: String) -> String {
        var index = markdown.startIndex
        while index < markdown.endIndex {
            let ch = markdown[index]
            if ch == "\n" || ch == "\r" {
                index = markdown.index(after: index)
                continue
            }
            break
        }
        return String(markdown[index...])
    }

    /// Sanitizes markdown by removing HTML comments outside code fences.
    private static func sanitizeRenderedMarkdown(_ markdown: String) -> String {
        var sanitizedLines: [String] = []
        sanitizedLines.reserveCapacity(64)

        var inFence = false
        var inHTMLComment = false

        for rawLine in markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)

            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                if !inHTMLComment {
                    inFence.toggle()
                    sanitizedLines.append(line)
                }
                continue
            }

            if inFence {
                sanitizedLines.append(line)
                continue
            }

            if inHTMLComment {
                if trimmed.contains("-->") {
                    inHTMLComment = false
                }
                continue
            }

            if trimmed.hasPrefix("<!--") {
                if !trimmed.contains("-->") {
                    inHTMLComment = true
                }
                continue
            }

            sanitizedLines.append(line)
        }

        return sanitizedLines.joined(separator: "\n")
    }

    private static let openingPattern: NSRegularExpression = {
        // Supports YAML frontmatter bounded by --- ... --- or --- ... ...
        let pattern = #"(?s)\A---[ \t]*\r?\n(.*?)\r?\n(?:---|\.{3})[ \t]*(?:\r?\n|\z)"#
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            fatalError("Invalid frontmatter regex: \(error)")
        }
    }()

    /// Parses YAML entries, handling simple key-value pairs and list items.
    private static func parseEntries(from yaml: String) -> [Frontmatter.Entry] {
        var orderedKeys: [String] = []
        var valuesByKey: [String: String] = [:]

        var activeListKey: String?
        var activeListItems: [String] = []
        var lastAssignedKey: String?

        func closeActiveListIfNeeded() {
            guard let key = activeListKey else { return }
            valuesByKey[key] = activeListItems.joined(separator: ", ")
            activeListKey = nil
            activeListItems.removeAll(keepingCapacity: true)
        }

        for rawLine in yaml.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            if let separator = trimmed.firstIndex(of: ":") {
                let keyPart = trimmed[..<separator].trimmingCharacters(in: CharacterSet.whitespaces)
                let valueStart = trimmed.index(after: separator)
                let valuePart = trimmed[valueStart...].trimmingCharacters(in: CharacterSet.whitespaces)
                if !keyPart.isEmpty {
                    closeActiveListIfNeeded()
                    let key = String(keyPart)
                    if !orderedKeys.contains(key) {
                        orderedKeys.append(key)
                    }

                    if valuePart.isEmpty {
                        activeListKey = key
                        valuesByKey[key] = ""
                    } else {
                        valuesByKey[key] = trimmedWrappingQuotes(from: String(valuePart))
                    }
                    lastAssignedKey = key
                    continue
                }
            }

            if let key = activeListKey {
                if trimmed.hasPrefix("-") {
                    let item = trimmed.drop(while: { $0 == "-" || $0 == " " })
                    let normalized = trimmedWrappingQuotes(from: String(item))
                    if !normalized.isEmpty {
                        activeListItems.append(normalized)
                    }
                } else {
                    let previous = valuesByKey[key] ?? ""
                    let combined = previous.isEmpty ? trimmed : "\(previous) \(trimmed)"
                    valuesByKey[key] = combined
                }
            } else if line.first?.isWhitespace == true, let key = lastAssignedKey {
                let previous = valuesByKey[key] ?? ""
                let normalized = trimmedWrappingQuotes(from: trimmed)
                guard !normalized.isEmpty else { continue }
                let combined = previous.isEmpty ? normalized : "\(previous) \(normalized)"
                valuesByKey[key] = combined
            }
        }

        closeActiveListIfNeeded()

        return orderedKeys.compactMap { key in
            guard let value = valuesByKey[key] else { return nil }
            return Frontmatter.Entry(key: key, value: value)
        }
    }

    private static func trimmedWrappingQuotes(from value: String) -> String {
        guard value.count >= 2 else { return value }
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}
