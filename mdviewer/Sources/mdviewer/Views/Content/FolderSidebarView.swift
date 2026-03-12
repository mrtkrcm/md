//
//  FolderSidebarView.swift
//  mdviewer
//
//  Sidebar view for displaying folder contents.
//

internal import OSLog
internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

/// Cache for folder scan results to avoid repeated expensive scans
private actor FolderScanCache {
    private struct Entry {
        let result: FolderScanResult
        let modificationDate: Date?
    }

    private var cache: [URL: Entry] = [:]

    func get(for url: URL) -> FolderScanResult? {
        guard let cached = cache[url] else { return nil }
        let currentModificationDate = folderModificationDate(at: url)
        if cached.modificationDate != currentModificationDate {
            cache.removeValue(forKey: url)
            return nil
        }
        return cached.result
    }

    func set(_ result: FolderScanResult, for url: URL) {
        cache[url] = Entry(
            result: result,
            modificationDate: folderModificationDate(at: url)
        )
    }

    func invalidate(for url: URL) {
        cache.removeValue(forKey: url)
    }
}

private let folderScanCache = FolderScanCache()

private func folderModificationDate(at url: URL) -> Date? {
    let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
    return attributes?[.modificationDate] as? Date
}

@MainActor
enum FolderSidebarPreloader {
    static func prewarmIfNeeded(fileURL: URL?) {
        guard let fileURL else { return }
        let folderURL = fileURL.deletingLastPathComponent()

        Task(priority: .utility) {
            if await folderScanCache.get(for: folderURL) != nil {
                return
            }
            do {
                let result = try await scanFolderItems(at: folderURL)
                await folderScanCache.set(result, for: folderURL)
            } catch {
                // Best effort prewarm only.
            }
        }
    }
}

/// ViewModel for managing folder sidebar state and operations.
/// Loads all items in a single pass — 2000 filename strings are trivial for
/// the CPU and avoiding progressive append eliminates repeated reloadData()
/// calls that were the primary source of scroll stutter.
@MainActor
private final class FolderViewModel: ObservableObject {
    @Published private(set) var rows: [FolderSidebarRow] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    /// Monotonic counter bumped on every rows mutation. The NSTableView
    /// coordinator compares this instead of doing O(n) array equality on
    /// every SwiftUI updateNSView pass (which fires on unrelated state
    /// changes like toolbar visibility).
    private(set) var rowsGeneration: Int = 0

    private var rootFolderURL: URL
    private var currentFolderURL: URL
    private var allItems: [FolderItem] = []

    init(fileURL: URL) {
        let initialFolder = fileURL.deletingLastPathComponent()
        rootFolderURL = initialFolder
        currentFolderURL = initialFolder
        loadContents()
    }

    func navigateUp() {
        guard currentFolderURL.path != rootFolderURL.path else { return }
        let parent = currentFolderURL.deletingLastPathComponent()
        guard parent.path.hasPrefix(rootFolderURL.path) else { return }
        currentFolderURL = parent
        loadContents()
    }

    func navigateInto(_ folderURL: URL) {
        guard folderURL.path.hasPrefix(rootFolderURL.path) else { return }
        currentFolderURL = folderURL
        loadContents()
    }

    var currentFolderName: String {
        currentFolderURL.lastPathComponent
    }

    var totalItemCount: Int {
        allItems.count
    }

    private func loadContents() {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            let folderURL = currentFolderURL

            // Check cache first
            if let cachedResult = await folderScanCache.get(for: folderURL) {
                applyResult(cachedResult)
                isLoading = false
                return
            }

            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try await scanFolderItems(at: folderURL)
                }.value
                applyResult(result)
                await folderScanCache.set(result, for: folderURL)
            } catch {
                allItems = []
                rebuildRows()
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func applyResult(_ result: FolderScanResult) {
        allItems = result.items
        rebuildRows()
    }

    private func rebuildRows() {
        var nextRows: [FolderSidebarRow] = []
        if currentFolderURL.path != rootFolderURL.path {
            nextRows.append(.parent)
        }
        nextRows.append(contentsOf: allItems.map(FolderSidebarRow.item))
        rowsGeneration += 1
        rows = nextRows
    }
}

