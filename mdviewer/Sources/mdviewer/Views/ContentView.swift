internal import SwiftUI
internal import OSLog
#if os(macOS)
@preconcurrency internal import AppKit
#endif

private enum ReaderMode: String, CaseIterable, Identifiable {
    case rendered = "Rendered"
    case raw = "Raw"

    var id: String { rawValue }
}

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
        .onAppear {
            if !document.isEffectivelyEmpty {
                showStartupWelcome = false
            }
            registerInteraction()
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
        }
        .popover(isPresented: $showAppearancePopover, arrowEdge: .top) {
            AppearancePopoverView(
                selectedTheme: selectedThemeBinding,
                readerFontSize: readerFontSizeBinding,
                readerFontFamily: readerFontFamilyBinding,
                syntaxPalette: syntaxPaletteBinding,
                codeFontSize: codeFontSizeBinding,
                appearanceMode: appearanceModeBinding,
                readerTextSpacing: readerTextSpacingBinding,
                readerColumnWidth: readerColumnWidthBinding
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
            HStack(alignment: .center, spacing: 12) {
                // Left: Metadata pill — zIndex ensures expanded panel floats above toolbar
                if readerMode == .rendered, let frontmatter {
                    FloatingMetadataView(frontmatter: frontmatter)
                        .zIndex(10)
                        .opacity(isTopBarVisible ? 1 : 0)
                        .allowsHitTesting(isTopBarVisible)
                        .animation(.easeInOut(duration: 0.22), value: isTopBarVisible)
                        .onHover { hovering in
                            isHoveringTopBar = hovering
                            if hovering { registerInteraction() } else { scheduleTopBarHide() }
                        }
                }

                Spacer(minLength: 20)

                // Right: Toolbar pill
                TopBarView(
                    showAppearancePopover: $showAppearancePopover,
                    readerMode: readerModeBinding,
                    openAction: openDocumentFromDisk,
                    shareItem: document.text
                )
                .onHover { hovering in
                    isHoveringTopBar = hovering
                    if hovering { registerInteraction() } else { scheduleTopBarHide() }
                }
                .opacity(isTopBarVisible ? 1 : 0)
                .allowsHitTesting(isTopBarVisible)
                .animation(.easeInOut(duration: 0.22), value: isTopBarVisible)
            }
            .padding(.top, 10)
            .padding(.horizontal, 14)

            Spacer()
        }
        .overlay(alignment: .top) {
            Color.clear
                .frame(height: 10)
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

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .basic
    }

    private var syntaxPalette: SyntaxPalette {
        SyntaxPalette.from(rawValue: syntaxPaletteRaw)
    }

    private var readerFontSize: ReaderFontSize {
        ReaderFontSize.from(rawValue: readerFontSizeRaw)
    }

    private var codeFontSize: CodeFontSize {
        CodeFontSize.from(rawValue: codeFontSizeRaw)
    }

    private var appearanceMode: AppearanceMode {
        AppearanceMode.from(rawValue: appearanceModeRaw)
    }

    private var readerFontFamily: ReaderFontFamily {
        ReaderFontFamily.from(rawValue: readerFontFamilyRaw)
    }

    private var readerMode: ReaderMode {
        ReaderMode(rawValue: readerModeRaw) ?? .rendered
    }

    private var readerTextSpacing: ReaderTextSpacing {
        ReaderTextSpacing.from(rawValue: readerTextSpacingRaw)
    }

    private var readerColumnWidth: ReaderColumnWidth {
        ReaderColumnWidth.from(rawValue: readerColumnWidthRaw)
    }

    private var effectiveColorScheme: ColorScheme {
        appearanceMode.preferredColorScheme ?? colorScheme
    }

    private var selectedThemeBinding: Binding<AppTheme> {
        Binding(
            get: { selectedTheme },
            set: { selectedThemeRaw = $0.rawValue }
        )
    }

    private var syntaxPaletteBinding: Binding<SyntaxPalette> {
        Binding(
            get: { syntaxPalette },
            set: { syntaxPaletteRaw = $0.rawValue }
        )
    }

    private var readerFontSizeBinding: Binding<ReaderFontSize> {
        Binding(
            get: { readerFontSize },
            set: { readerFontSizeRaw = $0.rawValue }
        )
    }

    private var codeFontSizeBinding: Binding<CodeFontSize> {
        Binding(
            get: { codeFontSize },
            set: { codeFontSizeRaw = $0.rawValue }
        )
    }

    private var appearanceModeBinding: Binding<AppearanceMode> {
        Binding(
            get: { appearanceMode },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    private var readerFontFamilyBinding: Binding<ReaderFontFamily> {
        Binding(
            get: { readerFontFamily },
            set: { readerFontFamilyRaw = $0.rawValue }
        )
    }

    private var readerModeBinding: Binding<ReaderMode> {
        Binding(
            get: { readerMode },
            set: { readerModeRaw = $0.rawValue }
        )
    }

    private var readerTextSpacingBinding: Binding<ReaderTextSpacing> {
        Binding(
            get: { readerTextSpacing },
            set: { readerTextSpacingRaw = $0.rawValue }
        )
    }

    private var readerColumnWidthBinding: Binding<ReaderColumnWidth> {
        Binding(
            get: { readerColumnWidth },
            set: { readerColumnWidthRaw = $0.rawValue }
        )
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
                .animation(.smooth(duration: 0.25), value: readerMode)
                .animation(.smooth(duration: 0.3), value: readerFontSize)
                .animation(.smooth(duration: 0.3), value: readerColumnWidth)
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
        withAnimation(.easeInOut(duration: 0.2)) {
            showTopBar = true
        }
    }

    private func scheduleTopBarHide() {
        idleHideTask?.cancel()
        guard !shouldShowWelcome, !showAppearancePopover else { return }
        guard !isHoveringTopBar, !isHoveringRevealZone else { return }

        let idleDelay: TimeInterval = 2.2
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

            withAnimation(.easeInOut(duration: 0.22)) {
                showTopBar = false
            }
        }
    }

    private func registerInteraction() {
        lastInteractionAt = Date()
        revealTopBar()
        scheduleTopBarHide()
    }

}

private struct RawMarkdownEditor: View {
    @Binding var text: String
    let fontFamily: ReaderFontFamily
    let fontSize: CGFloat
    let syntaxPalette: SyntaxPalette
    let colorScheme: ColorScheme

    var body: some View {
        RawMarkdownTextView(
            text: $text,
            fontFamily: fontFamily,
            fontSize: fontSize,
            syntaxPalette: syntaxPalette,
            colorScheme: colorScheme
        )
        .frame(minHeight: 480, alignment: .topLeading)
        .glassPanel(cornerRadius: 12)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

#if os(macOS)
private struct RawMarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    let fontFamily: ReaderFontFamily
    let fontSize: CGFloat
    let syntaxPalette: SyntaxPalette
    let colorScheme: ColorScheme

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.usesFindBar = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.focusRingType = .none
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.focusRingType = .none
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView

        context.coordinator.applyTextIfNeeded(text, to: textView)
        context.coordinator.applyHighlighting(
            to: textView,
            fontFamily: fontFamily,
            fontSize: fontSize,
            syntaxPalette: syntaxPalette,
            colorScheme: colorScheme
        )

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.applyTextIfNeeded(text, to: textView)
        context.coordinator.applyHighlighting(
            to: textView,
            fontFamily: fontFamily,
            fontSize: fontSize,
            syntaxPalette: syntaxPalette,
            colorScheme: colorScheme
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        private var isApplyingProgrammaticChange = false
        private var currentFontFamily: ReaderFontFamily = .newYork
        private var currentFontSize: CGFloat = 14
        private var currentSyntaxPalette: SyntaxPalette = .midnight
        private var currentColorScheme: ColorScheme = .light

        private let headingRegex = try? NSRegularExpression(pattern: #"(?m)^(#{1,6})\s.*$"#)
        private let blockquoteRegex = try? NSRegularExpression(pattern: #"(?m)^>\s.*$"#)
        private let listRegex = try? NSRegularExpression(pattern: #"(?m)^\s*(?:[-*+]|\d+\.)\s.*$"#)
        private let inlineCodeRegex = try? NSRegularExpression(pattern: #"`[^`\n]+`"#)
        private let linkRegex = try? NSRegularExpression(pattern: #"\[[^\]]+\]\([^)]+\)"#)
        private let frontmatterRegex = try? NSRegularExpression(pattern: #"(?s)\A---\n.*?\n---\n?"#)
        private let fencedCodeRegex = try? NSRegularExpression(pattern: #"(?s)```(\w+)?\n(.*?)```"#)
        private let stringRegex = try? NSRegularExpression(pattern: #""([^"\\]|\\.)*""#)
        private let lineCommentRegex = try? NSRegularExpression(pattern: #"//.*"#, options: [.anchorsMatchLines])
        private let blockCommentRegex = try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#)
        private let keywordRegex = try? NSRegularExpression(pattern: #"\b(let|var|func|struct|class|enum|protocol|extension|import|if|else|for|while|guard|switch|case|default|return|throw|throws|try|catch|in|where|async|await|actor|defer|do|repeat|break|continue|fallthrough|typealias|associatedtype|some|any|mutating|nonmutating|init|deinit|subscript|static|final|private|fileprivate|internal|public|open)\b"#)
        private let numberRegex = try? NSRegularExpression(pattern: #"\b(0x[0-9A-Fa-f]+|[0-9]+(?:\.[0-9]+)?)\b"#)
        private let typeRegex = try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]+)\b"#)
        private let callRegex = try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#)

        init(text: Binding<String>) {
            _text = text
        }

        @MainActor
        func textDidChange(_ notification: Notification) {
            guard !isApplyingProgrammaticChange else { return }
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            applyHighlighting(
                to: textView,
                fontFamily: currentFontFamily,
                fontSize: currentFontSize,
                syntaxPalette: currentSyntaxPalette,
                colorScheme: currentColorScheme
            )
        }

        @MainActor
        func applyTextIfNeeded(_ newText: String, to textView: NSTextView) {
            guard textView.string != newText else { return }
            isApplyingProgrammaticChange = true
            textView.string = newText
            isApplyingProgrammaticChange = false
        }

        @MainActor
        func applyHighlighting(
            to textView: NSTextView,
            fontFamily: ReaderFontFamily,
            fontSize: CGFloat,
            syntaxPalette: SyntaxPalette,
            colorScheme: ColorScheme
        ) {
            guard let storage = textView.textStorage else { return }
            currentFontFamily = fontFamily
            currentFontSize = fontSize
            currentSyntaxPalette = syntaxPalette
            currentColorScheme = colorScheme

            let fullRange = NSRange(location: 0, length: storage.length)
            let selection = textView.selectedRanges
            let syntax = syntaxPalette.nativeSyntax
            let baseForeground: NSColor = colorScheme == .dark
                ? NSColor(calibratedWhite: 0.90, alpha: 1)
                : NSColor(calibratedWhite: 0.16, alpha: 1)
            let secondaryForeground: NSColor = colorScheme == .dark
                ? NSColor(calibratedWhite: 0.65, alpha: 1)
                : NSColor(calibratedWhite: 0.40, alpha: 1)
            let baseFont = fontFamily.nsFont(size: fontSize)
            let boldFont = fontFamily.nsFont(size: fontSize, traits: .bold)
            let codeFont = fontFamily.nsFont(size: fontSize, monospaced: true)
            let codeBackground: NSColor = colorScheme == .dark
                ? NSColor(calibratedWhite: 0.16, alpha: 1)
                : NSColor(calibratedWhite: 0.95, alpha: 1)

            isApplyingProgrammaticChange = true
            storage.beginEditing()

            storage.setAttributes(
                [
                    .font: baseFont,
                    .foregroundColor: baseForeground
                ],
                range: fullRange
            )

            apply(regex: frontmatterRegex, in: storage.string, range: fullRange) { range in
                storage.addAttribute(.foregroundColor, value: secondaryForeground, range: range)
            }
            apply(regex: headingRegex, in: storage.string, range: fullRange) { range in
                storage.addAttribute(.foregroundColor, value: syntax.keyword, range: range)
                storage.addAttribute(.font, value: boldFont, range: range)
            }
            apply(regex: blockquoteRegex, in: storage.string, range: fullRange) { range in
                storage.addAttribute(.foregroundColor, value: secondaryForeground, range: range)
            }
            apply(regex: listRegex, in: storage.string, range: fullRange) { range in
                storage.addAttribute(.foregroundColor, value: syntax.call, range: range)
            }
            apply(regex: inlineCodeRegex, in: storage.string, range: fullRange) { range in
                storage.addAttribute(.foregroundColor, value: syntax.string, range: range)
                storage.addAttribute(.backgroundColor, value: codeBackground, range: range)
            }
            apply(regex: linkRegex, in: storage.string, range: fullRange) { range in
                storage.addAttribute(.foregroundColor, value: syntax.call, range: range)
                storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }

            applyFencedSwiftHighlighting(
                storage: storage,
                regexRange: fullRange,
                syntax: syntax,
                codeBackground: codeBackground,
                codeFont: codeFont
            )

            storage.endEditing()
            textView.selectedRanges = selection
            isApplyingProgrammaticChange = false
        }

        private func applyFencedSwiftHighlighting(
            storage: NSTextStorage,
            regexRange: NSRange,
            syntax: NativeSyntaxStyle,
            codeBackground: NSColor,
            codeFont: NSFont
        ) {
            guard let fencedCodeRegex else { return }

            fencedCodeRegex.enumerateMatches(in: storage.string, options: [], range: regexRange) { result, _, _ in
                guard
                    let result,
                    result.numberOfRanges >= 3
                else { return }

                let languageRange = result.range(at: 1)
                let bodyRange = result.range(at: 2)
                guard bodyRange.location != NSNotFound, bodyRange.length > 0 else { return }

                storage.addAttribute(.backgroundColor, value: codeBackground, range: bodyRange)
                storage.addAttribute(.font, value: codeFont, range: bodyRange)

                let language = languageRange.location == NSNotFound
                    ? ""
                    : (storage.string as NSString).substring(with: languageRange).lowercased()
                guard language == "swift" else { return }

                var protected: [NSRange] = []

                apply(regex: stringRegex, in: storage.string, range: bodyRange) { range in
                    storage.addAttribute(.foregroundColor, value: syntax.string, range: range)
                    protected.append(range)
                }
                apply(regex: blockCommentRegex, in: storage.string, range: bodyRange) { range in
                    storage.addAttribute(.foregroundColor, value: syntax.comment, range: range)
                    protected.append(range)
                }
                apply(regex: lineCommentRegex, in: storage.string, range: bodyRange) { range in
                    storage.addAttribute(.foregroundColor, value: syntax.comment, range: range)
                    protected.append(range)
                }
                apply(regex: keywordRegex, in: storage.string, range: bodyRange) { range in
                    guard !intersectsProtected(range: range, protected: protected) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.keyword, range: range)
                }
                apply(regex: numberRegex, in: storage.string, range: bodyRange) { range in
                    guard !intersectsProtected(range: range, protected: protected) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.number, range: range)
                }
                apply(regex: typeRegex, in: storage.string, range: bodyRange) { range in
                    guard !intersectsProtected(range: range, protected: protected) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.type, range: range)
                }
                apply(regex: callRegex, in: storage.string, range: bodyRange) { range in
                    guard !intersectsProtected(range: range, protected: protected) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.call, range: range)
                }
            }
        }

        private func intersectsProtected(range: NSRange, protected: [NSRange]) -> Bool {
            protected.contains { NSIntersectionRange($0, range).length > 0 }
        }

        private func apply(
            regex: NSRegularExpression?,
            in text: String,
            range: NSRange,
            handler: (NSRange) -> Void
        ) {
            guard let regex else { return }
            regex.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
                guard let target = result?.range, target.location != NSNotFound, target.length > 0 else { return }
                handler(target)
            }
        }
    }
}
#endif

private struct FloatingMetadataView: View {
    let frontmatter: Frontmatter
    @AppStorage("frontmatterPanelExpanded") private var isExpanded = false

    var body: some View {
        // VStack keeps layout stable: only the collapsed button affects HStack height.
        // The expanded panel lives in a zero-height overlay so it can't push siblings.
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed button — sole layout contributor
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .animation(.easeInOut(duration: 0.15), value: isExpanded)

                    Label("Metadata", systemImage: "tag")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(frontmatter.entries.isEmpty ? "YAML" : "\(frontmatter.entries.count)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .glassPanel()

            // Zero-height anchor: expanded panel anchors here, contributing no layout height
            Color.clear
                .frame(width: 0, height: 0)
                .overlay(alignment: .topLeading) {
                    if isExpanded {
                        expandedPanel
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .offset(y: -8)))
                    }
                }
        }
    }

    private var expandedPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if frontmatter.entries.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Frontmatter detected")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Raw YAML is shown because key/value extraction is unavailable for this structure.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(frontmatter.rawYAML.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(frontmatter.entries.enumerated()), id: \.offset) { _, entry in
                        FloatingMetadataEntryView(entry: entry)
                    }
                }
            }
        }
        .frame(width: 280)
        .frame(maxHeight: 280)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassPanel()
    }
}

