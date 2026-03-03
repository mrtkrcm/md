//
//  WelcomeStartView.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - WelcomeStartView

/// Empty state welcome screen shown when no document is loaded.
/// Styled with large glass panel for prominent liquid design aesthetic.
/// Fully accessible with VoiceOver support and reduced motion awareness.
struct WelcomeStartView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let openAction: () -> Void
    let useStarterAction: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                appIcon

                welcomeText

                actionButtons
            }
            .padding(DesignTokens.Spacing.xxl)
            .glassPanel(cornerRadius: DesignTokens.CornerRadius.large)
            .frame(maxWidth: DesignTokens.Layout.welcomeMaxWidth)
            // Group content for VoiceOver
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Welcome to mdviewer")
            .accessibilityHint("A markdown document reader and editor")

            Spacer()
        }
        .padding(DesignTokens.Spacing.extraLarge * 2)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subviews

    private var appIcon: some View {
        Image(systemName: "doc.text")
            .font(.system(
                size: DesignTokens.Typography.iconLarge,
                weight: .thin
            ))
            .foregroundStyle(.tertiary)
            // Decorative icon - hidden from VoiceOver
            .accessibilityHidden(true)
    }

    private var welcomeText: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            Text("Welcome")
                .font(.system(
                    size: DesignTokens.Typography.title,
                    weight: .semibold
                ))
                .accessibilityLabel("Welcome to mdviewer")
                // Add heading trait for VoiceOver rotor navigation
                .accessibilityAddTraits(.isHeader)

            Text("Open a markdown file or start with starter content.")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Open a markdown file or start with starter content")
        }
    }

    private var actionButtons: some View {
        HStack(spacing: DesignTokens.Spacing.relaxed) {
            Button("Open...", action: openAction)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Open File")
                .accessibilityHint("Open a markdown file from disk")
                // Ensure button is keyboard navigable
                .keyboardShortcut("o", modifiers: .command)

            Button("Use Starter", action: useStarterAction)
                .buttonStyle(.bordered)
                .accessibilityLabel("Use Starter Document")
                .accessibilityHint("Create a new document with sample content")
        }
    }
}

// MARK: - Previews

#Preview("Welcome Start") {
    WelcomeStartView(
        openAction: {},
        useStarterAction: {}
    )
}
