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

/// ViewModel for managing folder sidebar state and operations
@MainActor
private final class FolderViewModel: ObservableObject {
    @Published private(set) var rows: [FolderSidebarRow] = []
    @Published private(set) var isLoading = false
    @Published private(set) var totalItemCount = 0
    @Published private(set) var hasMoreItems = false

    private var currentFilePath: String = ""
    private var rootFolderURL: URL
    private var currentFolderURL: URL
    private var allItems: [FolderItem] = []
    private var visibleItems: [FolderItem] = []
    private var loadedCount = 0
    private var isAppendingPage = false
    private var progressiveAppendTask: Task<Void, Never>?

    private let pageSize = 200

    init(fileURL: URL) {
        let initialFolder = fileURL.deletingLastPathComponent()
        rootFolderURL = initialFolder
        currentFolderURL = initialFolder
        currentFilePath = fileURL.path
        loadContents()
    }

    func updateFileURL(_ newURL: URL) {
        guard newURL.path != currentFilePath else { return }
        currentFilePath = newURL.path
        let nextRoot = newURL.deletingLastPathComponent()
        if nextRoot.path != rootFolderURL.path {
            rootFolderURL = nextRoot
            currentFolderURL = nextRoot
            loadContents()
            return
        }
        rebuildRows()
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

    var visibleItemCount: Int {
        visibleItems.count
    }

    private func loadContents() {
        progressiveAppendTask?.cancel()

        Task { @MainActor in
            let folderURL = currentFolderURL

            // Check cache first
            if let cachedResult = await folderScanCache.get(for: folderURL) {
                applyCachedScanResult(cachedResult)
                isLoading = false
                return
            }

            isLoading = true

            // Perform scan
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try await scanFolderItems(at: folderURL)
                }.value
                applyScanResult(result)

                // Cache the result
                await folderScanCache.set(result, for: folderURL)
            } catch {
                rows = []
                allItems = []
                visibleItems = []
                loadedCount = 0
                totalItemCount = 0
                hasMoreItems = false
            }
            isLoading = false
        }
    }

    private func applyScanResult(_ result: FolderScanResult) {
        progressiveAppendTask?.cancel()
        allItems = result.items
        visibleItems = []
        totalItemCount = allItems.count
        rebuildRows()
        loadedCount = 0
        hasMoreItems = !allItems.isEmpty
        startProgressiveAppend()
    }

    private func applyCachedScanResult(_ result: FolderScanResult) {
        progressiveAppendTask?.cancel()
        allItems = result.items
        visibleItems = result.items
        totalItemCount = allItems.count
        loadedCount = allItems.count
        hasMoreItems = false
        rebuildRows()
    }

    private func appendNextPage() {
        guard !isAppendingPage else { return }
        guard loadedCount < allItems.count else {
            hasMoreItems = false
            return
        }

        isAppendingPage = true
        let nextCount = min(allItems.count, loadedCount + pageSize)
        let nextItems = Array(allItems[loadedCount ..< nextCount])
        loadedCount = nextCount

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            visibleItems.append(contentsOf: nextItems)
            rebuildRows()
        }

        hasMoreItems = loadedCount < allItems.count
        isAppendingPage = false
    }

    private func startProgressiveAppend() {
        progressiveAppendTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled, loadedCount < allItems.count {
                appendNextPage()
                if loadedCount < allItems.count {
                    try? await Task.sleep(for: .milliseconds(12))
                }
            }
        }
    }

    private func rebuildRows() {
        var nextRows: [FolderSidebarRow] = []
        if currentFolderURL.path != rootFolderURL.path {
            nextRows.append(.parent)
        }
        nextRows.append(contentsOf: visibleItems.map(FolderSidebarRow.item))
        rows = nextRows
    }
}

/// Sidebar showing folder contents
@MainActor
struct FolderSidebarView: View {
    let fileURL: URL
    let currentFileURL: URL?
    let onOpenFile: ((URL) -> Void)?

    @Environment(\.openDocument) private var openDocument
    @StateObject private var viewModel: FolderViewModel

