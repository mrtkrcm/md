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
/// Uses native macOS toolbar components with SF Symbol effects for liquid design.
struct ContentToolbar: ToolbarContent {
    @Binding var readerMode: ReaderMode
    @Binding var showAppearancePopover: Bool
    @Binding var showMetadataInspector: Bool
    @Binding var sidebarMode: SidebarMode
    let documentText: String
    let hasFrontmatter: Bool
    let fileURL: URL?

    var body: some ToolbarContent {
        // Centered mode switcher - native NSSegmentedControl style with symbol effects
        ToolbarItem(id: "mode", placement: .principal) {
            Picker("Mode", selection: $readerMode) {
                Image(systemName: "doc.text.image")
                    .help("Rendered")
                    .tag(ReaderMode.rendered)
                    .accessibilityLabel("Rendered Mode")
                    .accessibilityHint("Show formatted markdown preview")
                    .symbolBounce(on: readerMode == .rendered)
                Image(systemName: "doc.plaintext")
                    .help("Raw")
                    .tag(ReaderMode.raw)
                    .accessibilityLabel("Raw Mode")
                    .accessibilityHint("Show raw markdown source")
                    .symbolBounce(on: readerMode == .raw)
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
            .accessibilityLabel("View Mode")
            .accessibilityValue(readerMode == .rendered ? "Rendered" : "Raw")
        }

        // Trailing action items - native macOS toolbar buttons with symbol effects
        ToolbarItem(id: "inspector", placement: .automatic) {
            Button {
                toolbarSignposter.emitEvent("InspectorToggleTapped")
                if !showMetadataInspector {
                    if sidebarMode == .folder, fileURL == nil, hasFrontmatter {
                        sidebarMode = .metadata
                    } else if sidebarMode == .metadata, !hasFrontmatter, fileURL != nil {
                        sidebarMode = .folder
                    }
                }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    showMetadataInspector.toggle()
                }
            } label: {
                Image(systemName: "sidebar.right")
                    .symbolBounce(on: showMetadataInspector)
            }
            .help(sidebarHelpText)
            .disabled(!canShowSidebar)
            .opacity(canShowSidebar ? 1.0 : 0.5)
            .accessibilityLabel("Inspector")
            .accessibilityHint(sidebarAccessibilityHint)
            .accessibilityValue(showMetadataInspector ? "Visible" : "Hidden")
        }

        ToolbarItem(id: "appearance", placement: .automatic) {
            Button {
                showAppearancePopover = true
            } label: {
                Image(systemName: "paintbrush")
                    .symbolBounce(on: showAppearancePopover)
            }
            .help("Appearance Settings")
            .accessibilityLabel("Appearance Settings")
            .accessibilityHint("Open appearance and theme settings")
        }

        ToolbarItem(id: "share", placement: .automatic) {
            ShareLink(item: documentText) {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Share Document")
            .accessibilityLabel("Share Document")
            .accessibilityHint("Share the document text")
        }
    }

    // MARK: - Helpers

    private var canShowSidebar: Bool {
        hasFrontmatter || fileURL != nil
    }

    private var sidebarHelpText: String {
        if !canShowSidebar {
            return "No metadata or folder available"
        }
        if showMetadataInspector {
            return "Hide Sidebar"
        }
        return "Show Sidebar"
    }

    private var sidebarAccessibilityHint: String {
        if !canShowSidebar {
            return "No metadata or folder information available"
        }
        return "Show or hide the sidebar panel"
    }
}
