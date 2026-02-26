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
                .transition(.elegantSlide(from: .bottom))
            } else {
                ReaderContentView(
                    document: $document,
                    parsed: parsed,
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
        switch preferences.readerMode {
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
            codeFontSize: CGFloat(preferences.codeFontSize.rawValue),
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
            ModePicker(readerMode: preferenceBinding(\.readerMode))
        }

        // Trailing action items - organized in logical order
        ToolbarItem(id: "metadata", placement: .automatic) {
            ToolbarButton(
                action: { showMetadataInspector.toggle() },
                systemImage: "sidebar.right",
                isActive: showMetadataInspector,
                helpText: "Toggle Metadata Panel"
            )
        }

        ToolbarItem(id: "appearance", placement: .automatic) {
            ToolbarButton(
                action: { showAppearancePopover = true },
                systemImage: "paintbrush",
                helpText: "Appearance Settings"
            )
        }

        ToolbarItem(id: "share", placement: .automatic) {
            ShareLink(item: documentText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help("Share Document")
        }

        ToolbarItem(id: "open", placement: .automatic) {
            ToolbarButton(
                action: openAction,
                systemImage: "folder",
                helpText: "Open markdown file"
            )
        }
    }

    private func preferenceBinding<T>(_ keyPath: ReferenceWritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { preferences[keyPath: keyPath] = $0 }
        )
    }
}

/// Modern mode picker with custom styling - icons only
private struct ModePicker: View {
    @Binding var readerMode: ReaderMode
    @State private var hoverMode: ReaderMode?

    var body: some View {
        HStack(spacing: 2) {
            ModeButton(
                mode: .rendered,
                icon: "doc.text.image",
                isSelected: readerMode == .rendered,
                isHovered: hoverMode == .rendered
            ) {
                readerMode = .rendered
            }
            .onHover { isHovered in
                hoverMode = isHovered ? .rendered : nil
            }

            ModeButton(
                mode: .raw,
                icon: "doc.plaintext",
                isSelected: readerMode == .raw,
                isHovered: hoverMode == .raw
            ) {
                readerMode = .raw
            }
            .onHover { isHovered in
                hoverMode = isHovered ? .raw : nil
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(
                    color: .black.opacity(0.04),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .help("Switch between rendered and raw view")
    }
}

/// Individual mode button with smooth animations - icon only
private struct ModeButton: View {
    let mode: ReaderMode
    let icon: String
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(width: 32, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(backgroundColor)
                .shadow(
                    color: isSelected ? .black.opacity(0.08) : .clear,
                    radius: 0.5,
                    x: 0,
                    y: 0.5
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(nsColor: .selectedControlColor)
        } else if isHovered {
            return Color.primary.opacity(0.06)
        }
        return Color.clear
    }
}

/// Modern toolbar button with hover and active states
private struct ToolbarButton: View {
    let action: () -> Void
    let systemImage: String
    var isActive: Bool = false
    let helpText: String
    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(backgroundColor)
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }

    private var backgroundColor: Color {
        if isActive {
            return Color(nsColor: .selectedControlColor).opacity(0.6)
        } else if isPressed {
            return Color.primary.opacity(0.12)
        } else if isHovered {
            return Color.primary.opacity(0.08)
        }
        return Color.clear
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

// MARK: - View Extensions

extension View {
    /// Adds press down/up event handlers to a view
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

/// Modifier for handling press down/up events
private struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
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
