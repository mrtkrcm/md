//
//  EditorActions.swift
//  mdviewer
//
//  Type-safe editor actions using SwiftUI's FocusedValues system.
//

internal import SwiftUI

/// Actions that can be performed by the focused markdown editor.
///
/// Use with `FocusedValue` to enable/disable menu commands based on
/// whether an editor is currently focused.
struct EditorActions {
    let insertBold: () -> Void
    let insertItalic: () -> Void
    let insertCodeBlock: () -> Void
    let insertLink: () -> Void
    let insertImage: () -> Void
    let setRenderedMode: () -> Void
    let setRawMode: () -> Void
    let jumpToLine: (Int) -> Void
}

// MARK: - Focused Value Key

struct EditorFocusedValue: FocusedValueKey {
    typealias Value = EditorActions
}

extension FocusedValues {
    /// The currently focused editor's actions, if any.
    var editorActions: EditorActions? {
        get { self[EditorFocusedValue.self] }
        set { self[EditorFocusedValue.self] = newValue }
    }
}
