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
        let appTheme: AppTheme
        let textSpacing: ReaderTextSpacing

        private var highlightConfig: HighlightConfiguration {
            HighlightConfiguration(
                fontFamily: fontFamily,
                fontSize: fontSize,
                syntaxPalette: syntaxPalette,
                colorScheme: colorScheme,
                appTheme: appTheme,
                textSpacing: textSpacing
            )
        }

        func makeNSView(context: Context) -> NSScrollView {
            let textView = makeConfiguredTextView(context: context)
            let scrollView = makeConfiguredScrollView(textView: textView)

            updateTextContainerSize(textView: textView, in: scrollView)
            configureLineNumberRuler(for: scrollView, textView: textView)

            context.coordinator.applyTextIfNeeded(text, to: textView)
            context.coordinator.applyHighlighting(to: textView, config: highlightConfig)

            return scrollView
        }

        func updateNSView(_ scrollView: NSScrollView, context: Context) {
            guard let textView = scrollView.documentView as? NSTextView else { return }

            updateTextContainerSize(textView: textView, in: scrollView)
            configureLineNumberRuler(for: scrollView, textView: textView)

            context.coordinator.applyTextIfNeeded(text, to: textView)
            context.coordinator.applyHighlighting(to: textView, config: highlightConfig)
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text)
        }

        static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
            coordinator.highlightTask?.cancel()
            coordinator.highlightTask = nil
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
            textView.drawsBackground = false
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
            scrollView.wantsLayer = true
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

        // MARK: - Highlight Configuration

        /// Groups all parameters that influence syntax highlighting into a single value type.
        /// Eliminates scattered `current*` instance variables and multi-parameter APIs.
        struct HighlightConfiguration: Equatable {
            var fontFamily: ReaderFontFamily = .newYork
            var fontSize: CGFloat = 14
            var syntaxPalette: SyntaxPalette = .midnight
            var colorScheme: ColorScheme = .light
            var appTheme: AppTheme = .basic
            var textSpacing: ReaderTextSpacing = .balanced
        }

        // MARK: - Coordinator

        final class Coordinator: NSObject, NSTextViewDelegate {
            private enum HighlightMode {
                case full
                case incremental(range: NSRange)
            }

            @Binding private var text: String
            private var isApplyingProgrammaticChange = false
            private(set) var config = HighlightConfiguration()
            weak var textView: NSTextView?
            private var pendingHighlightRange: NSRange?
            fileprivate var highlightTask: Task<Void, Never>?

            /// Cached fenced code block parse results, invalidated on edits near fence markers
            private var cachedFencedBlocks: [FencedBlock]?
            private var cachedFencedBlocksTextLength: Int = -1

            private let headingRegex = try? NSRegularExpression(pattern: #"(?m)^(#{1,6})\s.*$"#)
            private let blockquoteRegex = try? NSRegularExpression(pattern: #"(?m)^>\s.*$"#)
            private let listRegex = try? NSRegularExpression(pattern: #"(?m)^\s*(?:[-*+]|\d+\.)\s.*$"#)
            private let inlineCodeRegex = try? NSRegularExpression(pattern: #"`[^`\n]+`"#)
            private let linkRegex = try? NSRegularExpression(pattern: #"\[[^\]]+\]\([^)]+\)"#)
            private let frontmatterRegex = try? NSRegularExpression(pattern: #"(?s)\A---\n.*?\n---\n?"#)
            private let fencedCodeRegex = try? NSRegularExpression(pattern: #"(?s)(`{3,})(\w+)?\n(.*?)\1"#)

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

                let newText = textView.string
                if text != newText { text = newText }

                // Invalidate fenced block cache when edits touch fence markers (```)
                if let storage = textView.textStorage,
                   storage.editedMask.contains(.editedCharacters)
                {
                    let editRange = storage.editedRange
                    if editRange.location != NSNotFound {
                        let nsStr = storage.string as NSString
                        // Expand to full lines around the edit to check for fence markers
                        let lineRange = nsStr.lineRange(for: editRange)
                        let editedLines = nsStr.substring(with: lineRange)
                        if editedLines.contains("```") {
                            cachedFencedBlocks = nil
                            cachedFencedBlocksTextLength = -1
                        } else {
                            // Text length changed but no fence markers — invalidate by length mismatch
                            cachedFencedBlocksTextLength = -1
                        }
                    } else {
                        cachedFencedBlocks = nil
                        cachedFencedBlocksTextLength = -1
                    }
                }

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

                scheduleHighlight(on: textView, mode: mode)
            }

            @MainActor
            func applyTextIfNeeded(_ newText: String, to textView: NSTextView) {
                guard textView.string != newText else { return }
                isApplyingProgrammaticChange = true
                textView.string = newText
                isApplyingProgrammaticChange = false
            }

            @MainActor
            func applyHighlighting(to textView: NSTextView, config newConfig: HighlightConfiguration) {
                config = newConfig
                scheduleHighlight(on: textView, mode: .full)
            }

            @MainActor
            private func scheduleHighlight(on textView: NSTextView, mode: HighlightMode) {
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
                    self.applyHighlightingNow(to: textView, targetRange: target)
                }
            }

            @MainActor
            private func applyHighlightingNow(
                to textView: NSTextView,
                targetRange: NSRange
            ) {
                guard let storage = textView.textStorage else { return }

                // Snapshot config for consistent use throughout this method
                let cfg = config

                let fullRange = NSRange(location: 0, length: storage.length)
                guard fullRange.length > 0 else { return }

                let requested = NSIntersectionRange(fullRange, targetRange)
                let highlightRange = expandedLineRange(in: storage.string as NSString, around: requested)

                let selection = textView.selectedRanges
                let syntax = cfg.syntaxPalette.nativeSyntax
                let fencedBlocks: [FencedBlock]
                if let cached = cachedFencedBlocks, cachedFencedBlocksTextLength == storage.length {
                    fencedBlocks = cached
                } else {
                    fencedBlocks = parseFencedBlocks(in: storage.string, range: fullRange)
                    cachedFencedBlocks = fencedBlocks
                    cachedFencedBlocksTextLength = storage.length
                }
                let fencedFullRanges = fencedBlocks.map(\.full)

                // Derive themed resources
                let palette = NativeThemePalette(theme: cfg.appTheme, scheme: cfg.colorScheme)
                let baseForeground = palette.textPrimary
                let secondaryForeground = palette.textSecondary

                let baseFont = cfg.fontFamily.nsFont(size: cfg.fontSize)
                let boldFont = cfg.fontFamily.nsFont(size: cfg.fontSize, traits: .bold)
                let codeFont = cfg.fontFamily.nsFont(size: cfg.fontSize, monospaced: true)
                let codeBackground = palette.codeBackground

                let paragraphStyle = cfg.textSpacing.paragraphStyle(fontSize: cfg.fontSize)

                // Preserve scroll position across attribute changes
                let scrollPoint = textView.enclosingScrollView?.documentVisibleRect.origin

                isApplyingProgrammaticChange = true
                storage.beginEditing()

                let kern = cfg.textSpacing.kern(for: cfg.fontSize)

                storage.setAttributes(
                    [
                        .font: baseFont,
                        .foregroundColor: baseForeground,
                        .paragraphStyle: paragraphStyle,
                        .kern: kern,
                    ],
                    range: highlightRange
                )

                applyMarkdownRules(
                    to: storage,
                    fullRange: fullRange,
                    highlightRange: highlightRange,
                    fencedFullRanges: fencedFullRanges,
                    syntax: syntax,
                    boldFont: boldFont,
                    secondaryForeground: secondaryForeground,
                    codeBackground: codeBackground
                )

                applyFencedCodeHighlighting(
                    storage: storage,
                    blocks: fencedBlocks,
                    highlightRange: highlightRange,
                    syntax: syntax,
                    codeBackground: codeBackground,
                    codeFont: codeFont
                )

                storage.endEditing()

                // Validate selection ranges before restoration
                let validSelection = selection.compactMap { rangeValue -> NSValue? in
                    let range = rangeValue.rangeValue
                    guard range.location + range.length <= storage.length else { return nil }
                    return rangeValue
                }
                textView.selectedRanges = validSelection.isEmpty
                    ? [NSValue(range: NSRange(location: 0, length: 0))]
                    : validSelection

                isApplyingProgrammaticChange = false

                // Restore scroll position after attribute changes
                if let scrollPoint {
                    textView.enclosingScrollView?.documentView?.scroll(scrollPoint)
                }
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

            // MARK: - Markdown Rule Application

            /// Applies markdown syntax rules (frontmatter, headings, blockquotes, lists,
            /// inline code, links) to the highlight range. Fenced code ranges are protected
            /// from receiving markdown styling.
            private func applyMarkdownRules(
                to storage: NSTextStorage,
                fullRange: NSRange,
                highlightRange: NSRange,
                fencedFullRanges: [NSRange],
                syntax: NativeSyntaxStyle,
                boldFont: NSFont,
                secondaryForeground: NSColor,
                codeBackground: NSColor
            ) {
                let text = storage.string

                // Frontmatter uses \A anchor — compute from fullRange, then intersect
                apply(regex: frontmatterRegex, in: text, range: fullRange) { range in
                    let intersection = NSIntersectionRange(range, highlightRange)
                    guard intersection.length > 0 else { return }
                    storage.addAttribute(.foregroundColor, value: secondaryForeground, range: intersection)
                }

                apply(regex: headingRegex, in: text, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.keyword, range: range)
                    storage.addAttribute(.font, value: boldFont, range: range)
                }

                apply(regex: blockquoteRegex, in: text, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: secondaryForeground, range: range)
                }

                apply(regex: listRegex, in: text, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.call, range: range)
                }

                apply(regex: inlineCodeRegex, in: text, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.string, range: range)
                    storage.addAttribute(.backgroundColor, value: codeBackground, range: range)
                }

                apply(regex: linkRegex, in: text, range: highlightRange) { range in
                    guard !intersectsProtected(range: range, protected: fencedFullRanges) else { return }
                    storage.addAttribute(.foregroundColor, value: syntax.call, range: range)
                    storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                }
            }

            // MARK: - Fenced Block Model

            /// A parsed fenced code block with its ranges and language, computed once
            /// from the full text to avoid redundant regex work during highlighting.
            private struct FencedBlock {
                let full: NSRange
                let body: NSRange
                let language: String
            }

            // MARK: - Fenced Code Highlighting

            /// Applies fenced code block styling using pre-computed blocks from the full text.
            /// Each block is intersected with `highlightRange` so incremental edits inside
            /// a code block retain code background, font, and syntax colors.
            private func applyFencedCodeHighlighting(
                storage: NSTextStorage,
                blocks: [FencedBlock],
                highlightRange: NSRange,
                syntax: NativeSyntaxStyle,
                codeBackground: NSColor,
                codeFont: NSFont
            ) {
                let fullText = storage.string

                for block in blocks {
                    guard NSIntersectionRange(block.full, highlightRange).length > 0 else { continue }
                    guard block.body.location != NSNotFound, block.body.length > 0 else { continue }

                    let bodyIntersection = NSIntersectionRange(block.body, highlightRange)
                    guard bodyIntersection.length > 0 else { continue }

                    storage.addAttribute(.backgroundColor, value: codeBackground, range: bodyIntersection)
                    storage.addAttribute(.font, value: codeFont, range: bodyIntersection)

                    if block.language == "swift" {
                        applySwiftSyntax(
                            to: storage,
                            in: fullText,
                            range: bodyIntersection,
                            syntax: syntax
                        )
                    }
                }
            }

            /// Applies Swift keyword/type/string/comment highlighting within a range.
            /// Uses a protected-ranges pattern: strings and comments are matched first,
            /// then keywords/types/numbers/calls skip ranges already claimed.
            private func applySwiftSyntax(
                to storage: NSTextStorage,
                in text: String,
                range: NSRange,
                syntax: NativeSyntaxStyle
            ) {
                var protected: [NSRange] = []

                // Literals & comments first — these take priority
                let literalRules: [(NSRegularExpression?, NSColor)] = [
                    (SwiftSyntaxRegexes.strings, syntax.string),
                    (SwiftSyntaxRegexes.blockComments, syntax.comment),
                    (SwiftSyntaxRegexes.lineComments, syntax.comment),
                ]
                for (regex, color) in literalRules {
                    apply(regex: regex, in: text, range: range) { matchRange in
                        storage.addAttribute(.foregroundColor, value: color, range: matchRange)
                        protected.append(matchRange)
                    }
                }

                // Semantic tokens — skip protected ranges
                let semanticRules: [(NSRegularExpression?, NSColor)] = [
                    (SwiftSyntaxRegexes.keywords, syntax.keyword),
                    (SwiftSyntaxRegexes.numbers, syntax.number),
                    (SwiftSyntaxRegexes.types, syntax.type),
                    (SwiftSyntaxRegexes.calls, syntax.call),
                ]
                for (regex, color) in semanticRules {
                    apply(regex: regex, in: text, range: range) { matchRange in
                        guard !intersectsProtected(range: matchRange, protected: protected) else { return }
                        storage.addAttribute(.foregroundColor, value: color, range: matchRange)
                    }
                }
            }

            /// Parses all fenced code blocks from the full text, capturing ranges and language
            /// in a single pass. The results are reused for both protected-range checks and
            /// code block styling, avoiding redundant regex work.
            private func parseFencedBlocks(in text: String, range: NSRange) -> [FencedBlock] {
                guard let fencedCodeRegex else { return [] }

                var blocks: [FencedBlock] = []
                let nsText = text as NSString
                fencedCodeRegex.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
                    guard
                        let result,
                        result.range.location != NSNotFound,
                        result.range.length > 0
                    else { return }

                    let bodyRange = result.numberOfRanges >= 4
                        ? result.range(at: 3)
                        : NSRange(location: NSNotFound, length: 0)

                    let languageRange = result.numberOfRanges >= 3 ? result.range(at: 2) : NSRange(location: NSNotFound, length: 0)
                    let language = languageRange.location != NSNotFound
                        ? nsText.substring(with: languageRange).lowercased()
                        : ""

                    blocks.append(FencedBlock(full: result.range, body: bodyRange, language: language))
                }
                return blocks
            }

            /// Binary search intersection check — requires `protected` sorted by location.
            private func intersectsProtected(range: NSRange, protected: [NSRange]) -> Bool {
                let rangeEnd = range.location + range.length
                var lo = 0, hi = protected.count
                while lo < hi {
                    let mid = (lo + hi) / 2
                    if protected[mid].location + protected[mid].length <= range.location {
                        lo = mid + 1
                    } else {
                        hi = mid
                    }
                }
                return lo < protected.count && protected[lo].location < rangeEnd
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
