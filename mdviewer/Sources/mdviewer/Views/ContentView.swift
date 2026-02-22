//
//  ContentView.swift
//  mdviewer
//

internal import SwiftUI
internal import OSLog
#if os(macOS)
    @preconcurrency internal import AppKit
#endif

@MainActor
struct ContentView: View {
    @Binding var document: MarkdownDocument

    @AppStorage("theme") private var selectedThemeRaw = AppTheme.basic.rawValue
    @AppStorage("syntaxPalette") private var syntaxPaletteRaw = SyntaxPalette.midnight.rawValue
    @AppStorage("readerFontSize") private var readerFontSizeRaw = ReaderFontSize.standard.rawValue
    @AppStorage("codeFontSize") private var codeFontSizeRaw = CodeFontSize.medium.rawValue
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.auto.rawValue
    @AppStorage("readerFontFamily") private var readerFontFamilyRaw = ReaderFontFamily.newYork.rawValue
    @AppStorage("readerMode") private var readerModeRaw = ReaderMode.rendered.rawValue
    @AppStorage("readerTextSpacing") private var readerTextSpacingRaw = ReaderTextSpacing.balanced.rawValue
    @AppStorage("readerColumnWidth") private var readerColumnWidthRaw = ReaderColumnWidth.balanced.rawValue

