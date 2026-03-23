//
//  ThemePreview.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Compact Theme Item

/// A compact theme picker item showing color swatches and theme name.
/// Used in grid layouts for efficient theme selection.
private struct ThemeItem: View {
    let theme: AppTheme
    let isSelected: Bool
    let colorScheme: ColorScheme

    private var palette: NativeThemePalette {
        NativeThemePalette.cached(theme: theme, scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                .fill(Color(palette.inlineCodeBackground))
                .overlay(
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                        Capsule()
                            .fill(Color(palette.heading))
                            .frame(width: DesignTokens.Spacing.xxl + DesignTokens.Spacing.large, height: 5)

                        Rectangle()
                            .fill(Color(palette.textPrimary).opacity(DesignTokens.Opacity.high))
                            .frame(height: 5)

                        HStack(spacing: DesignTokens.Spacing.tight) {
                            ColorSwatch(color: palette.heading, label: "Heading")
                            ColorSwatch(color: palette.textPrimary, label: "Text")
                            ColorSwatch(color: palette.link, label: "Link")
                            ColorSwatch(color: palette.codeBackground, label: "Code")
                        }
                    }
                    .padding(DesignTokens.Spacing.compact)
                )
                .frame(height: DesignTokens.Component.Button.height)

            VStack(alignment: .leading, spacing: 1) {
                Text(theme.rawValue)
                    .font(.system(size: DesignTokens.Typography.small, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(theme.description)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(DesignTokens.Spacing.compact)
        .frame(maxWidth: .infinity, minHeight: DesignTokens.Component.Button.heightLarge + DesignTokens.Spacing.xxl)
        .background(backgroundStyle)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous))
        .contentShape(Rectangle())
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous)
            .fill(
                isSelected ? .regularMaterial : .thinMaterial
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous)
                    .stroke(
                        isSelected ? Color(palette.accent) : Color(nsColor: .separatorColor).opacity(0.35),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
    }
}

// MARK: - Color Swatch

private struct ColorSwatch: View {
    let color: NSColor
    let label: String

    var body: some View {
        Circle()
            .fill(Color(color))
            .frame(width: DesignTokens.Spacing.standard, height: DesignTokens.Spacing.standard)
            .overlay(
                Circle()
                    .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
            )
            .accessibilityLabel(label)
    }
}

// MARK: - Theme Preview Grid (Scrollable)

/// A scrollable grid of theme items for selecting a theme.
/// Displays themes in a 3-column layout for optimal space efficiency.
struct ThemePreviewGrid: View {
    @Binding var selectedTheme: AppTheme
    let colorScheme: ColorScheme

    /// Fixed 3-column grid with compact equal spacing
    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.compact),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.compact),
        GridItem(.flexible()),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.compact) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeItem(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        colorScheme: colorScheme
                    )
                    .onTapGesture {
                        withAnimation(DesignTokens.AnimationPreset.fast) {
                            selectedTheme = theme
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(theme.rawValue) theme")
                    .accessibilityHint(theme.description)
                    .accessibilityAddTraits(selectedTheme == theme ? .isSelected : [])
                }
            }
            .padding(.vertical, DesignTokens.Spacing.tight)
        }
        .frame(height: DesignTokens.Layout.settingsThemeGridHeight - DesignTokens.Spacing.xxl)
    }
}

// MARK: - Theme Preview Carousel (Horizontal)

/// A horizontal carousel of theme previews for compact spaces.
struct ThemePreviewCarousel: View {
    @Binding var selectedTheme: AppTheme
    let colorScheme: ColorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.standard) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeCarouselItem(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        colorScheme: colorScheme
                    )
                    .onTapGesture {
                        withAnimation(DesignTokens.AnimationPreset.spring(response: 0.3, damping: 0.8)) {
                            selectedTheme = theme
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(theme.rawValue) theme")
                    .accessibilityHint(theme.description)
                    .accessibilityAddTraits(selectedTheme == theme ? .isSelected : [])
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.compact)
        }
    }
}

