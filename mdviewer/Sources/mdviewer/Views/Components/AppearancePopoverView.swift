//
//  AppearancePopoverView.swift
//  mdviewer
//

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
    @Binding var showLineNumbers: Bool
    @Binding var typographyPreferences: TypographyPreferences

    @State private var showAdvancedTypography = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
                appearanceSection
                readerSection
                typographySection
                syntaxSection
            }
            .padding(DesignTokens.Spacing.extraLarge)
        }
        .frame(width: DesignTokens.Layout.appearancePopoverWidth)
        .glassPanel(cornerRadius: DesignTokens.CornerRadius.standard)
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        popoverSection(title: "Appearance") {
            Picker("", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Appearance Mode")
        }
    }

    private var readerSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
            Divider()

            popoverSection(title: "Reader") {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .accessibilityLabel("Reader Theme")

                Picker("Font", selection: $readerFontFamily) {
                    ForEach(ReaderFontFamily.allCases) { family in
                        Text(family.rawValue).tag(family)
                    }
                }
                .accessibilityLabel("Reader Font")

                Picker("Text Size", selection: $readerFontSize) {
                    ForEach(ReaderFontSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .accessibilityLabel("Reader Text Size")

                Picker("Text Spacing", selection: $readerTextSpacing) {
                    ForEach(ReaderTextSpacing.allCases) { spacing in
                        Text(spacing.rawValue).tag(spacing)
                    }
                }
                .accessibilityLabel("Reader Text Spacing")

                Picker("Column Width", selection: $readerColumnWidth) {
                    ForEach(ReaderColumnWidth.allCases) { width in
                        Text(width.rawValue).tag(width)
                    }
                }
                .accessibilityLabel("Reader Column Width")
            }
        }
    }

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Divider()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAdvancedTypography.toggle()
                }
            } label: {
                HStack {
                    Text("Typography")
                        .font(.system(size: DesignTokens.Typography.standard, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showAdvancedTypography ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Advanced Typography Settings")
            .accessibilityHint(showAdvancedTypography ? "Collapse typography options" : "Expand typography options")

            if showAdvancedTypography {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                    Toggle("Font Smoothing", isOn: $typographyPreferences.fontSmoothing)
                        .accessibilityLabel("Enable Font Smoothing")

                    Toggle("Ligatures", isOn: $typographyPreferences.ligatures)
                        .accessibilityLabel("Enable Font Ligatures")

                    Toggle("Hanging Punctuation", isOn: $typographyPreferences.hangingPunctuation)
                        .accessibilityLabel("Enable Hanging Punctuation")

                    Toggle("Hyphenation", isOn: $typographyPreferences.hyphenation)
                        .accessibilityLabel("Enable Automatic Hyphenation")

                    Picker("Justification", selection: $typographyPreferences.justification) {
                        ForEach(TextJustification.allCases) { justification in
                            Text(justification.rawValue).tag(justification)
                        }
                    }
                    .accessibilityLabel("Text Justification")

                    HStack {
                        Text("Presets")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Conservative") {
                            typographyPreferences = .conservative
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)

                        Button("Default") {
                            typographyPreferences = TypographyPreferences()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)

                        Button("Premium") {
                            typographyPreferences = .premium
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
                .padding(.top, DesignTokens.Spacing.tight)
            }
        }
    }

    private var syntaxSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
            Divider()

            popoverSection(title: "Syntax") {
                Picker("Palette", selection: $syntaxPalette) {
                    ForEach(SyntaxPalette.allCases) { palette in
                        Text(palette.rawValue).tag(palette)
                    }
                }
                .accessibilityLabel("Syntax Highlighting Palette")

                Picker("Code Size", selection: $codeFontSize) {
                    ForEach(CodeFontSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .accessibilityLabel("Code Font Size")

                Toggle("Line Numbers", isOn: $showLineNumbers)
                    .accessibilityLabel("Show Line Numbers")
                    .accessibilityHint("Display line numbers in the editor")
            }
        }
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func popoverSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Text(title)
                .font(.system(size: DesignTokens.Typography.standard, weight: .semibold))
                .foregroundStyle(.secondary)

            content()
        }
    }
}

// MARK: - Previews

#Preview("Appearance Popover") {
    AppearancePopoverView(
        selectedTheme: .constant(.github),
        readerFontSize: .constant(.standard),
        readerFontFamily: .constant(.newYork),
        syntaxPalette: .constant(.midnight),
        codeFontSize: .constant(.medium),
        appearanceMode: .constant(.auto),
        readerTextSpacing: .constant(.balanced),
        readerColumnWidth: .constant(.balanced),
        showLineNumbers: .constant(true),
        typographyPreferences: .constant(TypographyPreferences())
    )
}
