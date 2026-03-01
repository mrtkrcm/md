//
//  RawMarkdownEditor.swift
//  mdviewer
//

internal import AppKit
internal import HighlightedTextEditor
internal import SwiftUI

// MARK: - Raw Markdown Editor

/// SwiftUI wrapper using HighlightedTextEditor for markdown syntax highlighting.
/// Provides a native text editing experience with live markdown highlighting.
struct RawMarkdownEditor: View {
    @Binding var text: String
    let fontSize: CGFloat
    let colorScheme: ColorScheme

    var body: some View {
        HighlightedTextEditor(text: $text, highlightRules: .markdown)
            .introspect { editor in
                configureTextView(editor.textView)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func configureTextView(_ textView: NSTextView) {
        // Configure for plain text editing
        textView.isRichText = false
        textView.usesFindBar = true
        textView.allowsUndo = true
        textView.drawsBackground = true
        textView.focusRingType = .none

        // Set font size
        let newFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = newFont
        textView.typingAttributes = [.font: newFont]

        // Set background and text colors
        textView.backgroundColor = colorScheme == .dark ? .black : .white
        textView.textColor = colorScheme == .dark ? .white : .black
    }
}
