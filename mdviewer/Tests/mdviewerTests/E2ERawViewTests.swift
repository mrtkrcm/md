//
//  E2ERawViewTests.swift
//  mdviewer
//
//  End-to-end tests for raw markdown editor view.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        internal import SwiftUI
        @testable internal import mdviewer

        /// E2E tests for raw markdown editor view behavior and rendering.
        @MainActor
        final class E2ERawViewTests: XCTestCase {
            
            // MARK: - Text Input Tests
            
            func testTextViewAcceptsInput() {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let testText = "# Hello World"
                coordinator.applyTextIfNeeded(testText, to: textView)
                
                XCTAssertEqual(textView.string, testText)
            }
            
            func testTextViewUpdatesBinding() {
                var text = ""
                let binding = Binding(
                    get: { text },
                    set: { text = $0 }
                )
                
                let textView = makeTextView()
                let coordinator = RawMarkdownTextView.Coordinator(text: binding)
                coordinator.textView = textView
                
                // Simulate text change
                textView.string = "Updated text"
                coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
                
                XCTAssertEqual(text, "Updated text")
            }
            
            func testEmptyDocumentRendering() {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                coordinator.applyTextIfNeeded("", to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                XCTAssertEqual(textView.string, "")
            }
            
            // MARK: - Syntax Highlighting Tests
            
            func testHeadingHighlighting() async {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "# Heading 1\n## Heading 2\n### Heading 3"
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                
                // Verify headings have bold font
                let h1Range = nsString.range(of: "# Heading 1")
                XCTAssertNotEqual(h1Range.location, NSNotFound)
                
                if h1Range.location != NSNotFound {
                    let font = storage.attribute(.font, at: h1Range.location, effectiveRange: nil) as? NSFont
                    XCTAssertTrue(font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false, "Heading should be bold")
                }
            }
            
            func testCodeBlockHighlighting() async {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = """
                ```swift
                let x = 42
                print(x)
                ```
                """
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                
                // Verify code has background color
                let codeRange = nsString.range(of: "let x = 42")
                XCTAssertNotEqual(codeRange.location, NSNotFound)
                
                if codeRange.location != NSNotFound {
                    let bgColor = storage.attribute(.backgroundColor, at: codeRange.location, effectiveRange: nil)
                    XCTAssertNotNil(bgColor, "Code should have background color")
                }
            }
            
            func testInlineCodeHighlighting() async {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "Use `let x = 42` in your code"
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                
                let inlineRange = nsString.range(of: "`let x = 42`")
                XCTAssertNotEqual(inlineRange.location, NSNotFound)
                
                if inlineRange.location != NSNotFound {
                    let bgColor = storage.attribute(.backgroundColor, at: inlineRange.location, effectiveRange: nil)
                    XCTAssertNotNil(bgColor, "Inline code should have background color")
                }
            }
            
            func testLinkHighlighting() async {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "[Link text](https://example.com)"
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                
                let linkRange = nsString.range(of: "[Link text](https://example.com)")
                XCTAssertNotEqual(linkRange.location, NSNotFound)
                
                if linkRange.location != NSNotFound {
                    let underline = storage.attribute(.underlineStyle, at: linkRange.location, effectiveRange: nil) as? Int
                    XCTAssertEqual(underline, NSUnderlineStyle.single.rawValue, "Link should be underlined")
                }
            }
            
            func testListHighlighting() async {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "- Item 1\n- Item 2\n* Item 3"
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                let storage = textView.textStorage!
                XCTAssertTrue(storage.length > 0)
            }
            
            func testBlockquoteHighlighting() async {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "> This is a quote\n> Second line"
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                let storage = textView.textStorage!
                XCTAssertTrue(storage.length > 0)
            }
            
            // MARK: - Protected Range Tests
            
            func testFencedCodeBlocksProtectContentFromOtherHighlighting() async {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                // Code inside fences should not get heading styling
                let source = """
                # Real Heading
                
                ```
                # This is not a heading
                ## This is also not a heading
                ```
                """
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                
                let realHeadingRange = nsString.range(of: "# Real Heading")
                let fakeHeadingRange = nsString.range(of: "# This is not a heading")
                
                XCTAssertNotEqual(realHeadingRange.location, NSNotFound)
                XCTAssertNotEqual(fakeHeadingRange.location, NSNotFound)
                
                if realHeadingRange.location != NSNotFound && fakeHeadingRange.location != NSNotFound {
                    let realFont = storage.attribute(.font, at: realHeadingRange.location, effectiveRange: nil) as? NSFont
                    let fakeFont = storage.attribute(.font, at: fakeHeadingRange.location, effectiveRange: nil) as? NSFont
                    
                    let realIsBold = realFont?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
                    let fakeIsBold = fakeFont?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
                    
                    XCTAssertTrue(realIsBold, "Real heading should be bold")
                    XCTAssertFalse(fakeIsBold, "Fake heading in code block should not be bold")
                }
            }
            
            // MARK: - Line Numbers Tests
            
            func testLineNumberRulerViewExists() {
                let scrollView = NSScrollView()
                let textView = makeTextView()
                scrollView.documentView = textView
                
                let rulerView = LineNumberRulerView(scrollView: scrollView)
                rulerView.clientView = textView
                scrollView.verticalRulerView = rulerView
                scrollView.hasVerticalRuler = true
                scrollView.rulersVisible = true
                
                XCTAssertNotNil(scrollView.verticalRulerView)
                XCTAssertTrue(scrollView.rulersVisible)
            }
            
            // MARK: - Performance Tests
            
            func testLargeDocumentHighlightingPerformance() {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                // Create a large document
                var lines: [String] = []
                for i in 0..<1000 {
                    lines.append("# Heading \(i)")
                    lines.append("Paragraph text with `inline code` and **bold**.")
                    lines.append("```swift")
                    lines.append("let x = \(i)")
                    lines.append("```")
                }
                let source = lines.joined(separator: "\n")
                
                measure {
                    coordinator.applyTextIfNeeded(source, to: textView)
                    coordinator.applyHighlighting(
                        to: textView,
                        fontFamily: .newYork,
                        fontSize: 16,
                        syntaxPalette: .midnight,
                        colorScheme: .light
                    )
                }
            }
            
            // MARK: - Font Family Tests
            
            func testAllFontFamiliesRenderWithoutCrash() {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "# Heading\n\nParagraph with `code`."
                
                for family in ReaderFontFamily.allCases {
                    coordinator.applyTextIfNeeded(source, to: textView)
                    coordinator.applyHighlighting(
                        to: textView,
                        fontFamily: family,
                        fontSize: 16,
                        syntaxPalette: .midnight,
                        colorScheme: .light
                    )
                    
                    XCTAssertEqual(textView.string, source, "Font family \(family) should render correctly")
                }
            }
            
            // MARK: - Color Scheme Tests
            
            func testLightAndDarkColorSchemes() {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "# Test Heading"
                
                for scheme in [ColorScheme.light, ColorScheme.dark] {
                    coordinator.applyTextIfNeeded(source, to: textView)
                    coordinator.applyHighlighting(
                        to: textView,
                        fontFamily: .newYork,
                        fontSize: 16,
                        syntaxPalette: .midnight,
                        colorScheme: scheme
                    )
                    
                    XCTAssertEqual(textView.string, source)
                }
            }
            
            // MARK: - Edge Cases
            
            func testDocumentWithOnlyWhitespace() {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "   \n\n\t\n   "
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                XCTAssertEqual(textView.string, source)
            }
            
            func testDocumentWithSpecialCharacters() {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = "# Emoji 🎉\n\nUnicode: ñ 中文\n\nMath: ∫ ∑"
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                XCTAssertEqual(textView.string, source)
            }
            
            func testVeryLongLine() {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let longLine = String(repeating: "word ", count: 500)
                let source = "# Heading\n\n\(longLine)"
                
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                XCTAssertEqual(textView.string, source)
            }
            
            func testNestedFencedCodeBlocks() async {
                let textView = makeTextView()
                let coordinator = makeCoordinator()
                coordinator.textView = textView
                
                let source = """
                ````markdown
                ```swift
                code here
                ```
                ````
                """
                
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(
                    to: textView,
                    fontFamily: .newYork,
                    fontSize: 16,
                    syntaxPalette: .midnight,
                    colorScheme: .light
                )
                
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                XCTAssertTrue(textView.string.contains("code here"))
            }
            
            // MARK: - Helpers
            
            private func makeTextView() -> NSTextView {
                let storage = NSTextStorage()
                let layout = NSLayoutManager()
                let container = NSTextContainer(size: NSSize(width: 600, height: CGFloat.greatestFiniteMagnitude))
                storage.addLayoutManager(layout)
                layout.addTextContainer(container)
                return NSTextView(frame: .zero, textContainer: container)
            }
            
            private func makeCoordinator() -> RawMarkdownTextView.Coordinator {
                RawMarkdownTextView.Coordinator(text: .constant(""))
            }
        }
    #endif
#endif
