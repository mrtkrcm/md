//
//  ThemePreview.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Theme Preview

/// A visual preview of a theme showing color swatches and sample text.
/// Used in theme pickers to provide visual identification.
struct ThemePreview: View {
    let theme: AppTheme
    let isSelected: Bool
    let colorScheme: ColorScheme

    @Environment(\.colorScheme) private var environmentColorScheme

    private var effectiveColorScheme: ColorScheme {
        colorScheme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            // Color swatches
            colorSwatches

            // Theme name
            Text(theme.rawValue)
                .font(.system(size: DesignTokens.Typography.small, weight: .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)

            // Sample text preview
            sampleText
        }
        .padding(DesignTokens.Spacing.standard)
        .frame(width: 100, height: 80)
        .background(backgroundStyle)
        .overlay(selectionOverlay)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .contentShape(Rectangle())
    }

    // MARK: - Subviews

    private var colorSwatches: some View {
        HStack(spacing: DesignTokens.Spacing.tight) {
            ColorSwatch(color: palette.heading, label: "Heading")
            ColorSwatch(color: palette.textPrimary, label: "Text")
            ColorSwatch(color: palette.link, label: "Link")
            ColorSwatch(color: palette.codeBackground, label: "Code")
        }
    }

    private var sampleText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Aa")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(palette.heading))

            Text("Preview")
                .font(.system(size: 8))
                .foregroundStyle(Color(palette.textSecondary))
        }
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
            .fill(Color(palette.codeBackground).opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
    }

    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .stroke(Color.accentColor, lineWidth: 2)
        }
    }

    // MARK: - Helpers

    private var palette: NativeThemePalette {
        NativeThemePalette.cached(theme: theme, scheme: effectiveColorScheme)
    }
}

// MARK: - Color Swatch

private struct ColorSwatch: View {
    let color: NSColor
    let label: String

    var body: some View {
        Circle()
            .fill(Color(color))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
            )
            .accessibilityLabel(label)
    }
}

// MARK: - Theme Preview Grid

/// A grid of theme previews for selecting a theme.
struct ThemePreviewGrid: View {
    @Binding var selectedTheme: AppTheme
    let colorScheme: ColorScheme

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: DesignTokens.Spacing.standard),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.standard) {
            ForEach(AppTheme.allCases) { theme in
                ThemePreview(
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
    }
}

// MARK: - Theme Preview Carousel

/// A horizontal carousel of theme previews for compact spaces.
struct ThemePreviewCarousel: View {
    @Binding var selectedTheme: AppTheme
    let colorScheme: ColorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.standard) {
                ForEach(AppTheme.allCases) { theme in
                    ThemePreview(
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

// MARK: - Live Theme Preview

/// A larger preview showing actual rendered markdown in the selected theme.
struct LiveThemePreview: View {
    let theme: AppTheme
    let colorScheme: ColorScheme

    private let sampleMarkdown = """
    # Heading 1
    ## Heading 2

    Regular paragraph with **bold** and *italic* text.

    > A blockquote for preview

    - List item one
    - List item two

    `inline code` and [a link](https://example.com)
    """

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Text("Preview")
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(Color(nsColor: .textBackgroundColor))
                .overlay(
                    sampleContent
                        .padding(DesignTokens.Spacing.standard)
                )
                .frame(height: 120)
        }
    }

    @ViewBuilder
    private var sampleContent: some View {
        // Simplified preview showing key elements
        VStack(alignment: .leading, spacing: 4) {
            Text("Heading Preview")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(palette.heading))

            Text("Body text with ")
                .font(.system(size: 10))
                .foregroundStyle(Color(palette.textPrimary))
                + Text("formatting")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(palette.textPrimary))

            HStack(spacing: 4) {
                Circle()
                    .fill(Color(palette.listMarker))
                    .frame(width: 4, height: 4)
                Text("Bullet point")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(palette.textSecondary))
            }

            Text("code")
                .font(.system(size: 9, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(palette.inlineCodeBackground))
                .cornerRadius(2)

            Text("Link example")
                .font(.system(size: 9))
                .foregroundStyle(Color(palette.link))
                .underline()
        }
    }

    private var palette: NativeThemePalette {
        NativeThemePalette.cached(theme: theme, scheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Theme Preview") {
    @Previewable @State var selectedTheme: AppTheme = .github

    VStack(spacing: DesignTokens.Spacing.relaxed) {
        ThemePreview(
            theme: .github,
            isSelected: true,
            colorScheme: .light
        )

        Divider()

        ThemePreviewGrid(
            selectedTheme: $selectedTheme,
            colorScheme: .light
        )
        .padding()
    }
    .padding()
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
