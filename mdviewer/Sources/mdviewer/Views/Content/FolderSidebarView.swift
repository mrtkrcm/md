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

/// Sidebar showing folder contents
@MainActor
struct FolderSidebarView: View {
    let fileURL: URL
    let onOpenFile: ((URL) -> Void)?

    @Environment(\.openDocument) private var openDocument
    @State private var items: [FolderItem] = []
    @State private var currentFilePath: String = ""
    @State private var isLoading = false
    @State private var didReachItemLimit = false

    init(fileURL: URL, onOpenFile: ((URL) -> Void)? = nil) {
        self.fileURL = fileURL
        self.onOpenFile = onOpenFile
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()
            contentView
        }
        .onAppear {
            currentFilePath = fileURL.path
            loadContents()
        }
        .onChange(of: fileURL) { _, newURL in
            currentFilePath = newURL.path
            loadContents()
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
        if isLoading {
            loadingView
        } else if items.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        rowView(for: item)
                    }
                }
            }
        }
    }

    private func rowView(for item: FolderItem) -> some View {
        let isCurrent = item.path == currentFilePath

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
            handleTap(item)
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
        if didReachItemLimit {
            return "Showing \(items.count) of \(maxFolderItems)+"
        }
        return "\(items.count) item\(items.count == 1 ? "" : "s")"
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

    private func loadContents() {
        isLoading = true

        Task { @MainActor in
            let folderURL = fileURL.deletingLastPathComponent()

            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try scanFolderItems(at: folderURL, limit: maxFolderItems)
                }.value
                items = result.items
                didReachItemLimit = result.didReachLimit
            } catch {
                items = []
                didReachItemLimit = false
            }
            isLoading = false
        }
    }

    private func handleTap(_ item: FolderItem) {
        if item.isDirectory {
            NSWorkspace.shared.open(item.url)
            return
        }

        let isCmd = NSApp.currentEvent?.modifierFlags.contains(.command) ?? false

        if isCmd {
            Task { try? await openDocument(at: item.url) }
        } else {
            currentFilePath = item.path
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
    let contents = try FileManager.default.contentsOfDirectory(
        at: folderURL,
        includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
    )

    let filtered = contents.compactMap(FolderItem.init(url:))
    let sorted = filtered.sorted {
        if $0.isDirectory != $1.isDirectory {
            return $0.isDirectory && !$1.isDirectory
        }
        return $0.name.localizedStandardCompare($1.name) == .orderedAscending
    }

    return FolderScanResult(
        items: Array(sorted.prefix(limit)),
        didReachLimit: sorted.count > limit
    )
}

#Preview {
    FolderSidebarView(fileURL: URL(fileURLWithPath: "/Users/user/Documents/file.md"))
        .frame(width: 250, height: 400)
}
