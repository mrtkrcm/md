import SwiftUI

struct SettingsView: View {
    private enum ReaderModeSetting: String, CaseIterable, Identifiable {
        case rendered = "Rendered"
        case raw = "Raw"

        var id: String { rawValue }
    }

    @AppStorage("theme") private var selectedThemeRaw = AppTheme.basic.rawValue
    @AppStorage("syntaxPalette") private var syntaxPaletteRaw = SyntaxPalette.midnight.rawValue
    @AppStorage("readerFontSize") private var readerFontSizeRaw = ReaderFontSize.standard.rawValue
    @AppStorage("codeFontSize") private var codeFontSizeRaw = CodeFontSize.medium.rawValue
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.auto.rawValue
    @AppStorage("readerFontFamily") private var readerFontFamilyRaw = ReaderFontFamily.newYork.rawValue
    @AppStorage("readerMode") private var readerModeRaw = ReaderModeSetting.rendered.rawValue

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Mode", selection: appearanceModeBinding) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Markdown") {
                Picker("Default View", selection: readerModeBinding) {
                    ForEach(ReaderModeSetting.allCases) { mode in
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
            }

            Section("Syntax Highlighting (Swift)") {
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
        .formStyle(.grouped)
        .frame(width: 460, height: 320)
        .padding(12)
    }

    private var selectedThemeBinding: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: selectedThemeRaw) ?? .basic },
            set: { selectedThemeRaw = $0.rawValue }
        )
    }

    private var syntaxPaletteBinding: Binding<SyntaxPalette> {
        Binding(
            get: { SyntaxPalette.from(rawValue: syntaxPaletteRaw) },
            set: { syntaxPaletteRaw = $0.rawValue }
        )
    }

    private var appearanceModeBinding: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode.from(rawValue: appearanceModeRaw) },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    private var readerFontFamilyBinding: Binding<ReaderFontFamily> {
        Binding(
            get: { ReaderFontFamily.from(rawValue: readerFontFamilyRaw) },
            set: { readerFontFamilyRaw = $0.rawValue }
        )
    }

    private var readerFontSizeBinding: Binding<ReaderFontSize> {
        Binding(
            get: { ReaderFontSize.from(rawValue: readerFontSizeRaw) },
            set: { readerFontSizeRaw = $0.rawValue }
        )
    }

    private var codeFontSizeBinding: Binding<CodeFontSize> {
        Binding(
            get: { CodeFontSize.from(rawValue: codeFontSizeRaw) },
            set: { codeFontSizeRaw = $0.rawValue }
        )
    }

    private var readerModeBinding: Binding<ReaderModeSetting> {
        Binding(
            get: { ReaderModeSetting(rawValue: readerModeRaw) ?? .rendered },
            set: { readerModeRaw = $0.rawValue }
        )
    }
}
