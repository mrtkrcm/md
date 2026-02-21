//
//  RenderedMarkdown.swift
//  mdviewer
//

internal import Foundation

#if os(macOS)
    @preconcurrency internal import AppKit

    // MARK: - RenderedMarkdown

    /// Immutable result of one render pass.
    ///
    /// `NSAttributedString` does not conform to `Sendable`, but this wrapper is safe across
    /// isolation boundaries because the attributed string is never mutated after creation.
    final class RenderedMarkdown: @unchecked Sendable {
        let attributedString: NSAttributedString

        init(attributedString: NSAttributedString) {
            self.attributedString = attributedString
        }
    }

#endif
