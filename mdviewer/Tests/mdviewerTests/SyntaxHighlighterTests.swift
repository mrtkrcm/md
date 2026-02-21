#if canImport(XCTest)
internal import XCTest
#if os(macOS)
internal import AppKit
@testable internal import mdviewer

final class SyntaxHighlighterTests: XCTestCase {
    func testRenderRequestCacheKeyIsDeterministic() {
        let lhs = RenderRequest(
            markdown: "```swift\nlet x = 1\n```",
            readerFontFamily: .newYork,
            readerFontSize: 16,
            codeFontSize: 14,
            appTheme: .basic,
            syntaxPalette: .midnight,
            colorScheme: .light,
            textSpacing: .balanced,
            readableWidth: ReaderColumnWidth.balanced.points
        )
        let rhs = RenderRequest(
            markdown: "```swift\nlet x = 1\n```",
            readerFontFamily: .newYork,
            readerFontSize: 16,
            codeFontSize: 14,
            appTheme: .basic,
            syntaxPalette: .midnight,
            colorScheme: .light,
            textSpacing: .balanced,
            readableWidth: ReaderColumnWidth.balanced.points
        )
        let changed = RenderRequest(
            markdown: "```swift\nlet x = 2\n```",
            readerFontFamily: .newYork,
            readerFontSize: 16,
            codeFontSize: 14,
            appTheme: .basic,
            syntaxPalette: .midnight,
            colorScheme: .light,
            textSpacing: .balanced,
            readableWidth: ReaderColumnWidth.balanced.points
        )

        XCTAssertEqual(lhs.cacheKey, rhs.cacheKey)
        XCTAssertNotEqual(lhs.cacheKey, changed.cacheKey)
    }

    func testSyntaxHighlightRespectsCommentAndStringPriority() async {
        let markdown = """
        ```swift
        let value = \"if let\"
        // return should stay a comment color
        if let x = foo() { print(x) }
        ```
        """

        let rendered = await MarkdownRenderService.shared.render(
            RenderRequest(
                markdown: markdown,
                readerFontFamily: .newYork,
                readerFontSize: 16,
                codeFontSize: 14,
                appTheme: .basic,
                syntaxPalette: .midnight,
                colorScheme: .light,
                textSpacing: .balanced,
                readableWidth: ReaderColumnWidth.balanced.points
            )
        ).attributedString

        let expected = SyntaxPalette.midnight.nativeSyntax

        let stringRange = (rendered.string as NSString).range(of: "if let")
        let commentRange = (rendered.string as NSString).range(of: "return")
        let keywordRange = (rendered.string as NSString).range(of: "if let x")

        XCTAssertNotEqual(stringRange.location, NSNotFound)
        XCTAssertNotEqual(commentRange.location, NSNotFound)
        XCTAssertNotEqual(keywordRange.location, NSNotFound)

        let stringColor = color(at: stringRange.location, in: rendered)
        let commentColor = color(at: commentRange.location, in: rendered)
        let keywordColor = color(at: keywordRange.location, in: rendered)

        XCTAssertTrue(approxEqual(stringColor, expected.string))
        XCTAssertTrue(approxEqual(commentColor, expected.comment))
        XCTAssertTrue(approxEqual(keywordColor, expected.keyword))
    }

    func testConcurrentRenderRequestsReturnConsistentOutput() async {
        await MarkdownRenderService.shared.resetForTesting()
        let request = RenderRequest(
            markdown: "```swift\nstruct User { let id: Int }\n```",
            readerFontFamily: .newYork,
            readerFontSize: 16,
            codeFontSize: 14,
            appTheme: .github,
            syntaxPalette: .midnight,
            colorScheme: .dark,
            textSpacing: .balanced,
            readableWidth: ReaderColumnWidth.balanced.points
        )

        var outputs = [String]()
        await withTaskGroup(of: String.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    let rendered = await MarkdownRenderService.shared.render(request)
                    return rendered.attributedString.string
                }
            }

            for await value in group {
                outputs.append(value)
            }
        }

        XCTAssertEqual(Set(outputs).count, 1)
        let stats = await MarkdownRenderService.shared.snapshotStats()
        XCTAssertGreaterThanOrEqual(stats.cacheHits, 1)
    }

    private func color(at location: Int, in text: NSAttributedString) -> NSColor {
        let attributes = text.attributes(at: location, effectiveRange: nil)
        return (attributes[.foregroundColor] as? NSColor) ?? .clear
    }

    private func approxEqual(_ lhs: NSColor, _ rhs: NSColor, tolerance: CGFloat = 0.02) -> Bool {
        guard
            let a = lhs.usingColorSpace(.deviceRGB),
            let b = rhs.usingColorSpace(.deviceRGB)
        else {
            return lhs == rhs
        }

        return abs(a.redComponent - b.redComponent) <= tolerance
            && abs(a.greenComponent - b.greenComponent) <= tolerance
            && abs(a.blueComponent - b.blueComponent) <= tolerance
            && abs(a.alphaComponent - b.alphaComponent) <= tolerance
    }
}
#endif
#endif
