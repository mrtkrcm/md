internal import SwiftUI

// MARK: - Settings View

/// Settings panel with liquid design styling.
/// Uses glass panel effect and subtle animations for consistent macOS aesthetic.
struct SettingsView: View {
    @AppStorage("theme") private var selectedThemeRaw = AppTheme.basic.rawValue
    @AppStorage("syntaxPalette") private var syntaxPaletteRaw = SyntaxPalette.midnight.rawValue
    @AppStorage("readerFontSize") private var readerFontSizeRaw = ReaderFontSize.standard.rawValue
    @AppStorage("codeFontSize") private var codeFontSizeRaw = CodeFontSize.medium.rawValue
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.auto.rawValue
    @AppStorage("readerFontFamily") private var readerFontFamilyRaw = ReaderFontFamily.newYork.rawValue
    @AppStorage("readerMode") private var readerModeRaw = ReaderMode.rendered.rawValue
    @AppStorage("readerTextSpacing") private var readerTextSpacingRaw = ReaderTextSpacing.balanced.rawValue
    @AppStorage("readerColumnWidth") private var readerColumnWidthRaw = ReaderColumnWidth.balanced.rawValue

    var body: some View {
        ZStack {
            // Liquid background for consistent design language
            LiquidBackground()
                .ignoresSafeArea()

            // Glass panel container
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
                    // Appearance Section
                    settingsSection(title: "Appearance") {
                        Picker("Mode", selection: appearanceModeBinding) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    // Markdown Section
                    settingsSection(title: "Markdown") {
                        Picker("Default View", selection: readerModeBinding) {
                            ForEach(ReaderMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }

                        Picker("Theme", selection: selectedThemeBinding) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }

                        Picker("Font", selection: readerFontFamilyBinding) {
                            ForEach(ReaderFontFamily.allCases) { family in
                                Text(family.rawValue).tag(family)
                            }
                        }

                        Picker("Text Size", selection: readerFontSizeBinding) {
                            ForEach(ReaderFontSize.allCases) { size in
                                Text(size.label).tag(size)
                            }
                        }

                        Picker("Text Spacing", selection: readerTextSpacingBinding) {
                            ForEach(ReaderTextSpacing.allCases) { spacing in
                                Text(spacing.rawValue).tag(spacing)
                            }
                        }

                        Picker("Column Width", selection: readerColumnWidthBinding) {
                            ForEach(ReaderColumnWidth.allCases) { width in
                                Text(width.rawValue).tag(width)
                            }
                        }
                    }

                    Divider()

                    // Syntax Section
                    settingsSection(title: "Syntax Highlighting") {
                        Picker("Palette", selection: syntaxPaletteBinding) {
                            ForEach(SyntaxPalette.allCases) { palette in
                                Text(palette.rawValue).tag(palette)
                            }
                        }

                        Picker("Code Size", selection: codeFontSizeBinding) {
                            ForEach(CodeFontSize.allCases) { size in
                                Text(size.label).tag(size)
                            }
                        }
                    }
                }
                .padding(DesignTokens.Spacing.extraLarge)
            }
            .glassPanel(cornerRadius: DesignTokens.CornerRadius.large)
            .padding(DesignTokens.Spacing.extraLarge)
        }
        .frame(
            width: DesignTokens.Layout.settingsWidth,
            height: DesignTokens.Layout.settingsHeight
        )
        .liquidAnimation(selectedThemeRaw)
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.relaxed) {
            Text(title)
                .font(.system(
                    size: DesignTokens.Typography.standard,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)

            content()
        }
    }

    // MARK: - Bindings

    private var selectedThemeBinding: Binding<AppTheme> { $selectedThemeRaw.stored() }
    private var syntaxPaletteBinding: Binding<SyntaxPalette> { $syntaxPaletteRaw.stored() }
    private var readerFontSizeBinding: Binding<ReaderFontSize> { $readerFontSizeRaw.stored() }
    private var codeFontSizeBinding: Binding<CodeFontSize> { $codeFontSizeRaw.stored() }
    private var appearanceModeBinding: Binding<AppearanceMode> { $appearanceModeRaw.stored() }
    private var readerFontFamilyBinding: Binding<ReaderFontFamily> { $readerFontFamilyRaw.stored() }
    private var readerModeBinding: Binding<ReaderMode> { $readerModeRaw.stored() }
    private var readerTextSpacingBinding: Binding<ReaderTextSpacing> { $readerTextSpacingRaw.stored() }
    private var readerColumnWidthBinding: Binding<ReaderColumnWidth> { $readerColumnWidthRaw.stored() }
}
