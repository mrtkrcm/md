//
//  LanguageDefinition.swift
//  mdviewer
//

#if os(macOS)
    internal import Foundation
    internal import AppKit

    // MARK: - Language Definition

    /// Defines syntax highlighting rules for a programming language
    struct LanguageDefinition: Sendable {
        let id: String
        let name: String
        let aliases: [String]
        let patterns: SyntaxPatterns
    }

    // MARK: - Syntax Patterns

    /// Regex patterns for syntax highlighting
    struct SyntaxPatterns: Sendable {
        let keywords: NSRegularExpression?
        let strings: NSRegularExpression?
        let lineComments: NSRegularExpression?
        let blockComments: NSRegularExpression?
        let numbers: NSRegularExpression?
        let types: NSRegularExpression?
        let calls: NSRegularExpression?
        let properties: NSRegularExpression?
        let operators: NSRegularExpression?
    }

    // MARK: - Language Registry

    /// Registry of supported programming languages for syntax highlighting
    enum LanguageRegistry {
        private static let definitions: [LanguageDefinition] = [
            swift,
            javascript,
            typescript,
            python,
            json,
            html,
            css,
            bash,
            sql,
            rust,
            go,
            ruby,
            java,
            c,
            cpp,
            csharp,
            php,
            yaml,
            markdown,
            xml,
        ]

        private static let aliasMap: [String: LanguageDefinition] = {
            var map: [String: LanguageDefinition] = [:]
            for def in definitions {
                map[def.id.lowercased()] = def
                for alias in def.aliases {
                    map[alias.lowercased()] = def
                }
            }
            return map
        }()

        /// Get language definition by identifier or alias
        static func definition(for identifier: String?) -> LanguageDefinition? {
            guard let identifier = identifier?.lowercased(), !identifier.isEmpty else {
                return nil
            }
            return aliasMap[identifier]
        }

        /// Detect language from code content (simple heuristics)
        static func detectLanguage(in code: String) -> LanguageDefinition? {
            let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }

            // Check for shebang
            if trimmed.hasPrefix("#!/") {
                if trimmed.contains("python") { return definition(for: "python") }
                if trimmed.contains("ruby") { return definition(for: "ruby") }
                if trimmed.contains("bash") || trimmed.contains("sh") { return definition(for: "bash") }
                if trimmed.contains("swift") { return definition(for: "swift") }
            }

            // Check for file extensions in comments or common patterns
            let firstLine = trimmed.prefix(100).lowercased()

            // JSON detection - starts with { or [ and has JSON-like structure
            if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
                let jsonPattern = try? NSRegularExpression(pattern: #"^\s*[\{\[]"#)
                let jsonEndPattern = try? NSRegularExpression(pattern: #"[\}\]]\s*$"#)
                let range = NSRange(location: 0, length: min(trimmed.count, 200))
                if
                    jsonPattern?.firstMatch(in: trimmed, range: range) != nil,
                    jsonEndPattern?.firstMatch(
                        in: trimmed,
                        range: NSRange(location: max(0, trimmed.count - 200), length: min(trimmed.count, 200))
                    ) != nil
                {
                    // Additional JSON validation - check for key-value pairs or array elements
                    if trimmed.contains("\"") || trimmed.contains("'"), trimmed.contains(":") || trimmed.contains("[") {
                        return definition(for: "json")
                    }
                    // Simple JSON arrays
                    if trimmed.hasPrefix("["), trimmed.contains(",") {
                        return definition(for: "json")
                    }
                }
            }

            // HTML detection
            if trimmed.hasPrefix("<") {
                if firstLine.contains("<!doctype html") || firstLine.contains("<html") {
                    return definition(for: "html")
                }
                if firstLine.contains("<?xml") {
                    return definition(for: "xml")
                }
                // Check for common HTML tags
                let htmlPattern = try? NSRegularExpression(
                    pattern: #"<([a-zA-Z][a-zA-Z0-9]*)[^>]*>.*?</\1>|<[a-zA-Z][^>]*/?>"#,
                    options: [.dotMatchesLineSeparators]
                )
                if
                    htmlPattern?
                        .firstMatch(in: trimmed, range: NSRange(location: 0, length: min(trimmed.count, 500))) != nil
                {
                    return definition(for: "html")
                }
            }

            // CSS detection
            if trimmed.contains("{") && trimmed.contains("}") {
                let cssPattern = try? NSRegularExpression(pattern: #"[.#@]?[a-zA-Z_-]+\s*\{[^}]*:\s*[^;]+;"#)
                if
                    cssPattern?
                        .firstMatch(in: trimmed, range: NSRange(location: 0, length: min(trimmed.count, 500))) != nil
                {
                    return definition(for: "css")
                }
            }

            // YAML detection
            if firstLine.contains(": ") || firstLine.hasSuffix(":") {
                let yamlPattern = try? NSRegularExpression(
                    pattern: #"^[a-zA-Z_][a-zA-Z0-9_]*:\s*(.|$)"#,
                    options: [.anchorsMatchLines]
                )
                if
                    yamlPattern?
                        .firstMatch(in: trimmed, range: NSRange(location: 0, length: min(trimmed.count, 500))) != nil
                {
                    return definition(for: "yaml")
                }
            }

            // Rust detection - look for unique Rust patterns (must come before Swift)
            let rustPattern = try? NSRegularExpression(pattern: #"\b(fn|impl|trait|mut|match)\s+"#)
            if
                rustPattern?
                    .firstMatch(in: trimmed, range: NSRange(location: 0, length: min(trimmed.count, 500))) != nil
            {
                return definition(for: "rust")
            }

            // Go detection - look for unique Go patterns
            let goPattern =
                try? NSRegularExpression(pattern: #"\bpackage\s+\w+|fmt\.Print|func\s+\w+\s*\([^)]*\)\s+\w+\s*\{"#)
            if goPattern?.firstMatch(in: trimmed, range: NSRange(location: 0, length: min(trimmed.count, 500))) != nil {
                return definition(for: "go")
            }

            // Swift detection
            let swiftPattern =
                try? NSRegularExpression(pattern: #"\b(let|var|func|struct|class|enum|protocol)\s+[a-zA-Z]"#)
            if
                swiftPattern?
                    .firstMatch(in: trimmed, range: NSRange(location: 0, length: min(trimmed.count, 500))) != nil
            {
                return definition(for: "swift")
            }

            // Python detection
            let pythonPattern = try? NSRegularExpression(
                pattern: #"\b(def|class|import|from)\s+[a-zA-Z_]|print\(|#.*$"#,
                options: [.anchorsMatchLines]
            )
            if
                pythonPattern?
                    .firstMatch(in: trimmed, range: NSRange(location: 0, length: min(trimmed.count, 500))) != nil
            {
                return definition(for: "python")
            }

            // JavaScript/TypeScript detection
            let jsPattern =
                try? NSRegularExpression(pattern: #"\b(const|let|var|function|=>|\bclass\b|\bimport\s+.*\s+from\b)"#)
            if jsPattern?.firstMatch(in: trimmed, range: NSRange(location: 0, length: min(trimmed.count, 500))) != nil {
                // TypeScript specific
                if trimmed.contains(": "), trimmed.contains("interface ") || trimmed.contains("type ") {
                    return definition(for: "typescript")
                }
                return definition(for: "javascript")
            }

            return nil
        }
    }
#endif
