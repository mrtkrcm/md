//
//  ContentView.swift
//  mdviewer
//
//  Main content container that composes reader, editor, and toolbar views.
//

internal import SwiftUI
internal import OSLog
#if os(macOS)
    internal import AppKit
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
    @SceneStorage("windowReaderMode") private var windowReaderModeRaw = ReaderMode.rendered.rawValue

    private let logger = Logger(subsystem: "mdviewer", category: "ui")

    private var windowReaderMode: ReaderMode {
        get { ReaderMode.from(rawValue: windowReaderModeRaw) }
        nonmutating set { windowReaderModeRaw = newValue.rawValue }
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
                .transition(.elegantSlide(from: .bottom))
            } else {
                ReaderContentView(
                    document: $document,
                    parsed: parsed,
                    readerMode: Binding(get: { windowReaderMode }, set: { windowReaderMode = $0 }),
                    preferences: preferences,
                    colorScheme: colorScheme
                )
                .transition(.opacity)
                .smoothAnimation(showStartupWelcome)
            }
        }
        .preferredColorScheme(preferences.effectiveColorScheme)
        .toolbar {
            ContentToolbar(
                readerMode: Binding(get: { windowReaderMode }, set: { windowReaderMode = $0 }),
                showAppearancePopover: $showAppearancePopover,
                showMetadataInspector: $showMetadataInspector,
                openAction: documentOps.openFromDisk,
                documentText: document.text
            )
        }
        .toolbarRole(.editor)
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
            if windowReaderModeRaw.isEmpty {
                windowReaderModeRaw = preferences.readerMode.rawValue
            }
            if !document.isEffectivelyEmpty {
                showStartupWelcome = false
            }
        }
        .popover(isPresented: $showAppearancePopover, arrowEdge: .top) {
            AppearancePopover(
                preferences: preferences
            )
            .transition(.popupScale)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showAppearancePopover)
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
    @Binding var readerMode: ReaderMode
    let preferences: AppPreferences
    let colorScheme: ColorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LiquidBackground()
                    .ignoresSafeArea()

                contentView(geometry: geometry)
                    .padding(.top, max(0, geometry.safeAreaInsets.top - 4))
            }
        }
    }

    @ViewBuilder
    private func contentView(geometry: GeometryProxy) -> some View {
        switch readerMode {
        case .rendered:
            renderedContent(geometry: geometry)
        case .raw:
            rawContent
        }
    }

    @ViewBuilder
    private func renderedContent(geometry: GeometryProxy) -> some View {
        NativeMarkdownTextView(
            markdown: parsed.renderedMarkdown,
            readerFontFamily: preferences.readerFontFamily,
            readerFontSize: preferences.readerFontSize.points,
            codeFontSize: preferences.codeFontSize.points,
            appTheme: preferences.theme,
            syntaxPalette: preferences.syntaxPalette,
            colorScheme: preferences.effectiveColorScheme ?? colorScheme,
            textSpacing: preferences.readerTextSpacing,
            readableWidth: min(preferences.readerColumnWidth.points, geometry.size.width - 48),
            showLineNumbers: preferences.showLineNumbers
        )
        .id(
            "rendered_\(preferences.theme)_\(preferences.readerFontFamily)_\(preferences.readerFontSize)_\(preferences.showLineNumbers)"
        )
        .smoothAnimation(preferences.readerFontSize)
        .smoothAnimation(preferences.readerColumnWidth)
    }

    @ViewBuilder
    private var rawContent: some View {
        RawMarkdownEditor(
            text: $document.text,
            fontFamily: preferences.readerFontFamily,
            fontSize: preferences.readerFontSize.points,
            syntaxPalette: preferences.syntaxPalette,
            colorScheme: preferences.effectiveColorScheme ?? colorScheme,
            showLineNumbers: preferences.showLineNumbers
        )
        .id("raw_\(preferences.readerFontFamily)_\(preferences.readerFontSize)_\(preferences.showLineNumbers)")
        .smoothAnimation(preferences.readerFontSize)
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
            readerColumnWidth: preferenceBinding(\.readerColumnWidth),
            showLineNumbers: preferenceBinding(\.showLineNumbers)
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


// MARK: - Previews

#Preview("Content View - Empty") {
    ContentView(document: .constant(MarkdownDocument()))
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
    print(greeting)
    ```
    """)))
    .environment(\.preferences, AppPreferences.shared)
}
