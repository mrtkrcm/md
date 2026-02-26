//
//  SyntaxHighlighterTests.swift
//  mdviewer
//

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
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false
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
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false
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
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false
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
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false
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
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false
                )

                var outputs = [String]()
                await withTaskGroup(of: String.self) { group in
                    for _ in 0 ..< 8 {
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

            // MARK: - Multi-language Syntax Highlighting Tests

            func testJavaScriptSyntaxHighlighting() async {
                let markdown = """
                ```javascript
                const value = "hello";
                // This is a comment
                function foo() { return 42; }
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
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false
                    )
                ).attributedString

                let expected = SyntaxPalette.midnight.nativeSyntax

                let stringRange = (rendered.string as NSString).range(of: "hello")
                let commentRange = (rendered.string as NSString).range(of: "This is a comment")
                let keywordRange = (rendered.string as NSString).range(of: "const")
                let numberRange = (rendered.string as NSString).range(of: "42")

                XCTAssertNotEqual(stringRange.location, NSNotFound)
                XCTAssertNotEqual(commentRange.location, NSNotFound)
                XCTAssertNotEqual(keywordRange.location, NSNotFound)
                XCTAssertNotEqual(numberRange.location, NSNotFound)

                let stringColor = color(at: stringRange.location, in: rendered)
                let commentColor = color(at: commentRange.location, in: rendered)
                let keywordColor = color(at: keywordRange.location, in: rendered)
                let numberColor = color(at: numberRange.location, in: rendered)

                XCTAssertTrue(approxEqual(stringColor, expected.string))
                XCTAssertTrue(approxEqual(commentColor, expected.comment))
                XCTAssertTrue(approxEqual(keywordColor, expected.keyword))
                XCTAssertTrue(approxEqual(numberColor, expected.number))
            }

            func testPythonSyntaxHighlighting() async {
                let markdown = """
                ```python
                value = "hello"
                # This is a comment
                def foo():
                    return 42
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
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false
                    )
                ).attributedString

                let expected = SyntaxPalette.midnight.nativeSyntax

                let stringRange = (rendered.string as NSString).range(of: "hello")
                let commentRange = (rendered.string as NSString).range(of: "This is a comment")
                let keywordRange = (rendered.string as NSString).range(of: "def")
                let numberRange = (rendered.string as NSString).range(of: "42")

                XCTAssertNotEqual(stringRange.location, NSNotFound)
                XCTAssertNotEqual(commentRange.location, NSNotFound)
                XCTAssertNotEqual(keywordRange.location, NSNotFound)
                XCTAssertNotEqual(numberRange.location, NSNotFound)

                let stringColor = color(at: stringRange.location, in: rendered)
                let commentColor = color(at: commentRange.location, in: rendered)
                let keywordColor = color(at: keywordRange.location, in: rendered)
                let numberColor = color(at: numberRange.location, in: rendered)

                XCTAssertTrue(approxEqual(stringColor, expected.string))
                XCTAssertTrue(approxEqual(commentColor, expected.comment))
                XCTAssertTrue(approxEqual(keywordColor, expected.keyword))
                XCTAssertTrue(approxEqual(numberColor, expected.number))
            }

            func testJSONSyntaxHighlighting() async {
                let markdown = """
                ```json
                {
                    "name": "test",
                    "count": 42,
                    "active": true
                }
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
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false
                    )
                ).attributedString

                let expected = SyntaxPalette.midnight.nativeSyntax

                let stringRange = (rendered.string as NSString).range(of: "test")
                let keywordRange = (rendered.string as NSString).range(of: "true")
                let numberRange = (rendered.string as NSString).range(of: "42")

                XCTAssertNotEqual(stringRange.location, NSNotFound)
                XCTAssertNotEqual(keywordRange.location, NSNotFound)
                XCTAssertNotEqual(numberRange.location, NSNotFound)

                let stringColor = color(at: stringRange.location, in: rendered)
                let keywordColor = color(at: keywordRange.location, in: rendered)
                let numberColor = color(at: numberRange.location, in: rendered)

                XCTAssertTrue(approxEqual(stringColor, expected.string))
                XCTAssertTrue(approxEqual(keywordColor, expected.keyword))
                XCTAssertTrue(approxEqual(numberColor, expected.number))
            }

            func testAutoDetectsSwiftCode() async {
                // No language specified, should auto-detect Swift
                let markdown = """
                ```
                let value = "hello"
                func test() -> Int { return 42 }
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
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false
                    )
                ).attributedString

                let expected = SyntaxPalette.midnight.nativeSyntax

                let stringRange = (rendered.string as NSString).range(of: "hello")
                let keywordRange = (rendered.string as NSString).range(of: "let")
                let typeRange = (rendered.string as NSString).range(of: "Int")

                XCTAssertNotEqual(stringRange.location, NSNotFound)
                XCTAssertNotEqual(keywordRange.location, NSNotFound)
                XCTAssertNotEqual(typeRange.location, NSNotFound)

                let stringColor = color(at: stringRange.location, in: rendered)
                let keywordColor = color(at: keywordRange.location, in: rendered)
                let typeColor = color(at: typeRange.location, in: rendered)

                XCTAssertTrue(approxEqual(stringColor, expected.string))
                XCTAssertTrue(approxEqual(keywordColor, expected.keyword))
                XCTAssertTrue(approxEqual(typeColor, expected.type))
            }

            func testAutoDetectsJSON() async {
                // No language specified, should auto-detect JSON
                let markdown = """
                ```
                {"name": "test", "value": 42}
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
                        readableWidth: ReaderColumnWidth.balanced.points,
                        showLineNumbers: false
                    )
                ).attributedString

                let expected = SyntaxPalette.midnight.nativeSyntax

                let stringRange = (rendered.string as NSString).range(of: "test")
                let numberRange = (rendered.string as NSString).range(of: "42")

                XCTAssertNotEqual(stringRange.location, NSNotFound)
                XCTAssertNotEqual(numberRange.location, NSNotFound)

                let stringColor = color(at: stringRange.location, in: rendered)
                let numberColor = color(at: numberRange.location, in: rendered)

                XCTAssertTrue(approxEqual(stringColor, expected.string))
                XCTAssertTrue(approxEqual(numberColor, expected.number))
            }

            func testLanguageRegistryLookup() {
                // Test exact matches
                XCTAssertNotNil(LanguageRegistry.definition(for: "swift"))
                XCTAssertNotNil(LanguageRegistry.definition(for: "javascript"))
                XCTAssertNotNil(LanguageRegistry.definition(for: "python"))

                // Test aliases
                XCTAssertNotNil(LanguageRegistry.definition(for: "js"))
                XCTAssertNotNil(LanguageRegistry.definition(for: "py"))
                XCTAssertNotNil(LanguageRegistry.definition(for: "ts"))
                XCTAssertNotNil(LanguageRegistry.definition(for: "rs"))
                XCTAssertNotNil(LanguageRegistry.definition(for: "yml"))

                // Test case insensitive
                XCTAssertNotNil(LanguageRegistry.definition(for: "SWIFT"))
                XCTAssertNotNil(LanguageRegistry.definition(for: "JavaScript"))
                XCTAssertNotNil(LanguageRegistry.definition(for: "Python"))

                // Test invalid language
                XCTAssertNil(LanguageRegistry.definition(for: "nonexistent"))
                XCTAssertNil(LanguageRegistry.definition(for: ""))
                XCTAssertNil(LanguageRegistry.definition(for: nil))
            }

            func testLanguageDetectionFromShebang() {
                let pythonCode = "#!/usr/bin/env python3\nprint('hello')"
                let rubyCode = "#!/usr/bin/env ruby\nputs 'hello'"
                let bashCode = "#!/bin/bash\necho hello"
                let swiftCode = "#!/usr/bin/swift\nprint(\"hello\")"

                XCTAssertEqual(LanguageRegistry.detectLanguage(in: pythonCode)?.id, "python")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: rubyCode)?.id, "ruby")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: bashCode)?.id, "bash")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: swiftCode)?.id, "swift")
            }

            func testLanguageDetectionFromContent() {
                let swiftCode = "let x: Int = 42\nfunc test() throws -> Int { return 42 }"
                let pythonCode = "def test():\n    return 42"
                let jsCode = "const x = 42;\nfunction test() {}"
                let rustCode = "let mut x = 42;\nfn test() -> i32 { 42 }"
                let goCode = "package main\nimport \"fmt\"\nfunc main() { fmt.Println() }"

                XCTAssertEqual(LanguageRegistry.detectLanguage(in: swiftCode)?.id, "swift")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: pythonCode)?.id, "python")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: jsCode)?.id, "javascript")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: rustCode)?.id, "rust")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: goCode)?.id, "go")
            }

            func testLanguageDetectionJSON() {
                let jsonCode = "{\"name\": \"test\", \"value\": 42}"
                let jsonArray = "[1, 2, 3]"

                XCTAssertEqual(LanguageRegistry.detectLanguage(in: jsonCode)?.id, "json")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: jsonArray)?.id, "json")
            }

            func testLanguageDetectionHTML() {
                let htmlCode = "<!DOCTYPE html>\n<html>\n<body>\n</body>\n</html>"
                let htmlFragment = "<div>Hello</div>"

                XCTAssertEqual(LanguageRegistry.detectLanguage(in: htmlCode)?.id, "html")
                XCTAssertEqual(LanguageRegistry.detectLanguage(in: htmlFragment)?.id, "html")
            }

            func testLanguageDetectionYAML() {
                let yamlCode = """
                name: test
                version: 1.0
                items:
                  - one
                  - two
                """

                XCTAssertEqual(LanguageRegistry.detectLanguage(in: yamlCode)?.id, "yaml")
            }
        }
    #endif
#endif
