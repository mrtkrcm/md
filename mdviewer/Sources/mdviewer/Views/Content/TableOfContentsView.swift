//
//  TableOfContentsView.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Table of Contents View

/// Displays a navigable table of contents for the current document.
struct TableOfContentsView: View {
    let documentURL: URL?
    let onSelectHeading: (Int) -> Void // Line number or character index

    @State private var headings: [Heading] = []
    @State private var isLoading = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView().controlSize(.small)
                    Text("Loading Outline...")
                        .font(.system(size: DesignTokens.Typography.bodySmall))
                        .foregroundStyle(.secondary)
                        .padding(.top, DesignTokens.Spacing.tight)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                headingsList
            }
        }
        .task(id: documentURL) {
            await loadAndParseHeadings()
        }
    }

    private func loadAndParseHeadings() async {
        guard let url = documentURL else { return }
        isLoading = true

        do {
            let parsed = try await Task.detached(priority: .utility) {
                let text = try String(contentsOf: url, encoding: .utf8)
                return await parseHeadings(from: text)
            }.value

            await MainActor.run {
                headings = parsed
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private var headingsList: some View {
        #if os(macOS)
            TableOfContentsTableView(headings: headings, onSelectHeading: onSelectHeading)
        #else
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                    ForEach(headings) { heading in
                        HeadingRow(heading: heading) {
                            onSelectHeading(heading.lineIndex)
                        }
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.standard)
            }
        #endif
    }

    // MARK: - Parsing

    struct Heading: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let level: Int
        let lineIndex: Int
    }

    private func parseHeadings(from text: String) async -> [Heading] {
        await Task.detached {
            var results: [Heading] = []
            let lines = text.components(separatedBy: .newlines)
            var inCodeBlock = false

            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Track code blocks to ignore headings inside them
                if trimmed.hasPrefix("```") {
                    inCodeBlock.toggle()
                    continue
                }
                if inCodeBlock { continue }

                if trimmed.hasPrefix("#") {
                    // Count hashes
                    var level = 0
                    for char in trimmed {
                        if char == "#" {
                            level += 1
                        } else {
                            break
                        }
                    }

                    // Validate level (1-6) and ensure space after hashes
                    if level >= 1, level <= 6 {
                        let contentIndex = line.index(line.startIndex, offsetBy: level)
                        if contentIndex < line.endIndex {
                            let suffix = line[contentIndex...]
                            if suffix.hasPrefix(" ") {
                                let headingText = suffix.trimmingCharacters(in: .whitespaces)
                                results.append(Heading(text: headingText, level: level, lineIndex: index))
                            }
                        }
                    }
                }
            }
            return results
        }.value
    }
}

// MARK: - Components

