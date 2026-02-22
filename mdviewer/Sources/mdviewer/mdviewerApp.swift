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
        @FocusedValue(\.editorActions) private var focusedEditorActions
    #endif

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
                .frame(minWidth: 600, minHeight: 400)
                .environment(\.preferences, AppPreferences.shared)
        }
        .defaultSize(width: 900, height: 700)
        #if os(macOS)
            .windowResizability(.contentMinSize)
            .windowToolbarStyle(.unifiedCompact)
            .commands {
                // Edit Menu - Markdown editing commands using focused values
                CommandMenu("Edit") {
                    Button("Toggle Bold") {
                        sendEditorAction(\.insertBold)
                    }
                    .keyboardShortcut("b", modifiers: [.command])
                    .disabled(focusedEditorActions == nil)

                    Button("Toggle Italic") {
                        sendEditorAction(\.insertItalic)
                    }
                    .keyboardShortcut("i", modifiers: [.command])
                    .disabled(focusedEditorActions == nil)

                    Button("Insert Code Block") {
                        sendEditorAction(\.insertCodeBlock)
                    }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .disabled(focusedEditorActions == nil)

                    Divider()

                    Button("Insert Link") {
                        sendEditorAction(\.insertLink)
                    }
                    .keyboardShortcut("k", modifiers: [.command])
                    .disabled(focusedEditorActions == nil)

                    Button("Insert Image") {
                        sendEditorAction(\.insertImage)
                    }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                    .disabled(focusedEditorActions == nil)
                }

                // View Menu
                CommandMenu("View") {
                    Button("Rendered Mode") {
                        AppPreferences.shared.setRenderedMode()
                    }
                    .keyboardShortcut("r", modifiers: [.command, .option])
                    .disabled(AppPreferences.shared.readerMode == .rendered)

                    Button("Raw Mode") {
                        AppPreferences.shared.setRawMode()
                    }
                    .keyboardShortcut("e", modifiers: [.command, .option])
                    .disabled(AppPreferences.shared.readerMode == .raw)

                    Divider()

                    Button("Zoom In") {
                        AppPreferences.shared.increaseFontSize()
                    }
                    .keyboardShortcut("=", modifiers: [.command])
                    .disabled(!AppPreferences.shared.canIncreaseFontSize)

                    Button("Zoom Out") {
                        AppPreferences.shared.decreaseFontSize()
                    }
                    .keyboardShortcut("-", modifiers: [.command])
                    .disabled(!AppPreferences.shared.canDecreaseFontSize)

                    Button("Reset Zoom") {
                        AppPreferences.shared.resetFontSize()
                    }
                    .keyboardShortcut("0", modifiers: [.command])

                    Divider()

                    Button("Show Appearance Settings") {
                        sendEditorAction(\.showAppearanceSettings)
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
                    .frame(minWidth: 520, minHeight: 480)
            }
            .defaultSize(width: 520, height: 480)
        #endif
    }

    #if os(macOS)
        /// Sends an action to the focused editor if available
        private func sendEditorAction(_ keyPath: KeyPath<EditorActions, () -> Void>) {
            focusedEditorActions?[keyPath: keyPath]()
        }
    #endif
}

#if os(macOS)
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
#endif
