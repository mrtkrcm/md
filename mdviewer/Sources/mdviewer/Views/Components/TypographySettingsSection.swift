//
//  TypographySettingsSection.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - TypographySubsectionView

/// Reusable advanced typography subsection used by both Settings and popover.
/// Keeps layout and labels consistent between native settings panels.
struct TypographySubsectionView: View {
    @Binding var typographyPreferences: TypographyPreferences
    let onPresetChange: (TypographyPreferences) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Advanced Typography")
                    .font(.system(size: DesignTokens.Typography.small, weight: .medium))

                Text("Smoothing, ligatures, hyphenation, and presets.")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundStyle(.secondary)
            }

            settingsToggle(
                title: "Font Smoothing",
                detail: "Softens glyph edges for a calmer reading texture.",
                isOn: $typographyPreferences.fontSmoothing,
                accessibilityLabel: "Enable Font Smoothing"
            )

            settingsToggle(
                title: "Ligatures",
                detail: "Uses typographic glyph substitutions when the selected font supports them.",
                isOn: $typographyPreferences.ligatures,
                accessibilityLabel: "Enable Font Ligatures"
            )

            settingsToggle(
                title: "Hyphenation",
                detail: "Balances dense paragraphs by allowing automatic word breaks.",
                isOn: $typographyPreferences.hyphenation,
                accessibilityLabel: "Enable Automatic Hyphenation"
            )

            HStack(alignment: .center, spacing: DesignTokens.Spacing.relaxed) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Justification")
                        .font(.system(size: DesignTokens.Typography.small, weight: .medium))

                    Text("Paragraph alignment in rendered mode.")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Justification", selection: $typographyPreferences.justification) {
                    ForEach(TextJustification.allCases) { justification in
                        Text(justification.rawValue).tag(justification)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
                .accessibilityLabel("Text Justification")
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

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                Text("Typography Presets")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: DesignTokens.Spacing.compact) {
                    presetButton(title: "Conservative", preferences: .conservative)
                    presetButton(title: "Default", preferences: TypographyPreferences())
                    presetButton(title: "Premium", preferences: .premium)
                }
            }
        }
    }

    private func settingsToggle(
        title: String,
        detail: String,
        isOn: Binding<Bool>,
        accessibilityLabel: String
    ) -> some View {
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

            Toggle(title, isOn: isOn)
                .labelsHidden()
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

    private func presetButton(title: String, preferences preset: TypographyPreferences) -> some View {
        Button(title) {
            onPresetChange(preset)
        }
        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
        .padding(.horizontal, DesignTokens.Spacing.standard)
        .padding(.vertical, DesignTokens.Spacing.compact)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.standard, style: .continuous)
                .fill(.thinMaterial)
        }
        .border(
            Color(nsColor: .separatorColor).opacity(DesignTokens.Opacity.mediumLight),
            width: 1,
            cornerRadius: DesignTokens.CornerRadius.standard
        )
        .buttonStyle(.plain)
    }
}
