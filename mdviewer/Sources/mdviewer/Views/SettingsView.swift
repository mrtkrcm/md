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
/// All controls have full VoiceOver accessibility support.
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
                    accessibilitySection
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
        // Mark as settings panel for VoiceOver
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("SettingsView")
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
            .accessibilityLabel("Appearance Mode")
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
            .accessibilityLabel("Default View Mode")

            Picker("Theme", selection: binding(\.theme)) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .accessibilityLabel("Reader Theme")

            Picker("Font", selection: binding(\.readerFontFamily)) {
                ForEach(ReaderFontFamily.allCases) { family in
                    Text(family.rawValue).tag(family)
                }
            }
            .accessibilityLabel("Reader Font")

            Picker("Text Size", selection: binding(\.readerFontSize)) {
                ForEach(ReaderFontSize.allCases) { size in
                    Text(size.label).tag(size)
                }
            }
            .accessibilityLabel("Reader Text Size")

            Picker("Text Spacing", selection: binding(\.readerTextSpacing)) {
                ForEach(ReaderTextSpacing.allCases) { spacing in
                    Text(spacing.rawValue).tag(spacing)
                }
            }
            .accessibilityLabel("Reader Text Spacing")

            Picker("Column Width", selection: binding(\.readerColumnWidth)) {
                ForEach(ReaderColumnWidth.allCases) { width in
                    Text(width.rawValue).tag(width)
                }
            }
            .accessibilityLabel("Reader Column Width")
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
            .accessibilityLabel("Syntax Highlighting Palette")

            Picker("Code Size", selection: binding(\.codeFontSize)) {
                ForEach(CodeFontSize.allCases) { size in
                    Text(size.label).tag(size)
                }
            }
            .accessibilityLabel("Code Font Size")
        }
    }

    @ViewBuilder
    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
            Divider()

            SettingsSection(title: "Accessibility") {
                Picker("Large File Warning", selection: binding(\.largeFileThreshold)) {
                    ForEach(LargeFileThreshold.allCases) { threshold in
                        Text(threshold.label).tag(threshold)
                    }
                }
                .accessibilityLabel("Large File Warning Threshold")
                .accessibilityHint("Show warning when opening files larger than this size")
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
                // Mark as heading for VoiceOver rotor navigation
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("\(title) Settings")

            content
        }
    }
}

// MARK: - Previews

#Preview("Settings") {
    SettingsView()
        .environment(\.preferences, AppPreferences.shared)
}
