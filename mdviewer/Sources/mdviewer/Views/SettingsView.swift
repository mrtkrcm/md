//
//  SettingsView.swift
//  mdviewer
//

internal import SwiftUI

/// Settings panel with a desktop-first liquid layout and grouped preference cards.
/// Preferences are automatically persisted via the shared `AppPreferences` object.
struct SettingsView: View {
    @Environment(\.preferences) private var preferences
    @Environment(\.colorScheme) private var colorScheme

    private var effectiveColorScheme: ColorScheme {
        switch preferences.appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return colorScheme
        }
    }

    private var currentPalette: NativeThemePalette {
        NativeThemePalette.cached(theme: preferences.theme, scheme: effectiveColorScheme)
    }

    private var typographyFeatureCount: Int {
        [
            preferences.typographyPreferences.fontSmoothing,
            preferences.typographyPreferences.ligatures,
            preferences.typographyPreferences.hyphenation,
        ]
        .filter(\.self)
        .count
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.extraWide) {
            settingsSummaryRail
                .frame(width: DesignTokens.Layout.settingsSidebarWidth)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraWide) {
                    overviewCard
                    appearanceCard
                    readingCard
                    codeCard
                    systemCard
                }
                .padding(.vertical, DesignTokens.Spacing.tight)
            }
        }
        .padding(DesignTokens.Spacing.extraWide)
        .frame(
            minWidth: DesignTokens.Layout.settingsWidth,
            idealWidth: DesignTokens.Layout.settingsWidth,
            minHeight: DesignTokens.Layout.settingsHeight,
            idealHeight: DesignTokens.Layout.settingsHeight,
            alignment: .topLeading
        )
        .background(.windowBackground)
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("SettingsView")
    }

    private var settingsSummaryRail: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
                Text("Preferences")
                    .font(.system(size: DesignTokens.Typography.body, weight: .semibold))

                Text("Reading, appearance, and editor defaults.")
                    .font(.system(size: DesignTokens.Typography.small))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SettingsHeroCard(palette: currentPalette)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                SettingsSummaryTile(
                    title: "Appearance",
                    value: preferences.appearanceMode.rawValue,
                    detail: preferences.theme.rawValue,
                    icon: "circle.lefthalf.filled.inverse"
                )

                SettingsSummaryTile(
                    title: "Reading",
                    value: preferences.readerMode.rawValue,
                    detail: "\(preferences.readerColumnWidth.rawValue) width",
                    icon: "doc.text.magnifyingglass"
                )

                SettingsSummaryTile(
                    title: "Typography",
                    value: preferences.readerFontFamily.rawValue,
                    detail: "\(typographyFeatureCount) advanced options enabled",
                    icon: "textformat.size"
                )

                SettingsSummaryTile(
                    title: "Code",
                    value: preferences.codeFontSize.label,
                    detail: preferences.showLineNumbers ? "Line numbers on" : "Line numbers off",
                    icon: "chevron.left.forwardslash.chevron.right"
                )
            }
        }
        .padding(DesignTokens.Spacing.relaxed)
        .glassPanel(cornerRadius: DesignTokens.CornerRadius.large)
    }

    private var overviewCard: some View {
        SettingsSectionCard(
            title: "Appearance & Theme",
            subtitle: "Choose the app mode and document palette.",
            symbol: "sparkles.rectangle.stack"
        ) {
            SettingsControlRow(
                title: "Appearance",
                detail: "Keep the app automatic or lock it to light or dark mode.",
                accessibilityLabel: "Appearance Mode"
            ) {
                Picker("Appearance", selection: binding(\.appearanceMode)) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
            }

            ThemePreviewGrid(
                selectedTheme: binding(\.theme),
                colorScheme: effectiveColorScheme
            )
        }
    }

    private var appearanceCard: some View {
        SettingsSectionCard(
            title: "Typography",
            subtitle: "Set type, spacing, and advanced reading polish.",
            symbol: "text.alignleft"
        ) {
            SettingsControlRow(
                title: "Font Family",
                detail: "Sets the primary reader face for rendered content.",
                accessibilityLabel: "Reader Font Family"
            ) {
                FontFamilyPicker(selection: binding(\.readerFontFamily))
                    .frame(width: 160)
            }

            SettingsControlRow(
                title: "Text Size",
                detail: "Adjusts the default reading scale across rendered documents.",
                accessibilityLabel: "Reader Font Size"
            ) {
                Picker("Text Size", selection: binding(\.readerFontSize)) {
                    ForEach(ReaderFontSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            SettingsControlRow(
                title: "Line Spacing",
                detail: "Controls reading rhythm between paragraphs and body lines.",
                accessibilityLabel: "Reader Line Spacing"
            ) {
                Picker("Line Spacing", selection: binding(\.readerTextSpacing)) {
                    ForEach(ReaderTextSpacing.allCases) { spacing in
                        Text(spacing.rawValue).tag(spacing)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            SettingsControlRow(
                title: "Column Width",
                detail: "Rendered mode only. Sets the maximum text measure for readability.",
                accessibilityLabel: "Reader Column Width"
            ) {
                Picker("Column Width", selection: binding(\.readerColumnWidth)) {
                    ForEach(ReaderColumnWidth.allCases) { width in
                        Text(width.rawValue).tag(width)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            SettingsControlRow(
                title: "Content Padding",
                detail: "Changes the horizontal breathing room around the rendered page.",
                accessibilityLabel: "Reader Content Padding"
            ) {
                Picker("Content Padding", selection: binding(\.readerContentPadding)) {
                    ForEach(ReaderContentPadding.allCases) { padding in
                        Text(padding.rawValue).tag(padding)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            TypographySubsectionView(
                typographyPreferences: Binding(
                    get: { preferences.typographyPreferences },
                    set: { preferences.typographyPreferences = $0 }
                )
            ) { newValue in
                withAnimation(DesignTokens.AnimationPreset.fast) {
                    preferences.typographyPreferences = newValue
                }
            }
        }
    }

    private var readingCard: some View {
        SettingsSectionCard(
            title: "Reading Defaults",
            subtitle: "Choose the default reading mode.",
            symbol: "book.pages"
        ) {
            SettingsControlRow(
                title: "Default View",
                detail: "Controls whether files open in rendered or raw editing mode by default.",
                accessibilityLabel: "Default View Mode"
            ) {
                Picker("Default View", selection: binding(\.readerMode)) {
                    ForEach(ReaderMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }
        }
    }

    private var codeCard: some View {
        SettingsSectionCard(
            title: "Code Rendering",
            subtitle: "Tune code readability in the editor and previews.",
            symbol: "chevron.left.forwardslash.chevron.right"
        ) {
            SettingsControlRow(
                title: "Code Font Size",
                detail: "Applies to monospaced code blocks and the raw editor.",
                accessibilityLabel: "Code Font Size"
            ) {
                Picker("Code Font Size", selection: binding(\.codeFontSize)) {
                    ForEach(CodeFontSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            SettingsControlRow(
                title: "Line Numbers",
                detail: "Shows source line references in the editor for easier navigation.",
                accessibilityLabel: "Show Line Numbers"
            ) {
                Toggle("Line Numbers", isOn: binding(\.showLineNumbers))
                    .labelsHidden()
            }
        }
    }

    private var systemCard: some View {
        SettingsSectionCard(
            title: "System Behavior",
            subtitle: "Configure warnings for heavy markdown files.",
            symbol: "externaldrive.badge.exclamationmark"
        ) {
            SettingsControlRow(
                title: "Large File Warning",
                detail: "Prompts before opening files above the selected size threshold.",
                accessibilityLabel: "Large File Warning Threshold"
            ) {
                Picker("Large File Warning", selection: binding(\.largeFileThreshold)) {
                    ForEach(LargeFileThreshold.allCases) { threshold in
                        Text(threshold.label).tag(threshold)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }
        }
    }

    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<AppPreferences, T>) -> Binding<T> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { newValue in
                withAnimation(DesignTokens.AnimationPreset.fast) {
                    preferences[keyPath: keyPath] = newValue
                }
            }
        )
    }
}

private struct SettingsHeroCard: View {
    let palette: NativeThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Text("Current Theme")
                .font(.system(size: DesignTokens.Typography.small, weight: .medium))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous)
                    .fill(.thinMaterial)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                    Capsule()
                        .fill(Color(palette.heading))
                        .frame(width: DesignTokens.Spacing.xxl * 2, height: DesignTokens.Spacing.compact)

                    HStack(spacing: DesignTokens.Spacing.tight) {
                        Circle()
                            .fill(Color(palette.link))
                            .frame(
                                width: DesignTokens.Spacing.comfortable,
                                height: DesignTokens.Spacing.comfortable
                            )

                        Rectangle()
                            .fill(Color(palette.textPrimary).opacity(DesignTokens.Opacity.high))
                            .frame(height: DesignTokens.Spacing.compact)
                    }

                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                        .fill(Color(palette.inlineCodeBackground))
                        .frame(height: DesignTokens.Spacing.extraWide)

                    Rectangle()
                        .fill(Color(palette.textSecondary).opacity(DesignTokens.Opacity.medium))
                        .frame(height: DesignTokens.Spacing.tight)
                }
                .padding(DesignTokens.Spacing.extraWide)
            }
            .frame(height: DesignTokens.Layout.settingsHeroHeight - DesignTokens.Spacing.extraWide)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous)
                    .stroke(Color(palette.accent).opacity(DesignTokens.Opacity.mediumLight), lineWidth: 1)
            )
        }
        .padding(DesignTokens.Spacing.relaxed)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous)
                .fill(.thinMaterial)
        }
        .border(
            Color(nsColor: .separatorColor).opacity(DesignTokens.Opacity.mediumLight),
            width: 1,
            cornerRadius: DesignTokens.CornerRadius.standard
        )
    }
}

private struct SettingsSummaryTile: View {
    let title: String
    let value: String
    let detail: String
    let icon: String

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.standard) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.Typography.small, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(
                    width: DesignTokens.Component.Button.height,
                    height: DesignTokens.Component.Button.height
                )
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: DesignTokens.Typography.standard, weight: .semibold))

                Text(detail)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.Spacing.relaxed)
        .padding(.vertical, DesignTokens.Spacing.standard)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous)
                .fill(.thinMaterial)
        }
        .border(
            Color(nsColor: .separatorColor).opacity(DesignTokens.Opacity.mediumLight),
            width: 1,
            cornerRadius: DesignTokens.CornerRadius.standard
        )
    }
}

