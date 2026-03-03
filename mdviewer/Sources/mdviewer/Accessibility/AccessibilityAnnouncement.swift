//
//  AccessibilityAnnouncement.swift
//  mdviewer
//
//  Helper for posting VoiceOver accessibility announcements.
//

internal import AppKit
internal import SwiftUI

// MARK: - Accessibility Announcement

/// Utility for posting accessibility announcements to VoiceOver.
/// Use this to notify users of state changes, loading completion, and other important events.
@MainActor
enum AccessibilityAnnouncement {
    /// Posts an announcement that VoiceOver will speak to the user.
    /// - Parameter message: The message to announce
    static func post(_ message: String) {
        // Use NSAccessibility post notification for the focused element
        // This ensures the announcement is spoken by VoiceOver
        if let focusedElement = NSApp.keyWindow?.firstResponder {
            NSAccessibility.post(
                element: focusedElement,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: message,
                ]
            )
        } else {
            // Fallback to posting on the main window
            if let mainWindow = NSApp.mainWindow {
                NSAccessibility.post(
                    element: mainWindow,
                    notification: .announcementRequested,
                    userInfo: [
                        .announcement: message,
                    ]
                )
            }
        }
    }

    /// Announces that a document has loaded.
    /// - Parameters:
    ///   - charCount: Number of characters in the document
    ///   - headingCount: Optional number of headings (for rendered mode)
    static func documentLoaded(charCount: Int, headingCount: Int? = nil) {
        let message: String
        if charCount == 0 {
            message = "Empty document loaded"
        } else if let headings = headingCount, headings > 0 {
            message = "Document loaded, \(charCount) characters, \(headings) headings"
        } else {
            message = "Document loaded, \(charCount) characters"
        }
        post(message)
    }

    /// Announces a mode change between rendered and raw.
    /// - Parameter isRenderedMode: Whether the new mode is rendered
    static func modeChanged(to isRenderedMode: Bool) {
        if isRenderedMode {
            post("Switched to rendered mode")
        } else {
            post("Switched to raw editing mode")
        }
    }

    /// Announces that settings have changed.
    /// - Parameter settingName: Name of the changed setting
    static func settingChanged(_ settingName: String) {
        post("\(settingName) updated")
    }

    /// Announces loading state for large documents.
    /// - Parameter isLoading: Whether loading is starting or complete
    static func documentLoading(_ isLoading: Bool) {
        if isLoading {
            post("Loading document...")
        } else {
            post("Document loaded")
        }
    }
}

// MARK: - View Extension

extension View {
    /// Announces a message via VoiceOver when the value changes.
    /// - Parameters:
    ///   - message: The message to announce
    ///   - value: The value to monitor for changes
    func announce<V: Equatable>(_ message: String, when value: V) -> some View {
        modifier(AccessibilityAnnouncementModifier(message: message, value: value))
    }
}

// MARK: - Announcement Modifier

/// View modifier that announces accessibility messages when a value changes.
struct AccessibilityAnnouncementModifier<Value: Equatable>: ViewModifier {
    let message: String
    let value: Value

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, _ in
                AccessibilityAnnouncement.post(message)
            }
    }
}
