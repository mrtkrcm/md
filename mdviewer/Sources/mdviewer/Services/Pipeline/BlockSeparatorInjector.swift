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

        // Cache NSString representation to avoid repeated conversions
        let nsText = text.string as NSString

        // Table cells are concatenated with no separators by the system parser.
        // Inject tab/newline separators before general block processing so table
        // rows become proper lines that the typography pass can style.
        injectTableSeparators(into: text, nsText: nsText)

        // The NSAttributedString markdown parser produces flat text.
        // We need to reconstruct paragraph structure from the PresentationIntent attributes.
        injectSeparatorsAtBlockBoundaries(into: text, nsText: nsText, length: text.length)

        // Nested list items should visually nest under parents.
        injectNestedListIndentation(into: text, nsText: nsText)
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
    private func injectTableSeparators(into text: NSMutableAttributedString, nsText: NSString) {
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

        // Pre-allocate insertions array with estimated capacity
        var insertions: [(location: Int, separator: String)] = []
        insertions.reserveCapacity(cells.count)

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

        // Reuse attributed string instances to reduce allocations
        let newlineAttr = NSAttributedString(string: "\n")
        let tabAttr = NSAttributedString(string: "\t")

        for insertion in insertions.reversed() {
            let loc = insertion.location
            guard loc > 0, loc <= text.length else { continue }
            text.insert(insertion.separator == "\n" ? newlineAttr : tabAttr, at: loc)
        }
    }

    /// Analyzes PresentationIntent attributes and inserts newlines between blocks.
    ///
    /// The parser creates overlapping semantic ranges for different intent types.
    /// We identify logical block transitions by comparing block identity between
    /// adjacent presentation-intent runs.
    private func injectSeparatorsAtBlockBoundaries(
        into text: NSMutableAttributedString,
        nsText: NSString,
        length: Int
    ) {
        let fullRange = NSRange(location: 0, length: length)
        var blockRuns: [BlockRun] = []
        blockRuns.reserveCapacity(64) // Pre-allocate for typical document size

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            var listItemIdentity: Int?
            var listItemOrdinal: Int?
            var listDepth = 0
            var listKindSignature = ""
            for component in intent.components {
                switch component.kind {
                case .listItem(let ordinal):
                    listItemIdentity = component.identity
                    listItemOrdinal = ordinal

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
                // Include range location to ensure each list item has a unique signature.
                // The parser may reuse identity/ordinal for nested items at the same level,
                // so we need the location to distinguish them.
                let listOrdinal = listItemOrdinal ?? 0
                let signature = "listItem-\(listItemIdentity)-ord\(listOrdinal)-d\(listDepth)-\(listKindSignature)-loc\(range.location)"
                blockRuns.append(BlockRun(range: range, blockSignature: signature))
                return
            }

            // Keep only block-level components and use the most specific one
            // as a stable signature for transition detection.
            var primaryBlock: PresentationIntent.IntentType?
            for component in intent.components {
                switch component.kind {
                case .header, .paragraph, .codeBlock, .blockQuote, .unorderedList, .orderedList,
                     .tableRow, .tableHeaderRow:
                    primaryBlock = component
                default:
                    break
                }
            }

            guard let block = primaryBlock else { return }
            let signature = "\(block.kind)-\(block.identity)"
            blockRuns.append(BlockRun(range: range, blockSignature: signature))
        }

        guard blockRuns.count > 1 else { return }

        var insertionPoints: [Int] = []
        insertionPoints.reserveCapacity(blockRuns.count / 2)

        // Use Set to avoid duplicate insertions
        var seenBoundaries = Set<Int>()
        seenBoundaries.reserveCapacity(blockRuns.count)

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

            // Skip if we already have a separator at this boundary
            guard seenBoundaries.insert(boundary).inserted else { continue }

            let scanStart = max(0, boundary - 1)
            let scanEnd = min(length, boundary + 1)
            let scanLength = max(0, scanEnd - scanStart)

            // Avoid duplicate separators when the source already contains one.
            let existingNewline: Bool
            if scanLength > 0 {
                let scanRange = NSRange(location: scanStart, length: scanLength)
                existingNewline = nsText.rangeOfCharacter(
                    from: .newlines,
                    options: [],
                    range: scanRange
                ).location != NSNotFound
            } else {
                existingNewline = false
            }

            if !existingNewline, boundary > 0, boundary <= length {
                insertionPoints.append(boundary)
            }
        }

        // Insert newlines in reverse order to maintain indices
        let newlineAttr = NSAttributedString(string: "\n")
        for location in insertionPoints.sorted(by: >) {
            if location > 0, location <= text.length {
                text.insert(newlineAttr, at: location)
            }
        }
    }

    // MARK: - Nested List Indentation

    private struct ListRun {
        let range: NSRange
        let depth: Int
    }

    /// Adds tab indentation before nested list items after line boundaries are restored.
    private func injectNestedListIndentation(into text: NSMutableAttributedString, nsText: NSString) {
        let fullRange = NSRange(location: 0, length: text.length)
        var runs: [ListRun] = []
        runs.reserveCapacity(32)

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
        insertions.reserveCapacity(runs.count)

        // Pre-compute tab strings to avoid repeated String(repeating:) calls
        var tabCache: [Int: String] = [:]

        for run in runs {
            let loc = run.range.location
            guard loc >= 0, loc < text.length else { continue }

            // Only indent true line starts to avoid inserting tabs into inline text.
            let isLineStart = loc == 0 || nsText.character(at: loc - 1) == 0x0A
            guard isLineStart else { continue }

            // Skip if indentation was already inserted.
            let alreadyIndented = nsText.character(at: loc) == 0x09
            guard !alreadyIndented else { continue }

            let tabCount = run.depth - 1
            let tabs = tabCache[tabCount] ?? {
                let tabString = String(repeating: "\t", count: tabCount)
                tabCache[tabCount] = tabString
                return tabString
            }()
            insertions.append((loc, tabs))
        }

        // Reuse attributed string for tabs
        let tabAttrCache: [String: NSAttributedString] = Dictionary(
            uniqueKeysWithValues: tabCache.map { ($0.value, NSAttributedString(string: $0.value)) }
        )

        for insertion in insertions.sorted(by: { $0.location > $1.location }) {
            let attr = tabAttrCache[insertion.text] ?? NSAttributedString(string: insertion.text)
            text.insert(attr, at: insertion.location)
        }
    }
}
