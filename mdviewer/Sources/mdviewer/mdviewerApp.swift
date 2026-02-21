internal import SwiftUI
#if os(macOS)
    @preconcurrency internal import AppKit
#endif

@main
struct mdviewerApp: App {
    #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        @AppStorage("readerFontSize") private var readerFontSizeRaw = ReaderFontSize.standard.rawValue
    #endif

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
        }
        #if os(macOS)
        .commands {
            CommandMenu("View") {
                Button("Zoom In") {
                    increaseReaderFontSize()
                }
                .keyboardShortcut("=", modifiers: [.command])
                .disabled(!canIncreaseReaderFontSize)

                Button("Zoom Out") {
                    decreaseReaderFontSize()
                }
                .keyboardShortcut("-", modifiers: [.command])
                .disabled(!canDecreaseReaderFontSize)
            }
        }
        #endif

        #if os(macOS)
            Settings {
                SettingsView()
            }
        #endif
    }
}

#if os(macOS)
    private extension mdviewerApp {
        var orderedReaderSizes: [ReaderFontSize] {
            ReaderFontSize.allCases.sorted { $0.rawValue < $1.rawValue }
        }

        var currentReaderFontSizeIndex: Int {
            let current = ReaderFontSize.from(rawValue: readerFontSizeRaw)
            return orderedReaderSizes.firstIndex(of: current) ?? 0
        }

        var canIncreaseReaderFontSize: Bool {
            currentReaderFontSizeIndex < orderedReaderSizes.count - 1
        }

        var canDecreaseReaderFontSize: Bool {
            currentReaderFontSizeIndex > 0
        }

        func increaseReaderFontSize() {
            guard canIncreaseReaderFontSize else { return }
            readerFontSizeRaw = orderedReaderSizes[currentReaderFontSizeIndex + 1].rawValue
        }

        func decreaseReaderFontSize() {
            guard canDecreaseReaderFontSize else { return }
            readerFontSizeRaw = orderedReaderSizes[currentReaderFontSizeIndex - 1].rawValue
        }
    }

    @MainActor
    final class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            NSWindow.allowsAutomaticWindowTabbing = true
            openDocumentFromCLIIfNeeded()
        }

        private func openDocumentFromCLIIfNeeded() {
            guard let url = cliDocumentURL() else {
                return
            }

            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                if let error {
                    NSApplication.shared.presentError(error)
                }
            }
        }

        private func cliDocumentURL() -> URL? {
            let args = CommandLine.arguments.dropFirst()

            guard let rawPath = args.first(where: { !$0.hasPrefix("-") }) else {
                return nil
            }

            let expandedPath = (rawPath as NSString).expandingTildeInPath
            let resolvedPath: String
            if expandedPath.hasPrefix("/") {
                resolvedPath = expandedPath
            } else {
                resolvedPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent(expandedPath)
                    .path
            }

            guard FileManager.default.fileExists(atPath: resolvedPath) else {
                return nil
            }

            return URL(fileURLWithPath: resolvedPath)
        }
    }
#endif
