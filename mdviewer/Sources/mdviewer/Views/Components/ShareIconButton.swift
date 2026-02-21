//
//  ShareIconButton.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - ShareIconButton

/// Share link button with hover state.
/// Uses liquid design tokens for consistent sizing and hover feedback.
struct ShareIconButton: View {
    let shareItem: String
    @State private var isHovering = false

    var body: some View {
        ShareLink(item: shareItem) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(
                    size: DesignTokens.Typography.iconStandard,
                    weight: .semibold
                ))
                .frame(width: 28, height: 28)
                .background(
                    isHovering ? Color.primary.opacity(DesignTokens.Opacity.medium) : .clear,
                    in: RoundedRectangle(
                        cornerRadius: DesignTokens.CornerRadius.small,
                        style: .continuous
                    )
                )
                .foregroundStyle(Color(nsColor: .secondaryLabelColor))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
