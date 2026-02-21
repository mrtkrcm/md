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
    private func injectSeparatorsAtBlockBoundaries(into text: NSMutableAttributedString, length: Int) {
        let fullRange = NSRange(location: 0, length: length)

        // Collect all block ranges from presentation intents
        var blockRanges: [NSRange] = []

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            for component in intent.components {
                switch component.kind {
                case .paragraph, .header, .codeBlock, .blockQuote, .unorderedList, .orderedList:
                    blockRanges.append(range)
                default:
                    break
                }
            }
        }

        // Sort ranges by location
        blockRanges.sort { $0.location < $1.location }

        // Mark the end of each block (except the last one) with a separator attribute
        // The actual spacing is handled by paragraph styles applied in TypographyApplier
        for i in 0 ..< (blockRanges.count - 1) {
            let currentRange = blockRanges[i]
            let endLocation = currentRange.location + currentRange.length

            // Ensure there's a newline at the end of the block
            if endLocation < length {
                let nextChar = (text.string as NSString).character(at: endLocation)
                if !CharacterSet.newlines.contains(UnicodeScalar(nextChar)!) {
                    // Insert a newline character
                    text.insert(NSAttributedString(string: "\n"), at: endLocation)

                    // Update length and remaining ranges
                    let insertedLength = 1

                    // Mark this as a paragraph separator
                    text.addAttribute(
                        MarkdownRenderAttribute.paragraphSeparator,
                        value: true,
                        range: NSRange(location: endLocation, length: insertedLength)
                    )

                    // Adjust subsequent ranges
                    for j in (i + 1) ..< blockRanges.count {
                        let oldRange = blockRanges[j]
                        blockRanges[j] = NSRange(
                            location: oldRange.location + insertedLength,
                            length: oldRange.length
                        )
                    }
                } else {
                    // Already has newline, just mark it
                    text.addAttribute(
                        MarkdownRenderAttribute.paragraphSeparator,
                        value: true,
                        range: NSRange(location: endLocation, length: 1)
                    )
                }
            }
        }
    }
}
