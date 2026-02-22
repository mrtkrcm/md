//
//  mdviewerApp.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    @preconcurrency internal import AppKit
#endif

@main
struct mdviewerApp: App {
    #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        @AppStorage("readerFontSize") private var readerFontSizeRaw = ReaderFontSize.standard.rawValue
        @AppStorage("readerMode") private var readerModeRaw = ReaderMode.rendered.rawValue
    #endif

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 900, height: 700)
        #if os(macOS)
        .commands {
            // File Menu additions
            CommandGroup(before: .newItem) {
                // Open Recent is automatically handled by NSDocumentController
                // We just need to ensure recent documents are tracked
                EmptyView()
            }

            // Edit Menu - Markdown editing commands
            CommandMenu("Edit") {
                Button("Toggle Bold") {
                    NotificationCenter.default.post(name: .toggleBold, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command])

                Button("Toggle Italic") {
                    NotificationCenter.default.post(name: .toggleItalic, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command])

                Button("Insert Code Block") {
                    NotificationCenter.default.post(name: .insertCodeBlock, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])

                Divider()

                Button("Insert Link") {
                    NotificationCenter.default.post(name: .insertLink, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("Insert Image") {
                    NotificationCenter.default.post(name: .insertImage, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }

            // View Menu
            CommandMenu("View") {
                Button("Rendered Mode") {
                    readerModeRaw = ReaderMode.rendered.rawValue
                }
                .keyboardShortcut("r", modifiers: [.command, .option])
                .disabled(readerMode == .rendered)

                Button("Raw Mode") {
                    readerModeRaw = ReaderMode.raw.rawValue
                }
                .keyboardShortcut("e", modifiers: [.command, .option])
                .disabled(readerMode == .raw)

                Divider()

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

                Button("Reset Zoom") {
                    readerFontSizeRaw = ReaderFontSize.standard.rawValue
                }
                .keyboardShortcut("0", modifiers: [.command])

                Divider()

                Button("Show Appearance Settings") {
                    NotificationCenter.default.post(name: .showAppearanceSettings, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }

            // Window Menu - Add Full Screen shortcut explicitly
            CommandGroup(after: .windowSize) {
                Divider()

                Button("Enter Full Screen") {
                    NSApplication.shared.keyWindow?.toggleFullScreen(nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
            }
        }
        #endif

        #if os(macOS)
            Settings {
                SettingsView()
            }
            .defaultSize(width: 520, height: 480)
        #endif
    }

    #if os(macOS)
    private var readerMode: ReaderMode {
        ReaderMode.from(rawValue: readerModeRaw)
    }
    #endif
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

        func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
            if !flag {
                NSDocumentController.shared.newDocument(nil)
            }
            return true
        }

        func application(_ application: NSApplication, open urls: [URL]) {
            for url in urls {
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                    if let error {
                        NSApplication.shared.presentError(error)
                    }
                }
            }
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

    // MARK: - Notifications
    extension Notification.Name {
        static let toggleBold = Notification.Name("toggleBold")
        static let toggleItalic = Notification.Name("toggleItalic")
        static let insertCodeBlock = Notification.Name("insertCodeBlock")
        static let insertLink = Notification.Name("insertLink")
        static let insertImage = Notification.Name("insertImage")
        static let showAppearanceSettings = Notification.Name("showAppearanceSettings")
    }
#endif
