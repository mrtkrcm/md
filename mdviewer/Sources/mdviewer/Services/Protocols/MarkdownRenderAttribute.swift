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
}
