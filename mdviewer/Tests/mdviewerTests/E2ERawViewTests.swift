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

            private static let defaultConfig = RawMarkdownTextView.HighlightConfiguration()

            // MARK: - Text Input Tests

            func testTextViewAcceptsInput() {
                let testText = "# Hello World"
                let (textView, _) = highlightedView(source: testText)
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

                textView.string = "Updated text"
                coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))

                XCTAssertEqual(text, "Updated text")
            }

            func testEmptyDocumentRendering() {
                let (textView, _) = highlightedView(source: "")
                XCTAssertEqual(textView.string, "")
            }

            // MARK: - Syntax Highlighting Tests

            func testHeadingHighlighting() async {
                let source = "# Heading 1\n## Heading 2\n### Heading 3"
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 100_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task

                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                let h1Range = nsString.range(of: "# Heading 1")
                XCTAssertNotEqual(h1Range.location, NSNotFound)

                guard h1Range.location != NSNotFound else {
                    XCTFail("Heading range must be found in storage")
                    return
                }
                let headingFont = storage.attribute(.font, at: h1Range.location, effectiveRange: nil) as? NSFont
                XCTAssertTrue(headingFont?.fontDescriptor.symbolicTraits.contains(.bold) ?? false, "Heading should be bold")
            }

            func testCodeBlockHighlighting() async {
                let source = """
                ```swift
                let x = 42
                print(x)
                ```
                """
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 100_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task

                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                let codeRange = nsString.range(of: "let x = 42")
                XCTAssertNotEqual(codeRange.location, NSNotFound)

                guard codeRange.location != NSNotFound else {
                    XCTFail("Code range must be found in storage")
                    return
                }
                let bgColor = storage.attribute(.backgroundColor, at: codeRange.location, effectiveRange: nil)
                XCTAssertNotNil(bgColor, "Code should have background color")
            }

            func testInlineCodeHighlighting() async {
                let source = "Use `let x = 42` in your code"
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 100_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task

                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                let inlineRange = nsString.range(of: "`let x = 42`")
                XCTAssertNotEqual(inlineRange.location, NSNotFound)

                guard inlineRange.location != NSNotFound else {
                    XCTFail("Inline code range must be found in storage")
                    return
                }
                let inlineBgColor = storage.attribute(.backgroundColor, at: inlineRange.location, effectiveRange: nil)
                XCTAssertNotNil(inlineBgColor, "Inline code should have background color")
            }

            func testLinkHighlighting() async {
                let source = "[Link text](https://example.com)"
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 100_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task

                let storage = textView.textStorage!
                let nsString = storage.string as NSString
                let linkRange = nsString.range(of: "[Link text](https://example.com)")
                XCTAssertNotEqual(linkRange.location, NSNotFound)

                guard linkRange.location != NSNotFound else {
                    XCTFail("Link range must be found in storage")
                    return
                }
                let underline = storage.attribute(.underlineStyle, at: linkRange.location, effectiveRange: nil) as? Int
                XCTAssertEqual(underline, NSUnderlineStyle.single.rawValue, "Link should be underlined")
            }

            func testListHighlighting() async {
                let source = "- Item 1\n- Item 2\n* Item 3"
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 100_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task
                XCTAssertTrue(textView.textStorage!.length > 0)
            }

            func testBlockquoteHighlighting() async {
                let source = "> This is a quote\n> Second line"
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 100_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task
                XCTAssertTrue(textView.textStorage!.length > 0)
            }

            // MARK: - Protected Range Tests

            func testFencedCodeBlocksProtectContentFromOtherHighlighting() async {
                let source = """
                # Real Heading

                ```
                # This is not a heading
                ## This is also not a heading
                ```
                """
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 100_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task

                let storage = textView.textStorage!
                let nsString = storage.string as NSString

                let realHeadingRange = nsString.range(of: "# Real Heading")
                let fakeHeadingRange = nsString.range(of: "# This is not a heading")

                XCTAssertNotEqual(realHeadingRange.location, NSNotFound)
                XCTAssertNotEqual(fakeHeadingRange.location, NSNotFound)

                guard realHeadingRange.location != NSNotFound, fakeHeadingRange.location != NSNotFound else {
                    XCTFail("Both real and fake heading ranges must be found")
                    return
                }

                let realFont = storage.attribute(.font, at: realHeadingRange.location, effectiveRange: nil) as? NSFont
                let fakeFont = storage.attribute(.font, at: fakeHeadingRange.location, effectiveRange: nil) as? NSFont

                let realIsBold = realFont?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
                let fakeIsBold = fakeFont?.fontDescriptor.symbolicTraits.contains(.bold) ?? false

                XCTAssertTrue(realIsBold, "Real heading should be bold")
                XCTAssertFalse(fakeIsBold, "Fake heading in code block should not be bold")
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
                    coordinator.applyHighlighting(to: textView, config: Self.defaultConfig)
                }
            }

            // MARK: - Font Family Tests

            func testAllFontFamiliesRenderWithoutCrash() {
                let source = "# Heading\n\nParagraph with `code`."

                for family in ReaderFontFamily.allCases {
                    var cfg = Self.defaultConfig
                    cfg.fontFamily = family
                    let (textView, _) = highlightedView(source: source, config: cfg)
                    XCTAssertEqual(textView.string, source, "Font family \(family) should render correctly")
                }
            }

            // MARK: - Color Scheme Tests

            func testLightAndDarkColorSchemes() {
                let source = "# Test Heading"

                for scheme in [ColorScheme.light, ColorScheme.dark] {
                    var cfg = Self.defaultConfig
                    cfg.colorScheme = scheme
                    let (textView, _) = highlightedView(source: source, config: cfg)
                    XCTAssertEqual(textView.string, source)
                }
            }

            // MARK: - Edge Cases

            func testDocumentWithOnlyWhitespace() {
                let source = "   \n\n\t\n   "
                let (textView, _) = highlightedView(source: source)
                XCTAssertEqual(textView.string, source)
            }

            func testDocumentWithSpecialCharacters() {
                let source = "# Emoji 🎉\n\nUnicode: ñ 中文\n\nMath: ∫ ∑"
                let (textView, _) = highlightedView(source: source)
                XCTAssertEqual(textView.string, source)
            }

            func testVeryLongLine() {
                let longLine = String(repeating: "word ", count: 500)
                let source = "# Heading\n\n\(longLine)"
                let (textView, _) = highlightedView(source: source)
                XCTAssertEqual(textView.string, source)
            }

            func testNestedFencedCodeBlocks() async {
                let source = """
                ````markdown
                ```swift
                code here
                ```
                ````
                """
                let (textView, coordinator) = highlightedView(source: source)
                try? await Task.sleep(nanoseconds: 100_000_000)
                _ = coordinator // Keep coordinator alive for async highlight Task
                XCTAssertTrue(textView.string.contains("code here"))
            }

            // MARK: - Rendering Audit Validation Tests
            //
            // These tests validate the fixes from the rendering audit:
            // Issues 1-7 covering incremental highlighting, parameter consistency,
            // background transparency, and kern/spacing.

            /// Issue 1: Incremental highlighting must preserve code block styling.
            /// When editing inside a fenced code block, the ``` markers are outside
            /// the incremental range. Code background and font must survive.
            func testIncrementalHighlightPreservesCodeBlockStyling() async throws {
                let source = """
                Some text above

                ```swift
                let original = 1
                ```

                Some text below
                """
                var text = source
                let binding = Binding(get: { text }, set: { text = $0 })

                let textView = makeTextView()
                let coordinator = RawMarkdownTextView.Coordinator(text: binding)
                coordinator.textView = textView

                // Full highlight first
                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(to: textView, config: Self.defaultConfig)
                try await Task.sleep(nanoseconds: 150_000_000)

                let storage = try XCTUnwrap(textView.textStorage)
                let nsString = storage.string as NSString

                // Verify initial code styling
                let codeRange = nsString.range(of: "let original = 1")
                XCTAssertNotEqual(codeRange.location, NSNotFound)
                let initialBg = storage.attribute(.backgroundColor, at: codeRange.location, effectiveRange: nil)
                XCTAssertNotNil(initialBg, "Code block should have background color after full highlight")

                // Simulate an incremental edit inside the code block:
                // Replace "1" with "42" — the edit range is inside the fenced block
                let oneRange = nsString.range(of: "1", range: codeRange)
                XCTAssertNotEqual(oneRange.location, NSNotFound)

                storage.replaceCharacters(in: oneRange, with: "42")
                text = storage.string

                // Trigger incremental re-highlight via textDidChange
                coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
                try await Task.sleep(nanoseconds: 150_000_000)

                // After incremental highlight, code styling must persist
                let updatedNsString = storage.string as NSString
                let updatedCodeRange = updatedNsString.range(of: "let original = 42")
                XCTAssertNotEqual(updatedCodeRange.location, NSNotFound, "Edited text should be present")

                guard updatedCodeRange.location != NSNotFound else {
                    XCTFail("Edited text 'let original = 42' must be present after incremental edit")
                    return
                }

                let bg = storage.attribute(.backgroundColor, at: updatedCodeRange.location, effectiveRange: nil)
                XCTAssertNotNil(bg, "Code block background must survive incremental highlighting")

                let updatedFont = storage.attribute(.font, at: updatedCodeRange.location, effectiveRange: nil) as? NSFont
                XCTAssertNotNil(updatedFont)
                XCTAssertTrue(
                    updatedFont?.fontDescriptor.symbolicTraits.contains(.monoSpace) ?? false,
                    "Code block font must remain monospaced after incremental highlight"
                )

                _ = coordinator
            }

            /// Issue 2: Incremental highlighting must preserve frontmatter styling.
            /// The \A anchor only matches at string start, so incremental edits
            /// that don't start at position 0 would lose frontmatter styling.
            func testIncrementalHighlightPreservesFrontmatterStyling() async throws {
                let source = """
                ---
                title: Test
                ---

                # Heading

                Body text here
                """
                var text = source
                let binding = Binding(get: { text }, set: { text = $0 })

                let textView = makeTextView()
                let coordinator = RawMarkdownTextView.Coordinator(text: binding)
                coordinator.textView = textView

                coordinator.applyTextIfNeeded(source, to: textView)
                coordinator.applyHighlighting(to: textView, config: Self.defaultConfig)
                try await Task.sleep(nanoseconds: 150_000_000)

                let storage = try XCTUnwrap(textView.textStorage)
                let nsString = storage.string as NSString

                // Capture frontmatter color
                let titleRange = nsString.range(of: "title: Test")
                XCTAssertNotEqual(titleRange.location, NSNotFound)
                let initialColor = storage.attribute(.foregroundColor, at: titleRange.location, effectiveRange: nil) as? NSColor
                XCTAssertNotNil(initialColor, "Frontmatter should have foreground color")

                // Edit body text (far from frontmatter) to trigger incremental highlight
                let bodyRange = nsString.range(of: "Body text here")
                XCTAssertNotEqual(bodyRange.location, NSNotFound)
                storage.replaceCharacters(in: bodyRange, with: "Body text edited")
                text = storage.string

                coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
                try await Task.sleep(nanoseconds: 150_000_000)

                // Frontmatter color must still be applied
                let updatedNsString = storage.string as NSString
                let updatedTitleRange = updatedNsString.range(of: "title: Test")
                XCTAssertNotEqual(updatedTitleRange.location, NSNotFound)

                guard updatedTitleRange.location != NSNotFound else {
                    XCTFail("Frontmatter 'title: Test' must be present after incremental edit")
                    return
                }

                let colorAfter = storage.attribute(.foregroundColor, at: updatedTitleRange.location, effectiveRange: nil) as? NSColor
                XCTAssertNotNil(colorAfter, "Frontmatter color must survive incremental highlighting")
                XCTAssertEqual(
                    initialColor, colorAfter,
                    "Frontmatter color should not change after incremental edit elsewhere"
                )

                _ = coordinator
            }

            /// Issue 3: Config consistency — changing theme via config must affect highlighting.
            func testHighlightConfigChangeUpdatesAllAttributes() async throws {
                let source = "# Heading\n\n```swift\nlet x = 1\n```"
                let textView = makeTextView()
                let coordinator = RawMarkdownTextView.Coordinator(text: .constant(source))
                coordinator.textView = textView
                coordinator.applyTextIfNeeded(source, to: textView)

                // Apply with one theme
                var config1 = Self.defaultConfig
                config1.appTheme = .basic
                config1.colorScheme = .light
                coordinator.applyHighlighting(to: textView, config: config1)
                try await Task.sleep(nanoseconds: 150_000_000)

                let storage = try XCTUnwrap(textView.textStorage)
                let nsString = storage.string as NSString
                let headingRange = nsString.range(of: "# Heading")
                let color1 = storage.attribute(.foregroundColor, at: headingRange.location, effectiveRange: nil) as? NSColor

                // Change syntax palette — color must update
                var config2 = config1
                config2.syntaxPalette = .wwdc18
                coordinator.applyHighlighting(to: textView, config: config2)
                try await Task.sleep(nanoseconds: 150_000_000)

                let color2 = storage.attribute(.foregroundColor, at: headingRange.location, effectiveRange: nil) as? NSColor
                XCTAssertNotNil(color1)
                XCTAssertNotNil(color2)
                XCTAssertNotEqual(color1, color2, "Heading color must change when syntax palette changes")

                // Verify config is stored consistently
                XCTAssertEqual(coordinator.config.syntaxPalette, .wwdc18)
                XCTAssertEqual(coordinator.config.appTheme, .basic)

                _ = coordinator
            }

            /// Issue 5 & 6: Raw view background must be transparent (drawsBackground = false).
            /// This ensures LiquidBackground shows through, matching the rendered view.
            /// Tested via SwiftUI hosting to exercise the actual NSViewRepresentable path.
            func testRawViewBackgroundIsTransparent() {
                let hostView = NSHostingView(
                    rootView: RawMarkdownTextView(
                        text: .constant("# Test"),
                        fontFamily: .newYork,
                        fontSize: 16,
                        syntaxPalette: .midnight,
                        colorScheme: .light,
                        showLineNumbers: false,
                        appTheme: .basic,
                        textSpacing: .balanced
                    )
                )
                hostView.frame = NSRect(x: 0, y: 0, width: 600, height: 400)
                hostView.layout()

                // Walk the view hierarchy to find the scroll view and text view
                let scrollView = findView(ofType: NSScrollView.self, in: hostView)
                XCTAssertNotNil(scrollView, "Should find NSScrollView in hosted view hierarchy")

                if let scrollView {
                    XCTAssertFalse(scrollView.drawsBackground, "Scroll view must have drawsBackground = false")

                    let textView = scrollView.documentView as? NSTextView
                    XCTAssertNotNil(textView, "Should find NSTextView as document view")
                    if let textView {
                        XCTAssertFalse(textView.drawsBackground, "Text view must have drawsBackground = false")
                    }
                }
            }

            /// Issue 7: Raw view must apply kern (letter spacing) from textSpacing.
            func testKernIsAppliedToBaseAttributes() async throws {
                let source = "Some body text for kern testing"

                for spacing in [ReaderTextSpacing.compact, .balanced, .relaxed] {
                    var cfg = Self.defaultConfig
                    cfg.textSpacing = spacing
                    let (textView, coordinator) = highlightedView(source: source, config: cfg)
                    try await Task.sleep(nanoseconds: 150_000_000)

                    let storage = try XCTUnwrap(textView.textStorage)
                    let kernValue = storage.attribute(.kern, at: 5, effectiveRange: nil) as? CGFloat
                    let expectedKern = spacing.kern(for: cfg.fontSize)

                    XCTAssertNotNil(kernValue, "Kern attribute must be present for spacing \(spacing)")
                    XCTAssertEqual(
                        kernValue, expectedKern,
                        "Kern value must match textSpacing.kern for \(spacing)"
                    )

                    _ = coordinator
                }
            }

            /// Issue 7: Verify kern changes when textSpacing changes.
            func testKernUpdatesWithTextSpacingChange() async throws {
                let source = "Kern update test"
                let textView = makeTextView()
                let coordinator = RawMarkdownTextView.Coordinator(text: .constant(source))
                coordinator.textView = textView
                coordinator.applyTextIfNeeded(source, to: textView)

                var compactConfig = Self.defaultConfig
                compactConfig.textSpacing = .compact
                coordinator.applyHighlighting(to: textView, config: compactConfig)
                try await Task.sleep(nanoseconds: 150_000_000)

                let storage = try XCTUnwrap(textView.textStorage)
                let compactKern = storage.attribute(.kern, at: 0, effectiveRange: nil) as? CGFloat

                var relaxedConfig = Self.defaultConfig
                relaxedConfig.textSpacing = .relaxed
                coordinator.applyHighlighting(to: textView, config: relaxedConfig)
                try await Task.sleep(nanoseconds: 150_000_000)

                let relaxedKern = storage.attribute(.kern, at: 0, effectiveRange: nil) as? CGFloat

                XCTAssertNotNil(compactKern)
                XCTAssertNotNil(relaxedKern)
                XCTAssertNotEqual(compactKern, relaxedKern, "Kern must differ between compact and relaxed spacing")
                XCTAssertEqual(compactKern, ReaderTextSpacing.compact.kern(for: Self.defaultConfig.fontSize))
                XCTAssertEqual(relaxedKern, ReaderTextSpacing.relaxed.kern(for: Self.defaultConfig.fontSize))

                _ = coordinator
            }

            /// Paragraph style (line spacing) must reflect textSpacing configuration.
            func testParagraphStyleReflectsTextSpacing() async throws {
                let source = "Line 1\nLine 2\nLine 3"

                for spacing in [ReaderTextSpacing.compact, .balanced, .relaxed] {
                    var cfg = Self.defaultConfig
                    cfg.textSpacing = spacing
                    let (textView, coordinator) = highlightedView(source: source, config: cfg)
                    try await Task.sleep(nanoseconds: 150_000_000)

                    let storage = try XCTUnwrap(textView.textStorage)
                    let paraStyle = storage.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
                    XCTAssertNotNil(paraStyle, "Paragraph style must be present for \(spacing)")

                    let expected = spacing.paragraphStyle(fontSize: cfg.fontSize)
                    XCTAssertEqual(
                        paraStyle?.lineSpacing, expected.lineSpacing,
                        "Line spacing must match textSpacing for \(spacing)"
                    )

                    _ = coordinator
                }
            }

            /// Theme palette must affect text colors. Uses a theme with concrete P3 colors
            /// (not dynamic system colors) so light/dark differences are testable headlessly.
            func testThemePaletteAffectsColors() async throws {
                let source = "> Blockquote text\n\n# Heading"
                let textView = makeTextView()
                let coordinator = RawMarkdownTextView.Coordinator(text: .constant(source))
                coordinator.textView = textView
                coordinator.applyTextIfNeeded(source, to: textView)

                // Use .solarized which has concrete P3 colors for both light/dark
                var lightConfig = Self.defaultConfig
                lightConfig.appTheme = .solarized
                lightConfig.colorScheme = .light
                coordinator.applyHighlighting(to: textView, config: lightConfig)
                try await Task.sleep(nanoseconds: 150_000_000)

                let storage = try XCTUnwrap(textView.textStorage)
                let nsString = storage.string as NSString
                let quoteRange = nsString.range(of: "> Blockquote text")
                let lightQuoteColor = storage.attribute(.foregroundColor, at: quoteRange.location, effectiveRange: nil) as? NSColor

                // Switch to dark scheme — concrete P3 colors differ
                var darkConfig = lightConfig
                darkConfig.colorScheme = .dark
                coordinator.applyHighlighting(to: textView, config: darkConfig)
                try await Task.sleep(nanoseconds: 150_000_000)

                let darkQuoteColor = storage.attribute(.foregroundColor, at: quoteRange.location, effectiveRange: nil) as? NSColor

                XCTAssertNotNil(lightQuoteColor)
                XCTAssertNotNil(darkQuoteColor)
                XCTAssertNotEqual(
                    lightQuoteColor, darkQuoteColor,
                    "Blockquote color should differ between light and dark schemes (solarized)"
                )

                _ = coordinator
            }

            // MARK: - Helpers

            private func highlightedView(
                source: String,
                config: RawMarkdownTextView.HighlightConfiguration = defaultConfig
            ) -> (NSTextView, RawMarkdownTextView.Coordinator) {
                let textView = makeTextView()
                let coordinator = RawMarkdownTextView.Coordinator(text: .constant(source))
                coordinator.textView = textView
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

            private func makeCoordinator() -> RawMarkdownTextView.Coordinator {
                RawMarkdownTextView.Coordinator(text: .constant(""))
            }

            /// Recursively finds the first subview of the given type in a view hierarchy.
            private func findView<T: NSView>(ofType type: T.Type, in view: NSView) -> T? {
                if let match = view as? T { return match }
                for subview in view.subviews {
                    if let found = findView(ofType: type, in: subview) { return found }
                }
                return nil
            }
        }
    #endif
#endif