/// Sidebar showing folder contents
@MainActor
struct FolderSidebarView: View {
    let currentFileURL: URL
    let rootFileURL: URL?
    let onOpenFile: ((URL) -> Void)?

    @Environment(\.openDocument) private var openDocument
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: FolderViewModel

    init(currentFileURL: URL, rootFileURL: URL? = nil, onOpenFile: ((URL) -> Void)? = nil) {
        self.currentFileURL = currentFileURL
        self.rootFileURL = rootFileURL
        self.onOpenFile = onOpenFile
        _viewModel = StateObject(
            wrappedValue: FolderViewModel(fileURL: rootFileURL ?? currentFileURL)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()
            contentView
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
            HStack(spacing: DesignTokens.Spacing.compact) {
                Image(systemName: "folder")
                    .font(.system(size: DesignTokens.Typography.bodySmall))
                    .foregroundStyle(.secondary)

                Text(viewModel.currentFolderName)
                    .font(.system(size: DesignTokens.Typography.bodySmall, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Text(subtitleText)
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, DesignTokens.Spacing.relaxed)
        .padding(.vertical, DesignTokens.Spacing.comfortable)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage)
        } else if viewModel.rows.isEmpty {
            emptyView
        } else {
            FolderSidebarTableView(
                rows: viewModel.rows,
                rowsGeneration: viewModel.rowsGeneration,
                currentFilePath: currentFileURL.path,
                onActivateRow: handleRowActivation
            )
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: DesignTokens.Typography.title))
                .foregroundStyle(.tertiary)
            Text("No Markdown Files")
                .font(.system(size: DesignTokens.Typography.bodySmall, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.extraLarge)
    }

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.standard) {
            Spacer()
            ProgressView()
                .controlSize(.small)
            Text("Loading…")
                .font(.system(size: DesignTokens.Typography.bodySmall))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.extraLarge)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: DesignTokens.Typography.title))
                .foregroundStyle(.orange)
            Text("Error Loading Folder")
                .font(.system(size: DesignTokens.Typography.bodySmall, weight: .medium))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.standard)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.extraLarge)
    }

    // MARK: - Computed

    private var subtitleText: String {
        let count = viewModel.totalItemCount
        return "\(count) item\(count == 1 ? "" : "s")"
    }

    // MARK: - Actions

    private func handleRowActivation(_ row: FolderSidebarRow) {
        switch row {
        case .parent:
            viewModel.navigateUp()
        case let .item(item):
            if item.isDirectory {
                viewModel.navigateInto(item.url)
            } else {
                handleTap(item)
            }
        }
    }

    private func handleTap(_ item: FolderItem) {
        let isCmd = NSApp.currentEvent?.modifierFlags.contains(.command) ?? false

        if isCmd {
            Task { try? await openDocument(at: item.url) }
        } else {
            onOpenFile?(item.url)
        }
    }
}

