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
            Text("Standard")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Font Smoothing", isOn: $typographyPreferences.fontSmoothing)
                .accessibilityLabel("Enable Font Smoothing")

            Toggle("Ligatures", isOn: $typographyPreferences.ligatures)
                .accessibilityLabel("Enable Font Ligatures")

            Divider()
                .padding(.vertical, DesignTokens.Spacing.tight)

            Text("Advanced Typography")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Hyphenation", isOn: $typographyPreferences.hyphenation)
                .accessibilityLabel("Enable Automatic Hyphenation")

            Picker("Justification", selection: $typographyPreferences.justification) {
                ForEach(TextJustification.allCases) { justification in
                    Text(justification.rawValue).tag(justification)
                }
            }
            .accessibilityLabel("Text Justification")

            HStack {
                Text("Typography Presets")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Conservative") {
                    onPresetChange(.conservative)
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Button("Default") {
                    onPresetChange(TypographyPreferences())
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Button("Premium") {
                    onPresetChange(.premium)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
    }
}
