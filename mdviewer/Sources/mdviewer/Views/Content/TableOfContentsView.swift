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
    let onSelectHeading: (Heading) -> Void

    @State private var headings: [Heading] = []
    @State private var isLoading = false
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView().controlSize(.small)
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
        guard let url = documentURL else {
            headings = []
            isLoading = false
            return
        }
        isLoading = true

        do {
            let parsed = try await Task.detached(priority: .utility) {
                let text = try String(contentsOf: url, encoding: .utf8)
                return Self.parseHeadings(from: text)
            }.value

            guard !Task.isCancelled else { return }
            await MainActor.run {
                headings = parsed
                isLoading = false
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                headings = []
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private var headingsList: some View {
        if headings.isEmpty {
            EmptyToCState()
                .padding(.horizontal, DesignTokens.Component.Sidebar.contentInset)
                .padding(.top, DesignTokens.Spacing.extraLarge)
        } else {
            #if os(macOS)
                TableOfContentsTableView(headings: headings, onSelectHeading: onSelectHeading)
            #else
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                        ForEach(headings) { heading in
                            HeadingRow(heading: heading) {
                                onSelectHeading(heading)
                            }
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.standard)
                }
            #endif
        }
    }

    // MARK: - Parsing

    struct Heading: Identifiable, Equatable {
        let id: String
        let text: String
        let level: Int
        let headingIndex: Int
        let lineIndex: Int
    }

    private nonisolated static func parseHeadings(from text: String) -> [Heading] {
        var results: [Heading] = []
        let lines = text.components(separatedBy: .newlines)
        var inCodeBlock = false
        var headingIndex = 0

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
                            results.append(
                                Heading(
                                    id: "\(index)-\(headingIndex)-\(headingText)",
                                    text: headingText,
                                    level: level,
                                    headingIndex: headingIndex,
                                    lineIndex: index
                                )
                            )
                            headingIndex += 1
                        }
                    }
                }
            }
        }

        return results
    }
}

// MARK: - Components