    init(fileURL: URL, currentFileURL: URL? = nil, onOpenFile: ((URL) -> Void)? = nil) {
        self.fileURL = fileURL
        self.currentFileURL = currentFileURL
        self.onOpenFile = onOpenFile
        _viewModel = StateObject(wrappedValue: FolderViewModel(fileURL: fileURL))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()
            contentView
        }
        .onChange(of: fileURL) { _, newURL in
            viewModel.updateFileURL(newURL)
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
        } else if viewModel.rows.isEmpty {
            emptyView
        } else {
            FolderSidebarTableView(
                rows: viewModel.rows,
                currentFilePath: (currentFileURL ?? fileURL).path,
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

    // MARK: - Computed

    private var subtitleText: String {
        if viewModel.hasMoreItems {
            return "Showing \(viewModel.visibleItemCount) of \(viewModel.totalItemCount) items"
        }
        return "\(viewModel.totalItemCount) item\(viewModel.totalItemCount == 1 ? "" : "s")"
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

            let tableView = NSTableView()
            tableView.headerView = nil
            tableView.intercellSpacing = NSSize(width: 0, height: 0)
            tableView.usesAlternatingRowBackgroundColors = false
            tableView.allowsColumnSelection = false
            tableView.allowsMultipleSelection = false
            tableView.allowsEmptySelection = true
            tableView.focusRingType = .none
            tableView.rowHeight = max(DesignTokens.Spacing.extraLarge, DesignTokens.Spacing.extraWide)

            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("FolderColumn"))
            column.resizingMask = .autoresizingMask
            tableView.addTableColumn(column)

            tableView.delegate = context.coordinator
            tableView.dataSource = context.coordinator
            context.coordinator.tableView = tableView

            scrollView.documentView = tableView
            context.coordinator.update(rows: rows, currentFilePath: currentFilePath)
            return scrollView
        }

        func updateNSView(_ nsView: NSScrollView, context: Context) {
            context.coordinator.onActivateRow = onActivateRow
            context.coordinator.update(rows: rows, currentFilePath: currentFilePath)
        }

        @MainActor
        final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
            var rows: [FolderSidebarRow] = []
            var currentFilePath: String = ""
            var onActivateRow: (FolderSidebarRow) -> Void
            weak var tableView: NSTableView?
            private var applyingSelection = false

            init(onActivateRow: @escaping (FolderSidebarRow) -> Void) {
                self.onActivateRow = onActivateRow
            }

            func update(rows: [FolderSidebarRow], currentFilePath: String) {
                let rowsChanged = self.rows != rows
                let pathChanged = self.currentFilePath != currentFilePath
                guard rowsChanged || pathChanged else { return }

                self.rows = rows
                self.currentFilePath = currentFilePath

                guard let tableView else { return }
                if rowsChanged {
                    tableView.reloadData()
                }

                applyingSelection = true
                if let currentRow = rows.firstIndex(where: { $0.isCurrentFile(path: currentFilePath) }) {
                    if tableView.selectedRow != currentRow {
                        tableView.selectRowIndexes(IndexSet(integer: currentRow), byExtendingSelection: false)
                    }
                } else {
                    tableView.deselectAll(nil)
                }
                applyingSelection = false
            }

            func numberOfRows(in _: NSTableView) -> Int {
                rows.count
            }

            func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
                guard row >= 0, row < rows.count else { return false }
                return rows[row].isSelectable
            }

            func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
                guard row >= 0, row < rows.count else { return nil }
                let rowItem = rows[row]
                let isCurrent = rowItem.isCurrentFile(path: currentFilePath)
                let identifier = FolderSidebarCellView.reuseIdentifier
                let cell: FolderSidebarCellView
                if let reused = tableView.makeView(withIdentifier: identifier, owner: nil) as? FolderSidebarCellView {
                    cell = reused
                } else {
                    cell = FolderSidebarCellView()
                    cell.identifier = identifier
                }
                cell.configure(row: rowItem, isCurrent: isCurrent)
                return cell
            }

            func tableViewSelectionDidChange(_ notification: Notification) {
                guard !applyingSelection else { return }
                guard let tableView = notification.object as? NSTableView else { return }
                let row = tableView.selectedRow
                guard row >= 0, row < rows.count else { return }
                onActivateRow(rows[row])
            }
        }
    }

    private final class FolderSidebarCellView: NSTableCellView {
        static let reuseIdentifier = NSUserInterfaceItemIdentifier("FolderSidebarCellView")

        private let iconView = NSImageView()
        private let labelView = NSTextField(labelWithString: "")
        private let checkView = NSTextField(labelWithString: "✓")

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setup()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }

        private func setup() {
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.symbolConfiguration = NSImage.SymbolConfiguration(
                pointSize: DesignTokens.Typography.bodySmall,
                weight: .regular
            )
            addSubview(iconView)

            labelView.translatesAutoresizingMaskIntoConstraints = false
            labelView.lineBreakMode = .byTruncatingMiddle
            labelView.font = .systemFont(ofSize: DesignTokens.Typography.bodySmall)
            addSubview(labelView)

            checkView.translatesAutoresizingMaskIntoConstraints = false
            checkView.font = .systemFont(ofSize: DesignTokens.Typography.caption, weight: .bold)
            checkView.textColor = .controlAccentColor
            checkView.isHidden = true
            addSubview(checkView)

            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.Spacing.relaxed),
                iconView.widthAnchor.constraint(equalToConstant: 18),
                iconView.centerYAnchor.constraint(equalTo: centerYAnchor),

                labelView.leadingAnchor.constraint(
                    equalTo: iconView.trailingAnchor,
                    constant: DesignTokens.Spacing.compact
                ),
                labelView.centerYAnchor.constraint(equalTo: centerYAnchor),

                checkView.leadingAnchor.constraint(
                    greaterThanOrEqualTo: labelView.trailingAnchor,
                    constant: DesignTokens.Spacing.tight
                ),
                checkView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.Spacing.relaxed),
                checkView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        }

        func configure(row: FolderSidebarRow, isCurrent: Bool) {
            iconView.image = NSImage(systemSymbolName: row.icon, accessibilityDescription: nil)
            iconView.contentTintColor = row.isDirectoryLike
                ? .controlAccentColor
                : (isCurrent ? .controlAccentColor : .secondaryLabelColor)
            labelView.stringValue = row.displayName
            labelView.textColor = row
                .isParentRow ? .secondaryLabelColor : (isCurrent ? .labelColor : .secondaryLabelColor)
            labelView.font = isCurrent
                ? .systemFont(ofSize: DesignTokens.Typography.bodySmall, weight: .medium)
                : .systemFont(ofSize: DesignTokens.Typography.bodySmall)
            checkView.isHidden = !isCurrent || row.isParentRow
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

private func normalizedPath(_ path: String) -> String {
    URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
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
            return lhs.isDirectory && !rhs.isDirectory
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    return FolderScanResult(items: items)
}

#Preview {
    FolderSidebarView(fileURL: URL(fileURLWithPath: "/Users/user/Documents/file.md"))
        .frame(width: 250, height: 400)
}
