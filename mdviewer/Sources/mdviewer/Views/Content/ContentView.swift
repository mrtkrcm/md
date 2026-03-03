//
//  ContentView.swift
//  mdviewer
//
//  Main content container that composes reader, editor, and toolbar views.
//

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

/// Main content view that coordinates document display, editing, and toolbar.
@MainActor
struct ContentView: View {
    @Binding var document: MarkdownDocument

    @Environment(\.preferences) private var preferences
    @Environment(\.openDocument) private var openDocument
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showStartupWelcome = true
    @State private var openErrorMessage: String?
    @State private var showMetadataInspector = false
    @State private var showAppearancePopover = false
    @State private var sidebarWidth: CGFloat = 260
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

            HStack(spacing: 0) {
                // Main content
                mainContent(parsed: parsed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Custom sidebar - replaces .inspector for better performance
                if showMetadataInspector {
                    InspectorSidebar(frontmatter: parsed.frontmatter, isPresented: $showMetadataInspector)
                        .frame(width: sidebarWidth)
                        .accessibleTransition(from: .trailing, reduceMotion: reduceMotion)
                }
            }
        }
        .preferredColorScheme(preferences.effectiveColorScheme)
        .onChange(of: windowReaderMode) { _, newMode in
            AccessibilityAnnouncement.modeChanged(to: newMode == .rendered)
        }
        .toolbar {
            ContentToolbar(
                readerMode: Binding(get: { windowReaderMode }, set: { windowReaderMode = $0 }),
                showAppearancePopover: $showAppearancePopover,
                showMetadataInspector: $showMetadataInspector,
                openAction: documentOps.openFromDisk,
                documentText: document.text,
                hasFrontmatter: parsed.frontmatter != nil
            )
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
        .accessibleAnimation(
            .spring(response: 0.28, dampingFraction: 0.82),
            value: showAppearancePopover,
            reduceMotion: reduceMotion
        )
        .alert("Unable to Open Document", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(openErrorMessage ?? "An unexpected error occurred while opening the document.")
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
                    preferences: preferences,
                    colorScheme: colorScheme,
                    reduceMotion: reduceMotion
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
    let preferences: AppPreferences
    let colorScheme: ColorScheme
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LiquidBackground()
                    .ignoresSafeArea()

                contentView(geometry: geometry)
            }
        }
    }

    @ViewBuilder
    private func contentView(geometry: GeometryProxy) -> some View {
        switch readerMode {
        case .rendered:
            renderedContent(geometry: geometry)
                .onAppear {
                    renderSignposter.emitEvent("RenderedModeAppeared")
                }

        case .raw:
            rawContent(geometry: geometry)
                .onAppear {
                    renderSignposter.emitEvent("RawModeAppeared")
                }
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
    }

    @ViewBuilder
    private func rawContent(geometry: GeometryProxy) -> some View {
        RawMarkdownEditor(
            text: $document.text,
            fontSize: preferences.readerFontSize.points,
            colorScheme: preferences.effectiveColorScheme ?? colorScheme,
            showLineNumbers: preferences.showLineNumbers
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibleAnimation(
            reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.2),
            value: preferences.readerFontSize,
            reduceMotion: reduceMotion
        )
        // Raw editor uses full available space without top padding
        .padding(.top, 0)
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
            showLineNumbers: preferenceBinding(\.showLineNumbers),
            typographyPreferences: preferenceBinding(\.typographyPreferences)
        )
    }

    private func preferenceBinding<T>(_ keyPath: ReferenceWritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { preferences[keyPath: keyPath] = $0 }
        )
    }
}

/// Unified inspector sidebar that handles both empty and populated states.
/// Uses static content rendering for immediate appearance.
private struct InspectorSidebar: View {
    let frontmatter: Frontmatter?
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Metadata")
                    .font(.headline)
                    .accessibilityLabel("Document Metadata")
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .accessibilityLabel("Close Inspector")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityHint("Close the metadata inspector panel")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Content - use static VStack for immediate render
            if let frontmatter {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(frontmatter.entries, id: \.key) { entry in
                            MetadataRow(entry: entry)
                        }
                    }
                }
            } else {
                EmptyMetadataState()
            }
        }
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

/// Single metadata row - pre-computed display value for performance.
private struct MetadataRow: View {
    let entry: Frontmatter.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.key)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(entry.key) field")
            Text(entry.displayValue)
                .font(.body)
                .textSelection(.enabled)
                .accessibilityLabel("Value: \(entry.displayValue)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.key): \(entry.displayValue)")
    }
}

/// Empty state for when no frontmatter exists.
private struct EmptyMetadataState: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
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
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
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