// MARK: - Theme Carousel Item

/// A card-style theme preview for carousel layouts.
private struct ThemeCarouselItem: View {
    let theme: AppTheme
    let isSelected: Bool
    let colorScheme: ColorScheme

    private var palette: NativeThemePalette {
        NativeThemePalette.cached(theme: theme, scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .center, spacing: DesignTokens.Spacing.compact) {
            HStack(spacing: DesignTokens.Spacing.tight) {
                ColorSwatch(color: palette.heading, label: "Heading")
                ColorSwatch(color: palette.textPrimary, label: "Text")
                ColorSwatch(color: palette.link, label: "Link")
                ColorSwatch(color: palette.codeBackground, label: "Code")
            }

            Text(theme.rawValue)
                .font(.system(size: DesignTokens.Typography.small, weight: .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, DesignTokens.Spacing.compact)
        .padding(.vertical, DesignTokens.Spacing.standard)
        .frame(width: 80, height: 60)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .stroke(
                            isSelected ? Color(nsColor: .controlAccentColor) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }
}

// MARK: - Live Theme Preview

/// A larger preview showing actual rendered markdown in the selected theme.
/// Used in popovers to show the effect of theme selection.
struct LiveThemePreview: View {
    let theme: AppTheme
    let colorScheme: ColorScheme

    private var palette: NativeThemePalette {
        NativeThemePalette.cached(theme: theme, scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Text("Preview")
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundStyle(Color(nsColor: .secondaryLabelColor))

            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(Color(nsColor: .textBackgroundColor))
                .overlay(
                    sampleContent
                        .padding(DesignTokens.Spacing.standard)
                )
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
        }
    }

    @ViewBuilder
    private var sampleContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Heading Preview")
                .font(.system(size: DesignTokens.Typography.bodySmall, weight: .bold))
                .foregroundStyle(Color(palette.heading))

            Text("Body text with ")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundStyle(Color(palette.textPrimary))
                + Text("formatting")
                .font(.system(size: DesignTokens.Typography.caption, weight: .bold))
                .foregroundStyle(Color(palette.textPrimary))

            HStack(spacing: DesignTokens.Spacing.tight) {
                Circle()
                    .fill(Color(palette.listMarker))
                    .frame(width: DesignTokens.Typography.tiny, height: DesignTokens.Typography.tiny)
                Text("Bullet point")
                    .font(.system(size: DesignTokens.Typography.previewExtraSmall))
                    .foregroundStyle(Color(palette.textSecondary))
            }

            Text("code")
                .font(.system(size: DesignTokens.Typography.previewExtraSmall, design: .monospaced))
                .padding(.horizontal, DesignTokens.Spacing.tight)
                .padding(.vertical, DesignTokens.SpacingScale.xxs)
                .background(Color(palette.inlineCodeBackground))
                .cornerRadius(DesignTokens.CornerRadius.small / 4)

            Text("Link example")
                .font(.system(size: DesignTokens.Typography.previewExtraSmall))
                .foregroundStyle(Color(palette.link))
                .underline()
        }
    }
}

// MARK: - Previews

#Preview("Theme Grid") {
    @Previewable @State var selectedTheme: AppTheme = .github

    ThemePreviewGrid(
        selectedTheme: $selectedTheme,
        colorScheme: .light
    )
    .padding()
    .frame(width: 400)
}

#Preview("Theme Grid (Dark)") {
    @Previewable @State var selectedTheme: AppTheme = .dracula

    ThemePreviewGrid(
        selectedTheme: $selectedTheme,
        colorScheme: .dark
    )
    .padding()
    .frame(width: 400)
    .preferredColorScheme(.dark)
}

#Preview("Theme Carousel") {
    @Previewable @State var selectedTheme: AppTheme = .dracula

    ThemePreviewCarousel(
        selectedTheme: $selectedTheme,
        colorScheme: .dark
    )
    .padding()
    .preferredColorScheme(.dark)
}
