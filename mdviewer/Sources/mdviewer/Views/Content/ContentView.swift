//
//  ContentView.swift
//  mdviewer
//
//  Main content container that composes reader, editor, and toolbar views.
//

internal import Foundation
internal import OSLog
internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Performance Signpost Logging

/// Signpost logger for UI performance profiling with Instruments.
/// Use the Core Animation or Time Profiler template to visualize these intervals.
private let uiPerformanceLog = OSSignposter(subsystem: "mdviewer", category: "UIPerformance")

// MARK: - Content View

/// Sidebar content mode.
enum SidebarMode: String, CaseIterable, Sendable {
    case toc = "toc_view"
    case metadata = "metadata_view"
    case folder = "folder_view"
}

/// Main content view that coordinates document display, editing, and toolbar.
@MainActor
struct ContentView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?

    @Environment(\.preferences) private var preferences
    @Environment(\.openDocument) private var openDocument
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showStartupWelcome = true
    @State private var openErrorMessage: String?
    @State private var showMetadataInspector = false
    @State private var sidebarMode: SidebarMode = .toc
    @State private var sidebarWidth: CGFloat = DesignTokens.Component.Sidebar.idealWidth
    @State private var parseDebounceTask: Task<Void, Never>?
    @State private var activeFileURL: URL?
    @State private var sidebarRootFileURL: URL?
    @State private var parsedMarkdown: ParsedMarkdown?
    @State private var debouncedTheme: AppTheme?
    @State private var themeDebounceTask: Task<Void, Never>?
    @SceneStorage("windowReaderMode") private var windowReaderModeRaw = ReaderMode.rendered.rawValue

    private let logger = Logger(subsystem: "mdviewer", category: "ui")

    private var windowReaderMode: ReaderMode {
        get { ReaderMode.from(rawValue: windowReaderModeRaw) }
        nonmutating set { windowReaderModeRaw = newValue.rawValue }
    }

    /// Effective theme with debouncing for rapid changes.
    /// Uses debouncedTheme when available, otherwise falls back to preferences.theme.
    private var effectiveTheme: AppTheme {
        debouncedTheme ?? preferences.theme
    }

    /// Effective parsed document state, ensures we always have a valid result
    private var currentParsed: ParsedMarkdown {
        parsedMarkdown ?? FrontmatterParser.parse(document.text)
    }

    // MARK: - Helpers

    private var documentOps: DocumentOperations {
        DocumentOperations(
            document: $document,
            openDocument: openDocument,
            onError: { openErrorMessage = $0 },
            onSuccess: { showStartupWelcome = false }
        )
    }

    private var markdownEditor: MarkdownEditor {
        MarkdownEditor(
            getReaderMode: { windowReaderMode },
            setReaderMode: { windowReaderMode = $0 }
        )
    }

    private var editorActions: EditorActions {
        EditorActions(
            insertBold: { markdownEditor.insertSyntax(wrap: "**") },
            insertItalic: { markdownEditor.insertSyntax(wrap: "*") },
            insertCodeBlock: { markdownEditor.insertSyntax(prefix: "\n```\n", suffix: "\n```\n") },
            insertLink: { markdownEditor.insertSyntax(prefix: "[", suffix: "](url)") },
            insertImage: { markdownEditor.insertSyntax(prefix: "![", suffix: "](image-url)") },
            setRenderedMode: { windowReaderMode = .rendered },
            setRawMode: { windowReaderMode = .raw },
            jumpToLine: { lineIndex in
                NotificationCenter.default.post(
                    name: NSNotification.Name("JumpToLine"),
                    object: nil,
                    userInfo: ["lineIndex": lineIndex]
                )
            }
        )
    }

    // MARK: - Body

    var body: some View {
        let parsed = currentParsed
        contentScaffold(parsed: parsed)
    }

    @ViewBuilder
    private func contentScaffold(parsed: ParsedMarkdown) -> some View {
        ZStack(alignment: .trailing) {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            // Main content with padding matching the sidebar width when visible
            mainContent(parsed: parsed)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: .top)
                .padding(.trailing, showMetadataInspector ? sidebarWidth : 0)
                // Temporarily disable implicit animations on the layout frame to prevent
                // continuous wrapping/unwrapping text relayouts while the sidebar slides.
                .animation(nil, value: showMetadataInspector)

            // Keep the sidebar mounted so showing it does not rebuild the entire
            // inspector hierarchy on demand, which was still visible as a choppy reveal.
            InspectorSidebar(
                frontmatter: parsed.frontmatter,
                documentText: document.text,
                isPresented: $showMetadataInspector,
                sidebarMode: $sidebarMode,
                currentFileURL: activeFileURL,
                folderRootFileURL: sidebarRootFileURL,
                onOpenFile: openFileInCurrentWindow
            )
            .frame(width: sidebarWidth)
            .frame(maxHeight: .infinity, alignment: .top)
            .frame(width: showMetadataInspector ? sidebarWidth : 0, alignment: .trailing)
            .clipped()
            .allowsHitTesting(showMetadataInspector)
            .accessibilityHidden(!showMetadataInspector)
            .animation(nil, value: showMetadataInspector)
        }
        .preferredColorScheme(preferences.effectiveColorScheme)
        .onChange(of: document.text) { _, newValue in
            // Debounce frontmatter parsing during rapid edits to avoid
            // blocking the main thread every keystroke.
            parseDebounceTask?.cancel()
            parseDebounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                parsedMarkdown = FrontmatterParser.parse(newValue)
            }
        }
        .task(id: fileURL) {
            // Re-parse when switching files to ensure metadata is fresh
            parsedMarkdown = FrontmatterParser.parse(document.text)
        }
        .onChange(of: windowReaderMode) { _, newMode in
            AccessibilityAnnouncement.modeChanged(to: newMode == .rendered)
        }
        .onChange(of: fileURL) { _, newURL in
            activeFileURL = newURL
            if sidebarRootFileURL == nil {
                sidebarRootFileURL = newURL
            }
            FolderSidebarPreloader.prewarmIfNeeded(fileURL: newURL)
        }
        .onChange(of: sidebarMode) { _, newMode in
            if preferences.sidebarMode != newMode {
                preferences.sidebarMode = newMode
            }
        }
        .onChange(of: preferences.theme) { _, newTheme in
            // Debounce theme changes to prevent rapid re-renders when cycling themes.
            // This improves performance across multiple windows.
            themeDebounceTask?.cancel()
            themeDebounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                debouncedTheme = newTheme
            }
        }
        .toolbar {
            contentToolbar(parsed: parsed)
        }
        .focusedSceneValue(\.editorActions, editorActions)
        .onAppear {
            if parsedMarkdown == nil {
                parsedMarkdown = FrontmatterParser.parse(document.text)
            }
            if windowReaderModeRaw.isEmpty {
                windowReaderModeRaw = preferences.readerMode.rawValue
            }
            if sidebarMode != preferences.sidebarMode {
                sidebarMode = preferences.sidebarMode
            }
            if !document.isEffectivelyEmpty {
                showStartupWelcome = false
            }
            if activeFileURL == nil {
                activeFileURL = fileURL
            }
            if sidebarRootFileURL == nil {
                sidebarRootFileURL = fileURL
            }
            // Initialize debounced theme to match current preference
            if debouncedTheme == nil {
                debouncedTheme = preferences.theme
            }
            FolderSidebarPreloader.prewarmIfNeeded(fileURL: activeFileURL)
        }
        .alert("Unable to Open Document", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(openErrorMessage ?? "An unexpected error occurred while opening the document.")
        }
    }

    @ToolbarContentBuilder
    private func contentToolbar(parsed: ParsedMarkdown) -> some ToolbarContent {
        ContentToolbar(
            readerMode: Binding(get: { windowReaderMode }, set: { windowReaderMode = $0 }),
            showMetadataInspector: $showMetadataInspector,
            sidebarMode: $sidebarMode,
            documentText: document.text,
            hasFrontmatter: parsed.frontmatter != nil,
            fileURL: activeFileURL
        )
    }

    // MARK: - File Opening

    /// Opens a file in the current window by replacing document content.
    private func openFileInCurrentWindow(url: URL) {
        guard url.path != activeFileURL?.path else {
            // Already open
            return
        }

        Task {
            do {
                // Perform file size check, I/O, and string decoding off the main thread
                let fileText = try await Task.detached(priority: .userInitiated) {
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0

                    guard fileSize <= MarkdownDocument.maxReadableFileSizeBytes else {
                        throw CocoaError(.fileReadTooLarge)
                    }

                    let data = try Data(contentsOf: url)
                    guard let text = MarkdownDocument.decode(data: data) else {
                        throw CocoaError(.fileReadUnknown)
                    }

                    return text
                }.value

                // Update UI state on the main thread
                await MainActor.run {
                    document.text = fileText
                    showStartupWelcome = false
                    activeFileURL = url
                    if sidebarRootFileURL == nil {
                        sidebarRootFileURL = url
                    }

                    // Synchronize current window metadata and clear edited state for the newly loaded file.
                    if let window = NSApp.keyWindow ?? NSApp.mainWindow {
                        window.representedURL = url
                        window.title = url.lastPathComponent
                        if let nsDocument = window.windowController?.document {
                            // Keep NSDocument identity in sync so titlebar/status UI updates to the opened file.
                            let selector = NSSelectorFromString("setFileURL:")
                            if nsDocument.responds(to: selector) {
                                _ = nsDocument.perform(selector, with: url)
                            }
                            nsDocument.undoManager?.removeAllActions()
                            nsDocument.updateChangeCount(.changeCleared)
                        }
                    }
                }
            } catch let error as CocoaError where error.code == .fileReadTooLarge {
                await MainActor.run { openErrorMessage = "File is too large to open." }
            } catch let error as CocoaError where error.code == .fileReadUnknown {
                await MainActor.run { openErrorMessage = "Unable to decode file content." }
            } catch {
                await MainActor.run {
                    logger.error("Failed to open file: \(error.localizedDescription)")
                    openErrorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(parsed: ParsedMarkdown) -> some View {
        ZStack {
            if showStartupWelcome, document.isEffectivelyEmpty {
                WelcomeStartView(
                    openAction: documentOps.openFromDisk,
                    useStarterAction: documentOps.resetToStarter
                )
                .padding(.top, 12)
                .transition(reduceMotion ? .opacity : .elegantSlide(from: .bottom))
            } else {
                ReaderContentView(
                    document: $document,
                    parsed: parsed,
                    readerMode: Binding(get: { windowReaderMode }, set: { windowReaderMode = $0 }),
                    colorScheme: colorScheme,
                    reduceMotion: reduceMotion,
                    onScroll: { _, _, _ in },
                    appTheme: effectiveTheme
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - Bindings

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { openErrorMessage != nil },
            set: { if !$0 { openErrorMessage = nil } }
        )
    }
}

// MARK: - Subviews

/// Signpost logger for document rendering performance profiling.
private let renderSignposter = OSSignposter(subsystem: "mdviewer", category: "DocumentRender")

/// Displays the main reader/editor content based on current mode.
private struct ReaderContentView: View {
    @Binding var document: MarkdownDocument
    let parsed: ParsedMarkdown
    @Binding var readerMode: ReaderMode
    @Environment(\.preferences) private var preferences
    let colorScheme: ColorScheme
    let reduceMotion: Bool
    let onScroll: (CGFloat, CGFloat, CGFloat) -> Void
    let appTheme: AppTheme

    /// Namespace for matched geometry effects between modes
    @Namespace private var animationNamespace

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LiquidBackground()
                    .ignoresSafeArea()

                contentView(geometry: geometry)
                    .matchedGeometryEffect(id: "contentContainer", in: animationNamespace)
            }
        }
    }

    @ViewBuilder
    private func contentView(geometry: GeometryProxy) -> some View {
        Group {
            switch readerMode {
            case .rendered:
                renderedContent(geometry: geometry)
                    .matchedGeometryEffect(id: "editorContent", in: animationNamespace)
                    .onAppear {
                        renderSignposter.emitEvent("RenderedModeAppeared")
                    }
                    .transition(.liquidMorph)

            case .raw:
                rawContent(geometry: geometry)
                    .matchedGeometryEffect(id: "editorContent", in: animationNamespace)
                    .onAppear {
                        renderSignposter.emitEvent("RawModeAppeared")
                    }
                    .transition(.liquidMorph)
            }
        }
        .animation(reduceMotion ? .linear(duration: 0.01) : DesignTokens.AnimationPreset.medium, value: readerMode)
    }

    @ViewBuilder
    private func renderedContent(geometry: GeometryProxy) -> some View {
        NativeMarkdownTextView(
            markdown: parsed.renderedMarkdown,
            readerFontFamily: preferences.readerFontFamily,
            readerFontSize: preferences.readerFontSize.points,
            codeFontSize: preferences.codeFontSize.points,
            appTheme: appTheme,
            colorScheme: preferences.effectiveColorScheme ?? colorScheme,
            textSpacing: preferences.readerTextSpacing,
            readableWidth: min(
                preferences.readerColumnWidth.points,
                geometry.size.width - (preferences.readerContentPadding.points * 2)
            ),
            contentPadding: preferences.readerContentPadding.points,
            showLineNumbers: preferences.showLineNumbers,
            typographyPreferences: preferences.typographyPreferences,
            onScroll: onScroll
        )
        .accessibleAnimation(
            reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.2),
            value: preferences.readerFontSize,
            reduceMotion: reduceMotion
        )
        .accessibleAnimation(
            reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.2),
            value: preferences.readerColumnWidth,
            reduceMotion: reduceMotion
        )
        .accessibleAnimation(
            reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.2),
            value: preferences.readerContentPadding,
            reduceMotion: reduceMotion
        )
    }

    @ViewBuilder
    private func rawContent(geometry: GeometryProxy) -> some View {
        RawMarkdownEditor(
            text: $document.text,
            fontSize: preferences.readerFontSize.points,
            colorScheme: preferences.effectiveColorScheme ?? colorScheme,
            showLineNumbers: preferences.showLineNumbers,
            contentPadding: preferences.readerContentPadding.points,
            onScroll: onScroll
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibleAnimation(
            reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.2),
            value: preferences.readerFontSize,
            reduceMotion: reduceMotion
        )
        .accessibleAnimation(
            reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.2),
            value: preferences.readerContentPadding,
            reduceMotion: reduceMotion
        )
        // Raw editor uses full available space without top padding
        .padding(.top, 0)
    }
}

