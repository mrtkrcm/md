//
//  NativeSyntaxStyle.swift
//  mdviewer
//

#if os(macOS)
    @preconcurrency internal import AppKit

    // MARK: - Native Syntax Style

    struct NativeSyntaxStyle {
        let keyword: NSColor
        let string: NSColor
        let type: NSColor
        let number: NSColor
        let comment: NSColor
        let call: NSColor
    }
#endif
