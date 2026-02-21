//
//  RawMarkdownEditor.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Raw Markdown Editor

/// SwiftUI wrapper that hosts the raw markdown editing text view
/// with syntax highlighting inside a glass-panel container.
/// Styled with liquid design tokens for consistency.
struct RawMarkdownEditor: View {
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
        .frame(minHeight: DesignTokens.Layout.minContentHeight, alignment: .topLeading)
        .glassPanel(cornerRadius: DesignTokens.CornerRadius.medium)
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.extraLarge)
    }
}