#if os(macOS)

    // MARK: - AppKit Folder List

    private struct FolderSidebarTableView: NSViewRepresentable {
        let rows: [FolderSidebarRow]
        let rowsGeneration: Int
        let currentFilePath: String
        let onActivateRow: (FolderSidebarRow) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(onActivateRow: onActivateRow)
        }

        func makeNSView(context: Context) -> NSScrollView {
            let scrollView = NSScrollView()
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true

            let contentView = FolderSidebarCanvasView(onActivateRow: context.coordinator.activateRow)
            contentView.autoresizingMask = [.width]
            context.coordinator.canvasView = contentView

            scrollView.documentView = contentView
            context.coordinator.update(rows: rows, generation: rowsGeneration, currentFilePath: currentFilePath)
            return scrollView
        }

        func updateNSView(_ nsView: NSScrollView, context: Context) {
            if let canvasView = nsView.documentView as? FolderSidebarCanvasView {
                canvasView.setFrameSize(
                    NSSize(
                        width: nsView.contentSize.width,
                        height: canvasView.frame.height
                    )
                )
            }
            context.coordinator.onActivateRow = onActivateRow
            context.coordinator.update(rows: rows, generation: rowsGeneration, currentFilePath: currentFilePath)
        }

        @MainActor
        final class Coordinator: NSObject {
            var onActivateRow: (FolderSidebarRow) -> Void
            weak var canvasView: FolderSidebarCanvasView?
            private var lastGeneration: Int = -1

            init(onActivateRow: @escaping (FolderSidebarRow) -> Void) {
                self.onActivateRow = onActivateRow
            }

            func update(rows: [FolderSidebarRow], generation: Int, currentFilePath: String) {
                guard let canvasView else { return }
                canvasView.setFrameSize(
                    NSSize(
                        width: canvasView.enclosingScrollView?.contentSize.width ?? canvasView.frame.width,
                        height: canvasView.frame.height
                    )
                )
                canvasView.update(
                    rows: rows,
                    generation: generation,
                    currentFilePath: currentFilePath,
                    rowsChanged: generation != lastGeneration
                )
                lastGeneration = generation
            }

            func activateRow(_ row: FolderSidebarRow) {
                onActivateRow(row)
            }
        }
    }

    private final class FolderSidebarCanvasView: NSView {
        private static let rowHeight = max(DesignTokens.Spacing.extraLarge, DesignTokens.Spacing.extraWide)
        private static let iconSize: CGFloat = 18
        private static let paragraphStyle: NSParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byTruncatingMiddle
            return style
        }()

        private static let symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: DesignTokens.Typography.bodySmall,
            weight: .regular
        )
        private static let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: DesignTokens.Typography.bodySmall),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle,
        ]
        private static let currentTextAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: DesignTokens.Typography.bodySmall, weight: .medium),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle,
        ]
        private static let parentTextAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: DesignTokens.Typography.bodySmall),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle,
        ]
        private static let imageCache = NSCache<NSString, NSImage>()

        override var isFlipped: Bool { true }

        private let onActivateRow: (FolderSidebarRow) -> Void
        private var rows: [FolderSidebarRow] = []
        private var currentFilePath: String = ""
        private var currentRowIndex: Int?

        init(onActivateRow: @escaping (FolderSidebarRow) -> Void) {
            self.onActivateRow = onActivateRow
            super.init(frame: .zero)
            wantsLayer = true
            layer?.drawsAsynchronously = true
            layerContentsRedrawPolicy = .onSetNeedsDisplay
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var acceptsFirstResponder: Bool { false }

        func update(rows: [FolderSidebarRow], generation _: Int, currentFilePath: String, rowsChanged: Bool) {
            let previousCurrentRowIndex = currentRowIndex
            let pathChanged = self.currentFilePath != currentFilePath
            guard rowsChanged || pathChanged else { return }

            self.rows = rows
            self.currentFilePath = currentFilePath
            currentRowIndex = rows.firstIndex(where: { $0.isCurrentFile(path: currentFilePath) })

            let documentHeight = CGFloat(rows.count) * Self.rowHeight
            let targetSize = NSSize(
                width: enclosingScrollView?.contentSize.width ?? frame.width,
                height: max(documentHeight, 1)
            )
            if frame.size != targetSize {
                setFrameSize(targetSize)
            }

            if rowsChanged {
                needsDisplay = true
                return
            }

            if let previousCurrentRowIndex {
                setNeedsDisplay(rowRect(at: previousCurrentRowIndex))
            }
            if let currentRowIndex, currentRowIndex != previousCurrentRowIndex {
                setNeedsDisplay(rowRect(at: currentRowIndex))
            }
        }

        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)

            let visibleStartIndex = max(0, Int(floor(dirtyRect.minY / Self.rowHeight)))
            let visibleEndIndex = min(rows.count, Int(ceil(dirtyRect.maxY / Self.rowHeight)))
            guard visibleStartIndex < visibleEndIndex else { return }

            for rowIndex in visibleStartIndex ..< visibleEndIndex {
                drawRow(at: rowIndex)
            }
        }

        override func mouseDown(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            let rowIndex = Int(point.y / Self.rowHeight)
            guard rowIndex >= 0, rowIndex < rows.count else {
                super.mouseDown(with: event)
                return
            }

            let row = rows[rowIndex]
            guard row.isSelectable else {
                super.mouseDown(with: event)
                return
            }
            onActivateRow(row)
        }

        private func drawRow(at rowIndex: Int) {
            let row = rows[rowIndex]
            let isCurrent = rowIndex == currentRowIndex
            let rowRect = rowRect(at: rowIndex)
            let iconRect = NSRect(
                x: DesignTokens.Spacing.relaxed,
                y: rowRect.minY + floor((rowRect.height - Self.iconSize) / 2),
                width: Self.iconSize,
                height: Self.iconSize
            )

            if isCurrent {
                currentBackgroundPath(in: rowRect).fill()
            }

            let trailingInset = DesignTokens.Spacing.wide
            let labelLeading = iconRect.maxX + DesignTokens.Spacing.compact
            let labelRect = NSRect(
                x: labelLeading,
                y: rowRect.minY + floor((rowRect.height - textHeight(for: row, isCurrent: isCurrent)) / 2),
                width: max(0, rowRect.width - labelLeading - trailingInset),
                height: textHeight(for: row, isCurrent: isCurrent)
            )

            let iconColor = iconColor(for: row, isCurrent: isCurrent)
            if let iconImage = Self.cachedSymbolImage(named: row.icon, color: iconColor) {
                iconImage.draw(
                    in: iconRect,
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1
                )
            }

            row.displayName.draw(
                in: labelRect,
                withAttributes: textAttributes(for: row, isCurrent: isCurrent)
            )
        }

        private func iconColor(for row: FolderSidebarRow, isCurrent: Bool) -> NSColor {
            row.isDirectoryLike ? .controlAccentColor : (isCurrent ? .controlAccentColor : .secondaryLabelColor)
        }

        private func textAttributes(for row: FolderSidebarRow, isCurrent: Bool) -> [NSAttributedString.Key: Any] {
            if row.isParentRow {
                return Self.parentTextAttributes
            }
            return isCurrent ? Self.currentTextAttributes : Self.normalTextAttributes
        }

        private func rowRect(at rowIndex: Int) -> NSRect {
            NSRect(
                x: 0,
                y: CGFloat(rowIndex) * Self.rowHeight,
                width: bounds.width,
                height: Self.rowHeight
            )
        }

        private func textHeight(for row: FolderSidebarRow, isCurrent: Bool) -> CGFloat {
            ceil(row.displayName.size(withAttributes: textAttributes(for: row, isCurrent: isCurrent)).height)
        }

        private func currentBackgroundPath(in bounds: NSRect) -> NSBezierPath {
            NSColor.selectedContentBackgroundColor
                .withAlphaComponent(DesignTokens.Opacity.medium)
                .setFill()
            return NSBezierPath(
                roundedRect: bounds.insetBy(
                    dx: DesignTokens.Component.Sidebar.rowHorizontalInset,
                    dy: DesignTokens.Component.Sidebar.rowVerticalInset / 4
                ),
                xRadius: DesignTokens.Component.Sidebar.rowCornerRadius,
                yRadius: DesignTokens.Component.Sidebar.rowCornerRadius
            )
        }

        private static func cachedSymbolImage(named name: String, color: NSColor) -> NSImage? {
            let cacheKey = "\(name)-\(color.description)" as NSString
            if let cached = imageCache.object(forKey: cacheKey) {
                return cached
            }

            guard
                let baseImage = NSImage(systemSymbolName: name, accessibilityDescription: nil),
                let image = baseImage.withSymbolConfiguration(
                    symbolConfiguration.applying(
                        NSImage.SymbolConfiguration(hierarchicalColor: color)
                    )
                )
            else {
                return nil
            }
            imageCache.setObject(image, forKey: cacheKey)
            return image
        }
    }
