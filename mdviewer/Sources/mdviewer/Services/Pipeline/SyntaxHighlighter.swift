//
//  SyntaxHighlighter.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Syntax Highlighter

/// Applies syntax highlighting to code blocks for multiple languages.
///
/// This component uses regex-based pattern matching to identify and colorize
/// language constructs within code blocks. Supports automatic language detection
/// when no language is specified.
struct SyntaxHighlighter: SyntaxHighlighting {
    // MARK: - Highlighting

    func highlight(_ text: NSMutableAttributedString, in range: NSRange, syntax: NativeSyntaxStyle) {
        guard range.length > 0 else { return }

        let nsText = text.string as NSString
        let codeBlocks = findCodeBlocks(in: text, range: range)

        for (codeRange, language) in codeBlocks {
            // Mermaid blocks are handled by MermaidDiagramRenderer (post-pipeline),
            // which replaces the text range with an image attachment. Skip them here
            // so no syntax-colour attributes are written onto text that will be removed.
            if language?.lowercased() == "mermaid" { continue }

            // Get language definition from explicit language tag or auto-detect
            let definition: LanguageDefinition?
            if let language, !language.isEmpty {
                definition = LanguageRegistry.definition(for: language)
            } else {
                // Auto-detect language from code content
                let substring = nsText.substring(with: codeRange)
                definition = LanguageRegistry.detectLanguage(in: substring)
            }

            if let definition {
                applyHighlighting(
                    to: text,
                    in: codeRange,
                    definition: definition,
                    syntax: syntax
                )
            }
        }
    }

    // MARK: - Private Methods

    private func findCodeBlocks(
        in text: NSMutableAttributedString,
        range: NSRange
    ) -> [(NSRange, String?)] {
        var blocks: [(NSRange, String?)] = []

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: range,
            options: []
        ) { value, intentRange, _ in
            guard let intent = value as? PresentationIntent else { return }

            for component in intent.components {
                if case .codeBlock(let language) = component.kind {
                    blocks.append((intentRange, language))
                }
            }
        }

        return blocks
    }

    private func applyHighlighting(
        to text: NSMutableAttributedString,
        in range: NSRange,
        definition: LanguageDefinition,
        syntax: NativeSyntaxStyle
    ) {
        let sourceText = text.string

        // NSMutableIndexSet gives O(log n) intersection tests vs the previous O(n)
        // linear scan over a [NSRange] array. For a 500-line file with 200+ matches
        // this drops highlighting from ~O(n²) to ~O(n log n).
        let protectedIndices = NSMutableIndexSet()

        // Apply highlighting in priority order (strings/comments first, then keywords)
        applyHighlights(
            for: definition.patterns.strings,
            in: text,
            range: range,
            sourceText: sourceText,
            color: syntax.string,
            protectedIndices: protectedIndices
        )

        applyHighlights(
            for: definition.patterns.blockComments,
            in: text,
            range: range,
            sourceText: sourceText,
            color: syntax.comment,
            protectedIndices: protectedIndices
        )

        applyHighlights(
            for: definition.patterns.lineComments,
            in: text,
            range: range,
            sourceText: sourceText,
            color: syntax.comment,
            protectedIndices: protectedIndices
        )

        applyHighlights(
            for: definition.patterns.keywords,
            in: text,
            range: range,
            sourceText: sourceText,
            color: syntax.keyword,
            protectedIndices: protectedIndices,
            skipProtected: true
        )

        applyHighlights(
            for: definition.patterns.numbers,
            in: text,
            range: range,
            sourceText: sourceText,
            color: syntax.number,
            protectedIndices: protectedIndices,
            skipProtected: true
        )

        applyHighlights(
            for: definition.patterns.types,
            in: text,
            range: range,
            sourceText: sourceText,
            color: syntax.type,
            protectedIndices: protectedIndices,
            skipProtected: true
        )

        applyHighlights(
            for: definition.patterns.calls,
            in: text,
            range: range,
            sourceText: sourceText,
            color: syntax.call,
            protectedIndices: protectedIndices,
            skipProtected: true
        )

        // Apply property highlighting (same color as calls)
        applyHighlights(
            for: definition.patterns.properties,
            in: text,
            range: range,
            sourceText: sourceText,
            color: syntax.call,
            protectedIndices: protectedIndices,
            skipProtected: true
        )
    }

    private func applyHighlights(
        for pattern: NSRegularExpression?,
        in text: NSMutableAttributedString,
        range: NSRange,
        sourceText: String,
        color: NSColor,
        protectedIndices: NSMutableIndexSet,
        skipProtected: Bool = false
    ) {
        guard let pattern else { return }

        pattern.enumerateMatches(in: sourceText, options: [], range: range) { match, _, _ in
            guard let match else { return }

            let matchRange = match.range
            guard matchRange.location != NSNotFound, matchRange.length > 0 else { return }

            if skipProtected {
                // O(log n): NSIndexSet stores ranges in sorted order, so intersection
                // is a binary search rather than a linear scan over all protected ranges.
                guard !protectedIndices.intersects(in: matchRange) else { return }
            } else {
                protectedIndices.add(in: matchRange)
            }

            text.addAttribute(.foregroundColor, value: color, range: matchRange)
        }
    }
}
