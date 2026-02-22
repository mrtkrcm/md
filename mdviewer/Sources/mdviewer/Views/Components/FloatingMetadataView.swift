//
//  FloatingMetadataView.swift
//  mdviewer
//

//
//  FloatingMetadataView.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - FloatingMetadataView

/// Floating panel displaying frontmatter metadata with expand/collapse.
/// Styled with glass panel effect for liquid design consistency.
struct FloatingMetadataView: View {
    let frontmatter: Frontmatter
    @AppStorage("frontmatterPanelExpanded") private var isExpanded = false

    var body: some View {
        // VStack keeps layout stable: only the collapsed button affects HStack height.
        // The expanded panel lives in a zero-height overlay so it can't push siblings.
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed button — sole layout contributor
            Button {
                withAnimation(.bouncy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.standard) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(
                            size: DesignTokens.Typography.caption,
                            weight: .semibold
                        ))
                        .foregroundStyle(.secondary)
                        .bouncyAnimation(isExpanded)
                        .accessibilityHidden(true)

                    Label("Metadata", systemImage: "tag")
                        .font(.system(
                            size: DesignTokens.Typography.small,
                            weight: .semibold
                        ))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(frontmatter.entries.isEmpty ? "YAML" : "\(frontmatter.entries.count)")
                        .font(.system(
                            size: DesignTokens.Typography.caption,
                            weight: .semibold,
                            design: .rounded
                        ))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Color.primary.opacity(DesignTokens.Opacity.mediumLight),
                            in: Capsule()
                        )
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, DesignTokens.Spacing.comfortable)
                .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .glassPanel()
            .accessibilityLabel("Document Metadata")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand and view document metadata")

            // Zero-height anchor: expanded panel anchors here, contributing no layout height
            Color.clear
                .frame(width: 0, height: 0)
                .overlay(alignment: .topLeading) {
                    if isExpanded {
                        expandedPanel
                            .padding(.top, DesignTokens.Spacing.standard)
                            .transition(.opacity.combined(with: .offset(y: -8)))
                    }
                }
        }
    }

    private var expandedPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if frontmatter.entries.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                    Text("Frontmatter detected")
                        .font(.system(
                            size: DesignTokens.Typography.bodySmall,
                            weight: .semibold
                        ))
                        .foregroundStyle(.primary)

                    Text("Raw YAML is shown because key/value extraction is unavailable for this structure.")
                        .font(.system(size: DesignTokens.Typography.small))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(frontmatter.rawYAML.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
                .padding(.horizontal, DesignTokens.Spacing.relaxed)
                .padding(.vertical, DesignTokens.Spacing.comfortable)
                .background(
                    Color.primary.opacity(DesignTokens.Opacity.light),
                    in: RoundedRectangle(
                        cornerRadius: DesignTokens.CornerRadius.medium,
                        style: .continuous
                    )
                )
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                    ForEach(Array(frontmatter.entries.enumerated()), id: \.offset) { _, entry in
                        FloatingMetadataEntryView(entry: entry)
                    }
                }
            }
        }
        // fixedSize makes the ScrollView use its content's ideal height, ignoring
        // the zero-height proposal it receives from the zero-size anchor overlay.
        // frame(maxHeight:) then caps it so very long frontmatter still scrolls.
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: DesignTokens.Layout.metadataWidth)
        .frame(maxHeight: DesignTokens.Layout.metadataMaxHeight)
        .padding(.horizontal, DesignTokens.Spacing.comfortable)
        .padding(.vertical, DesignTokens.Spacing.standard)
        .glassPanel()
    }
}
