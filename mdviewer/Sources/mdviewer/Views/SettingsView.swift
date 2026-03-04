//
//  SettingsView.swift
//  mdviewer
//

internal import SwiftUI

/// Settings panel with macOS native sectioned layout.
/// Preferences are automatically persisted via the shared `AppPreferences` object.
/// All controls have full VoiceOver accessibility support.
struct SettingsView: View {
    @Environment(\.preferences) private var preferences

    var body: some View {
        Form {
            Section("General") {
                Picker("Appearance", selection: binding(\.appearanceMode)) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Appearance Mode")

                Picker("Theme", selection: binding(\.theme)) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .accessibilityLabel("Reader Theme")
            }

            Section("Typography") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                    HStack {
                        Text("Font Family")
                            .foregroundStyle(.primary)
                        Spacer()
                        FontFamilyPicker(selection: binding(\.readerFontFamily))
                            .frame(width: 140)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Reader Font Family")

                    Picker("Text Size", selection: binding(\.readerFontSize)) {
                        ForEach(ReaderFontSize.allCases) { size in
                            Text(size.label).tag(size)
                        }
                    }
                    .accessibilityLabel("Reader Font Size")

                    Picker("Line Spacing", selection: binding(\.readerTextSpacing)) {
                        ForEach(ReaderTextSpacing.allCases) { spacing in
                            Text(spacing.rawValue).tag(spacing)
                        }
                    }
                    .accessibilityLabel("Reader Line Spacing")

                    Picker("Column Width", selection: binding(\.readerColumnWidth)) {
                        ForEach(ReaderColumnWidth.allCases) { width in
                            Text(width.rawValue).tag(width)
                        }
                    }
                    .accessibilityLabel("Reader Column Width")

                    TypographySubsectionView(typographyPreferences: Binding(
                        get: { preferences.typographyPreferences },
                        set: { preferences.typographyPreferences = $0 }
                    )) { newValue in
                        preferences.typographyPreferences = newValue
                    }
                }
            }

            Section("Reading") {
                Picker("Default View", selection: binding(\.readerMode)) {
                    ForEach(ReaderMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .accessibilityLabel("Default View Mode")
            }

            Section("Code") {
                Picker("Syntax Palette", selection: binding(\.syntaxPalette)) {
                    ForEach(SyntaxPalette.allCases) { palette in
                        Text(palette.rawValue).tag(palette)
                    }
                }
                .accessibilityLabel("Syntax Highlighting Palette")

                Picker("Code Font Size", selection: binding(\.codeFontSize)) {
                    ForEach(CodeFontSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .accessibilityLabel("Code Font Size")

                Toggle("Line Numbers", isOn: binding(\.showLineNumbers))
                    .accessibilityLabel("Show Line Numbers")
                    .accessibilityHint("Display line numbers in the editor")
            }

            Section("System") {
                Picker("Large File Warning", selection: binding(\.largeFileThreshold)) {
                    ForEach(LargeFileThreshold.allCases) { threshold in
                        Text(threshold.label).tag(threshold)
                    }
                }
                .accessibilityLabel("Large File Warning Threshold")
                .accessibilityHint("Show warning when opening files larger than this size")
            }
        }
        .formStyle(.grouped)
        .frame(
            width: DesignTokens.Layout.settingsWidth,
            height: DesignTokens.Layout.settingsHeight
        )
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("SettingsView")
    }

    // MARK: - Binding Helpers

    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { preferences[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Previews

#Preview("Settings") {
    SettingsView()
        .environment(\.preferences, AppPreferences.shared)
}
