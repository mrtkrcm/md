//
//  MarkdownEditor.swift
//  mdviewer
//

internal import SwiftUI

/// Handles markdown text insertion operations.
@MainActor
struct MarkdownEditor {
    let preferences: AppPreferences

    /// Inserts markdown syntax at the current cursor position.
    /// If not in raw mode, switches to raw mode first.
    func insertSyntax(wrap: String) {
        insertSyntax(prefix: wrap, suffix: wrap)
    }

    /// Inserts markdown syntax with prefix and suffix at the current cursor position.
    /// If not in raw mode, switches to raw mode first.
    func insertSyntax(prefix: String, suffix: String) {
        guard preferences.readerMode == .raw else {
            preferences.readerMode = .raw
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: .insertText,
                    object: nil,
                    userInfo: ["prefix": prefix, "suffix": suffix]
                )
            }
            return
        }

        NotificationCenter.default.post(
            name: .insertText,
            object: nil,
            userInfo: ["prefix": prefix, "suffix": suffix]
        )
    }
}

// MARK: - Editor Notifications

extension Notification.Name {
    /// Posted when text should be inserted into the editor.
    /// UserInfo contains "prefix" and "suffix" strings.
    static let insertText = Notification.Name("insertText")
}
