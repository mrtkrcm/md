//
//  InspectorMetadataView.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Inspector Metadata View

/// Native inspector panel for document metadata using modern SwiftUI.
/// Provides a sidebar view of YAML frontmatter with native styling.
struct InspectorMetadataView: View {
    let frontmatter: Frontmatter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.relaxed) {
                // Header
                HStack {
                    Label("Document Metadata", systemImage: "tag")
                        .font(.system(
                            size: DesignTokens.Typography.bodySmall,
                            weight: .semibold
                        ))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("YAML")
                        .font(.system(
                            size: DesignTokens.Typography.caption,
                            weight: .medium,
                            design: .rounded
                        ))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Color.secondary.opacity(DesignTokens.Opacity.light),
                            in: Capsule()
                        )
                }
                .padding(.bottom, DesignTokens.Spacing.standard)

                Divider()

                // Content
                if frontmatter.entries.isEmpty {
                    rawYAMLView
                } else {
                    structuredMetadataView
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var rawYAMLView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            Text("Raw Frontmatter")
                .font(.system(
                    size: DesignTokens.Typography.small,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)

            Text(frontmatter.rawYAML.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                        .fill(Color.secondary.opacity(DesignTokens.Opacity.light))
                )
        }
    }

    private var structuredMetadataView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.relaxed) {
            ForEach(Array(frontmatter.entries.enumerated()), id: \.offset) { _, entry in
                InspectorMetadataEntryView(entry: entry)
            }
        }
    }
}

// MARK: - Inspector Metadata Entry View

/// Single metadata entry row for the inspector panel.
private struct InspectorMetadataEntryView: View {
    let entry: Frontmatter.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
            Text(entry.key)
                .font(.system(
                    size: DesignTokens.Typography.caption,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)

            Text(entry.value)
                .font(.system(size: DesignTokens.Typography.standard))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.comfortable)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .fill(Color.secondary.opacity(DesignTokens.Opacity.light))
        )
    }
}