#if os(macOS)
    private struct TableOfContentsTableView: NSViewRepresentable {
        let headings: [TableOfContentsView.Heading]
        let onSelectHeading: (Int) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(onSelectHeading: onSelectHeading)
        }

        func makeNSView(context: Context) -> NSScrollView {
            let scrollView = NSScrollView()
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true

            let tableView = HoverTrackingTableView()
            tableView.headerView = nil
            tableView.intercellSpacing = NSSize(width: 0, height: 0)
            tableView.usesAlternatingRowBackgroundColors = false
            tableView.allowsColumnSelection = false
            tableView.allowsMultipleSelection = false
            tableView.allowsEmptySelection = true
            tableView.focusRingType = .none
            tableView.selectionHighlightStyle = .none
            tableView.rowHeight = DesignTokens.Spacing.extraLarge

            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ToCColumn"))
            column.resizingMask = .autoresizingMask
            tableView.addTableColumn(column)

            tableView.delegate = context.coordinator
            tableView.dataSource = context.coordinator
            tableView.onHoveredRowChange = context.coordinator.updateHoveredRow
            context.coordinator.tableView = tableView
            context.coordinator.update(headings: headings)

            scrollView.documentView = tableView
            return scrollView
        }

        func updateNSView(_ nsView: NSScrollView, context: Context) {
            context.coordinator.onSelectHeading = onSelectHeading
            context.coordinator.update(headings: headings)
        }

        @MainActor
        final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
            var headings: [TableOfContentsView.Heading] = []
            var onSelectHeading: (Int) -> Void
            weak var tableView: HoverTrackingTableView?
            private var hoveredRow = -1
            private var applyingSelection = false

            init(onSelectHeading: @escaping (Int) -> Void) {
                self.onSelectHeading = onSelectHeading
            }

            func update(headings: [TableOfContentsView.Heading]) {
                guard self.headings != headings else { return }
                self.headings = headings
                hoveredRow = -1
                tableView?.reloadData()
            }

            func updateHoveredRow(_ row: Int) {
                guard hoveredRow != row else { return }

                let previousRow = hoveredRow
                hoveredRow = row

                refreshHoverState(for: previousRow)
                refreshHoverState(for: row)
            }

            private func refreshHoverState(for row: Int) {
                guard row >= 0, let tableView else { return }
                guard
                    let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? HeadingCellView
                else {
                    return
                }
                cell.setHovered(row == hoveredRow)
            }

            func numberOfRows(in _: NSTableView) -> Int {
                headings.count
            }

            func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
                row >= 0 && row < headings.count
            }

            func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
                guard row >= 0, row < headings.count else { return nil }

                let identifier = HeadingCellView.reuseIdentifier
                let cell: HeadingCellView
                if let reused = tableView.makeView(withIdentifier: identifier, owner: nil) as? HeadingCellView {
                    cell = reused
                } else {
                    cell = HeadingCellView()
                    cell.identifier = identifier
                }

                cell.configure(heading: headings[row], isHovered: row == hoveredRow)
                return cell
            }

            func tableViewSelectionDidChange(_ notification: Notification) {
                guard !applyingSelection else { return }
                guard let tableView = notification.object as? NSTableView else { return }

                let row = tableView.selectedRow
                guard row >= 0, row < headings.count else { return }

                applyingSelection = true
                onSelectHeading(headings[row].lineIndex)
                tableView.deselectAll(nil)
                applyingSelection = false
            }
        }
    }

    private final class HoverTrackingTableView: NSTableView {
        var onHoveredRowChange: ((Int) -> Void)?

        private var trackingArea: NSTrackingArea?
        private var hoveredRow = -1

        override func updateTrackingAreas() {
            super.updateTrackingAreas()

            if let trackingArea {
                removeTrackingArea(trackingArea)
            }

            let newTrackingArea = NSTrackingArea(
                rect: .zero,
                options: [.activeInKeyWindow, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(newTrackingArea)
            trackingArea = newTrackingArea
        }

        override func mouseEntered(with event: NSEvent) {
            super.mouseEntered(with: event)
            updateHoveredRow(with: event)
        }

        override func mouseMoved(with event: NSEvent) {
            super.mouseMoved(with: event)
            updateHoveredRow(with: event)
        }

        override func mouseExited(with event: NSEvent) {
            super.mouseExited(with: event)
            setHoveredRow(-1)
        }

        private func updateHoveredRow(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            setHoveredRow(row(at: point))
        }

        private func setHoveredRow(_ row: Int) {
            guard hoveredRow != row else { return }
            hoveredRow = row
            onHoveredRowChange?(row)
        }
    }

    private final class HeadingCellView: NSTableCellView {
        static let reuseIdentifier = NSUserInterfaceItemIdentifier("HeadingCellView")

        private static let rowHeight = DesignTokens.Spacing.extraLarge
        private static let baseIndent = DesignTokens.Spacing.relaxed
        private static let paragraphStyle: NSParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byTruncatingTail
            return style
        }()

        private var currentHeading: TableOfContentsView.Heading?
        private var isHovered = false

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setup()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }

        override var intrinsicContentSize: NSSize {
            NSSize(width: NSView.noIntrinsicMetric, height: Self.rowHeight)
        }

        private func setup() {
            wantsLayer = true
            layer?.drawsAsynchronously = true
            layerContentsRedrawPolicy = .onSetNeedsDisplay
        }

        func configure(heading: TableOfContentsView.Heading, isHovered: Bool) {
            let needsUpdate = currentHeading != heading || self.isHovered != isHovered
            guard needsUpdate else { return }

            currentHeading = heading
            self.isHovered = isHovered
            needsDisplay = true
        }

        func setHovered(_ isHovered: Bool) {
            guard self.isHovered != isHovered else { return }
            self.isHovered = isHovered
            needsDisplay = true
        }

        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)

            guard let currentHeading else { return }

            let backgroundRect = bounds.insetBy(dx: DesignTokens.Spacing.standard, dy: DesignTokens.Spacing.tight / 2)
            if isHovered {
                NSColor.selectedContentBackgroundColor.withAlphaComponent(DesignTokens.Opacity.medium).setFill()
                NSBezierPath(
                    roundedRect: backgroundRect,
                    xRadius: DesignTokens.CornerRadius.small,
                    yRadius: DesignTokens.CornerRadius.small
                ).fill()
            }

            let indent = CGFloat(max(currentHeading.level - 1, 0)) * Self.baseIndent
            let textRect = NSRect(
                x: DesignTokens.Spacing.wide + indent,
                y: floor((bounds.height - DesignTokens.Typography.standard) / 2) - 1,
                width: max(0, bounds.width - (DesignTokens.Spacing.extraWide * 2) - indent),
                height: bounds.height
            )

            currentHeading.text.draw(
                with: textRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [
                    .font: NSFont.systemFont(ofSize: DesignTokens.Typography.standard),
                    .foregroundColor: isHovered ? NSColor.labelColor : NSColor.secondaryLabelColor,
                    .paragraphStyle: Self.paragraphStyle,
                ]
            )
        }
    }
#endif

private struct HeadingRow: View {
    let heading: TableOfContentsView.Heading
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Indentation based on level
                Color.clear
                    .frame(width: CGFloat(heading.level - 1) * 12)

                Text(heading.text)
                    .font(.system(size: DesignTokens.Typography.standard))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(isHovered ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.wide)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
                .padding(.horizontal, DesignTokens.Spacing.standard)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("\(heading.text), level \(heading.level)")
        .accessibilityHint("Jump to this heading")
    }
}

private struct EmptyToCState: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.relaxed) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No Headings")
                .font(.headline)
            Text("This document has no detected headings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.extraLarge)
        .frame(maxWidth: .infinity)
    }
}
