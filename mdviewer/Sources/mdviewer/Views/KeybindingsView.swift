//
//  KeybindingsView.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Keybinding Definition

struct Keybinding: Identifiable {
    let id = UUID()
    let title: String
    let key: String
    let modifiers: EventModifiers
    let description: String?
}

struct KeybindingSection: Identifiable {
    let id = UUID()
    let title: String
    let keybindings: [Keybinding]
}

// MARK: - Keybindings View

struct KeybindingsView: View {
    @Environment(\.dismiss) private var dismiss

    private let sections: [KeybindingSection] = [
        editingSection,
        viewSection,
        windowSection,
        navigationSection,
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.title2.bold())

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(sections) { section in
                        KeybindingSectionView(section: section)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Text("Press \u{2318} to use Command key shortcuts")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 500)
        .frame(maxWidth: 800, maxHeight: 700)
    }

    // MARK: - Sections

    private static var editingSection: KeybindingSection {
        KeybindingSection(
            title: "Editing",
            keybindings: [
                Keybinding(
                    title: "Toggle Bold",
                    key: "B",
                    modifiers: .command,
                    description: "Wrap selection in bold markdown"
                ),
                Keybinding(
                    title: "Toggle Italic",
                    key: "I",
                    modifiers: .command,
                    description: "Wrap selection in italic markdown"
                ),
                Keybinding(
                    title: "Insert Link",
                    key: "K",
                    modifiers: .command,
                    description: "Insert markdown link syntax"
                ),
                Keybinding(
                    title: "Insert Code Block",
                    key: "K",
                    modifiers: [.command, .shift],
                    description: "Insert fenced code block"
                ),
                Keybinding(
                    title: "Insert Image",
                    key: "I",
                    modifiers: [.command, .shift],
                    description: "Insert markdown image syntax"
                ),
            ]
        )
    }

    private static var viewSection: KeybindingSection {
        KeybindingSection(
            title: "View",
            keybindings: [
                Keybinding(
                    title: "Rendered Mode",
                    key: "R",
                    modifiers: [.command, .option],
                    description: "Switch to rendered markdown view"
                ),
                Keybinding(
                    title: "Raw Mode",
                    key: "E",
                    modifiers: [.command, .option],
                    description: "Switch to raw editor view"
                ),
                Keybinding(
                    title: "Zoom In",
                    key: "+",
                    modifiers: .command,
                    description: "Increase text size"
                ),
                Keybinding(
                    title: "Zoom Out",
                    key: "−",
                    modifiers: .command,
                    description: "Decrease text size"
                ),
                Keybinding(
                    title: "Reset Zoom",
                    key: "0",
                    modifiers: .command,
                    description: "Reset to default text size"
                ),
                Keybinding(
                    title: "Show Appearance Settings",
                    key: "T",
                    modifiers: [.command, .shift],
                    description: "Open appearance popover"
                ),
                Keybinding(
                    title: "Toggle Settings",
                    key: ",",
                    modifiers: .command,
                    description: "Open/close settings window"
                ),
            ]
        )
    }

    private static var windowSection: KeybindingSection {
        KeybindingSection(
            title: "Window & Tabs",
            keybindings: [
                Keybinding(
                    title: "New Window",
                    key: "N",
                    modifiers: .command,
                    description: nil
                ),
                Keybinding(
                    title: "New Tab",
                    key: "T",
                    modifiers: .command,
                    description: nil
                ),
                Keybinding(
                    title: "Show All Tabs",
                    key: "\\",
                    modifiers: [.command, .shift],
                    description: nil
                ),
                Keybinding(
                    title: "Close Window",
                    key: "W",
                    modifiers: .command,
                    description: nil
                ),
                Keybinding(
                    title: "Enter Full Screen",
                    key: "F",
                    modifiers: [.command, .control],
                    description: nil
                ),
            ]
        )
    }

    private static var navigationSection: KeybindingSection {
        KeybindingSection(
            title: "Navigation",
            keybindings: [
                Keybinding(
                    title: "Find",
                    key: "F",
                    modifiers: .command,
                    description: "Open find bar"
                ),
                Keybinding(
                    title: "Open File",
                    key: "O",
                    modifiers: .command,
                    description: "Open file dialog"
                ),
                Keybinding(
                    title: "Show Shortcuts",
                    key: "/",
                    modifiers: .command,
                    description: "Show this shortcuts window"
                ),
            ]
        )
    }
}

// MARK: - Section View

private struct KeybindingSectionView: View {
    let section: KeybindingSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                ForEach(section.keybindings) { binding in
                    KeybindingRow(binding: binding)
                }
            }
        }
    }
}

// MARK: - Keybinding Row

private struct KeybindingRow: View {
    let binding: Keybinding

    var body: some View {
        HStack(spacing: 16) {
            // Title and description
            VStack(alignment: .leading, spacing: 2) {
                Text(binding.title)
                    .font(.body)

                if let description = binding.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Keyboard shortcut display
            HStack(spacing: 4) {
                ForEach(modifierSymbols, id: \.self) { symbol in
                    KeyboardKeyView(symbol: symbol)
                }
                KeyboardKeyView(symbol: binding.key)
            }
        }
        .padding(.vertical, 4)
    }

    private var modifierSymbols: [String] {
        var symbols: [String] = []
        if binding.modifiers.contains(.command) { symbols.append("⌘") }
        if binding.modifiers.contains(.option) { symbols.append("⌥") }
        if binding.modifiers.contains(.control) { symbols.append("⌃") }
        if binding.modifiers.contains(.shift) { symbols.append("⇧") }
        return symbols
    }
}

// MARK: - Keyboard Key View

private struct KeyboardKeyView: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .frame(minWidth: 24, minHeight: 24)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 0.5, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
    }
}

// MARK: - Preview

#Preview("Keybindings") {
    KeybindingsView()
}