/// Unified inspector sidebar that handles metadata and folder views.
/// Uses static content rendering for immediate appearance.
private struct InspectorSidebar: View {
    let frontmatter: Frontmatter?
    let documentText: String
    @Binding var isPresented: Bool
    @Binding var sidebarMode: SidebarMode
    let currentFileURL: URL?
    let folderRootFileURL: URL?
    let onOpenFile: (URL) -> Void
    @Environment(\.colorScheme) private var colorScheme

    /// Cache document stats to avoid recomputing on every render
    @State private var cachedDocumentStats: DocumentStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inspectorHeader
            inspectorContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
        }
        .frame(
            minWidth: DesignTokens.Component.Sidebar.minWidth,
            idealWidth: DesignTokens.Component.Sidebar.idealWidth,
            maxWidth: DesignTokens.Component.Sidebar.maxWidth,
            maxHeight: .infinity,
            alignment: .top
        )
        .modifier(SidebarPanelBackgroundModifier())
        .overlay(alignment: .leading) {
            sidebarLeadingEdge
        }
        .clipShape(sidebarClipShape)
        .task(id: documentText) {
            await computeStats(text: documentText, url: currentFileURL)
        }
        .task(id: currentFileURL) {
            await computeStats(text: documentText, url: currentFileURL)
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        switch sidebarMode {
        case .toc:
            TableOfContentsView(documentURL: currentFileURL) { heading in
                NotificationCenter.default.post(
                    name: NSNotification.Name("JumpToLine"),
                    object: nil,
                    userInfo: [
                        "headingIndex": heading.headingIndex,
                        "lineIndex": heading.lineIndex,
                    ]
                )
            }
        case .folder:
            folderContent
        case .metadata:
            metadataContent
        }
    }

    private var inspectorHeader: some View {
        HStack(spacing: 0) {
            InspectorSidebarModeControl(sidebarMode: $sidebarMode)
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: DesignTokens.Spacing.compact)

            InspectorSidebarIconButton(systemImage: "xmark", accessibilityLabel: "Close Inspector") {
                isPresented = false
            }
            .accessibilityHint("Close the inspector panel")
        }
        .padding(.horizontal, DesignTokens.Component.Sidebar.contentInset)
        .padding(.top, DesignTokens.Spacing.standard)
        .padding(.bottom, DesignTokens.Spacing.standard)
    }

    private var sidebarLeadingEdge: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(colorScheme == .dark ? 0.12 : 0.2))
            .frame(width: DesignTokens.Component.Sidebar.borderLineWidth)
    }

    private var sidebarClipShape: some Shape {
        Rectangle()
    }

    private func computeStats(text: String, url: URL?) async {
        // Run intensive text processing and disk I/O off the main thread
        let stats = await Task.detached(priority: .utility) {
            DocumentStats(documentText: text, fileURL: url)
        }.value

        // Update main thread state once calculation finishes
        await MainActor.run {
            cachedDocumentStats = stats
        }
    }

    @ViewBuilder
    private var metadataContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let frontmatter {
                    ForEach(frontmatter.entries, id: \.key) { entry in
                        MetadataRow(entry: entry)
                    }
                    Divider()
                        .padding(.vertical, DesignTokens.Spacing.standard)
                        .padding(.horizontal, DesignTokens.Spacing.extraWide)
                } else {
                    EmptyMetadataState()
                }

                if let stats = cachedDocumentStats {
                    DocumentStatsSection(stats: stats)
                }
            }
        }
    }

    @ViewBuilder
    private var folderContent: some View {
        if let currentFileURL {
            FolderSidebarView(
                currentFileURL: currentFileURL,
                rootFileURL: folderRootFileURL,
                onOpenFile: onOpenFile
            )
        } else {
            EmptyFolderState()
        }
    }
}

