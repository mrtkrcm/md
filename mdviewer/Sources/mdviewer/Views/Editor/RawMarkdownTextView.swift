//
//  RawMarkdownTextView.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    internal import AppKit

    // MARK: - Touch Bar Support

    /// Custom text view with Touch Bar support for markdown editing
    @MainActor
    final class MarkdownEditorTextView: NSTextView {
        override func makeTouchBar() -> NSTouchBar? {
            let touchBar = NSTouchBar()
            touchBar.delegate = self
            touchBar.customizationIdentifier = "com.mrtkrcm.mdviewer.editor"
            touchBar.defaultItemIdentifiers = [
                .boldButton,
                .italicButton,
                .codeButton,
                .linkButton,
                .imageButton,
                .flexibleSpace,
                .otherItemsProxy,
            ]
            touchBar.customizationAllowedItemIdentifiers = [
                .boldButton,
                .italicButton,
                .codeButton,
                .linkButton,
                .imageButton,
                .headingButton,
                .quoteButton,
                .listButton,
            ]
            return touchBar
        }

        // MARK: - Touch Bar Actions

        @objc
        func insertBold(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "**", suffix: "**")
        }

        @objc
        func insertItalic(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "*", suffix: "*")
        }

        @objc
        func insertCode(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "`", suffix: "`")
        }

        @objc
        func insertCodeBlock(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "\n```\n", suffix: "\n```\n")
        }

        @objc
        func insertLink(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "[", suffix: "](url)")
        }

        @objc
        func insertImage(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "![", suffix: "](image-url)")
        }

        @objc
        func insertHeading(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "# ", suffix: "")
        }

        @objc
        func insertQuote(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "> ", suffix: "")
        }

        @objc
        func insertList(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "- ", suffix: "")
        }

        private func insertMarkdownSyntax(prefix: String, suffix: String) {
            let selectedRange = selectedRange()
            let selectedText = (string as NSString).substring(with: selectedRange)
            let newText = prefix + selectedText + suffix

            textStorage?.replaceCharacters(in: selectedRange, with: newText)

            // Position cursor between prefix and suffix if no text was selected
            if selectedText.isEmpty {
                let cursorPosition = selectedRange.location + prefix.utf16.count
                setSelectedRange(NSRange(location: cursorPosition, length: 0))
            } else {
                setSelectedRange(NSRange(location: selectedRange.location, length: newText.utf16.count))
            }

            // Notify delegate of text change
            if let delegate = delegate as? RawMarkdownTextView.Coordinator {
                delegate.textDidChange(Notification(name: NSText.didChangeNotification, object: self))
            }
        }

        // MARK: - Services Menu Support

        override func validRequestor(
            forSendType sendType: NSPasteboard.PasteboardType?,
            returnType: NSPasteboard.PasteboardType?
        ) -> Any? {
            // Support sending/receiving text via Services menu
            if let sendType, sendType == .string {
                return self
            }
            if let returnType, returnType == .string {
                return self
            }
            return super.validRequestor(forSendType: sendType, returnType: returnType)
        }

        @objc
        func insertTextFromService(
            _ pasteboard: NSPasteboard,
            userData: String?,
            error: AutoreleasingUnsafeMutablePointer<NSString?>
        ) {
            guard let text = pasteboard.string(forType: .string) else {
                error.pointee = "No text found on pasteboard" as NSString
                return
            }
            insertText(text, replacementRange: selectedRange())
        }

        @objc
        func replaceTextFromService(
            _ pasteboard: NSPasteboard,
            userData: String?,
            error: AutoreleasingUnsafeMutablePointer<NSString?>
        ) {
            guard let text = pasteboard.string(forType: .string) else {
                error.pointee = "No text found on pasteboard" as NSString
                return
            }
            let fullRange = NSRange(location: 0, length: string.utf16.count)
            textStorage?.replaceCharacters(in: fullRange, with: text)
        }
    }

    // MARK: - NSTouchBarDelegate

    extension MarkdownEditorTextView {
        override func touchBar(
            _ touchBar: NSTouchBar,
            makeItemForIdentifier identifier: NSTouchBarItem.Identifier
        ) -> NSTouchBarItem? {
            switch identifier {
            case .boldButton:
                return makeTouchBarButton(
                    identifier: identifier,
                    title: "Bold",
                    imageName: "bold",
                    action: #selector(insertBold)
                )
            case .italicButton:
                return makeTouchBarButton(
                    identifier: identifier,
                    title: "Italic",
                    imageName: "italic",
                    action: #selector(insertItalic)
                )
            case .codeButton:
                return makeTouchBarButton(
                    identifier: identifier,
                    title: "Code",
                    imageName: "chevron.left.forwardslash.chevron.right",
                    action: #selector(insertCode)
                )
            case .linkButton:
                return makeTouchBarButton(
                    identifier: identifier,
                    title: "Link",
                    imageName: "link",
                    action: #selector(insertLink)
                )
            case .imageButton:
                return makeTouchBarButton(
                    identifier: identifier,
                    title: "Image",
                    imageName: "photo",
                    action: #selector(insertImage)
                )
            case .headingButton:
                return makeTouchBarButton(
                    identifier: identifier,
                    title: "Heading",
                    imageName: "textformat.size",
                    action: #selector(insertHeading)
                )
            case .quoteButton:
                return makeTouchBarButton(
                    identifier: identifier,
                    title: "Quote",
                    imageName: "text.quote",
                    action: #selector(insertQuote)
                )
            case .listButton:
                return makeTouchBarButton(
                    identifier: identifier,
                    title: "List",
                    imageName: "list.bullet",
                    action: #selector(insertList)
                )
            default:
                return nil
            }
        }

        private func makeTouchBarButton(
            identifier: NSTouchBarItem.Identifier,
            title: String,
            imageName: String,
            action: Selector
        ) -> NSTouchBarItem {
            let image = NSImage(systemSymbolName: imageName, accessibilityDescription: title) ?? NSImage()
            let button = NSButton(image: image, target: self, action: action)
            button.bezelStyle = .texturedRounded

            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = button
            item.customizationLabel = title
            return item
        }
    }

    // MARK: - Touch Bar Item Identifiers

    extension NSTouchBarItem.Identifier {
        static let boldButton = NSTouchBarItem.Identifier("com.mrtkrcm.mdviewer.touchbar.bold")
        static let italicButton = NSTouchBarItem.Identifier("com.mrtkrcm.mdviewer.touchbar.italic")
        static let codeButton = NSTouchBarItem.Identifier("com.mrtkrcm.mdviewer.touchbar.code")
        static let linkButton = NSTouchBarItem.Identifier("com.mrtkrcm.mdviewer.touchbar.link")
        static let imageButton = NSTouchBarItem.Identifier("com.mrtkrcm.mdviewer.touchbar.image")
        static let headingButton = NSTouchBarItem.Identifier("com.mrtkrcm.mdviewer.touchbar.heading")
        static let quoteButton = NSTouchBarItem.Identifier("com.mrtkrcm.mdviewer.touchbar.quote")
        static let listButton = NSTouchBarItem.Identifier("com.mrtkrcm.mdviewer.touchbar.list")
    }

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
            @Binding private var text: String
            private var isApplyingProgrammaticChange = false
            private var currentFontFamily: ReaderFontFamily = .newYork
            private var currentFontSize: CGFloat = 14
            private var currentSyntaxPalette: SyntaxPalette = .midnight
            private var currentColorScheme: ColorScheme = .light
            weak var textView: NSTextView?

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
                let selectedText = (textView.string as NSString).substring(with: selectedRange)

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

    // MARK: - Line Number Ruler

    /// A custom ruler view that displays line numbers for NSTextView
    final class LineNumberRulerView: NSRulerView {
        private var font: NSFont = .monospacedSystemFont(ofSize: 11, weight: .regular)
        private var textColor: NSColor = .secondaryLabelColor
        private var separatorColor: NSColor = .separatorColor

        init(scrollView: NSScrollView?) {
            super.init(scrollView: scrollView, orientation: .verticalRuler)
            ruleThickness = 40
            needsDisplay = true
        }

        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func awakeFromNib() {
            super.awakeFromNib()
            MainActor.assumeIsolated {
                self.ruleThickness = 40
            }
        }

        /// Define the required thickness for the ruler
        override var requiredThickness: CGFloat {
            40
        }

        override func draw(_ dirtyRect: NSRect) {
            // Fill background
            NSColor.controlBackgroundColor.setFill()
            dirtyRect.fill()

            // Draw separator line on the right edge
            let separatorPath = NSBezierPath()
            separatorPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: dirtyRect.minY))
            separatorPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: dirtyRect.maxY))
            separatorColor.withAlphaComponent(0.3).setStroke()
            separatorPath.lineWidth = 0.5
            separatorPath.stroke()

            // Draw line numbers
            drawLineNumbers(in: dirtyRect)
        }

        private func drawLineNumbers(in rect: NSRect) {
            guard
                let textView = clientView as? NSTextView,
                let layoutManager = textView.layoutManager,
                let textContainer = textView.textContainer else { return }

            // Get the visible glyph range
            let visibleRect = textView.visibleRect
            let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
            let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

            guard glyphRange.length > 0 || textView.string.isEmpty else { return }

            let string = textView.string as NSString
            var lineNumber = 1

            // Count lines up to the visible range start
            if characterRange.location > 0 {
                let prevRange = NSRange(location: 0, length: characterRange.location)
                let prevString = string.substring(with: prevRange)
                lineNumber = prevString.components(separatedBy: .newlines).count
            }

            // Get the text view's coordinate conversion
            layoutManager
                .enumerateLineFragments(forGlyphRange: glyphRange) { [weak self] lineRect, _, _, glyphRangeForLine, _ in
                    guard let self else { return }

                    // Get the character range for this line fragment
                    let charRange = layoutManager.characterRange(
                        forGlyphRange: glyphRangeForLine,
                        actualGlyphRange: nil
                    )
                    let lineStart = charRange.location

                    // Only draw line number for the first fragment of each line (not soft wraps)
                    let isFirstFragment = lineStart == 0 ||
                        (lineStart > 0 && lineStart - 1 < string.length && string.character(at: lineStart - 1) == 0x0A)

                    if isFirstFragment {
                        // Convert the line rect to ruler coordinates
                        let convertedRect = textView.convert(lineRect, to: self)

                        // Only draw if visible in the ruler's dirty rect
                        if convertedRect.intersects(rect) {
                            let numberString = "\(lineNumber)" as NSString
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: font,
                                .foregroundColor: textColor,
                            ]
                            let stringSize = numberString.size(withAttributes: attributes)

                            // Right-align the number with padding
                            let x = ruleThickness - stringSize.width - 8
                            let y = convertedRect.minY + (convertedRect.height - stringSize.height) / 2

                            numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
                        }

                        lineNumber += 1
                    }
                }

            // Handle empty document case - show line 1
            if textView.string.isEmpty {
                let numberString = "1" as NSString
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: textColor,
                ]
                let stringSize = numberString.size(withAttributes: attributes)
                let x = ruleThickness - stringSize.width - 8
                let y = textView.textContainerInset.height + (font.pointSize - stringSize.height) / 2
                numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
            }
        }
    }
#endif
