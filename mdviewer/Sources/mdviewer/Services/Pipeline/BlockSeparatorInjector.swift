//
//  BlockSeparatorInjector.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Block Separator Injector

/// Injects visual separators between block-level Markdown elements in a single efficient pass.
struct BlockSeparatorInjector: BlockSeparatorInjecting {
    func injectSeparators(into text: NSMutableAttributedString) {
        let length = text.length
        guard length > 0 else { return }

        let newlineAttr = NSAttributedString(string: "\n")
        let tabAttr = NSAttributedString(string: "\t")
        var mutations: [(location: Int, text: NSAttributedString)] = []
        mutations.reserveCapacity(128)

        // Pre-compute tab strings
        let tabCache: [Int: NSAttributedString] = (1 ... 10).reduce(into: [:]) { dict, depth in
            dict[depth] = NSAttributedString(string: String(repeating: "\t", count: depth))
        }

        // 1. Discover all intents
        var intents: [(intent: PresentationIntent, range: NSRange)] = []
        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: NSRange(location: 0, length: length),
            options: []
        ) { value, range, _ in
            if let intent = value as? PresentationIntent {
                intents.append((intent, range))
            }
        }

        // 2. Process transitions and indentation
        for i in 0 ..< intents.count {
            let curr = intents[i].intent
            let currRange = intents[i].range

            // Transition logic (Newline discovery)
            if i > 0 {
                let prev = intents[i - 1].intent

                if let sep = detectSeparator(prev: prev, curr: curr, newlineAttr: newlineAttr, tabAttr: tabAttr) {
                    mutations.append((currRange.location, sep))
                }
            }

            // Indentation logic
            var depth = 0
            var hasListItem = false
            for component in curr.components {
                switch component.kind {
                case .unorderedList, .orderedList: depth += 1
                case .listItem: hasListItem = true
                default: break
                }
            }

            if hasListItem, depth > 1 {
                if let tabs = tabCache[depth - 1] {
                    mutations.append((currRange.location, tabs))
                }
            }
        }

        // 3. Apply mutations in reverse order to preserve indices
        // We must sort primarily by location DESC, and secondarily by
        // original index DESC to maintain relative order at same location.
        let sortedMutations = mutations.enumerated().sorted { a, b in
            if a.element.location != b.element.location {
                return a.element.location > b.element.location
            }
            return a.offset > b.offset
        }

        for (_, mutation) in sortedMutations {
            if mutation.location >= 0, mutation.location <= text.length {
                text.insert(mutation.text, at: mutation.location)
            }
        }
    }

    private func detectSeparator(
        prev: PresentationIntent,
        curr: PresentationIntent,
        newlineAttr: NSAttributedString,
        tabAttr: NSAttributedString
    ) -> NSAttributedString? {
        // Table cell transitions
        let prevTable = tableInfo(from: prev)
        let currTable = tableInfo(from: curr)

        if let p = prevTable, let c = currTable {
            if p.row != c.row || p.isHeader != c.isHeader {
                return newlineAttr
            } else {
                return tabAttr // BlockSeparatorInjector currently only inserts newlines
            }
        }

        // List item transitions
        let prevList = listItemOrdinal(from: prev)
        let currList = listItemOrdinal(from: curr)

        if prevList != nil, currList != nil {
            return newlineAttr
        }

        // General block transitions
        let prevBlock = primaryBlockSignature(from: prev)
        let currBlock = primaryBlockSignature(from: curr)

        if prevBlock != currBlock {
            return newlineAttr
        }

        return nil
    }

    private func tableInfo(from intent: PresentationIntent) -> (row: Int, isHeader: Bool)? {
        var row = -2
        var isHeader = false
        var isTable = false
        for component in intent.components {
            switch component.kind {
            case .tableCell: isTable = true
            case .tableRow(let r): row = r
            case .tableHeaderRow: isHeader = true; row = -1
            default: break
            }
        }
        return isTable ? (row, isHeader) : nil
    }

    private func listItemOrdinal(from intent: PresentationIntent) -> Int? {
        for component in intent.components {
            if case .listItem(let ordinal) = component.kind {
                return ordinal
            }
        }
        return nil
    }

    private func primaryBlockSignature(from intent: PresentationIntent) -> String? {
        for component in intent.components {
            switch component.kind {
            case .header, .paragraph, .codeBlock, .blockQuote, .unorderedList, .orderedList,
                 .tableRow, .tableHeaderRow:
                return "\(component.kind)-\(component.identity)"
            case .listItem(let ordinal):
                return "listItem-\(component.identity)-ord\(ordinal)"
            default:
                break
            }
        }
        return nil
    }
}
