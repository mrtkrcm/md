//
//  GlassPanelModifier.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Glass Panel Modifier

/// Applies a glass panel effect with material background and subtle styling.
/// Used for floating UI elements like the top bar and welcome panel.
private struct GlassPanelModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
                    )
                    .shadow(
                        color: .black.opacity(DesignTokens.Shadow.opacity),
                        radius: DesignTokens.Shadow.radius,
                        x: 0,
                        y: DesignTokens.Shadow.yOffset
                    )
            )
    }
}

// MARK: - View Extension

extension View {
    /// Applies glass panel styling with material background and subtle shadow.
    func glassPanel(cornerRadius: CGFloat = DesignTokens.CornerRadius.standard) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius))
    }
}