#if os(macOS)
    private struct TableOfContentsTableView: NSViewRepresentable {
        let headings: [TableOfContentsView.Heading]
        let onSelectHeading: (TableOfContentsView.Heading) -> Void

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
            tableView.rowHeight = DesignTokens.Component.Sidebar.rowHeight

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
            var onSelectHeading: (TableOfContentsView.Heading) -> Void
            weak var tableView: HoverTrackingTableView?
            private var hoveredRow = -1
            private var applyingSelection = false

            init(onSelectHeading: @escaping (TableOfContentsView.Heading) -> Void) {
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
                onSelectHeading(headings[row])
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

    /// Uses native NSTextField + Auto Layout for pixel-perfect vertical centering
    /// regardless of heading level font size. The text field handles its own
    /// intrinsic content size, eliminating manual y-offset calculations.
    private final class HeadingCellView: NSTableCellView {
        static let reuseIdentifier = NSUserInterfaceItemIdentifier("HeadingCellView")

        private static let baseIndent = DesignTokens.Spacing.relaxed
        private static let leadingPadding = DesignTokens.Component.Sidebar.rowHorizontalInset + DesignTokens.Spacing.compact
        private static let trailingPadding = DesignTokens.Spacing.relaxed

        private let label: NSTextField = {
            let field = NSTextField(labelWithString: "")
            field.translatesAutoresizingMaskIntoConstraints = false
            field.cell?.lineBreakMode = .byTruncatingTail
            field.maximumNumberOfLines = 1
            field.isEditable = false
            field.isSelectable = false
            field.isBordered = false
            field.drawsBackground = false
            return field
        }()

        private let hoverBackdrop: NSView = {
            let view = NSView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.wantsLayer = true
            view.layer?.cornerRadius = DesignTokens.CornerRadius.small
            view.layer?.cornerCurve = .continuous
            return view
        }()

        private var leadingConstraint: NSLayoutConstraint?
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

        private func setup() {
            addSubview(hoverBackdrop)
            addSubview(label)
            textField = label

            let leading = label.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Self.leadingPadding
            )
            leadingConstraint = leading

            NSLayoutConstraint.activate([
                // Hover backdrop
                hoverBackdrop.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: DesignTokens.Component.Sidebar.rowHorizontalInset
                ),
                hoverBackdrop.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -DesignTokens.Component.Sidebar.rowHorizontalInset
                ),
                hoverBackdrop.topAnchor.constraint(
                    equalTo: topAnchor,
                    constant: DesignTokens.Component.Sidebar.rowVerticalInset / 2
                ),
                hoverBackdrop.bottomAnchor.constraint(
                    equalTo: bottomAnchor,
                    constant: -DesignTokens.Component.Sidebar.rowVerticalInset / 2
                ),
                // Label
                leading,
                label.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -Self.trailingPadding
                ),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])

            hoverBackdrop.isHidden = true
        }

        func configure(heading: TableOfContentsView.Heading, isHovered: Bool) {
            guard currentHeading != heading || self.isHovered != isHovered else { return }
            currentHeading = heading
            self.isHovered = isHovered
            applyState()
        }

        func setHovered(_ isHovered: Bool) {
            guard self.isHovered != isHovered else { return }
            self.isHovered = isHovered
            applyHoverState()
        }

        private func applyState() {
            guard let heading = currentHeading else { return }

            label.stringValue = heading.text
            label.font = font(for: heading.level)

            let indent = CGFloat(max(heading.level - 1, 0)) * Self.baseIndent
            leadingConstraint?.constant = Self.leadingPadding + indent

            applyHoverState()
        }

        private func applyHoverState() {
            guard let heading = currentHeading else { return }

            label.textColor = isHovered ? .labelColor : textColor(for: heading.level)
            hoverBackdrop.isHidden = !isHovered
            hoverBackdrop.layer?.backgroundColor = isHovered
                ? NSColor.labelColor.withAlphaComponent(0.04).cgColor
                : nil
        }

        private func font(for level: Int) -> NSFont {
            switch level {
            case 1:
                return .systemFont(ofSize: DesignTokens.Typography.bodySmall, weight: .medium)
            case 2:
                return .systemFont(ofSize: DesignTokens.Typography.bodySmall, weight: .regular)
            default:
                return .systemFont(ofSize: DesignTokens.Typography.small, weight: .regular)
            }
        }

        private func textColor(for level: Int) -> NSColor {
            switch level {
            case 1: .labelColor
            case 2: .secondaryLabelColor
            default: .tertiaryLabelColor
            }
        }
    }
#endif

private struct HeadingRow: View {
    let heading: TableOfContentsView.Heading
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(heading.text)
                .font(font)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(isHovered ? .primary : foregroundStyle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, CGFloat(max(heading.level - 1, 0)) * DesignTokens.Spacing.relaxed)
                .padding(.horizontal, DesignTokens.Component.Sidebar.rowHorizontalInset + DesignTokens.Spacing.compact)
                .frame(height: DesignTokens.Component.Sidebar.rowHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .fill(isHovered ? Color(nsColor: .labelColor).opacity(0.04) : Color.clear)
                .padding(.horizontal, DesignTokens.Component.Sidebar.rowHorizontalInset)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("\(heading.text), level \(heading.level)")
        .accessibilityHint("Jump to this heading")
    }

    private var font: Font {
        switch heading.level {
        case 1:
            return .system(size: DesignTokens.Typography.bodySmall, weight: .medium)
        case 2:
            return .system(size: DesignTokens.Typography.bodySmall)
        default:
            return .system(size: DesignTokens.Typography.small)
        }
    }

    private var foregroundStyle: Color {
        switch heading.level {
        case 1:
            return .primary
        case 2:
            return .secondary
        default:
            return Color(nsColor: .tertiaryLabelColor)
        }
    }
}

private struct EmptyToCState: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.compact) {
            Spacer()
            Text("No Headings")
                .font(.system(size: DesignTokens.Typography.bodySmall))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
