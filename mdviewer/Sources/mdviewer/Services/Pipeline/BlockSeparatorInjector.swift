//
//  BlockSeparatorInjector.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Block Separator Injector

/// A contiguous run of text sharing the same block-level presentation intent.
private struct BlockRun {
    let range: NSRange
    let blockSignature: String
}

/// Injects visual separators between block-level Markdown elements.
///
/// The macOS NSAttributedString(markdown:) parser produces flat text without proper
/// paragraph structure. This component works around that by analyzing the original
/// markdown and inserting proper paragraph breaks.
struct BlockSeparatorInjector: BlockSeparatorInjecting {
    // MARK: - Separator Injection

    func injectSeparators(into text: NSMutableAttributedString) {
        let length = text.length
        guard length > 0 else { return }

        // Table cells are concatenated with no separators by the system parser.
        // Inject tab/newline separators before general block processing so table
        // rows become proper lines that the typography pass can style.
        injectTableSeparators(into: text)

        // The NSAttributedString markdown parser produces flat text.
        // We need to reconstruct paragraph structure from the PresentationIntent attributes.
        injectSeparatorsAtBlockBoundaries(into: text, length: text.length)

        // Nested list items should visually nest under parents.
        injectNestedListIndentation(into: text)
    }

    // MARK: - Private Methods

    // MARK: - Table Separators

    /// A single table cell discovered by scanning PresentationIntent attributes.
    private struct TableCell {
        let range: NSRange
        let row: Int // -1 for header row
        let column: Int
        let isHeader: Bool
    }

    /// Scans for table cell intents and inserts tab characters between cells
    /// in the same row and newline characters between rows.
    private func injectTableSeparators(into text: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: text.length)
        var cells: [TableCell] = []

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            var column = -1
            var row = -1
            var isHeader = false

            for component in intent.components {
                switch component.kind {
                case .tableCell(let col):
                    column = col

                case .tableRow(let r):
                    row = r

                case .tableHeaderRow:
                    row = -1
                    isHeader = true

                default:
                    break
                }
            }

            guard column >= 0 else { return }
            cells.append(TableCell(range: range, row: row, column: column, isHeader: isHeader))
        }

        guard cells.count > 1 else { return }

        // Sort by range location to process in document order.
        // Insert separators in reverse to preserve indices.
        var insertions: [(location: Int, separator: String)] = []

        for i in 1 ..< cells.count {
            let prev = cells[i - 1]
            let curr = cells[i]
            let boundary = prev.range.location + prev.range.length

            guard boundary <= text.length else { continue }

            if curr.row != prev.row || curr.isHeader != prev.isHeader {
                // Row transition → newline
                insertions.append((boundary, "\n"))
            } else {
                // Cell transition within same row → tab
                insertions.append((boundary, "\t"))
            }
        }

        for insertion in insertions.reversed() {
            let loc = insertion.location
            guard loc > 0, loc <= text.length else { continue }
            text.insert(NSAttributedString(string: insertion.separator), at: loc)
        }
    }

    /// Analyzes PresentationIntent attributes and inserts newlines between blocks.
    ///
    /// The parser creates overlapping semantic ranges for different intent types.
    /// We identify logical block transitions by comparing block identity between
    /// adjacent presentation-intent runs.
    private func injectSeparatorsAtBlockBoundaries(into text: NSMutableAttributedString, length: Int) {
        let fullRange = NSRange(location: 0, length: length)
        let nsText = text.string as NSString

        var blockRuns: [BlockRun] = []

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            var listItemIdentity: Int?
            var listDepth = 0
            var listKindSignature = ""
            for component in intent.components {
                switch component.kind {
                case .listItem:
                    listItemIdentity = component.identity

                case .unorderedList:
                    listDepth += 1
                    listKindSignature.append("u")

                case .orderedList:
                    listDepth += 1
                    listKindSignature.append("o")

                default:
                    break
                }
            }

            if let listItemIdentity, listDepth > 0 {
                let signature = "listItem-\(listItemIdentity)-d\(listDepth)-\(listKindSignature)"
                blockRuns.append(BlockRun(range: range, blockSignature: signature))
                return
            }

            // Keep only block-level components and use the most specific one
            // as a stable signature for transition detection.
            let blockComponents = intent.components.filter { component in
                switch component.kind {
                case .header, .paragraph, .codeBlock, .blockQuote, .unorderedList, .orderedList,
                     .tableRow, .tableHeaderRow:
                    return true

                default:
                    return false
                }
            }

            guard let primaryBlock = blockComponents.last else { return }
            let signature = "\(primaryBlock.kind)-\(primaryBlock.identity)"
            blockRuns.append(BlockRun(range: range, blockSignature: signature))
        }

        guard blockRuns.count > 1 else { return }

        var insertionPoints: [Int] = []

        for index in 1 ..< blockRuns.count {
            let previous = blockRuns[index - 1]
            let current = blockRuns[index]

            // Only inject when we cross into a different logical block.
            guard previous.blockSignature != current.blockSignature else { continue }

            let previousEnd = previous.range.location + previous.range.length
            // Use the previous run end as separator insertion point.
            // With overlapping intent runs, current.start can be inside
            // the previous run and is not a reliable visual boundary.
            let boundary = min(length, max(0, previousEnd))
            let scanStart = max(0, boundary - 1)
            let scanEnd = min(length, boundary + 1)
            let scanLength = max(0, scanEnd - scanStart)
            let scanRange = NSRange(location: scanStart, length: scanLength)

            // Avoid duplicate separators when the source already contains one.
            let existingNewline = scanLength > 0
                && nsText.rangeOfCharacter(
                    from: .newlines,
                    options: [],
                    range: scanRange
                ).location != NSNotFound

            if !existingNewline, boundary > 0, boundary <= length {
                insertionPoints.append(boundary)
            }
        }

        // Insert newlines in reverse order to maintain indices
        for location in Set(insertionPoints).sorted(by: >) {
            if location > 0, location <= text.length {
                text.insert(NSAttributedString(string: "\n"), at: location)
            }
        }
    }

    // MARK: - Nested List Indentation

    private struct ListRun {
        let range: NSRange
        let depth: Int
    }

    /// Adds tab indentation before nested list items after line boundaries are restored.
    private func injectNestedListIndentation(into text: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: text.length)
        let nsText = text.string as NSString
        var runs: [ListRun] = []

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }
            var depth = 0
            var hasListItem = false
            for component in intent.components {
                switch component.kind {
                case .unorderedList, .orderedList:
                    depth += 1

                case .listItem:
                    hasListItem = true

                default:
                    break
                }
            }
            guard hasListItem, depth > 1 else { return }
            runs.append(ListRun(range: range, depth: depth))
        }

        guard !runs.isEmpty else { return }

        var insertions: [(location: Int, text: String)] = []
        for run in runs {
            let loc = run.range.location
            guard loc >= 0, loc < text.length else { continue }

            // Only indent true line starts to avoid inserting tabs into inline text.
            let isLineStart = loc == 0 || nsText.character(at: loc - 1) == 0x0A
            guard isLineStart else { continue }

            // Skip if indentation was already inserted.
            let alreadyIndented = nsText.character(at: loc) == 0x09
            guard !alreadyIndented else { continue }

            let tabs = String(repeating: "\t", count: run.depth - 1)
            insertions.append((loc, tabs))
        }

        for insertion in insertions.sorted(by: { $0.location > $1.location }) {
            text.insert(NSAttributedString(string: insertion.text), at: insertion.location)
        }
    }
}
