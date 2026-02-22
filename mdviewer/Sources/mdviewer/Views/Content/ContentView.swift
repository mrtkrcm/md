//
//  ContentView.swift
//  mdviewer
//
//  Main content container that composes reader, editor, and toolbar views.
//

internal import SwiftUI
internal import OSLog
#if os(macOS)
    @preconcurrency internal import AppKit
#endif

/// Main content view that coordinates document display, editing, and toolbar.
@MainActor
struct ContentView: View {
    @Binding var document: MarkdownDocument

    @Environment(\.preferences) private var preferences
    @Environment(\.openDocument) private var openDocument
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var showStartupWelcome = true
    @State private var openErrorMessage: String?
    @State private var topBarManager = TopBarVisibilityManager()
    @State private var showMetadataInspector = false

    private let logger = Logger(subsystem: "mdviewer", category: "ui")

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
        MarkdownEditor(preferences: preferences)
    }

    private var editorActions: EditorActions {
        EditorActions(
            insertBold: { markdownEditor.insertSyntax(wrap: "**") },
            insertItalic: { markdownEditor.insertSyntax(wrap: "*") },
            insertCodeBlock: { markdownEditor.insertSyntax(prefix: "\n```\n", suffix: "\n```\n") },
            insertLink: { markdownEditor.insertSyntax(prefix: "[", suffix: "](url)") },
            insertImage: { markdownEditor.insertSyntax(prefix: "![", suffix: "](image-url)") },
            showAppearanceSettings: { topBarManager.showAppearancePopover = true }
        )
    }

    // MARK: - Body

    var body: some View {
        let parsed = FrontmatterParser.parse(document.text)

        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if showStartupWelcome && document.isEffectivelyEmpty {
                WelcomeStartView(
                    openAction: documentOps.openFromDisk,
                    useStarterAction: documentOps.resetToStarter
                )
                .padding(.top, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                ReaderContentView(
                    document: $document,
                    parsed: parsed,
                    preferences: preferences,
                    colorScheme: colorScheme
                )
                .transition(.opacity)
            }

            TopBarOverlay(
                frontmatter: parsed.frontmatter,
                preferences: preferences,
                topBarManager: topBarManager,
                documentOps: documentOps,
                documentText: document.text
            )
        }
        .preferredColorScheme(preferences.effectiveColorScheme)
        .toolbar {
            ContentToolbar(
                preferences: preferences,
                showAppearancePopover: $topBarManager.showAppearancePopover,
                showMetadataInspector: $showMetadataInspector,
                documentText: document.text
            )
        }
        .inspector(isPresented: $showMetadataInspector) {
            if let frontmatter = parsed.frontmatter,
               !frontmatter.rawYAML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                InspectorMetadataView(frontmatter: frontmatter)
                    .inspectorColumnWidth(min: 200, ideal: 280, max: 400)
            } else {
                ContentUnavailableView {
                    Label("No Metadata", systemImage: "tag.slash")
                } description: {
                    Text("This document has no YAML frontmatter")
                }
                .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
            }
        }
        .focusedSceneValue(\.editorActions, editorActions)
        .onAppear {
            if !document.isEffectivelyEmpty {
                showStartupWelcome = false
            }
            topBarManager.registerInteraction()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                topBarManager.registerInteraction()
            } else {
                topBarManager.cleanup()
            }
        }
        .onChange(of: topBarManager.showAppearancePopover) { _, shown in
            topBarManager.handlePopoverChange(isPresented: shown)
        }
        .onDisappear {
            topBarManager.cleanup()
        }
        .popover(isPresented: $topBarManager.showAppearancePopover, arrowEdge: .top) {
            AppearancePopover(
                preferences: preferences
            )
        }
        .alert("Unable to Open Document", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(openErrorMessage ?? "An unexpected error occurred while opening the document.")
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

/// Displays the main reader/editor content based on current mode.
private struct ReaderContentView: View {
    @Binding var document: MarkdownDocument
    let parsed: ParsedMarkdown
    let preferences: AppPreferences
    let colorScheme: ColorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LiquidBackground()
                    .ignoresSafeArea()

                Group {
                    if preferences.readerMode == .rendered {
                        renderedContent(geometry: geometry)
                    } else {
                        rawContent
                    }
                }
                .padding(.top, geometry.safeAreaInsets.top + 42)
                .smoothAnimation(preferences.readerMode)
                .smoothAnimation(preferences.readerFontSize)
                .smoothAnimation(preferences.readerColumnWidth)
            }
        }
    }

    @ViewBuilder
    private func renderedContent(geometry: GeometryProxy) -> some View {
        NativeMarkdownTextView(
            markdown: parsed.renderedMarkdown,
            readerFontFamily: preferences.readerFontFamily,
            readerFontSize: preferences.readerFontSize.points,
            codeFontSize: CGFloat(preferences.codeFontSize.rawValue),
            appTheme: preferences.theme,
            syntaxPalette: preferences.syntaxPalette,
            colorScheme: preferences.effectiveColorScheme ?? colorScheme,
            textSpacing: preferences.readerTextSpacing,
            readableWidth: min(preferences.readerColumnWidth.points, geometry.size.width - 48)
        )
        .id("rendered_\(preferences.theme)_\(preferences.readerFontFamily)_\(preferences.readerFontSize)")
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98)),
            removal: .opacity
        ))
    }

    @ViewBuilder
    private var rawContent: some View {
        RawMarkdownEditor(
            text: $document.text,
            fontFamily: preferences.readerFontFamily,
            fontSize: preferences.readerFontSize.points,
            syntaxPalette: preferences.syntaxPalette,
            colorScheme: preferences.effectiveColorScheme ?? colorScheme
        )
        .id("raw_\(preferences.readerFontFamily)_\(preferences.readerFontSize)")
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
}

