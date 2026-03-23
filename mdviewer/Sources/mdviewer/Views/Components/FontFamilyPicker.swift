//
//  FontFamilyPicker.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit
#endif
internal import SwiftUI

// MARK: - Font Family Picker

/// A macOS-native font picker with quick presets and full NSFontPanel integration.
///
/// Features:
/// - Quick access to curated font presets grouped by category
/// - "More Fonts..." option opens the native macOS font panel
/// - Live preview of each font in its own typeface
/// - Keyboard accessible with proper VoiceOver support
struct FontFamilyPicker: View {
    @Binding var selection: ReaderFontFamily

    /// Tracks whether the font panel is currently open
    @State private var isFontPanelOpen = false

    /// Delegate for handling font panel changes
    @State private var fontPanelDelegate: FontPanelDelegate?

    var body: some View {
        Menu(content: menuContent, label: menuLabel)
            .menuStyle(.borderlessButton)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Font Family")
            .accessibilityHint("Choose a font for reading, or open the font panel for more options")
            .onAppear {
                // Clean up font panel delegate when view disappears
                fontPanelDelegate = nil
            }
    }

    // MARK: - Menu Content

    private func menuContent() -> some View {
        Group {
            // MARK: System Fonts Section

            Section("System") {
                fontButton(for: .sfPro)
            }

            // MARK: Serif Fonts Section

            Section("Serif") {
                fontButton(for: .newYork)
                fontButton(for: .georgia)
            }

            // MARK: Monospace Fonts Section

            Section("Monospace") {
                fontButton(for: .mapleMonoNF)
            }

            Divider()

            // MARK: Full Font Panel Access

            Button {
                showFontPanel()
            } label: {
                HStack {
                    Image(systemName: "textformat")
                        .font(.system(size: DesignTokens.Typography.bodySmall))
                        .frame(width: 16)
                    Text("More Fonts...")
                    Spacer()
                    Text("⌘T")
                        .font(.system(size: DesignTokens.Typography.small))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel("Open font panel")
            .accessibilityHint("Opens the system font panel for selecting any installed font")
        }
    }

    private func fontButton(for family: ReaderFontFamily) -> some View {
        Button {
            withAnimation(.easeInOut(duration: DesignTokens.Animation.fast)) {
                selection = family
            }
        } label: {
            fontButtonLabel(for: family)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(family.displayName)")
    }

    private func fontButtonLabel(for family: ReaderFontFamily) -> some View {
        HStack(spacing: DesignTokens.Spacing.standard) {
            // Font preview with sample text
            Text("Aa")
                .font(family.swiftUIFont(size: 14))
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(family.displayName)
                    .font(.system(size: 13))

                // Show font category hint for non-system fonts
                if family != .sfPro {
                    Text(family.categoryLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            checkmarkIfSelected(family)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func checkmarkIfSelected(_ family: ReaderFontFamily) -> some View {
        if selection == family {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.accentColor)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Menu Label

    private func menuLabel() -> some View {
        HStack(spacing: DesignTokens.Spacing.standard) {
            // Font name in its own typeface - prominently displayed
            Text(selection.displayName)
                .font(selection.swiftUIFont(size: 14))
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .opacity(0.6)
        }
        .padding(.horizontal, DesignTokens.Spacing.comfortable)
        .frame(height: DesignTokens.Component.Input.height)
        .background(menuBackground)
        .contentShape(Rectangle())
    }

    private var menuBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
            .fill(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
    }

    // MARK: - Font Panel Integration

    #if os(macOS)
        private func showFontPanel() {
            // Create delegate to handle font changes
            fontPanelDelegate = FontPanelDelegate { font in
                // Map the selected NSFont to our ReaderFontFamily
                if let newFamily = ReaderFontFamily(from: font) {
                    selection = newFamily
                }
            }

            // Configure and show the font panel
            let fontManager = NSFontManager.shared
            fontManager.target = fontPanelDelegate

            let currentFont = selection.nsFont(size: NSFont.systemFontSize)
            NSFontPanel.shared.setPanelFont(currentFont, isMultiple: false)

            // Restrict to relevant modes (collection, face, size)
            NSFontPanel.shared.orderBack(nil)

            isFontPanelOpen = true
        }
    #else
        private func showFontPanel() {
            // Font panel is macOS-only
        }
    #endif
}

// MARK: - Font Panel Delegate

#if os(macOS)
    /// Handles font selection from the native macOS font panel.
    private final class FontPanelDelegate: NSObject {
        private let onFontChange: (NSFont) -> Void

        init(onFontChange: @escaping (NSFont) -> Void) {
            self.onFontChange = onFontChange
            super.init()
        }

        /// Called when the user selects a font in the font panel.
        @objc
        func changeFont(_ sender: NSFontManager?) {
            guard let manager = sender else { return }

            // Get the current font from the panel
            let currentFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let newFont = manager.convert(currentFont)

            onFontChange(newFont)
        }

        /// Restricts the font panel to show only relevant options.
        @objc
        func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
            [.collection, .face, .size]
        }
    }
#endif

// MARK: - ReaderFontFamily Extensions

extension ReaderFontFamily {
    /// Display name optimized for UI presentation.
    var displayName: String {
        switch self {
        case .mapleMonoNF:
            "Maple Mono"
        case .sfPro:
            "SF Pro"
        case .newYork:
            "New York"
        case .georgia:
            "Georgia"
        }
    }

    /// Category label shown as secondary text.
    var categoryLabel: String {
        switch self {
        case .mapleMonoNF:
            "Monospaced"
        case .sfPro:
            "System"
        case .newYork, .georgia:
            "Serif"
        }
    }

    /// SwiftUI Font representation for preview rendering.
    func swiftUIFont(size: CGFloat) -> SwiftUI.Font {
        switch self {
        case .mapleMonoNF:
            return .custom("Maple Mono NF", size: size)
        case .sfPro:
            return .system(size: size, weight: .regular, design: .default)
        case .newYork:
            return .custom("New York", size: size)
        case .georgia:
            return .custom("Georgia", size: size)
        }
    }

    #if os(macOS)
        /// Creates a ReaderFontFamily from an NSFont, attempting to match by name.
        init?(from font: NSFont) {
            let fontName = font.fontName.lowercased()
            let familyName = font.familyName?.lowercased() ?? ""

            // Check for monospace fonts
            let isMonospace = fontName.contains("mono") || fontName.contains("menlo")
                || fontName.contains("courier") || familyName.contains("mono")
            if isMonospace {
                // Keep current monospace selection or default to Maple Mono
                self = .mapleMonoNF
                return
            }

            // Check for serif fonts
            if fontName.contains("newyork") || fontName.contains("new york") {
                self = .newYork
                return
            }

            if fontName.contains("georgia") || familyName.contains("georgia") {
                self = .georgia
                return
            }

            if fontName.contains("times") || fontName.contains("hoefler") {
                self = .newYork
                return
            }

            // Default to SF Pro for system fonts and everything else
            self = .sfPro
        }
    #endif
}

// MARK: - Previews

#Preview("Font Family Picker") {
    @Previewable @State var selectedFont: ReaderFontFamily = .newYork

    VStack(spacing: 20) {
        FontFamilyPicker(selection: $selectedFont)
            .frame(width: 200)

        Divider()

        Text("Selected: \(selectedFont.displayName)")
            .font(.caption)
            .foregroundStyle(.secondary)

        Text("The quick brown fox jumps over the lazy dog.")
            .font(selectedFont.swiftUIFont(size: 16))
            .padding()
    }
    .padding()
}
