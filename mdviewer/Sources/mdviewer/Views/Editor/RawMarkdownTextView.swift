//
//  RawMarkdownTextView.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    internal import AppKit

    // MARK: - Raw Markdown Text View (NSViewRepresentable)

    /// NSViewRepresentable that provides a native AppKit text editor
    /// with markdown syntax highlighting for headings, code blocks,
    /// links, lists, blockquotes, and fenced Swift code.
    struct RawMarkdownTextView: NSViewRepresentable {
        private enum Layout {
            static let inset = NSSize(width: 14, height: 14)
            static let rulerThickness: CGFloat = 40
        }

        @Binding var text: String
        let fontFamily: ReaderFontFamily
        let fontSize: CGFloat
        let syntaxPalette: SyntaxPalette
        let colorScheme: ColorScheme
        let showLineNumbers: Bool

        func makeNSView(context: Context) -> NSScrollView {
            let textView = makeConfiguredTextView(context: context)
            let scrollView = makeConfiguredScrollView(textView: textView)

            updateTextContainerSize(textView: textView, in: scrollView)
            configureLineNumberRuler(for: scrollView, textView: textView)

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

            updateTextContainerSize(textView: textView, in: scrollView)
            configureLineNumberRuler(for: scrollView, textView: textView)

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

        private func makeConfiguredTextView(context: Context) -> MarkdownEditorTextView {
            let textStorage = NSTextStorage()
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            let textContainer = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
            textContainer.lineFragmentPadding = 0
            textContainer.widthTracksTextView = true
            layoutManager.addTextContainer(textContainer)

            let textView = MarkdownEditorTextView(frame: .zero, textContainer: textContainer)
            context.coordinator.textView = textView
            textView.delegate = context.coordinator
            textView.isEditable = true
            textView.isSelectable = true
            textView.isRichText = true
            textView.usesFindBar = true
            textView.allowsUndo = true
            textView.drawsBackground = true
            textView.backgroundColor = NSColor(named: "WindowBackgroundColor") ?? .controlBackgroundColor
            textView.focusRingType = .none
            textView.textContainerInset = Layout.inset
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.widthTracksTextView = true
            textView.minSize = .zero
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.autoresizingMask = [.width]

            return textView
        }

        private func makeConfiguredScrollView(textView: NSTextView) -> NSScrollView {
            let scrollView = NSScrollView()
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder
            scrollView.focusRingType = .none
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.documentView = textView
            return scrollView
        }

        private func updateTextContainerSize(textView: NSTextView, in scrollView: NSScrollView) {
            let contentSize = scrollView.contentSize
            textView.minSize = NSSize(width: 0, height: contentSize.height)
            textView.textContainer?.containerSize = NSSize(
                width: contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        }

        private func configureLineNumberRuler(for scrollView: NSScrollView, textView: NSTextView) {
            if showLineNumbers {
                if scrollView.verticalRulerView == nil {
                    let rulerView = LineNumberRulerView(scrollView: scrollView)
                    rulerView.clientView = textView
                    scrollView.verticalRulerView = rulerView
                }
                scrollView.hasHorizontalRuler = false
                scrollView.hasVerticalRuler = true
                scrollView.rulersVisible = true
                if let rulerView = scrollView.verticalRulerView as? LineNumberRulerView {
                    rulerView.ruleThickness = Layout.rulerThickness
                    rulerView.needsDisplay = true
                }
            } else {
                scrollView.rulersVisible = false
                scrollView.hasVerticalRuler = false
                scrollView.verticalRulerView = nil
            }
        }

        // MARK: - Coordinator

        final class Coordinator: NSObject, NSTextViewDelegate {
            private enum HighlightMode {
                case full
                case incremental(range: NSRange)
            }

            @Binding private var text: String
            private var isApplyingProgrammaticChange = false
            private var currentFontFamily: ReaderFontFamily = .newYork
            private var currentFontSize: CGFloat = 14
            private var currentSyntaxPalette: SyntaxPalette = .midnight
            private var currentColorScheme: ColorScheme = .light
            weak var textView: NSTextView?
            private var pendingHighlightRange: NSRange?
            private var highlightTask: Task<Void, Never>?

            private let headingRegex = try? NSRegularExpression(pattern: #"(?m)^(#{1,6})\s.*$"#)
            private let blockquoteRegex = try? NSRegularExpression(pattern: #"(?m)^>\s.*$"#)
            private let listRegex = try? NSRegularExpression(pattern: #"(?m)^\s*(?:[-*+]|\d+\.)\s.*$"#)
            private let inlineCodeRegex = try? NSRegularExpression(pattern: #"`[^`\n]+`"#)
            private let linkRegex = try? NSRegularExpression(pattern: #"\[[^\]]+\]\([^)]+\)"#)
            private let frontmatterRegex = try? NSRegularExpression(pattern: #"(?s)\A---\n.*?\n---\n?"#)
            private let fencedCodeRegex = try? NSRegularExpression(pattern: #"(?s)```(\w+)?\n(.*?)```"#)

            init(text: Binding<String>) {
                _text = text
                super.init()
                registerNotificationObserver()
            }

            deinit {
                highlightTask?.cancel()
                NotificationCenter.default.removeObserver(self)
            }

            private func registerNotificationObserver() {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleInsertText(_:)),
                    name: .insertText,
                    object: nil
                )
            }

            @MainActor @objc
            private func handleInsertText(_ notification: Notification) {
                guard let textView else { return }
                guard
                    let userInfo = notification.userInfo,
                    let prefix = userInfo["prefix"] as? String,
                    let suffix = userInfo["suffix"] as? String else { return }

                let selectedRange = textView.selectedRange()
                let nsString = textView.string as NSString

                // Bounds check
                guard selectedRange.location != NSNotFound,
                      selectedRange.location + selectedRange.length <= nsString.length
                else { return }

                let selectedText = nsString.substring(with: selectedRange)

                let newText = prefix + selectedText + suffix
                let finalRange = NSRange(location: selectedRange.location, length: newText.utf16.count)

                textView.textStorage?.replaceCharacters(in: selectedRange, with: newText)

                // Position cursor between prefix and suffix if no text was selected
                if selectedText.isEmpty {
                    let cursorPosition = selectedRange.location + prefix.utf16.count
                    textView.setSelectedRange(NSRange(location: cursorPosition, length: 0))
                } else {
                    textView.setSelectedRange(finalRange)
                }

                // Trigger text change notification
                textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
            }

            @MainActor
            func textDidChange(_ notification: Notification) {
                guard !isApplyingProgrammaticChange else { return }
                guard let textView = notification.object as? NSTextView else { return }
                text = textView.string

                // Prefer incremental highlight; only use full when storage reports character edits
                // but the range is invalid. Avoid full re-highlight on attribute-only changes.
                let mode: HighlightMode
                if let storage = textView.textStorage,
                   storage.editedMask.contains(.editedCharacters),
                   storage.editedRange.location != NSNotFound
                {
                    mode = .incremental(range: storage.editedRange)
                } else {
                    // Attribute-only edits don't need re-highlighting — skip
                    return
                }

                scheduleHighlight(
                    on: textView,
                    mode: mode,
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
                scheduleHighlight(
                    on: textView,
                    mode: .full,
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                    syntaxPalette: syntaxPalette,
                    colorScheme: colorScheme
                )
            }

            @MainActor
            private func scheduleHighlight(
                on textView: NSTextView,
                mode: HighlightMode,
                fontFamily: ReaderFontFamily,
                fontSize: CGFloat,
                syntaxPalette: SyntaxPalette,
                colorScheme: ColorScheme
            ) {
                currentFontFamily = fontFamily
                currentFontSize = fontSize
                currentSyntaxPalette = syntaxPalette
                currentColorScheme = colorScheme

                let fullTextRange = NSRange(location: 0, length: textView.string.utf16.count)
                switch mode {
                case .full:
                    pendingHighlightRange = fullTextRange
                case .incremental(let range):
                    if let existing = pendingHighlightRange {
                        pendingHighlightRange = NSUnionRange(existing, range)
                    } else {
                        pendingHighlightRange = range
                    }
                }

                highlightTask?.cancel()
                let delayNanos: UInt64
                switch mode {
                case .full:
                    delayNanos = 0
                case .incremental:
                    delayNanos = 60_000_000 // 60ms debounce while typing
                }

                highlightTask = Task { @MainActor [weak self, weak textView] in
                    guard let self, let textView else { return }
                    if delayNanos > 0 {
                        try? await Task.sleep(nanoseconds: delayNanos)
                    }
                    guard !Task.isCancelled else { return }

                    let target = self.pendingHighlightRange ?? fullTextRange
                    self.pendingHighlightRange = nil
                    self.applyHighlightingNow(
                        to: textView,
                        targetRange: target,
                        fontFamily: fontFamily,
                        fontSize: fontSize,
                        syntaxPalette: syntaxPalette,
                        colorScheme: colorScheme
                    )
                }
            }

            @MainActor
            private func applyHighlightingNow(
                to textView: NSTextView,
                targetRange: NSRange,
                fontFamily: ReaderFontFamily,
                fontSize: CGFloat,
                syntaxPalette: SyntaxPalette,
                colorScheme: ColorScheme
            ) {
                guard let storage = textView.textStorage else { return }

                let fullRange = NSRange(location: 0, length: storage.length)
                guard fullRange.length > 0 else { return }

                let requested = NSIntersectionRange(fullRange, targetRange)
                let highlightRange = expandedLineRange(in: storage.string as NSString, around: requested)

                let selection = textView.selectedRanges
                let syntax = syntaxPalette.nativeSyntax
                let fencedRanges = fencedCodeRanges(in: storage.string, range: fullRange)
                let fencedFullRanges = fencedRanges.map(\.full)

                // Use theme palette for consistency with renderer
                let palette = NativeThemePalette(theme: .basic, scheme: colorScheme)
                let baseForeground = palette.textPrimary
                let secondaryForeground = palette.textSecondary

                let baseFont = fontFamily.nsFont(size: fontSize)
                let boldFont = fontFamily.nsFont(size: fontSize, traits: .bold)
                let codeFont = fontFamily.nsFont(size: fontSize, monospaced: true)
                let codeBackground = palette.codeBackground

                isApplyingProgrammaticChange = true
                storage.beginEditing()

                storage.setAttributes(
                    [
                        .font: baseFont,
                        .foregroundColor: baseForeground,
                    ],
                    range: highlightRange
                )

                apply(regex: frontmatterRegex, in: storage.string, range: highlightRange) { range in
                    storage.addAttribute(.foregroundColor, value: secondaryForeground, range: range)
                }
                apply(regex: headingRegex, in: storage.string, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.keyword, range: range)
                    storage.addAttribute(.font, value: boldFont, range: range)
                }
                apply(regex: blockquoteRegex, in: storage.string, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: secondaryForeground, range: range)
                }
                apply(regex: listRegex, in: storage.string, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.call, range: range)
                }
                apply(regex: inlineCodeRegex, in: storage.string, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.string, range: range)
                    storage.addAttribute(.backgroundColor, value: codeBackground, range: range)
                }
                apply(regex: linkRegex, in: storage.string, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.call, range: range)
                    storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                }

                applyFencedSwiftHighlighting(
                    storage: storage,
                    regexRange: highlightRange,
                    syntax: syntax,
                    codeBackground: codeBackground,
                    codeFont: codeFont
                )

                storage.endEditing()
                textView.selectedRanges = selection
                isApplyingProgrammaticChange = false
            }

            private func expandedLineRange(in nsString: NSString, around range: NSRange) -> NSRange {
                let len = nsString.length
                guard len > 0 else { return NSRange(location: 0, length: 0) }
                if range.location == NSNotFound || range.length == 0 && range.location > len {
                    return NSRange(location: 0, length: len)
                }

                let clampedStart = max(0, min(range.location, len))
                let clampedEnd = max(clampedStart, min(range.location + range.length, len))

                let startLine = nsString.lineRange(for: NSRange(location: clampedStart, length: 0))

                // Guard against empty-string edge: lineRange requires location < length
                let endLineLocation = clampedEnd >= len ? max(0, len - 1) : clampedEnd
                guard endLineLocation < len else {
                    return NSRange(location: startLine.location, length: len - startLine.location)
                }
                let endLine = nsString.lineRange(for: NSRange(location: endLineLocation, length: 0))

                return NSUnionRange(startLine, endLine)
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

                    apply(regex: SwiftSyntaxRegexes.strings, in: storage.string, range: bodyRange) { range in
                        storage.addAttribute(.foregroundColor, value: syntax.string, range: range)
                        protected.append(range)
                    }
                    apply(regex: SwiftSyntaxRegexes.blockComments, in: storage.string, range: bodyRange) { range in
                        storage.addAttribute(.foregroundColor, value: syntax.comment, range: range)
                        protected.append(range)
                    }
                    apply(regex: SwiftSyntaxRegexes.lineComments, in: storage.string, range: bodyRange) { range in
                        storage.addAttribute(.foregroundColor, value: syntax.comment, range: range)
                        protected.append(range)
                    }
                    apply(regex: SwiftSyntaxRegexes.keywords, in: storage.string, range: bodyRange) { range in
                        guard !intersectsProtected(range: range, protected: protected) else { return }
                        storage.addAttribute(.foregroundColor, value: syntax.keyword, range: range)
                    }
                    apply(regex: SwiftSyntaxRegexes.numbers, in: storage.string, range: bodyRange) { range in
                        guard !intersectsProtected(range: range, protected: protected) else { return }
                        storage.addAttribute(.foregroundColor, value: syntax.number, range: range)
                    }
                    apply(regex: SwiftSyntaxRegexes.types, in: storage.string, range: bodyRange) { range in
                        guard !intersectsProtected(range: range, protected: protected) else { return }
                        storage.addAttribute(.foregroundColor, value: syntax.type, range: range)
                    }
                    apply(regex: SwiftSyntaxRegexes.calls, in: storage.string, range: bodyRange) { range in
                        guard !intersectsProtected(range: range, protected: protected) else { return }
                        storage.addAttribute(.foregroundColor, value: syntax.call, range: range)
                    }
                }
            }

            private func fencedCodeRanges(in text: String, range: NSRange) -> [(full: NSRange, body: NSRange)] {
                guard let fencedCodeRegex else { return [] }

                var ranges: [(full: NSRange, body: NSRange)] = []
                fencedCodeRegex.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
                    guard
                        let result,
                        result.range.location != NSNotFound,
                        result.range.length > 0
                    else { return }

                    let bodyRange = result.numberOfRanges >= 3 ? result.range(at: 2) : NSRange(location: NSNotFound, length: 0)
                    ranges.append((full: result.range, body: bodyRange))
                }
                return ranges
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
