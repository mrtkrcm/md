//
//  ToolIconButton.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - ToolIconButton

/// Reusable icon button with hover state for toolbar actions.
/// Uses liquid design tokens for consistent sizing and visual feedback.
struct ToolIconButton: View {
    let icon: String
    var isActive: Bool = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(
                    size: DesignTokens.Typography.iconStandard,
                    weight: .semibold
                ))
                .frame(width: 28, height: 28)
                .background(
                    backgroundFill,
                    in: RoundedRectangle(
                        cornerRadius: DesignTokens.CornerRadius.small,
                        style: .continuous
                    )
                )
                .foregroundStyle(isActive ? Color.accentColor : Color(nsColor: .secondaryLabelColor))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var backgroundFill: Color {
        if isActive { return Color.accentColor.opacity(DesignTokens.Opacity.mediumHigh) }
        if isHovering { return Color.primary.opacity(DesignTokens.Opacity.medium) }
        return .clear
    }
}