private struct FloatingMetadataEntryView: View {
    let entry: Frontmatter.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(displayKey(entry.key))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.value.isEmpty ? "—" : entry.value)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func displayKey(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

}

private struct TopBarView: View {
    @Binding var showAppearancePopover: Bool
    @Binding var readerMode: ReaderMode
    let openAction: () -> Void
    let shareItem: String

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Picker("Reader Mode", selection: $readerMode) {
                    ForEach(ReaderMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 148)
                .help("Switch between rendered preview and raw markdown")
            }
            .padding(.leading, 4)

            Divider()
                .frame(height: 18)

            ToolIconButton(icon: "slider.horizontal.3", isActive: showAppearancePopover) {
                showAppearancePopover.toggle()
            }
            .help("Appearance settings")

            ShareIconButton(shareItem: shareItem)
            .help("Share markdown")

            ToolIconButton(icon: "folder") {
                openAction()
            }
                .help("Open markdown file")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassPanel()
    }
}

private extension View {
    @ViewBuilder
    func glassPanel(cornerRadius: CGFloat = 14) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            self
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 12, y: 4)
        }
    }
}

private struct ToolIconButton: View {
    let icon: String
    var isActive: Bool = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(backgroundFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(isActive ? Color.accentColor : Color(nsColor: .secondaryLabelColor))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var backgroundFill: Color {
        if isActive { return Color.accentColor.opacity(0.12) }
        if isHovering { return Color.primary.opacity(0.10) }
        return .clear
    }
}

private struct ShareIconButton: View {
    let shareItem: String
    @State private var isHovering = false

