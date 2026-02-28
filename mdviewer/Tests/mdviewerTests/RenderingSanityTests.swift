//
//  RenderingSanityTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer

        final class RenderingSanityTests: XCTestCase {
            private func makeRequest(markdown: String) -> RenderRequest {
                RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 12,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 760,
                    showLineNumbers: false
                )
            }

            /// Sanity smoke test that catches block-collapsing regressions quickly.
            func testRenderedOutputKeepsBlockBoundaries() async {
                let markdown = """
                # Title

                First paragraph.

                Second paragraph.
                """

                let rendered = await MarkdownRenderService.shared.render(makeRequest(markdown: markdown))
                let text = rendered.attributedString.string as NSString

                XCTAssertNotEqual(text.range(of: "Title").location, NSNotFound)
                XCTAssertNotEqual(text.range(of: "First paragraph.").location, NSNotFound)
                XCTAssertNotEqual(text.range(of: "Second paragraph.").location, NSNotFound)
                XCTAssertNotEqual(text.range(of: "\n").location, NSNotFound, "Expected visible line breaks between blocks")
            }

            /// Sanity check for major style channels used by the renderer.
            func testRenderedOutputAppliesCoreStyles() async {
                let markdown = """
                # Heading

                Body with `inline code`.

                ```swift
                let x = 1
                ```
                """

                let rendered = await MarkdownRenderService.shared.render(makeRequest(markdown: markdown))
                let text = rendered.attributedString
                let ns = text.string as NSString

                let headingRange = ns.range(of: "Heading")
                let inlineRange = ns.range(of: "inline code")
                let fencedBodyRange = ns.range(of: "let x = 1")

                XCTAssertNotEqual(headingRange.location, NSNotFound)
                XCTAssertNotEqual(inlineRange.location, NSNotFound)
                XCTAssertNotEqual(fencedBodyRange.location, NSNotFound)

                XCTAssertNotNil(text.attribute(.paragraphStyle, at: headingRange.location, effectiveRange: nil))
                XCTAssertNotNil(text.attribute(.backgroundColor, at: inlineRange.location, effectiveRange: nil))
                XCTAssertNotNil(text.attribute(.font, at: fencedBodyRange.location, effectiveRange: nil))
            }

            /// Fenced code should preserve internal lines and not be flattened.
            func testFencedCodePreservesLineStructure() async {
                let markdown = """
                ```swift
                let a = 1
                let b = 2
                print(a + b)
                ```
                """

                let rendered = await MarkdownRenderService.shared.render(makeRequest(markdown: markdown))
                let output = rendered.attributedString.string

                XCTAssertTrue(output.contains("let a = 1"))
                XCTAssertTrue(output.contains("let b = 2"))
                XCTAssertTrue(output.contains("print(a + b)"))
                XCTAssertGreaterThanOrEqual(
                    output.filter { $0 == "\n" }.count,
                    2,
                    "Expected multiple line breaks to remain inside fenced code"
                )
            }
        }
    #endif
#endif
