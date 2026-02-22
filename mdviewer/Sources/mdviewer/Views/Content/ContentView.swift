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
    @State private var showMetadataInspector = false
    @State private var showAppearancePopover = false

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
            showAppearanceSettings: { showAppearancePopover = true }
        )
    }

    // MARK: - Body

    var body: some View {
        let parsed = FrontmatterParser.parse(document.text)

        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if showStartupWelcome, document.isEffectivelyEmpty {
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
        }
        .preferredColorScheme(preferences.effectiveColorScheme)
        .toolbar {
            ContentToolbar(
                preferences: preferences,
                showAppearancePopover: $showAppearancePopover,
                showMetadataInspector: $showMetadataInspector,
                openAction: documentOps.openFromDisk,
                documentText: document.text
            )
        }
        .inspector(isPresented: $showMetadataInspector) {
            if let metadataView = InspectorMetadataView(frontmatter: parsed.frontmatter) {
                metadataView
                    .inspectorColumnWidth(min: 220, ideal: 280, max: 400)
            } else {
                MetadataEmptyView {
                    showMetadataInspector = false
                }
                .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
            }
        }
        .focusedSceneValue(\.editorActions, editorActions)
        .onAppear {
            if !document.isEffectivelyEmpty {
                showStartupWelcome = false
            }
        }
        .popover(isPresented: $showAppearancePopover, arrowEdge: .top) {
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
                .padding(.top, geometry.safeAreaInsets.top + 8)
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

/// Toolbar content for the content view.
private struct ContentToolbar: ToolbarContent {
    let preferences: AppPreferences
    @Binding var showAppearancePopover: Bool
    @Binding var showMetadataInspector: Bool
    let openAction: () -> Void
    let documentText: String

    var body: some ToolbarContent {
        // Mode picker - principal placement for centered importance
        ToolbarItem(id: "mode", placement: .principal) {
            Picker("Mode", selection: preferenceBinding(\.readerMode)) {
                Image(systemName: "eye")
                    .help("Rendered View")
                    .tag(ReaderMode.rendered)
                Image(systemName: "pencil.line")
                    .help("Raw Markdown")
                    .tag(ReaderMode.raw)
            }
            .pickerStyle(.segmented)
            .controlSize(.small)
            .help("Switch between rendered and raw view")
            .accessibilityLabel("Reader Mode")
            .accessibilityHint("Switch between rendered and raw markdown view")
        }

        // Trailing action items - organized in logical order
        ToolbarItem(id: "metadata", placement: .automatic) {
            Button(action: { showMetadataInspector.toggle() }) {
                Image(systemName: "sidebar.right")
            }
            .help("Toggle Metadata Panel")
            .accessibilityLabel("Metadata Panel")
            .accessibilityHint("Show or hide document metadata inspector")
        }

        ToolbarItem(id: "appearance", placement: .automatic) {
            Button(action: { showAppearancePopover = true }) {
                Image(systemName: "paintbrush")
            }
            .help("Appearance Settings")
            .accessibilityLabel("Appearance Settings")
            .accessibilityHint("Open appearance and typography settings")
        }

        ToolbarItem(id: "share", placement: .automatic) {
            ShareLink(item: documentText) {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Share Document")
            .accessibilityLabel("Share Document")
            .accessibilityHint("Share the current markdown document")
        }

        ToolbarItem(id: "open", placement: .automatic) {
            Button(action: openAction) {
                Image(systemName: "folder")
            }
            .help("Open markdown file")
            .accessibilityLabel("Open File")
            .accessibilityHint("Open a markdown file from disk")
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

/// Empty state view for metadata inspector with helpful actions.
private struct MetadataEmptyView: View {
    let onDismiss: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Metadata", systemImage: "tag.slash")
        } description: {
            Text("This document has no YAML frontmatter")
        } actions: {
            Button("Close Inspector") {
                onDismiss()
            }
            .controlSize(.small)
        }
    }
}