    var body: some View {
        ShareLink(item: shareItem) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(
                    isHovering ? Color.primary.opacity(0.10) : .clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .foregroundStyle(Color(nsColor: .secondaryLabelColor))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

private struct WelcomeStartView: View {
    let openAction: () -> Void
    let useStarterAction: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(.tertiary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome")
                        .font(.system(size: 28, weight: .semibold))

                    Text("Open a markdown file or start with starter content.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Button("Open...", action: openAction)
                        .buttonStyle(.borderedProminent)
                    Button("Use Starter", action: useStarterAction)
                        .buttonStyle(.bordered)
                }
            }
            .padding(28)
            .glassPanel(cornerRadius: 20)
            .frame(maxWidth: 380)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

private struct AppearancePopoverView: View {
    @Binding var selectedTheme: AppTheme
    @Binding var readerFontSize: ReaderFontSize
    @Binding var readerFontFamily: ReaderFontFamily
    @Binding var syntaxPalette: SyntaxPalette
    @Binding var codeFontSize: CodeFontSize
    @Binding var appearanceMode: AppearanceMode
    @Binding var readerTextSpacing: ReaderTextSpacing
    @Binding var readerColumnWidth: ReaderColumnWidth

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Picker("", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reader")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }

                    Picker("Font", selection: $readerFontFamily) {
                        ForEach(ReaderFontFamily.allCases) { family in
                            Text(family.rawValue).tag(family)
                        }
                    }

                    Picker("Text Size", selection: $readerFontSize) {
                        ForEach(ReaderFontSize.allCases) { size in
                            Text(size.label).tag(size)
                        }
                    }

                    Picker("Text Spacing", selection: $readerTextSpacing) {
                        ForEach(ReaderTextSpacing.allCases) { spacing in
                            Text(spacing.rawValue).tag(spacing)
                        }
                    }

                    Picker("Column Width", selection: $readerColumnWidth) {
                        ForEach(ReaderColumnWidth.allCases) { width in
                            Text(width.rawValue).tag(width)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Syntax")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Picker("Palette", selection: $syntaxPalette) {
                        ForEach(SyntaxPalette.allCases) { palette in
                            Text(palette.rawValue).tag(palette)
                        }
                    }

                    Picker("Code Size", selection: $codeFontSize) {
                        ForEach(CodeFontSize.allCases) { size in
                            Text(size.label).tag(size)
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 300)
    }
}

// MARK: - Liquid Design Components

/// Subtle animated background that responds to system appearance
private struct LiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if #available(macOS 15.0, *) {
                ModernLiquidBackground()
            } else {
                LegacyLiquidBackground()
            }
        }
    }
}

@available(macOS 15.0, *)
private struct ModernLiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: false)) { _ in
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(x: 0, y: 0), .init(x: 0.5, y: 0), .init(x: 1, y: 0),
                    .init(x: 0, y: 0.5), .init(x: 0.5, y: 0.5), .init(x: 1, y: 0.5),
                    .init(x: 0, y: 1), .init(x: 0.5, y: 1), .init(x: 1, y: 1)
                ],
                colors: colors
            )
            .opacity(0.15)
            .blur(radius: 40)
        }
        .animation(.easeInOut(duration: 2.0), value: colorScheme)
    }

    private var colors: [Color] {
        switch colorScheme {
        case .dark:
            return [
                .black, .black, .black,
                Color.purple.opacity(0.2), Color.blue.opacity(0.1), Color.black,
                Color.indigo.opacity(0.15), .black, Color.purple.opacity(0.1)
            ]
        default:
            return [
                .white, .white, .white,
                Color.blue.opacity(0.08), Color.purple.opacity(0.05), .white,
                Color.cyan.opacity(0.06), .white, Color.blue.opacity(0.04)
            ]
        }
    }
}

