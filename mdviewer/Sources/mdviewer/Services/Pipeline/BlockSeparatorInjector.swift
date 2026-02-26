//
//  BlockSeparatorInjector.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Block Separator Injector

/// Injects visual separators between block-level Markdown elements.
///
/// This component identifies block boundaries using PresentationIntent attributes
/// and ensures proper paragraph separation by inserting newlines and marker attributes.
struct BlockSeparatorInjector: BlockSeparatorInjecting {
    // MARK: - Separator Injection

    func injectSeparators(into text: NSMutableAttributedString) {
        let length = text.length
        guard length > 0 else { return }

        injectSeparatorsAtBlockBoundaries(into: text, length: length)
    }

    // MARK: - Private Methods

    /// Identifies block boundaries from PresentationIntent attributes and marks them
    /// for the layout manager to render with proper spacing.
    ///
    /// IMPORTANT: This component only marks existing newlines. It does NOT inject new ones.
    /// Injecting newlines would double-space content when combined with NSParagraphStyle.paragraphSpacing.
    /// All visual spacing between blocks is handled by TypographyApplier's paragraph styles.
    private func injectSeparatorsAtBlockBoundaries(into text: NSMutableAttributedString, length: Int) {
        let fullRange = NSRange(location: 0, length: length)

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            for component in intent.components {
                switch component.kind {
                case .paragraph, .header, .codeBlock, .blockQuote, .unorderedList, .orderedList:
                    let endLocation = range.location + range.length

                    // Mark existing newlines at block boundaries
                    if endLocation < length {
                        let nextChar = (text.string as NSString).character(at: endLocation)
                        if CharacterSet.newlines.contains(UnicodeScalar(nextChar)!) {
                            text.addAttribute(
                                MarkdownRenderAttribute.paragraphSeparator,
                                value: true,
                                range: NSRange(location: endLocation, length: 1)
                            )
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
