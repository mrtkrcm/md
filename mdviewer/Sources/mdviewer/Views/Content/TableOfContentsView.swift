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

    private final class HeadingCellView: NSTableCellView {
        static let reuseIdentifier = NSUserInterfaceItemIdentifier("HeadingCellView")

        private static let rowHeight = DesignTokens.Component.Sidebar.rowHeight
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

            let backgroundRect = bounds.insetBy(
                dx: DesignTokens.Component.Sidebar.rowHorizontalInset,
                dy: DesignTokens.Component.Sidebar.rowVerticalInset / 2
            )
            if isHovered {
                let hoverPath = hoverBackgroundPath(in: backgroundRect)
                hoverPath.fill()
                hoverPath.stroke()
            }

            let indent = CGFloat(max(currentHeading.level - 1, 0)) * Self.baseIndent
            let railRect = NSRect(
                x: DesignTokens.Component.Sidebar.rowHorizontalInset + indent,
                y: rowRectMidYAligned(in: backgroundRect, height: backgroundRect.height - DesignTokens.Spacing.tight),
                width: DesignTokens.Component.Sidebar.hierarchyRailWidth,
                height: backgroundRect.height - DesignTokens.Spacing.tight
            )
            let textRect = NSRect(
                x: railRect.maxX + DesignTokens.Spacing.standard,
                y: floor((bounds.height - DesignTokens.Typography.standard) / 2) - 1,
                width: max(0, bounds.width - (DesignTokens.Spacing.extraWide * 2) - indent),
                height: bounds.height
            )

            hierarchyRailColor(for: currentHeading.level).setFill()
            let hierarchyPath = NSBezierPath(
                roundedRect: railRect,
                xRadius: DesignTokens.Component.Sidebar.hierarchyRailWidth,
                yRadius: DesignTokens.Component.Sidebar.hierarchyRailWidth
            )
            hierarchyPath.fill()

            currentHeading.text.draw(
                with: textRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: textAttributes(for: currentHeading)
            )
        }

        private func rowRectMidYAligned(in bounds: NSRect, height: CGFloat) -> CGFloat {
            bounds.minY + floor((bounds.height - height) / 2)
        }

        private func hoverBackgroundPath(in rect: NSRect) -> NSBezierPath {
            let path = NSBezierPath(
                roundedRect: rect,
                xRadius: DesignTokens.Component.Sidebar.rowCornerRadius,
                yRadius: DesignTokens.Component.Sidebar.rowCornerRadius
            )
            let fillColor = NativeThemePalette.p3Color(r: 0.92, g: 0.95, b: 0.99, a: 0.12)
            let strokeColor = NativeThemePalette.p3Color(r: 0.78, g: 0.84, b: 0.94, a: 0.18)
            fillColor.setFill()
            strokeColor.setStroke()
            path.lineWidth = DesignTokens.Component.Sidebar.hoverRingWidth
            return path
        }

        private func hierarchyRailColor(for level: Int) -> NSColor {
            switch level {
            case 1:
                return NSColor.controlAccentColor.withAlphaComponent(0.82)
            case 2:
                return NSColor.controlAccentColor.withAlphaComponent(0.58)
            case 3:
                return NativeThemePalette.p3Color(r: 0.66, g: 0.76, b: 0.88, a: 0.40)
            default:
                return NativeThemePalette.p3Color(r: 0.72, g: 0.79, b: 0.88, a: 0.28)
            }
        }

        private func textAttributes(for heading: TableOfContentsView.Heading) -> [NSAttributedString.Key: Any] {
            [
                .font: font(for: heading.level),
                .foregroundColor: isHovered ? NSColor.labelColor : textColor(for: heading.level),
                .paragraphStyle: Self.paragraphStyle,
            ]
        }

        private func font(for level: Int) -> NSFont {
            switch level {
            case 1:
                return NSFont.systemFont(ofSize: DesignTokens.Typography.standard, weight: .semibold)
            case 2:
                return NSFont.systemFont(ofSize: DesignTokens.Typography.standard, weight: .medium)
            default:
                return NSFont.systemFont(ofSize: DesignTokens.Typography.bodySmall, weight: .regular)
            }
        }

        private func textColor(for level: Int) -> NSColor {
            switch level {
            case 1:
                return NSColor.labelColor
            case 2:
                return NSColor.secondaryLabelColor
            default:
                return NSColor.tertiaryLabelColor
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
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: DesignTokens.Component.Sidebar.hierarchyRailWidth, style: .continuous)
                    .fill(railColor)
                    .frame(
                        width: DesignTokens.Component.Sidebar.hierarchyRailWidth,
                        height: DesignTokens.Component.Sidebar.rowHeight - DesignTokens.Spacing.standard
                    )
                    .padding(.leading, CGFloat(max(heading.level - 1, 0)) * DesignTokens.Spacing.relaxed)
                    .padding(.trailing, DesignTokens.Spacing.standard)

                Text(heading.text)
                    .font(font)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(isHovered ? .primary : foregroundStyle)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Component.Sidebar.rowHorizontalInset)
            .frame(height: DesignTokens.Component.Sidebar.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Component.Sidebar.rowCornerRadius, style: .continuous)
                .fill(isHovered ? hoverFillColor : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Component.Sidebar.rowCornerRadius, style: .continuous)
                        .stroke(
                            isHovered ? hoverStrokeColor : Color.clear,
                            lineWidth: DesignTokens.Component.Sidebar.hoverRingWidth
                        )
                }
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
            return .system(size: DesignTokens.Typography.standard, weight: .semibold)
        case 2:
            return .system(size: DesignTokens.Typography.standard, weight: .medium)
        default:
            return .system(size: DesignTokens.Typography.bodySmall)
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

    private var railColor: Color {
        switch heading.level {
        case 1:
            return Color(nsColor: NSColor.controlAccentColor.withAlphaComponent(0.82))
        case 2:
            return Color(nsColor: NSColor.controlAccentColor.withAlphaComponent(0.58))
        case 3:
            return Color(nsColor: NativeThemePalette.p3Color(r: 0.66, g: 0.76, b: 0.88, a: 0.40))
        default:
            return Color(nsColor: NativeThemePalette.p3Color(r: 0.72, g: 0.79, b: 0.88, a: 0.28))
        }
    }

    private var hoverFillColor: Color {
        Color(nsColor: NativeThemePalette.p3Color(r: 0.92, g: 0.95, b: 0.99, a: 0.12))
    }

    private var hoverStrokeColor: Color {
        Color(nsColor: NativeThemePalette.p3Color(r: 0.78, g: 0.84, b: 0.94, a: 0.18))
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
