//
//  MarkdownEditorTextView.swift
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
            let nsString = string as NSString

            // Bounds check before substring extraction
            guard selectedRange.location != NSNotFound,
                  selectedRange.location + selectedRange.length <= nsString.length
            else { return }

            let selectedText = nsString.substring(with: selectedRange)
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
#endif
