//
//  FrontmatterPresentationTests.swift
//  mdviewer
//

#if canImport(XCTest)
    @testable internal import mdviewer
    internal import XCTest

    final class FrontmatterPresentationTests: XCTestCase {
        func testFrontmatterKeepsOrderedEntriesForDynamicRendering() {
            let markdown = """
            ---
            zebra: last
            author: Murat
            title: Guide
            ---
            Body
            """

            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.entries.map(\.key), ["zebra", "author", "title"])
        }

        func testFrontmatterMetadataRemainsAccessibleByKey() {
            let markdown = """
            ---
            published_at: 2026-02-19
            category: docs
            ---
            Body
            """

            let parsed = FrontmatterParser.parse(markdown)
            XCTAssertEqual(parsed.frontmatter?.metadata["published_at"], "2026-02-19")
            XCTAssertEqual(parsed.frontmatter?.metadata["category"], "docs")
        }
    }
#endif