#endif

// MARK: - Folder Item

private enum FolderSidebarRow: Identifiable, Equatable, Sendable {
    case parent
    case item(FolderItem)

    var id: String {
        switch self {
        case .parent:
            "folder-parent-row"
        case let .item(item):
            item.id
        }
    }

    var displayName: String {
        switch self {
        case .parent:
            ".."
        case let .item(item):
            item.name
        }
    }

    var icon: String {
        switch self {
        case .parent:
            "arrowshape.turn.up.left.fill"
        case let .item(item):
            item.icon
        }
    }

    var isParentRow: Bool {
        if case .parent = self {
            return true
        }
        return false
    }

    var isDirectoryLike: Bool {
        switch self {
        case .parent:
            true
        case let .item(item):
            item.isDirectory
        }
    }

    var isSelectable: Bool {
        true
    }

    func isCurrentFile(path: String) -> Bool {
        switch self {
        case .parent:
            false
        case let .item(item):
            !item.isDirectory && normalizedPath(item.path) == normalizedPath(path)
        }
    }
}

struct FolderItem: Identifiable, Equatable, Sendable {
    let id: String
    let url: URL
    let path: String
    let name: String
    let isDirectory: Bool
    let icon: String

    /// Creates a FolderItem by scanning the URL's resource values.
    init?(url: URL) {
        self.url = url
        path = normalizedPath(url.path)
        id = url.path
        name = url.lastPathComponent

        guard
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]),
            let isDir = values.isDirectory else { return nil }

        let isPackage = values.isPackage ?? false
        let ext = url.pathExtension.lowercased()

        // Skip packages and non-markdown files
        if isDir && !isPackage {
            isDirectory = true
            icon = "folder.fill"
        } else if markdownExtensions.contains(ext) || ext.isEmpty {
            isDirectory = false
            icon = "doc.text"
        } else {
            return nil
        }
    }

    /// Creates a FolderItem directly with specified properties (for testing).
    init(url: URL, isDirectory: Bool) {
        self.url = url
        path = normalizedPath(url.path)
        id = url.path
        name = url.lastPathComponent
        self.isDirectory = isDirectory
        icon = isDirectory ? "folder.fill" : "doc.text"
    }

    static func == (lhs: FolderItem, rhs: FolderItem) -> Bool {
        lhs.path == rhs.path
    }
}

