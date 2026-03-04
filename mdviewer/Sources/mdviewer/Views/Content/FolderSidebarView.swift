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

/// Maximum files to show in sidebar
private let maxFolderItems = 500

/// Cache for folder scan results to avoid repeated expensive scans
private actor FolderScanCache {
    private var cache: [URL: (result: FolderScanResult, timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 30 // 30 seconds

    func get(for url: URL) -> FolderScanResult? {
        guard let cached = cache[url] else { return nil }
        if Date().timeIntervalSince(cached.timestamp) > cacheDuration {
            cache.removeValue(forKey: url)
            return nil
        }
        return cached.result
    }

    func set(_ result: FolderScanResult, for url: URL) {
        cache[url] = (result, Date())
    }

    func invalidate(for url: URL) {
        cache.removeValue(forKey: url)
    }
}

private let folderScanCache = FolderScanCache()

/// ViewModel for managing folder sidebar state and operations
@MainActor
private final class FolderViewModel: ObservableObject {
    @Published private(set) var items: [FolderItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var didReachItemLimit = false

    private let fileURL: URL
    private var currentFilePath: String = ""

    init(fileURL: URL) {
        self.fileURL = fileURL
        currentFilePath = fileURL.path
        loadContents()
    }

    func updateFileURL(_ newURL: URL) {
        guard newURL.path != currentFilePath else { return }
        currentFilePath = newURL.path
        loadContents()
    }

    private func loadContents() {
        isLoading = true

        Task { @MainActor in
            let folderURL = fileURL.deletingLastPathComponent()

            // Check cache first
            if let cachedResult = await folderScanCache.get(for: folderURL) {
                items = cachedResult.items
                didReachItemLimit = cachedResult.didReachLimit
                isLoading = false
                return
            }

            // Perform scan
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try scanFolderItems(at: folderURL, limit: maxFolderItems)
                }.value
                items = result.items
                didReachItemLimit = result.didReachLimit

                // Cache the result
                await folderScanCache.set(result, for: folderURL)
            } catch {
                items = []
                didReachItemLimit = false
            }
            isLoading = false
        }
    }
}

/// Sidebar showing folder contents
@MainActor
struct FolderSidebarView: View {
    let fileURL: URL
    let onOpenFile: ((URL) -> Void)?

    @Environment(\.openDocument) private var openDocument
    @StateObject private var viewModel: FolderViewModel

    init(fileURL: URL, onOpenFile: ((URL) -> Void)? = nil) {
        self.fileURL = fileURL
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

                Text(folderName)
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
        } else if viewModel.items.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.items) { item in
                        rowView(for: item)
                    }
                }
            }
        }
    }

    private func rowView(for item: FolderItem) -> some View {
        let isCurrent = item.path == fileURL.path

        return HStack(spacing: 6) {
            Image(systemName: item.icon)
                .foregroundStyle(iconColor(for: item, isCurrent: isCurrent))
                .font(.system(size: 13))
                .frame(width: 18, alignment: .center)

            Text(item.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(textColor(isCurrent: isCurrent))

            Spacer(minLength: 4)

            if isCurrent {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .background(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .help(item.name)
        .onTapGesture {
            // Only handle taps for files, not directories
            if !item.isDirectory {
                handleTap(item)
            }
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

    private var folderName: String {
        fileURL.deletingLastPathComponent().lastPathComponent
    }

    private var subtitleText: String {
        if viewModel.didReachItemLimit {
            return "Showing \(viewModel.items.count) of \(maxFolderItems)+"
        }
        return "\(viewModel.items.count) item\(viewModel.items.count == 1 ? "" : "s")"
    }

    // MARK: - Helpers

    private func iconColor(for item: FolderItem, isCurrent: Bool) -> Color {
        if item.isDirectory { return .accentColor }
        return isCurrent ? .accentColor : .secondary
    }

    private func textColor(isCurrent: Bool) -> Color {
        isCurrent ? .primary : .secondary
    }

    // MARK: - Actions

    private func handleTap(_ item: FolderItem) {
        if item.isDirectory {
            NSWorkspace.shared.open(item.url)
            return
        }

        let isCmd = NSApp.currentEvent?.modifierFlags.contains(.command) ?? false

        if isCmd {
            Task { try? await openDocument(at: item.url) }
        } else {
            onOpenFile?(item.url)
        }
    }
}

// MARK: - Folder Item

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
        path = url.path
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
        path = url.path
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
    let didReachLimit: Bool
}

private let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn", "mdwn", "text", "txt"]

private func scanFolderItems(at folderURL: URL, limit: Int) throws -> FolderScanResult {
    let fileManager = FileManager.default

    // First, find all folders that contain markdown files
    var foldersWithMarkdown: Set<URL> = []
    var allMarkdownFiles: [FolderItem] = []

    // Use enumerator to scan the entire directory tree
    guard
        let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: nil
        )
    else {
        return FolderScanResult(items: [], didReachLimit: false)
    }

    // Collect all markdown files and track which folders contain them
    while let url = enumerator.nextObject() as? URL {
        let ext = url.pathExtension.lowercased()

        // Only process markdown files
        guard markdownExtensions.contains(ext) || ext.isEmpty else {
            continue
        }

        // Create FolderItem for the file
        if let item = FolderItem(url: url), !item.isDirectory {
            allMarkdownFiles.append(item)

            // Mark all parent directories up to the root folder
            var currentURL = url.deletingLastPathComponent()
            while currentURL.path.hasPrefix(folderURL.path), currentURL != folderURL {
                foldersWithMarkdown.insert(currentURL)
                currentURL = currentURL.deletingLastPathComponent()
            }
        }
    }

    // Create folder items for folders that contain markdown
    var folderItems: [FolderItem] = []
    for folderURL in foldersWithMarkdown.sorted(by: { $0.path < $1.path }) {
        if let folderItem = FolderItem(url: folderURL) {
            folderItems.append(folderItem)
        }
    }

    // Combine folders and files, with folders first
    var allItems = folderItems + allMarkdownFiles

    // Sort: folders first (alphabetically), then files (alphabetically)
    allItems.sort { lhs, rhs in
        if lhs.isDirectory != rhs.isDirectory {
            return lhs.isDirectory && !rhs.isDirectory
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    // Apply the limit
    let didReachLimit = allItems.count > limit
    let finalItems = Array(allItems.prefix(limit))

    return FolderScanResult(
        items: finalItems,
        didReachLimit: didReachLimit
    )
}

#Preview {
    FolderSidebarView(fileURL: URL(fileURLWithPath: "/Users/user/Documents/file.md"))
        .frame(width: 250, height: 400)
}
