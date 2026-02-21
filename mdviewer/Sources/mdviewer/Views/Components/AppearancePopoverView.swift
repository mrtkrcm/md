internal import SwiftUI

// MARK: - AppearancePopoverView

/// Settings popover for appearance, reader, and syntax configuration.
/// Styled with glass panel effect for consistent liquid design language.
struct AppearancePopoverView: View {
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
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
                // Appearance Section
                popoverSection(title: "Appearance") {
                    Picker("", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // Reader Section
                popoverSection(title: "Reader") {
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

                // Syntax Section
                popoverSection(title: "Syntax") {
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
            .padding(DesignTokens.Spacing.extraLarge)
        }
        .frame(width: DesignTokens.Layout.appearancePopoverWidth)
        .glassPanel(cornerRadius: DesignTokens.CornerRadius.standard)
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func popoverSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Text(title)
                .font(.system(
                    size: DesignTokens.Typography.standard,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)

            content()
        }
    }
}
