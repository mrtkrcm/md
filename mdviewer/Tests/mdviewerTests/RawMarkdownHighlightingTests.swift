//
//  RawMarkdownHighlightingTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        internal import SwiftUI
        @testable internal import mdviewer

        @MainActor
        final class RawMarkdownHighlightingTests: XCTestCase {

            private static let defaultConfig = RawMarkdownTextView.HighlightConfiguration()

            func testFencedCodeDoesNotReceiveHeadingStyling() async throws {
                let source = """
                # Real Heading

                ```text
                # Not a heading
                ```
                """

                let (textView, coordinator) = highlightedView(source: source)
                try await Task.sleep(nanoseconds: 180_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task

                let storage = try XCTUnwrap(textView.textStorage)
                let nsString = storage.string as NSString
                let headingRange = nsString.range(of: "# Real Heading")
                let fencedHashRange = nsString.range(of: "# Not a heading")
                XCTAssertNotEqual(headingRange.location, NSNotFound)
                XCTAssertNotEqual(fencedHashRange.location, NSNotFound)

                let headingFont = storage.attribute(.font, at: headingRange.location, effectiveRange: nil) as? NSFont
                let fencedFont = storage.attribute(.font, at: fencedHashRange.location, effectiveRange: nil) as? NSFont
                XCTAssertNotNil(headingFont)
                XCTAssertNotNil(fencedFont)
                XCTAssertTrue(isBold(headingFont), "Markdown heading should be bold")
                XCTAssertFalse(isBold(fencedFont), "Fence content should not get heading bold styling")
            }

            func testHeadingColorChangesAcrossSyntaxPalettes() async {
                let source = "# Palette Heading"
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 180_000_000)
                let firstColor = headingColor(in: textView)

                var wwdc18Config = Self.defaultConfig
                wwdc18Config.syntaxPalette = .wwdc18
                coordinator.applyHighlighting(to: textView, config: wwdc18Config)
                try? await Task.sleep(nanoseconds: 180_000_000)
                let secondColor = headingColor(in: textView)

                XCTAssertNotNil(firstColor)
                XCTAssertNotNil(secondColor)
                XCTAssertNotEqual(firstColor, secondColor, "Heading token color should respond to palette changes")
            }

            // MARK: - Helpers

            private func highlightedView(
                source: String,
                config: RawMarkdownTextView.HighlightConfiguration = defaultConfig
            ) -> (NSTextView, RawMarkdownTextView.Coordinator) {
                let textView = makeTextView()
                let coordinator = RawMarkdownTextView.Coordinator(text: .constant(source))
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(to: textView, config: config)
                return (textView, coordinator)
            }

            private func makeTextView() -> NSTextView {
                let storage = NSTextStorage()
                let layout = NSLayoutManager()
                let container = NSTextContainer(size: NSSize(width: 600, height: CGFloat.greatestFiniteMagnitude))
                storage.addLayoutManager(layout)
                layout.addTextContainer(container)
                return NSTextView(frame: .zero, textContainer: container)
            }

            private func headingColor(in textView: NSTextView) -> NSColor? {
                guard let storage = textView.textStorage else { return nil }
                let nsString = storage.string as NSString
                let range = nsString.range(of: "# Palette Heading")
                guard range.location != NSNotFound else { return nil }
                return storage.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor
            }

            private func isBold(_ font: NSFont?) -> Bool {
                guard let font else { return false }
                return font.fontDescriptor.symbolicTraits.contains(.bold)
            }
        }
    #endif
#endif