private struct SettingsSectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.relaxed) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
                Image(systemName: symbol)
                    .font(.system(size: DesignTokens.Typography.small, weight: .semibold))
                    .frame(
                        width: DesignTokens.Component.Button.height,
                        height: DesignTokens.Component.Button.height
                    )
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: DesignTokens.Typography.standard, weight: .semibold))

                    Text(subtitle)
                        .font(.system(size: DesignTokens.Typography.small))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                content
            }
        }
        .padding(DesignTokens.Spacing.relaxed)
        .glassPanel(cornerRadius: DesignTokens.CornerRadius.standard)
    }
}

private struct SettingsControlRow<Control: View>: View {
    let title: String
    let detail: String
    let accessibilityLabel: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.relaxed) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: DesignTokens.Typography.small, weight: .medium))

                Text(detail)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            control
                .accessibilityLabel(accessibilityLabel)
        }
        .padding(.horizontal, DesignTokens.Spacing.relaxed)
        .padding(.vertical, DesignTokens.Spacing.standard)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous)
                .fill(.thinMaterial)
        }
        .border(
            Color(nsColor: .separatorColor).opacity(DesignTokens.Opacity.mediumLight),
            width: 1,
            cornerRadius: DesignTokens.CornerRadius.standard
        )
    }
}

#Preview("Settings") {
    SettingsView()
        .environment(\.preferences, AppPreferences.shared)
}
