//
//  MarkdownRenderAttribute.swift
//  mdviewer
//

internal import Foundation

// MARK: - Markdown Render Attribute Keys

/// Namespace for attributed string keys used during Markdown rendering.
///
/// These keys are used to tag metadata on attributed strings that is consumed
/// by the layout manager for drawing decorations like blockquote borders and backgrounds.
enum MarkdownRenderAttribute {
    /// Key used by NSAttributedString(markdown:) to convey block and inline semantic structure.
    ///
    /// The value is a `PresentationIntent` describing the semantic role of the text.
    static let presentationIntent = NSAttributedString.Key("NSPresentationIntent")

    /// Key used for inline presentation intents.
    ///
    /// The value is an `InlinePresentationIntent` for inline semantic elements.
    static let inlinePresentationIntent = NSAttributedString.Key("NSInlinePresentationIntent")

    /// Key for blockquote accent color.
    ///
    /// Stored on blockquote character ranges by the renderer. The layout manager
    /// reads this during drawing to color the left border accent bar.
    static let blockquoteAccent = NSAttributedString.Key("mdv.blockquoteAccent")

    /// Key for blockquote background color.
    ///
    /// Stored on blockquote character ranges by the renderer. The layout manager
    /// reads this during drawing to color the blockquote background.
    static let blockquoteBackground = NSAttributedString.Key("mdv.blockquoteBackground")

    /// Key for blockquote nesting depth.
    ///
    /// The value is an `Int` indicating the nesting level of the blockquote.
    /// The layout manager uses this to adjust indentation.
    static let blockquoteDepth = NSAttributedString.Key("mdv.blockquoteDepth")

    /// Key indicating a paragraph separator.
    ///
    /// Used to mark boundaries between block-level elements.
    static let paragraphSeparator = NSAttributedString.Key("mdv.paragraphSeparator")

    /// Key indicating a code block for line numbering.
    ///
    /// The value is a `Bool` indicating this range is part of a code block.
    static let codeBlock = NSAttributedString.Key("mdv.codeBlock")

    /// Key for themed table header row background color.
    ///
    /// Stored on table header ranges; consumed by `ReaderLayoutManager`
    /// to draw header surface decoration.
    static let tableHeaderBackground = NSAttributedString.Key("mdv.tableHeaderBackground")

    /// Key for themed table row background color.
    ///
    /// Stored on alternating table row ranges; consumed by
    /// `ReaderLayoutManager` for zebra-striping.
    static let tableRowBackground = NSAttributedString.Key("mdv.tableRowBackground")

    /// Key indicating whether a table row is alternating.
    ///
    /// Value is a `Bool` used by layout drawing logic to gate zebra fills.
    static let tableRowAlternating = NSAttributedString.Key("mdv.tableRowAlternating")

    /// Key for table border color.
    ///
    /// Stored on table rows and headers; consumed by layout drawing to render
    /// separators and outer edges.
    static let tableBorder = NSAttributedString.Key("mdv.tableBorder")

    /// Key for task-list checkbox state.
    ///
    /// Value is a `Bool` where `true` means checked.
    static let taskListChecked = NSAttributedString.Key("mdv.taskListChecked")
}
