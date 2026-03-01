//
//  FrontmatterParserEdgeCaseTests.swift
//  mdviewer
//

#if canImport(XCTest)
    @testable internal import mdviewer
    internal import XCTest

    final class FrontmatterParserEdgeCaseTests: XCTestCase {
        // MARK: - Value parsing edge cases

        func testParsesColonInValue() {
            let markdown = "---\nurl: https://example.com/path?q=1\n---\nBody"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["url"], "https://example.com/path?q=1")
        }

        func testParsesSingleQuotedValues() {
            let markdown = "---\ntitle: 'My Title'\n---\nBody"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "My Title")
        }

        func testParsesDoubleQuotedValues() {
            let markdown = "---\ntitle: \"Quoted\"\n---\nBody"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "Quoted")
        }

        func testParsesEmptyFrontmatterBlock() {
            // The regex requires at least one line between delimiters;
            // a blank line between --- satisfies this requirement.
            let markdown = "---\n\n---\nBody"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertNotNil(parsed.frontmatter, "Frontmatter should be non-nil even when empty")
            XCTAssertTrue(
                parsed.frontmatter?.entries.isEmpty ?? false,
                "Empty frontmatter block should produce no entries"
            )
            XCTAssertEqual(parsed.renderedMarkdown, "Body")
        }

        func testParsesYamlCommentLines() {
            let markdown = """
            ---
            # this is a comment
            title: Real Value
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "Real Value")
            XCTAssertEqual(
                parsed.frontmatter?.entries.count,
                1,
                "Comment lines should not produce entries; count should be 1"
            )
        }

        func testCrlfLineEndingsInFrontmatter() {
            let markdown = "---\r\ntitle: CRLF Test\r\nauthor: Murat\r\n---\r\nBody"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "CRLF Test")
            XCTAssertEqual(parsed.frontmatter?.metadata["author"], "Murat")
            XCTAssertEqual(parsed.renderedMarkdown, "Body")
        }

        func testOnlyFirstFrontmatterBlockIsParsed() {
            let markdown = """
            ---
            title: First Block
            ---
            Body text here.

            ---
            title: Second Block
            ---
            More body.
            """
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "First Block")
            // The second "---" block is in the body, not parsed as frontmatter
            XCTAssertTrue(
                parsed.renderedMarkdown.contains("Second Block") || parsed.renderedMarkdown.contains("More body"),
                "Content after first frontmatter block should appear in rendered markdown"
            )
        }

        func testFrontmatterImmediatelyFollowedByCodeFence() {
            let markdown = """
            ---
            title: Code Test
            ---
            ```swift
            let x = 42
            ```
            """
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertNotNil(parsed.frontmatter)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "Code Test")
            XCTAssertTrue(
                parsed.renderedMarkdown.contains("let x = 42"),
                "Code block content should appear in rendered markdown"
            )
        }

        func testDuplicateKeysLastValueWins() {
            let markdown = """
            ---
            title: First Title
            title: Second Title
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(
                parsed.frontmatter?.metadata["title"],
                "Second Title",
                "Duplicate key: last value should win"
            )
            // Still only one entry for that key
            let titleEntries = parsed.frontmatter?.entries.filter { $0.key == "title" } ?? []
            XCTAssertEqual(
                titleEntries.count,
                1,
                "Duplicate keys should produce only one entry"
            )
        }

        func testEmptyValueIsPreservedAsEntry() {
            let markdown = """
            ---
            subtitle:
            title: Present
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            // The "subtitle:" key with no value (and no list items following) should exist as an entry
            let hasSubtitle = parsed.frontmatter?.entries.contains { $0.key == "subtitle" } ?? false
            XCTAssertTrue(hasSubtitle, "Key with empty value should still produce an entry")
        }

        // MARK: - sanitizeRenderedMarkdown

        func testMultiLineHtmlCommentIsStripped() {
            let markdown = """
            ---
            title: Multi Comment
            ---
            <!--
            This comment spans
            multiple lines
            -->
            # Heading After Comment
            """
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertFalse(
                parsed.renderedMarkdown.contains("multiple lines"),
                "Multi-line HTML comment content should be stripped"
            )
            XCTAssertTrue(
                parsed.renderedMarkdown.contains("# Heading After Comment"),
                "Content after multi-line HTML comment should be preserved"
            )
        }

        func testHtmlCommentInsideCodeFenceIsNotStripped() {
            let markdown = """
            ---
            title: Code Fence Test
            ---
            ```
            <!-- this comment is inside a code fence -->
            let x = 1
            ```
            """
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertTrue(
                parsed.renderedMarkdown.contains("<!-- this comment is inside a code fence -->"),
                "HTML comment inside a backtick code fence should NOT be stripped"
            )
        }

        func testTildeFencePreservesHtmlComment() {
            let markdown = """
            ---
            title: Tilde Fence Test
            ---
            ~~~
            <!-- comment inside tilde fence -->
            code here
            ~~~
            """
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertTrue(
                parsed.renderedMarkdown.contains("<!-- comment inside tilde fence -->"),
                "HTML comment inside a tilde fence should NOT be stripped"
            )
        }

        func testInlineHtmlCommentOnSameLineIsStripped() {
            let markdown = """
            ---
            title: Inline Comment Test
            ---
            <!-- single line comment -->
            # Heading After
            """
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertFalse(
                parsed.renderedMarkdown.contains("single line comment"),
                "Inline HTML comment on its own line should be stripped"
            )
            XCTAssertTrue(
                parsed.renderedMarkdown.contains("# Heading After"),
                "Heading after inline comment should be preserved"
            )
        }

        // MARK: - Body edge cases

        func testFrontmatterWithNoBodyProducesEmptyRenderedMarkdown() {
            let markdown = "---\ntitle: No Body\n---\n"
            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertNotNil(parsed.frontmatter)
            XCTAssertEqual(parsed.frontmatter?.metadata["title"], "No Body")
            let trimmed = parsed.renderedMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertTrue(
                trimmed.isEmpty,
                "Frontmatter with no body should produce empty/whitespace-only renderedMarkdown"
            )
        }

        func testManyEntriesPreserveInsertionOrder() {
            let markdown = """
            ---
            alpha: 1
            bravo: 2
            charlie: 3
            delta: 4
            echo: 5
            foxtrot: 6
            golf: 7
            hotel: 8
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let keys = parsed.frontmatter?.entries.map(\.key) ?? []
            XCTAssertEqual(
                keys,
                ["alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel"],
                "Entries should preserve YAML insertion order"
            )
        }
    }
#endif
