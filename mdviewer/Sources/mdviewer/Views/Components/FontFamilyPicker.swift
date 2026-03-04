//
//  FontFamilyPicker.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - FontFamilyPicker

/// A native-style font family picker that shows each font option
/// rendered in its actual typeface for better visual identification.
struct FontFamilyPicker: View {
    @Binding var selection: ReaderFontFamily

    var body: some View {
        Menu(content: menuContent, label: menuLabel)
            .menuStyle(.borderlessButton)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Font Family")
            .accessibilityHint("Choose a font for reading")
    }

    // MARK: - Menu Content

    private func menuContent() -> some View {
        ForEach(ReaderFontFamily.allCases) { family in
            fontButton(for: family)
        }
    }

    private func fontButton(for family: ReaderFontFamily) -> some View {
        Button {
            selection = family
        } label: {
            fontButtonLabel(for: family)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(family.displayName)")
    }

    private func fontButtonLabel(for family: ReaderFontFamily) -> some View {
        HStack {
            Text(family.displayName)
                .font(family.swiftUIFont(size: 13))
            Spacer()
            checkmarkIfSelected(family)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func checkmarkIfSelected(_ family: ReaderFontFamily) -> some View {
        if selection == family {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.accentColor)
        }
    }

    // MARK: - Menu Label

    private func menuLabel() -> some View {
        HStack(spacing: DesignTokens.Spacing.compact) {
            Text(selection.displayName)
                .font(selection.swiftUIFont(size: 13))
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
}

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
    }
    .padding()
}
