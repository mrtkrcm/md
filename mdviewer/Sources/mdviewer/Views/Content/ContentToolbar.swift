//
//  ContentToolbar.swift
//  mdviewer
//
//  Toolbar content for the main document window.
//

internal import OSLog
internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

/// Signpost logger for toolbar interaction profiling.
private let toolbarSignposter = OSSignposter(subsystem: "mdviewer", category: "Toolbar")

/// Toolbar content providing mode switching and primary document actions.
/// Uses native macOS toolbar components without custom styling.
struct ContentToolbar: ToolbarContent {
    @Binding var readerMode: ReaderMode
    @Binding var showAppearancePopover: Bool
    @Binding var showMetadataInspector: Bool
    let openAction: () -> Void
    let documentText: String
    let hasFrontmatter: Bool

    var body: some ToolbarContent {
        // Centered mode switcher - native NSSegmentedControl style
        ToolbarItem(id: "mode", placement: .principal) {
            Picker("Mode", selection: $readerMode) {
                Image(systemName: "doc.text.image")
                    .help("Rendered")
                    .tag(ReaderMode.rendered)
                Image(systemName: "doc.plaintext")
                    .help("Raw")
                    .tag(ReaderMode.raw)
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
        }

        // Trailing action items - native macOS toolbar buttons
        ToolbarItem(id: "inspector", placement: .automatic) {
            Button {
                toolbarSignposter.emitEvent("InspectorToggleTapped")
                showMetadataInspector.toggle()
            } label: {
                Image(systemName: "sidebar.right")
            }
            .help(hasFrontmatter ? "Toggle Metadata Panel" : "No metadata available")
            .disabled(!hasFrontmatter)
            .opacity(hasFrontmatter ? 1.0 : 0.5)
        }

        ToolbarItem(id: "appearance", placement: .automatic) {
            Button {
                showAppearancePopover = true
            } label: {
                Image(systemName: "paintbrush")
            }
            .help("Appearance Settings")
        }

        ToolbarItem(id: "share", placement: .automatic) {
            ShareLink(item: documentText) {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Share Document")
        }

        ToolbarItem(id: "open", placement: .automatic) {
            Button {
                openAction()
            } label: {
                Image(systemName: "folder")
            }
            .help("Open markdown file")
        }
    }
}
