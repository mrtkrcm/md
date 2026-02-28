//
//  ContentToolbar.swift
//  mdviewer
//
//  Toolbar content for the main document window.
//

internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

/// Toolbar content providing mode switching and primary document actions.
/// Uses native macOS toolbar styling with custom mode picker for native appearance.
struct ContentToolbar: ToolbarContent {
    @Binding var readerMode: ReaderMode
    @Binding var showAppearancePopover: Bool
    @Binding var showMetadataInspector: Bool
    let openAction: () -> Void
    let documentText: String

    var body: some ToolbarContent {
        // Centered mode switcher with native macOS styling
        ToolbarItem(id: "mode", placement: .principal) {
            ModePicker(readerMode: $readerMode)
        }

        // Trailing action items with native macOS toolbar button styling
        ToolbarItem(id: "inspector", placement: .automatic) {
            ToolbarButton(
                action: { showMetadataInspector.toggle() },
                systemImage: "sidebar.right",
                isActive: showMetadataInspector,
                helpText: "Toggle Metadata Panel"
            )
        }

        ToolbarItem(id: "appearance", placement: .automatic) {
            ToolbarButton(
                action: { showAppearancePopover = true },
                systemImage: "paintbrush",
                helpText: "Appearance Settings"
            )
        }

        ToolbarItem(id: "share", placement: .automatic) {
            ShareLink(item: documentText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help("Share Document")
        }

        ToolbarItem(id: "open", placement: .automatic) {
            ToolbarButton(
                action: openAction,
                systemImage: "folder",
                helpText: "Open markdown file"
            )
        }
    }
}

// MARK: - Mode Picker

/// Native macOS mode picker with custom styling matching system controls.
private struct ModePicker: View {
    @Binding var readerMode: ReaderMode
    @State private var hoverMode: ReaderMode?

    var body: some View {
        HStack(spacing: 2) {
            ModeButton(
                mode: .rendered,
                icon: "doc.text.image",
                isSelected: readerMode == .rendered,
                isHovered: hoverMode == .rendered
            ) {
                readerMode = .rendered
            }
            .onHover { isHovered in
                hoverMode = isHovered ? .rendered : nil
            }

            ModeButton(
                mode: .raw,
                icon: "doc.plaintext",
                isSelected: readerMode == .raw,
                isHovered: hoverMode == .raw
            ) {
                readerMode = .raw
            }
            .onHover { isHovered in
                hoverMode = isHovered ? .raw : nil
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(
                    color: .black.opacity(0.04),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .help("Switch between rendered and raw view")
    }
}

/// Individual mode button with native macOS selection styling.
private struct ModeButton: View {
    let mode: ReaderMode
    let icon: String
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(width: 32, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(backgroundColor)
                .shadow(
                    color: isSelected ? .black.opacity(0.08) : .clear,
                    radius: 0.5,
                    x: 0,
                    y: 0.5
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(nsColor: .selectedControlColor)
        } else if isHovered {
            return Color.primary.opacity(0.06)
        }
        return Color.clear
    }
}

// MARK: - Toolbar Button

/// Native macOS toolbar button with hover and active states.
private struct ToolbarButton: View {
    let action: () -> Void
    let systemImage: String
    var isActive: Bool = false
    let helpText: String
    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(backgroundColor)
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }

    private var backgroundColor: Color {
        if isActive {
            return Color(nsColor: .selectedControlColor).opacity(0.6)
        } else if isPressed {
            return Color.primary.opacity(0.12)
        } else if isHovered {
            return Color.primary.opacity(0.08)
        }
        return Color.clear
    }
}
