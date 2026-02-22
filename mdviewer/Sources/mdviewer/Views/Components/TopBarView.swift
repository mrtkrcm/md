//
//  TopBarView.swift
//  mdviewer
//

//
//  TopBarView.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - TopBarView

/// Toolbar with reader mode picker and action buttons.
/// Styled with glass panel for consistent liquid design language.
struct TopBarView: View {
    @Binding var showAppearancePopover: Bool
    @Binding var readerMode: ReaderMode
    let openAction: () -> Void
    let shareItem: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.relaxed) {
            HStack(spacing: DesignTokens.Spacing.compact) {
                Image(systemName: "doc.text")
                    .font(.system(
                        size: DesignTokens.Typography.iconSmall,
                        weight: .semibold
                    ))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Picker("Reader Mode", selection: $readerMode) {
                    ForEach(ReaderMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: DesignTokens.Layout.readerModePickerWidth)
                .help("Switch between rendered preview and raw markdown")
                .accessibilityLabel("Reader Mode")
                .accessibilityHint("Switch between rendered preview and raw markdown")
            }
            .padding(.leading, DesignTokens.Spacing.tight)

            Divider()
                .frame(height: 18)
                .accessibilityHidden(true)

            ToolIconButton(icon: "slider.horizontal.3", isActive: showAppearancePopover) {
                showAppearancePopover.toggle()
            }
            .help("Appearance settings")
            .accessibilityLabel("Appearance Settings")
            .accessibilityHint("Open appearance and typography settings")

            ShareIconButton(shareItem: shareItem)
                .help("Share markdown")
                .accessibilityLabel("Share Document")
                .accessibilityHint("Share the current markdown document")

            ToolIconButton(icon: "folder") {
                openAction()
            }
            .help("Open markdown file")
            .accessibilityLabel("Open File")
            .accessibilityHint("Open a markdown file from disk")
        }
        .padding(.horizontal, DesignTokens.Spacing.comfortable)
        .padding(.vertical, 7)
        .glassPanel()
    }
}