/// Background modifier that applies native Liquid Glass on macOS 26+,
/// falling back to a clean material on older systems.
private struct SidebarPanelBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect)
        } else {
            content
                .background(.ultraThinMaterial)
        }
    }
}

private struct InspectorSidebarModeControl: View {
    @Binding var sidebarMode: SidebarMode
    @State private var hoveredMode: SidebarMode?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.tight) {
            modeButton(.toc, systemImage: "list.bullet", accessibilityLabel: "Table of Contents")
            modeButton(.metadata, systemImage: "info.circle", accessibilityLabel: "Metadata View")
            modeButton(.folder, systemImage: "folder", accessibilityLabel: "Folder View")
        }
    }

    private func modeButton(
        _ mode: SidebarMode,
        systemImage: String,
        accessibilityLabel: String
    ) -> some View {
        let isSelected = sidebarMode == mode
        let isHovered = hoveredMode == mode

        return Button {
            sidebarMode = mode
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: DesignTokens.Typography.bodySmall, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .tertiary)
                .frame(
                    width: DesignTokens.Component.Button.heightSmall,
                    height: DesignTokens.Component.Button.heightSmall
                )
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                        .fill(isSelected
                            ? Color(nsColor: .controlAccentColor).opacity(colorScheme == .dark ? 0.14 : 0.10)
                            : isHovered
                            ? Color(nsColor: .labelColor).opacity(0.04)
                            : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredMode = hovering ? mode : (hoveredMode == mode ? nil : hoveredMode)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct InspectorSidebarIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: DesignTokens.Typography.small, weight: .medium))
                .foregroundStyle(isHovered ? .secondary : .tertiary)
                .frame(
                    width: DesignTokens.Component.Button.heightSmall,
                    height: DesignTokens.Component.Button.heightSmall
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Single metadata row - pre-computed display value for performance.
private struct MetadataRow: View {
    let entry: Frontmatter.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
            Text(entry.key)
                .font(.system(size: DesignTokens.Typography.bodySmall, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(entry.key) field")
            Text(entry.displayValue)
                .font(.system(size: DesignTokens.Typography.standard))
                .textSelection(.enabled)
                .accessibilityLabel("Value: \(entry.displayValue)")
        }
        .padding(.horizontal, DesignTokens.Spacing.extraWide)
        .padding(.vertical, DesignTokens.Spacing.standard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.key): \(entry.displayValue)")
    }
}

/// Empty state for when no frontmatter exists.
private struct EmptyMetadataState: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.relaxed) {
            Image(systemName: "tag.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .accessibilityLabel("No metadata icon")
                .accessibilityHidden(true)
            Text("No Metadata")
                .font(.headline)
                .accessibilityLabel("No metadata available")
            Text("This document has no YAML frontmatter")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("This document does not contain YAML frontmatter metadata")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, DesignTokens.Spacing.extraWide)
        .padding(.vertical, DesignTokens.Spacing.extraLarge)
        .accessibilityElement(children: .contain)
    }
}

