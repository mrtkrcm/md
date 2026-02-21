internal import SwiftUI

// MARK: - WelcomeStartView

/// Empty state welcome screen shown when no document is loaded.
/// Styled with large glass panel for prominent liquid design aesthetic.
struct WelcomeStartView: View {
    let openAction: () -> Void
    let useStarterAction: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                Image(systemName: "doc.text")
                    .font(.system(
                        size: DesignTokens.Typography.iconLarge,
                        weight: .thin
                    ))
                    .foregroundStyle(.tertiary)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                    Text("Welcome")
                        .font(.system(
                            size: DesignTokens.Typography.title,
                            weight: .semibold
                        ))

                    Text("Open a markdown file or start with starter content.")
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: DesignTokens.Spacing.relaxed) {
                    Button("Open...", action: openAction)
                        .buttonStyle(.borderedProminent)
                    Button("Use Starter", action: useStarterAction)
                        .buttonStyle(.bordered)
                }
            }
            .padding(DesignTokens.Spacing.xxl)
            .glassPanel(cornerRadius: DesignTokens.CornerRadius.large)
            .frame(maxWidth: DesignTokens.Layout.welcomeMaxWidth)

            Spacer()
        }
        .padding(DesignTokens.Spacing.extraLarge * 2)
        .frame(maxWidth: .infinity)
    }
}
