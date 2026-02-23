//
//  DocumentOperations.swift
//  mdviewer
//

internal import SwiftUI
internal import OSLog
#if os(macOS)
    internal import AppKit
#endif

/// Handles document operations like opening files and resetting content.
@MainActor
struct DocumentOperations {
    let document: Binding<MarkdownDocument>
    let openDocument: OpenDocumentAction
    let onError: (String) -> Void
    let onSuccess: () -> Void

    private let logger = Logger(subsystem: "mdviewer", category: "document-ops")

    func openFromDisk() {
        #if os(macOS)
            let panel = NSOpenPanel()
            panel.title = "Open Markdown File"
            panel.allowedContentTypes = MarkdownDocument.readableContentTypes
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.resolvesAliases = true

            guard panel.runModal() == .OK, let url = panel.url else {
                return
            }

            Task { @MainActor in
                do {
                    try await openDocument(at: url)
                    onSuccess()
                } catch {
                    logger.error("Open document failed: \(String(describing: error), privacy: .public)")
                    onError(error.localizedDescription)
                }
            }
        #endif
    }

    func resetToStarter() {
        document.wrappedValue.text = MarkdownDocument.starterContent
        onSuccess()
    }
}