private struct FolderScanResult: Sendable {
    let items: [FolderItem]
}

/// Thread-safe cache for resolved file paths. Path normalization (symlink
/// resolution + standardization) is measurably expensive when called per-row
/// during table view updates; caching eliminates redundant syscalls.
private final class NormalizedPathCache: @unchecked Sendable {
    private var cache: [String: String] = [:]
    private let lock = NSLock()

    func resolve(_ path: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[path] { return cached }
        let resolved = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
        cache[path] = resolved
        return resolved
    }
}

private let normalizedPathCache = NormalizedPathCache()

private func normalizedPath(_ path: String) -> String {
    normalizedPathCache.resolve(path)
}

private let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn", "mdwn", "text", "txt"]

private func scanFolderItems(at folderURL: URL) async throws -> FolderScanResult {
    let fileManager = FileManager.default
    let urls = try fileManager.contentsOfDirectory(
        at: folderURL,
        includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
    )

    var items: [FolderItem] = []
    items.reserveCapacity(urls.count)

    for url in urls {
        if let item = FolderItem(url: url) {
            items.append(item)
        }
    }

    items.sort { lhs, rhs in
        if lhs.isDirectory != rhs.isDirectory {
            return lhs.isDirectory
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    return FolderScanResult(items: items)
}

#Preview {
    FolderSidebarView(currentFileURL: URL(fileURLWithPath: "/Users/user/Documents/file.md"))
        .frame(width: 250, height: 400)
}
