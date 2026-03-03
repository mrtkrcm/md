//
//  DocumentOperations.swift
//  mdviewer
//
//  Handles document operations like opening files and resetting content.
//  Includes file size warnings for accessibility.
//

internal import OSLog
internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

/// Handles document operations like opening files and resetting content.
/// Provides accessibility-friendly warnings for large files.
/// Uses user-configurable threshold from AppPreferences.
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

            // Check file size before opening using user's threshold preference
            checkFileSizeAndOpen(url: url)
        #endif
    }

    /// Checks file size and shows warning for large files before opening.
    /// Uses the user's configured threshold from AppPreferences.
    /// - Parameter url: The file URL to check and open
    private func checkFileSizeAndOpen(url: URL) {
        #if os(macOS)
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0

                // Use user's configured threshold
                let threshold = AppPreferences.shared.largeFileThreshold

                if threshold.shouldWarn(for: fileSize) {
                    // Show warning for large files
                    showLargeFileWarning(url: url, fileSize: fileSize)
                } else {
                    // Open normally for small files
                    openDocumentAsync(url: url)
                }
            } catch {
                // If we can't get file size, proceed anyway
                logger.warning("Could not determine file size for \(url.path), proceeding anyway")
                openDocumentAsync(url: url)
            }
        #endif
    }

    /// Shows a warning alert for large files with accessibility labels.
    /// - Parameters:
    ///   - url: The file URL
    ///   - fileSize: The file size in bytes
    private func showLargeFileWarning(url: URL, fileSize: Int64) {
        #if os(macOS)
            let sizeInMB = Double(fileSize) / 1_048_576.0
            let formattedSize = String(format: "%.1f MB", sizeInMB)

            let alert = NSAlert()
            alert.messageText = "Large File"
            alert.informativeText = "This file is \(formattedSize). Opening may take a moment and could affect performance. Do you want to continue?"
            alert.alertStyle = .warning

            let continueButton = alert.addButton(withTitle: "Continue")
            let cancelButton = alert.addButton(withTitle: "Cancel")

            // Set accessibility labels for buttons
            continueButton.setAccessibilityLabel("Continue opening large file")
            cancelButton.setAccessibilityLabel("Cancel opening file")

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                // User chose to continue
                openDocumentAsync(url: url)
            }
            // If cancelled, do nothing
        #endif
    }

    /// Opens the document asynchronously.
    /// - Parameter url: The file URL to open
    private func openDocumentAsync(url: URL) {
        Task { @MainActor in
            do {
                try await openDocument(at: url)
                onSuccess()
            } catch {
                logger.error("Open document failed: \(String(describing: error), privacy: .public)")
                onError(error.localizedDescription)
            }
        }
    }

    func resetToStarter() {
        document.wrappedValue.text = MarkdownDocument.starterContent
        onSuccess()
    }
}

// MARK: - File Size Formatter

extension DocumentOperations {
    /// Formats file size for display.
    /// - Parameter bytes: Size in bytes
    /// - Returns: Human-readable string
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
