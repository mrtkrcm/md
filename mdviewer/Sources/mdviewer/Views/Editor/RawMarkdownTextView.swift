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

        @objc func insertBold(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "**", suffix: "**")
        }

        @objc func insertItalic(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "*", suffix: "*")
        }

        @objc func insertCode(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "`", suffix: "`")
        }

        @objc func insertCodeBlock(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "\n```\n", suffix: "\n```\n")
        }

        @objc func insertLink(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "[", suffix: "](url)")
        }

        @objc func insertImage(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "![", suffix: "](image-url)")
        }

        @objc func insertHeading(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "# ", suffix: "")
        }

        @objc func insertQuote(_ sender: Any?) {
            insertMarkdownSyntax(prefix: "> ", suffix: "")
        }

        @objc func insertList(_ sender: Any?) {
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

        override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
            // Support sending/receiving text via Services menu
            if let sendType = sendType, sendType == .string {
                return self
            }
            if let returnType = returnType, returnType == .string {
                return self
            }
            return super.validRequestor(forSendType: sendType, returnType: returnType)
        }

        @objc func insertTextFromService(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
            guard let text = pasteboard.string(forType: .string) else {
                error.pointee = "No text found on pasteboard" as NSString
                return
            }
            insertText(text, replacementRange: selectedRange())
        }

        @objc func replaceTextFromService(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
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
            let button = NSButton(image: NSImage(systemSymbolName: imageName, accessibilityDescription: title)!, target: self, action: action)
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
        @Binding var text: String
        let fontFamily: ReaderFontFamily
        let fontSize: CGFloat
        let syntaxPalette: SyntaxPalette
        let colorScheme: ColorScheme

        func makeNSView(context: Context) -> NSScrollView {
            let textView = MarkdownEditorTextView()
            context.coordinator.textView = textView
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
#endif