/// Fallback for macOS 14 using RadialGradient
private struct LegacyLiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color
                Color(nsColor: .windowBackgroundColor)

                // Animated orbs
                ForEach(0..<3) { i in
                    RadialGradient(
                        colors: [
                            orbColor(for: i).opacity(0.15),
                            orbColor(for: i).opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.6
                    )
                    .offset(x: offsetX(for: i, width: geometry.size.width),
                            y: offsetY(for: i, height: geometry.size.height))
                    .blur(radius: 60)
                    .animation(
                        .easeInOut(duration: 8 + Double(i) * 2)
                        .repeatForever(autoreverses: true),
                        value: phase
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    private func orbColor(for index: Int) -> Color {
        switch (colorScheme, index) {
        case (.dark, 0): return .purple
        case (.dark, 1): return .blue
        case (.dark, _): return .indigo
        default:
            return [.blue, .cyan, .purple][index]
        }
    }

    private func offsetX(for index: Int, width: CGFloat) -> CGFloat {
        let offsets: [CGFloat] = [-width * 0.2, width * 0.3, -width * 0.1]
        return offsets[index]
    }

    private func offsetY(for index: Int, height: CGFloat) -> CGFloat {
        let offsets: [CGFloat] = [-height * 0.1, height * 0.2, height * 0.3]
        return offsets[index]
    }
}