private struct DocumentStats: Sendable {
    let words: Int
    let characters: Int
    let lines: Int
    let readingTimeMinutes: Int
    let fileSizeBytes: Int64
    let lastModified: Date?

    init(documentText: String, fileURL: URL?) {
        let tokens = documentText.split(whereSeparator: \.isWhitespace)
        words = tokens.count
        characters = documentText.count
        lines = documentText.isEmpty ? 0 : documentText.split(whereSeparator: \.isNewline).count
        readingTimeMinutes = words > 0 ? max(1, Int(ceil(Double(words) / 200.0))) : 0

        if
            let fileURL,
            let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let fileSize = attributes[.size] as? NSNumber
        {
            fileSizeBytes = fileSize.int64Value
            lastModified = attributes[.modificationDate] as? Date
        } else {
            fileSizeBytes = Int64(documentText.utf8.count)
            lastModified = nil
        }
    }
}

private struct DocumentStatsSection: View {
    let stats: DocumentStats

    private static let fileSizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Document Stats")
                .font(.system(size: DesignTokens.Typography.standard, weight: .semibold))
                .padding(.horizontal, DesignTokens.Spacing.extraWide)
                .padding(.bottom, DesignTokens.Spacing.standard)
                .accessibilityAddTraits(.isHeader)

