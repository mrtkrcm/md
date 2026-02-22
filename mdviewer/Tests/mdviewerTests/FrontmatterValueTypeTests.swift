//
//  FrontmatterValueTypeTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    @testable internal import mdviewer

    final class FrontmatterValueTypeTests: XCTestCase {
        // MARK: - URL Detection

        func testDetectsHTTPSURLs() {
            let markdown = """
            ---
            homepage: https://example.com
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "homepage" }

            XCTAssertNotNil(entry)
            XCTAssertTrue(entry?.isURL ?? false, "Should detect HTTPS URL")
            XCTAssertEqual(entry?.urlValue?.absoluteString, "https://example.com")
        }

        func testDetectsHTTPURLs() {
            let markdown = """
            ---
            link: http://oldsite.com/page
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "link" }

            XCTAssertTrue(entry?.isURL ?? false, "Should detect HTTP URL")
        }

        func testDetectsMailtoURLs() {
            let markdown = """
            ---
            email: mailto:test@example.com
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "email" }

            XCTAssertTrue(entry?.isURL ?? false, "Should detect mailto URL")
        }

        func testPlainTextNotDetectedAsURL() {
            let markdown = """
            ---
            note: Check out example.com for more
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "note" }

            XCTAssertFalse(entry?.isURL ?? true, "Should not detect plain text as URL")
            if case .text(let text) = entry?.typedValue {
                XCTAssertEqual(text, "Check out example.com for more")
            } else {
                XCTFail("Should be text type")
            }
        }

        // MARK: - Date Detection

        func testDetectsISO8601Date() {
            let markdown = """
            ---
            created: 2026-02-19
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "created" }

            XCTAssertNotNil(entry)
            if case .date = entry?.typedValue {
                // Successfully detected as date
            } else {
                XCTFail("Should detect ISO 8601 date, got \(String(describing: entry?.typedValue))")
            }
        }

        func testDetectsISODateWithTime() {
            let markdown = """
            ---
            timestamp: 2026-02-19T14:30:00
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "timestamp" }

            if case .date = entry?.typedValue {
                // Successfully detected as date
            } else {
                XCTFail("Should detect ISO date with time")
            }
        }

        func testDetectsISODateWithTimezone() {
            let markdown = """
            ---
            updated: 2026-02-19T14:30:00Z
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "updated" }

            if case .date = entry?.typedValue {
                // Successfully detected as date
            } else {
                XCTFail("Should detect ISO date with timezone")
            }
        }

        // MARK: - Boolean Detection

        func testDetectsTrueBoolean() {
            let markdown = """
            ---
            published: true
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "published" }

            if case .boolean(let value) = entry?.typedValue {
                XCTAssertTrue(value)
            } else {
                XCTFail("Should detect true boolean")
            }
        }

        func testDetectsFalseBoolean() {
            let markdown = """
            ---
            published: false
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "published" }

            if case .boolean(let value) = entry?.typedValue {
                XCTAssertFalse(value)
            } else {
                XCTFail("Should detect false boolean")
            }
        }

        func testDetectsYesNoBooleans() {
            let markdown = """
            ---
            enabled: yes
            disabled: no
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)

            if
                case .boolean(let enabled) = parsed.frontmatter?.entries.first(where: { $0.key == "enabled" })?
                    .typedValue
            {
                XCTAssertTrue(enabled)
            } else {
                XCTFail("Should detect 'yes' as true")
            }

            if
                case .boolean(let disabled) = parsed.frontmatter?.entries.first(where: { $0.key == "disabled" })?
                    .typedValue
            {
                XCTAssertFalse(disabled)
            } else {
                XCTFail("Should detect 'no' as false")
            }
        }

        // MARK: - Number Detection

        func testDetectsInteger() {
            let markdown = """
            ---
            count: 42
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "count" }

            if case .number(let value) = entry?.typedValue {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("Should detect integer number")
            }
        }

        func testDetectsDecimal() {
            let markdown = """
            ---
            rating: 4.5
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "rating" }

            if case .number(let value) = entry?.typedValue {
                XCTAssertEqual(value, 4.5)
            } else {
                XCTFail("Should detect decimal number")
            }
        }

        // MARK: - List Detection

        func testDetectsYAMLList() {
            let markdown = """
            ---
            tags:
              - swift
              - markdown
              - macos
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "tags" }

            XCTAssertTrue(entry?.isList ?? false, "Should detect list")
            XCTAssertEqual(entry?.listItems, ["swift", "markdown", "macos"])

            if case .list(let items) = entry?.typedValue {
                XCTAssertEqual(items, ["swift", "markdown", "macos"])
            } else {
                XCTFail("Should be list type")
            }
        }

        func testDisplayValueForList() {
            let markdown = """
            ---
            tags:
              - swift
              - markdown
            ---
            Body
            """
            let parsed = FrontmatterParser.parse(markdown)
            let entry = parsed.frontmatter?.entries.first { $0.key == "tags" }

            XCTAssertEqual(entry?.displayValue, "swift, markdown")
            XCTAssertEqual(parsed.frontmatter?.metadata["tags"], "swift, markdown")
        }

        // MARK: - Display Key Formatting

        func testDisplayKeyFormatsUnderscores() {
            let entry = Frontmatter.Entry(
                key: "created_at",
                rawValue: "2026-02-19",
                typedValue: .text("2026-02-19")
            )
            XCTAssertEqual(entry.displayKey, "Created At")
        }

        func testDisplayKeyFormatsDashes() {
            let entry = Frontmatter.Entry(
                key: "published-date",
                rawValue: "2026-02-19",
                typedValue: .text("2026-02-19")
            )
            XCTAssertEqual(entry.displayKey, "Published Date")
        }

        func testDisplayKeyCapitalizes() {
            let entry = Frontmatter.Entry(
                key: "title",
                rawValue: "Hello",
                typedValue: .text("Hello")
            )
            XCTAssertEqual(entry.displayKey, "Title")
        }

        // MARK: - Display Value Formatting

        func testDisplayValueForBooleanTrue() {
            let entry = Frontmatter.Entry(
                key: "published",
                rawValue: "true",
                typedValue: .boolean(true)
            )
            XCTAssertEqual(entry.displayValue, "Yes")
        }

        func testDisplayValueForBooleanFalse() {
            let entry = Frontmatter.Entry(
                key: "published",
                rawValue: "false",
                typedValue: .boolean(false)
            )
            XCTAssertEqual(entry.displayValue, "No")
        }

        func testDisplayValueForInteger() {
            let entry = Frontmatter.Entry(
                key: "count",
                rawValue: "42",
                typedValue: .number(42)
            )
            XCTAssertEqual(entry.displayValue, "42")
        }

        func testDisplayValueForDecimal() {
            let entry = Frontmatter.Entry(
                key: "rating",
                rawValue: "4.500000",
                typedValue: .number(4.5)
            )
            XCTAssertEqual(entry.displayValue, "4.5")
        }

        func testDisplayValueForURL() {
            let entry = Frontmatter.Entry(
                key: "link",
                rawValue: "https://example.com",
                typedValue: .url(URL(string: "https://example.com")!)
            )
            XCTAssertEqual(entry.displayValue, "https://example.com")
        }
    }
#endif