    @Environment(\.openDocument) private var openDocument
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.undoManager) private var undoManager

    @State private var openErrorMessage: String?
    @State private var showStartupWelcome = true
    @State private var showAppearancePopover = false
    @State private var showTopBar = true
    @State private var idleHideTask: Task<Void, Never>?
    @State private var isHoveringTopBar = false
    @State private var isHoveringRevealZone = false
    @State private var lastInteractionAt = Date()

    private let logger = Logger(subsystem: "mdviewer", category: "ui")

    var body: some View {
        let parsed = FrontmatterParser.parse(document.text)

        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if shouldShowWelcome {
                WelcomeStartView(
                    openAction: openDocumentFromDisk,
                    useStarterAction: resetStarter
                )
                .padding(.top, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                readerContent(parsed: parsed)
                    .transition(.opacity)
            }

            topOverlay(frontmatter: parsed.frontmatter)
        }
        .preferredColorScheme(appearanceMode.preferredColorScheme)
        .toolbar {
            toolbarContent
        }
        .onAppear {
            if !document.isEffectivelyEmpty {
                showStartupWelcome = false
            }
            registerInteraction()
            registerNotificationObservers()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                registerInteraction()
            } else {
                idleHideTask?.cancel()
                idleHideTask = nil
            }
        }
        .onChange(of: showAppearancePopover) { _, shown in
            if shown {
                revealTopBar()
            } else {
                scheduleTopBarHide()
            }
        }
        .onDisappear {
            idleHideTask?.cancel()
            idleHideTask = nil
            removeNotificationObservers()
        }
        .popover(isPresented: $showAppearancePopover, arrowEdge: .top) {
            AppearancePopoverView(
                selectedTheme: $selectedThemeRaw.stored(),
                readerFontSize: $readerFontSizeRaw.stored(),
                readerFontFamily: $readerFontFamilyRaw.stored(),
                syntaxPalette: $syntaxPaletteRaw.stored(),
                codeFontSize: $codeFontSizeRaw.stored(),
                appearanceMode: $appearanceModeRaw.stored(),
                readerTextSpacing: $readerTextSpacingRaw.stored(),
                readerColumnWidth: $readerColumnWidthRaw.stored()
            )
        }
        .alert("Unable to Open Document", isPresented: openErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(openErrorMessage ?? "An unexpected error occurred while opening the document.")
        }
    }

    private func topOverlay(frontmatter: Frontmatter?) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.relaxed) {
                // Left: Metadata pill — only rendered when frontmatter has content
                if
                    readerMode == .rendered,
                    let frontmatter,
                    !frontmatter.rawYAML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                {
                    FloatingMetadataView(frontmatter: frontmatter)
                        .zIndex(10)
                        .opacity(isTopBarVisible ? 1 : 0)
                        .allowsHitTesting(isTopBarVisible)
                        .liquidAnimation(isTopBarVisible)
                        .onHover { hovering in
                            isHoveringTopBar = hovering
                            if hovering { registerInteraction() } else { scheduleTopBarHide() }
                        }
                }

                Spacer(minLength: 20)

                // Right: Toolbar pill
                TopBarView(
                    showAppearancePopover: $showAppearancePopover,
                    readerMode: $readerModeRaw.stored(),
                    openAction: openDocumentFromDisk,
                    shareItem: document.text
                )
                .onHover { hovering in
                    isHoveringTopBar = hovering
                    if hovering { registerInteraction() } else { scheduleTopBarHide() }
                }
                .opacity(isTopBarVisible ? 1 : 0)
                .allowsHitTesting(isTopBarVisible)
                .liquidAnimation(isTopBarVisible)
            }
            .padding(.top, DesignTokens.Spacing.topBarTop)
            .padding(.horizontal, DesignTokens.Spacing.topBarHorizontal)

            Spacer()
        }
        .overlay(alignment: .top) {
            Color.clear
                .frame(height: DesignTokens.Layout.revealZoneHeight)
                .contentShape(Rectangle())
                .onHover { hovering in
                    isHoveringRevealZone = hovering
                    if hovering { registerInteraction() } else { scheduleTopBarHide() }
                }
        }
    }

    private var shouldShowWelcome: Bool {
        showStartupWelcome && document.isEffectivelyEmpty
    }

    private var isTopBarVisible: Bool {
        showTopBar || showAppearancePopover || isHoveringTopBar || isHoveringRevealZone
    }

    private var selectedTheme: AppTheme { .from(rawValue: selectedThemeRaw) }
    private var syntaxPalette: SyntaxPalette { .from(rawValue: syntaxPaletteRaw) }
    private var readerFontSize: ReaderFontSize { .from(rawValue: readerFontSizeRaw) }
    private var codeFontSize: CodeFontSize { .from(rawValue: codeFontSizeRaw) }
    private var appearanceMode: AppearanceMode { .from(rawValue: appearanceModeRaw) }
    private var readerFontFamily: ReaderFontFamily { .from(rawValue: readerFontFamilyRaw) }
    private var readerMode: ReaderMode { .from(rawValue: readerModeRaw) }
    private var readerTextSpacing: ReaderTextSpacing { .from(rawValue: readerTextSpacingRaw) }
    private var readerColumnWidth: ReaderColumnWidth { .from(rawValue: readerColumnWidthRaw) }

    private var effectiveColorScheme: ColorScheme {
        appearanceMode.preferredColorScheme ?? colorScheme
    }

    private var openErrorBinding: Binding<Bool> {
        Binding(
            get: { openErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    openErrorMessage = nil
                }
            }
        )
    }

    // MARK: - Liquid Design Content View

    @ViewBuilder
    private func readerContent(parsed: ParsedMarkdown) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background subtle gradient for liquid feel
                LiquidBackground()
                    .ignoresSafeArea()

                // Main content with fluid transition
                Group {
                    if readerMode == .rendered {
                        NativeMarkdownTextView(
                            markdown: parsed.renderedMarkdown,
                            readerFontFamily: readerFontFamily,
                            readerFontSize: readerFontSize.points,
                            codeFontSize: CGFloat(codeFontSize.rawValue),
                            appTheme: selectedTheme,
                            syntaxPalette: syntaxPalette,
                            colorScheme: effectiveColorScheme,
                            textSpacing: readerTextSpacing,
                            readableWidth: min(readerColumnWidth.points, geometry.size.width - 48)
                        )
                        .id("rendered_\(selectedTheme)_\(readerFontFamily)_\(readerFontSize)")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                    } else {
                        RawMarkdownEditor(
                            text: $document.text,
                            fontFamily: readerFontFamily,
                            fontSize: readerFontSize.points,
                            syntaxPalette: syntaxPalette,
                            colorScheme: effectiveColorScheme
                        )
                        .id("raw_\(readerFontFamily)_\(readerFontSize)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.top, geometry.safeAreaInsets.top + 42)
                .liquidAnimation(readerMode, duration: DesignTokens.Animation.medium)
                .liquidAnimation(readerFontSize, duration: DesignTokens.Animation.slow)
                .liquidAnimation(readerColumnWidth, duration: DesignTokens.Animation.slow)
            }
            .simultaneousGesture(TapGesture().onEnded { registerInteraction() })
        }
    }

    private func openDocumentFromDisk() {
        #if os(macOS)
            let panel = NSOpenPanel()
            panel.title = "Open Markdown File"
            panel.allowedContentTypes = MarkdownDocument.readableContentTypes
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.resolvesAliases = true

            guard panel.runModal() == .OK, let url = panel.url else {
                return
            }

            Task { @MainActor in
                do {
                    try await openDocument(at: url)
                    showStartupWelcome = false
                } catch {
                    logger.error("Open document failed: \(String(describing: error), privacy: .public)")
                    openErrorMessage = error.localizedDescription
                }
            }
        #endif
    }

    private func resetStarter() {
        document.text = MarkdownDocument.starterContent
        showStartupWelcome = false
    }

    private func revealTopBar() {
        idleHideTask?.cancel()
        idleHideTask = nil
        withAnimation(.easeInOut(duration: DesignTokens.Animation.normal)) {
            showTopBar = true
        }
    }

    private func scheduleTopBarHide() {
        idleHideTask?.cancel()
        guard !shouldShowWelcome, !showAppearancePopover else { return }
        guard !isHoveringTopBar, !isHoveringRevealZone else { return }

        let idleDelay = DesignTokens.Animation.idleDelay
        let elapsed = Date().timeIntervalSince(lastInteractionAt)
        let delay = max(0.12, idleDelay - elapsed)

        idleHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            guard !isHoveringTopBar, !isHoveringRevealZone, !showAppearancePopover else { return }

            if Date().timeIntervalSince(lastInteractionAt) < idleDelay {
                scheduleTopBarHide()
                return
            }

            withAnimation(.easeInOut(duration: DesignTokens.Animation.topBar)) {
                showTopBar = false
            }
        }
    }

    private func registerInteraction() {
        lastInteractionAt = Date()
        revealTopBar()
        scheduleTopBarHide()
    }

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(id: "mode", placement: .navigation) {
            Picker("Mode", selection: $readerModeRaw) {
                Image(systemName: "eye")
                    .help("Rendered View")
                    .tag(ReaderMode.rendered.rawValue)
                Image(systemName: "pencil.line")
                    .help("Raw Markdown")
                    .tag(ReaderMode.raw.rawValue)
            }
            .pickerStyle(.segmented)
            .help("Switch between rendered and raw view")
        }

        ToolbarItem(id: "appearance", placement: .primaryAction) {
            Button(action: { showAppearancePopover = true }) {
                Image(systemName: "paintbrush")
            }
            .help("Appearance Settings")
        }

        ToolbarItem(id: "share", placement: .primaryAction) {
            ShareLink(item: document.text) {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Share Document")
        }
    }

    // MARK: - Notification Handling

    private func registerNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .toggleBold,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                insertMarkdownSyntax(wrap: "**")
            }
        }

        NotificationCenter.default.addObserver(
            forName: .toggleItalic,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                insertMarkdownSyntax(wrap: "*")
            }
        }

        NotificationCenter.default.addObserver(
            forName: .insertCodeBlock,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                insertMarkdownSyntax(prefix: "\n```\n", suffix: "\n```\n")
            }
        }

        NotificationCenter.default.addObserver(
            forName: .insertLink,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                insertMarkdownSyntax(prefix: "[", suffix: "](url)")
            }
        }

        NotificationCenter.default.addObserver(
            forName: .insertImage,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                insertMarkdownSyntax(prefix: "![", suffix: "](image-url)")
            }
        }

        NotificationCenter.default.addObserver(
            forName: .showAppearanceSettings,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                showAppearancePopover = true
            }
        }
    }

    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .toggleBold, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toggleItalic, object: nil)
        NotificationCenter.default.removeObserver(self, name: .insertCodeBlock, object: nil)
        NotificationCenter.default.removeObserver(self, name: .insertLink, object: nil)
        NotificationCenter.default.removeObserver(self, name: .insertImage, object: nil)
        NotificationCenter.default.removeObserver(self, name: .showAppearanceSettings, object: nil)
    }

    private func insertMarkdownSyntax(wrap: String) {
        insertMarkdownSyntax(prefix: wrap, suffix: wrap)
    }

    private func insertMarkdownSyntax(prefix: String, suffix: String) {
        // Only works in raw mode
        guard readerMode == .raw else {
            // Switch to raw mode first
            readerModeRaw = ReaderMode.raw.rawValue
            // Post again after a short delay to apply the insertion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .insertCodeBlock, object: nil)
            }
            return
        }

        // Post notification to the editor to insert text
        NotificationCenter.default.post(
            name: .insertText,
            object: nil,
            userInfo: ["prefix": prefix, "suffix": suffix]
        )
    }
}

// MARK: - Additional Notifications
extension Notification.Name {
    static let insertText = Notification.Name("insertText")
}

// MARK: - Extracted Components

// UI components moved to Views/Components/:
// - FloatingMetadataView, FloatingMetadataEntryView
// - TopBarView, ToolIconButton, ShareIconButton
// - GlassPanelModifier (View.glassPanel extension)
// - WelcomeStartView, AppearancePopoverView
// - LiquidBackground (ModernLiquidBackground, LegacyLiquidBackground)
