//
//  ContentToolbar.swift
//  mdviewer
//
//  Toolbar content for the main document window.
//

internal import SwiftUI

/// Toolbar content providing mode switching and primary document actions.
struct ContentToolbar: ToolbarContent {
    @Binding var readerMode: ReaderMode
    @Binding var showAppearancePopover: Bool
    @Binding var showMetadataInspector: Bool
    let openAction: () -> Void
    let documentText: String

    var body: some ToolbarContent {
        // Centered mode switcher
        ToolbarItem(id: "mode", placement: .principal) {
            Picker("Mode", selection: $readerMode) {
                Label("Rendered", systemImage: "doc.text.image")
                    .tag(ReaderMode.rendered)
                Label("Raw", systemImage: "doc.plaintext")
                    .tag(ReaderMode.raw)
            }
            .pickerStyle(.segmented)
            .labelStyle(.iconOnly)
            .frame(width: 120)
            .help("Switch between rendered and raw view")
        }

        // Primary actions — individual items let the system handle spacing/glass
        ToolbarItem(id: "open", placement: .primaryAction) {
            Button(action: openAction) {
                Label("Open", systemImage: "folder")
            }
            .help("Open markdown file")
        }

        ToolbarItem(id: "share", placement: .primaryAction) {
            ShareLink(item: documentText) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .help("Share Document")
        }

        ToolbarItem(id: "appearance", placement: .primaryAction) {
            Button(action: { showAppearancePopover = true }) {
                Label("Appearance", systemImage: "paintbrush")
            }
            .help("Appearance Settings")
        }

        ToolbarItem(id: "inspector", placement: .primaryAction) {
            Button(action: { showMetadataInspector.toggle() }) {
                Label("Metadata", systemImage: "sidebar.right")
            }
            .help("Toggle Metadata Panel")
        }
    }
}
