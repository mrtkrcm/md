//
//  AppearancePopoverView.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - AppearancePopoverView

/// Settings popover for appearance, reader, and syntax configuration.
/// Uses native macOS sectioned form layout for clear organization.
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

    var body: some View {
        Form {
            Section("Appearance") {
                appearanceSection
            }

            Section("Reader") {
                readerSection
            }

            Section("Typography") {
                typographySection
            }

            Section("Syntax") {
                syntaxSection
            }
        }
        .formStyle(.grouped)
        .frame(width: DesignTokens.Layout.appearancePopoverWidth)
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Picker("Mode", selection: $appearanceMode) {
            ForEach(AppearanceMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Appearance Mode")
    }

    private var readerSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
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

    private var typographySection: some View {
        TypographySubsectionView(typographyPreferences: $typographyPreferences) {
            typographyPreferences = $0
        }
    }

    private var syntaxSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
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
