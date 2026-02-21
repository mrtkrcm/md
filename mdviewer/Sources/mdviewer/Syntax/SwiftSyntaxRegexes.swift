#if os(macOS)
internal import Foundation

// MARK: - Shared Swift Syntax Regexes

/// Singleton regex instances for Swift syntax highlighting, shared between the raw
/// markdown editor (`RawMarkdownTextView`) and the render pipeline (`MarkdownRenderService`).
///
/// `NSRegularExpression` is `Sendable` and thread-safe for concurrent matching once
/// initialised, making these safe to access from any isolation domain.
enum SwiftSyntaxRegexes {
    static let keywords: NSRegularExpression? =
        try? NSRegularExpression(
            pattern: #"\b(let|var|func|struct|class|enum|protocol|extension|import|if|else|for|while|guard|switch|case|default|return|throw|throws|try|catch|in|where|async|await|actor|defer|do|repeat|break|continue|fallthrough|typealias|associatedtype|some|any|mutating|nonmutating|init|deinit|subscript|static|final|private|fileprivate|internal|public|open)\b"#
        )

    static let numbers: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"\b(0x[0-9A-Fa-f]+|[0-9]+(?:\.[0-9]+)?)\b"#)

    static let types: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]+)\b"#)

    static let calls: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#)

    static let strings: NSRegularExpression? =
        try? NSRegularExpression(pattern: #""([^"\\]|\\.)*""#)

    static let lineComments: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"//.*"#, options: [.anchorsMatchLines])

    static let blockComments: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#)
}
#endif
