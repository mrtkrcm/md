//
//  FrontmatterParserTests.swift
//  mdviewer
//

#if canImport(XCTest)
    @testable internal import mdviewer
    internal import XCTest

    final class FrontmatterParserTests: XCTestCase {
        func testParsesValidFrontmatterAndExtractsBody() {
            let markdown = """
            ---
            title: Hello
            author: "Murat"
            tags: swift
            ---
            # Heading

            Body
            """

            let parsed = FrontmatterParser.parse(markdown)

            XCTAssertEqual(parsed.renderedMarkdown, "# Heading\n\nBody")
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "Hello")
            XCTAssertEqual(parsed.frontmatter?.metadata["author"], "Murat")
            XCTAssertEqual(parsed.frontmatter?.metadata["tags"], "swift")
            XCTAssertEqual(parsed.frontmatter?.entries.map(\.key), ["title", "author", "tags"])
        }

        func testParsesDotDelimiterVariant() {
            let markdown = """
            ---
            title: Dot Delimiter
            ...
            Paragraph
            """

            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.renderedMarkdown, "Paragraph")
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "Dot Delimiter")
        }

        func testLeavesMarkdownUnchangedWithoutClosingFence() {
            let markdown = """
            ---
            title: Not actually frontmatter
            # Heading
            """

            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.renderedMarkdown, markdown)
            XCTAssertNil(parsed.frontmatter)
        }

        func testLeavesMarkdownUnchangedWhenNoFrontmatter() {
            let markdown = "# Plain Markdown\n\nText"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.renderedMarkdown, markdown)
            XCTAssertNil(parsed.frontmatter)
        }

        func testParsesYamlListAsCommaSeparatedValue() {
            let markdown = """
            ---
            title: Demo
            tags:
              - swift
              - markdown
              - viewer
            ---
            # Hello
            """

            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["tags"], "swift, markdown, viewer")
        }

        func testParsesFrontmatterWhenFileStartsWithUTF8BOM() {
            let markdown = "\u{FEFF}---\ntitle: BOM case\n---\n# Heading"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "BOM case")
            XCTAssertEqual(parsed.renderedMarkdown, "# Heading")
        }

        func testParsesFrontmatterAfterLeadingBlankLines() {
            let markdown = "\n\n---\ntitle: Leading blank lines\n---\nBody"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "Leading blank lines")
            XCTAssertEqual(parsed.renderedMarkdown, "Body")
        }

        func testParsesWrappedYamlValueLines() {
            let markdown = """
            ---
            description: Conducts web research for external information, documentation, and best
              practices
            ---
            Body
            """

            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(
                parsed.frontmatter?.metadata["description"],
                "Conducts web research for external information, documentation, and best practices"
            )
        }

        func testStripsHtmlCommentLinesFromRenderedMarkdown() {
            let markdown = """
            ---
            title: Demo
            ---
            <!-- Tags: research, web, documentation -->

            # Heading
            """

            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertFalse(parsed.renderedMarkdown.contains("<!-- Tags:"))
            XCTAssertTrue(parsed.renderedMarkdown.contains("# Heading"))
        }

        func testKeepsFrontmatterForNestedYamlStructures() {
            let markdown = """
            ---
            author:
              name: Murat
              social:
                github: mrtkrcm
            ---
            Body
            """

            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertNotNil(parsed.frontmatter)
            XCTAssertEqual(parsed.renderedMarkdown, "Body")
        }
    }
#endif