/// Floating top bar overlay with metadata and toolbar.
private struct TopBarOverlay: View {
    let frontmatter: Frontmatter?
    let preferences: AppPreferences
    @Bindable var topBarManager: TopBarVisibilityManager
    let documentOps: DocumentOperations
    let documentText: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.relaxed) {
                metadataSection
                Spacer(minLength: 20)
                toolbarSection
            }
            .padding(.top, DesignTokens.Spacing.topBarTop)
            .padding(.horizontal, DesignTokens.Spacing.topBarHorizontal)

            Spacer()
        }
        .overlay(alignment: .top) {
            revealZone
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        if preferences.readerMode == .rendered,
           let frontmatter,
           !frontmatter.rawYAML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            FloatingMetadataView(frontmatter: frontmatter)
                .zIndex(10)
                .opacity(topBarManager.shouldShow ? 1 : 0)
                .allowsHitTesting(topBarManager.shouldShow)
                .liquidAnimation(topBarManager.shouldShow)
                .onHover { hovering in
                    topBarManager.isHoveringTopBar = hovering
                    if hovering { topBarManager.registerInteraction() } else { topBarManager.scheduleHide() }
                }
        }
    }

    @ViewBuilder
    private var toolbarSection: some View {
        TopBarView(
            showAppearancePopover: $topBarManager.showAppearancePopover,
            readerMode: preferenceBinding(\.readerMode),
            openAction: documentOps.openFromDisk,
            shareItem: documentText
        )
        .onHover { hovering in
            topBarManager.isHoveringTopBar = hovering
            if hovering { topBarManager.registerInteraction() } else { topBarManager.scheduleHide() }
        }
        .opacity(topBarManager.shouldShow ? 1 : 0)
        .allowsHitTesting(topBarManager.shouldShow)
        .liquidAnimation(topBarManager.shouldShow)
    }

    @ViewBuilder
    private var revealZone: some View {
        Color.clear
            .frame(height: DesignTokens.Layout.revealZoneHeight)
            .contentShape(Rectangle())
            .onHover { hovering in
                topBarManager.isHoveringRevealZone = hovering
                if hovering { topBarManager.registerInteraction() } else { topBarManager.scheduleHide() }
            }
    }

    private func preferenceBinding<T>(_ keyPath: ReferenceWritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { preferences[keyPath: keyPath] = $0 }
        )
    }
}

/// Toolbar content for the content view.
private struct ContentToolbar: ToolbarContent {
    let preferences: AppPreferences
    @Binding var showAppearancePopover: Bool
    @Binding var showMetadataInspector: Bool
    let documentText: String

    var body: some ToolbarContent {
        ToolbarItem(id: "mode", placement: .navigation) {
            Picker("Mode", selection: preferenceBinding(\.readerMode)) {
                Image(systemName: "eye")
                    .help("Rendered View")
                    .tag(ReaderMode.rendered)
                Image(systemName: "pencil.line")
                    .help("Raw Markdown")
                    .tag(ReaderMode.raw)
            }
            .pickerStyle(.segmented)
            .help("Switch between rendered and raw view")
            .accessibilityLabel("Reader Mode")
            .accessibilityHint("Switch between rendered and raw markdown view")
        }

        ToolbarItem(id: "metadata", placement: .secondaryAction) {
            Button(action: { showMetadataInspector.toggle() }) {
                Image(systemName: "sidebar.right")
            }
            .help("Toggle Metadata Panel")
            .accessibilityLabel("Metadata Panel")
            .accessibilityHint("Show or hide document metadata inspector")
        }

        ToolbarItem(id: "appearance", placement: .primaryAction) {
            Button(action: { showAppearancePopover = true }) {
                Image(systemName: "paintbrush")
            }
            .help("Appearance Settings")
            .accessibilityLabel("Appearance Settings")
            .accessibilityHint("Open appearance and typography settings")
        }

        ToolbarItem(id: "share", placement: .primaryAction) {
            ShareLink(item: documentText) {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Share Document")
            .accessibilityLabel("Share Document")
            .accessibilityHint("Share the current markdown document")
        }
    }

    private func preferenceBinding<T>(_ keyPath: ReferenceWritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { preferences[keyPath: keyPath] = $0 }
        )
    }
}

/// Appearance popover wrapper that creates bindings from preferences.
private struct AppearancePopover: View {
    let preferences: AppPreferences

    var body: some View {
        AppearancePopoverView(
            selectedTheme: preferenceBinding(\.theme),
            readerFontSize: preferenceBinding(\.readerFontSize),
            readerFontFamily: preferenceBinding(\.readerFontFamily),
            syntaxPalette: preferenceBinding(\.syntaxPalette),
            codeFontSize: preferenceBinding(\.codeFontSize),
            appearanceMode: preferenceBinding(\.appearanceMode),
            readerTextSpacing: preferenceBinding(\.readerTextSpacing),
            readerColumnWidth: preferenceBinding(\.readerColumnWidth)
        )
    }

    private func preferenceBinding<T>(_ keyPath: ReferenceWritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { preferences[keyPath: keyPath] = $0 }
        )
    }
}
