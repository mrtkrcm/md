internal import SwiftUI

// MARK: - FloatingMetadataEntryView

/// Single metadata entry row for the floating metadata panel.
/// Styled with subtle background for visual hierarchy within the glass panel.
struct FloatingMetadataEntryView: View {
    let entry: Frontmatter.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
            Text(displayKey(entry.key))
                .font(.system(
                    size: DesignTokens.Typography.caption,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.value.isEmpty ? "\u{2014}" : entry.value)
                .font(.system(
                    size: DesignTokens.Typography.bodySmall,
                    weight: .regular
                ))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
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
    }

    private func displayKey(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}
