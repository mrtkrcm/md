//
//  SettingsView.swift
//  mdviewer
//
//  Settings panel with liquid design styling.
//

internal import SwiftUI

/// Settings panel with liquid design styling.
///
/// Uses glass panel effect and subtle animations for consistent macOS aesthetic.
/// Preferences are automatically persisted via the shared `AppPreferences` object.
struct SettingsView: View {
    @Environment(\.preferences) private var preferences

    var body: some View {
        ZStack {
            LiquidBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
                    appearanceSection
                    Divider()
                    markdownSection
                    Divider()
                    syntaxSection
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
        .liquidAnimation(preferences.theme)
    }

    // MARK: - Sections

    @ViewBuilder
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            Picker("Mode", selection: binding(\.appearanceMode)) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var markdownSection: some View {
        SettingsSection(title: "Markdown") {
            Picker("Default View", selection: binding(\.readerMode)) {
                ForEach(ReaderMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Picker("Theme", selection: binding(\.theme)) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }

            Picker("Font", selection: binding(\.readerFontFamily)) {
                ForEach(ReaderFontFamily.allCases) { family in
                    Text(family.rawValue).tag(family)
                }
            }

            Picker("Text Size", selection: binding(\.readerFontSize)) {
                ForEach(ReaderFontSize.allCases) { size in
                    Text(size.label).tag(size)
                }
            }

            Picker("Text Spacing", selection: binding(\.readerTextSpacing)) {
                ForEach(ReaderTextSpacing.allCases) { spacing in
                    Text(spacing.rawValue).tag(spacing)
                }
            }

            Picker("Column Width", selection: binding(\.readerColumnWidth)) {
                ForEach(ReaderColumnWidth.allCases) { width in
                    Text(width.rawValue).tag(width)
                }
            }
        }
    }

    @ViewBuilder
    private var syntaxSection: some View {
        SettingsSection(title: "Syntax Highlighting") {
            Picker("Palette", selection: binding(\.syntaxPalette)) {
                ForEach(SyntaxPalette.allCases) { palette in
                    Text(palette.rawValue).tag(palette)
                }
            }

            Picker("Code Size", selection: binding(\.codeFontSize)) {
                ForEach(CodeFontSize.allCases) { size in
                    Text(size.label).tag(size)
                }
            }
        }
    }

    // MARK: - Binding Helper

    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { preferences[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Settings Section

/// Reusable section container for settings views.
private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.relaxed) {
            Text(title)
                .font(.system(
                    size: DesignTokens.Typography.standard,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)

            content
        }
    }
}

// MARK: - Previews

#Preview("Settings") {
    SettingsView()
        .environment(\.preferences, AppPreferences.shared)
}