            StatsRow(label: "Words", value: "\(stats.words)", numericTransition: true)
            StatsRow(label: "Characters", value: "\(stats.characters)", numericTransition: true)
            StatsRow(label: "Lines", value: "\(stats.lines)", numericTransition: true)
            StatsRow(
                label: "Reading Time",
                value: stats.readingTimeMinutes > 0 ? "\(stats.readingTimeMinutes) min" : "—"
            )
            StatsRow(label: "File Size", value: Self.fileSizeFormatter.string(fromByteCount: stats.fileSizeBytes))
            StatsRow(label: "Modified", value: modifiedText, showsDivider: false)
        }
        .padding(.bottom, DesignTokens.Spacing.standard)
    }

    private var modifiedText: String {
        guard let lastModified = stats.lastModified else { return "—" }
        return Self.dateFormatter.string(from: lastModified)
    }
}

private struct StatsRow: View {
    let label: String
    let value: String
    var showsDivider: Bool = true
    var numericTransition: Bool = false

    private var contentTransition: ContentTransition {
        if numericTransition, #available(macOS 15.0, iOS 17.0, *) {
            return .numericText(countsDown: false)
        }
        return .opacity
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.standard) {
                    Text(label)
                        .font(.system(size: DesignTokens.Typography.bodySmall, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: DesignTokens.Spacing.relaxed)
                    Text(value)
                        .font(.system(size: DesignTokens.Typography.standard))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .contentTransition(contentTransition)
                        .animation(DesignTokens.AnimationPreset.fast, value: value)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                    Text(label)
                        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.system(size: DesignTokens.Typography.bodySmall))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .contentTransition(contentTransition)
                        .animation(DesignTokens.AnimationPreset.fast, value: value)
                }
            }

            if showsDivider {
                Divider()
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.extraWide)
        .padding(.vertical, DesignTokens.Spacing.standard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// Empty state for when no file URL is available.
private struct EmptyFolderState: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.relaxed) {
            Spacer()
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: DesignTokens.Typography.title))
                .foregroundStyle(.secondary)
                .accessibilityLabel("No folder icon")
                .accessibilityHidden(true)
            Text("No Folder")
                .font(.headline)
                .accessibilityLabel("No folder available")
            Text("This document is not saved to a folder")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Document is not saved to a folder")
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignTokens.Spacing.extraWide)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("Content View - Empty") {
    ContentView(document: .constant(MarkdownDocument()), fileURL: nil)
        .environment(\.preferences, AppPreferences.shared)
}

#Preview("Content View - With Content") {
    ContentView(document: .constant(MarkdownDocument(text: """
        # Hello World

        This is a **markdown** document.

        - Item 1
        - Item 2
        - Item 3

        ```swift
        let greeting = "Hello"
        debugLog(greeting)
        ```
    """)), fileURL: nil)
        .environment(\.preferences, AppPreferences.shared)
}
