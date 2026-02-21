//
//  SyntaxHighlighter.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Syntax Highlighter

/// Applies Swift syntax highlighting to code blocks.
///
/// This component uses regex-based pattern matching to identify and colorize
/// Swift language constructs within code blocks.
struct SyntaxHighlighter: SyntaxHighlighting {
    // MARK: - Highlighting

    func highlight(_ text: NSMutableAttributedString, in range: NSRange, syntax: NativeSyntaxStyle) {
        guard range.length > 0 else { return }

        let codeBlocks = findCodeBlocks(in: text, range: range)

        for (codeRange, language) in codeBlocks {
            guard language?.lowercased() == "swift" else { continue }

            applySwiftHighlighting(
                to: text,
                in: codeRange,
                syntax: syntax
            )
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

    private func applySwiftHighlighting(
        to text: NSMutableAttributedString,
        in range: NSRange,
        syntax: NativeSyntaxStyle
    ) {
        var protectedRanges: [NSRange] = []

        // Apply highlighting in priority order (strings/comments first, then keywords)
        applyHighlights(
            for: SwiftSyntaxRegexes.strings,
            in: text,
            range: range,
            color: syntax.string,
            protectedRanges: &protectedRanges
        )

        applyHighlights(
            for: SwiftSyntaxRegexes.blockComments,
            in: text,
            range: range,
            color: syntax.comment,
            protectedRanges: &protectedRanges
        )

        applyHighlights(
            for: SwiftSyntaxRegexes.lineComments,
            in: text,
            range: range,
            color: syntax.comment,
            protectedRanges: &protectedRanges
        )

        applyHighlights(
            for: SwiftSyntaxRegexes.keywords,
            in: text,
            range: range,
            color: syntax.keyword,
            protectedRanges: &protectedRanges,
            skipProtected: true
        )

        applyHighlights(
            for: SwiftSyntaxRegexes.numbers,
            in: text,
            range: range,
            color: syntax.number,
            protectedRanges: &protectedRanges,
            skipProtected: true
        )

        applyHighlights(
            for: SwiftSyntaxRegexes.types,
            in: text,
            range: range,
            color: syntax.type,
            protectedRanges: &protectedRanges,
            skipProtected: true
        )

        applyHighlights(
            for: SwiftSyntaxRegexes.calls,
            in: text,
            range: range,
            color: syntax.call,
            protectedRanges: &protectedRanges,
            skipProtected: true
        )
    }

    private func applyHighlights(
        for pattern: NSRegularExpression?,
        in text: NSMutableAttributedString,
        range: NSRange,
        color: NSColor,
        protectedRanges: inout [NSRange],
        skipProtected: Bool = false
    ) {
        guard let pattern else { return }

        pattern.enumerateMatches(in: text.string, options: [], range: range) { match, _, _ in
            guard let match else { return }

            let matchRange = match.range
            guard matchRange.location != NSNotFound, matchRange.length > 0 else { return }

            if skipProtected {
                let intersectsProtected = protectedRanges.contains {
                    NSIntersectionRange($0, matchRange).length > 0
                }
                guard !intersectsProtected else { return }
            } else {
                protectedRanges.append(matchRange)
            }

            text.addAttribute(.foregroundColor, value: color, range: matchRange)
        }
    }
}
