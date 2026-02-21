//
//  GlassPanelModifier.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Glass Panel Modifier

extension View {
    /// Applies a glass panel effect with liquid design styling.
    /// Uses material background, subtle border, and soft shadow.
    ///
    /// - Parameter cornerRadius: The corner radius for the panel. Defaults to `DesignTokens.CornerRadius.standard`.
    @ViewBuilder
    func glassPanel(cornerRadius: CGFloat = DesignTokens.CornerRadius.standard) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(DesignTokens.Opacity.veryHigh), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(DesignTokens.Shadow.opacity),
                    radius: DesignTokens.Shadow.radius,
                    y: DesignTokens.Shadow.yOffset
                )
        }
    }
}
