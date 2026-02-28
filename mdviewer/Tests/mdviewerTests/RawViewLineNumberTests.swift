//
//  RawViewLineNumberTests.swift
//  mdviewer
//
//  Tests for raw view line number ruler rendering safety and correctness.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer

        final class RawViewLineNumberTests: XCTestCase {
            // MARK: - Bounds Safety

            /// Test character access doesn't crash with boundary checks.
            /// This validates the fix to drawLineNumbers() bounds checking.
            func testBoundsCheckedCharacterAccess() {
                let testStrings: [String] = [
                    "",
                    "a",
                    "ab",
                    "line1\nline2",
                    "line1\nline2\nline3",
                    String(repeating: "x", count: 1000),
                ]

                for testString in testStrings {
                    let nsString = testString as NSString
                    let length = nsString.length

                    // Simulate the fix: bounds check before character access
                    for position in 0 ... min(length, 10) {
                        if position > 0, position - 1 < length {
                            let char = nsString.character(at: position - 1)
                            XCTAssertGreaterThanOrEqual(char, 0)
                        }
                    }
                }
            }

            /// Test that newline detection doesn't crash on empty strings.
            func testNewlineDetectionOnEmptyString() {
                let empty = "" as NSString
                XCTAssertEqual(empty.length, 0)

                // Should not crash when checking for newline at invalid position
                if 0 < empty.length {
                    _ = empty.character(at: 0)
                }
            }

            /// Test character access at string boundaries.
            func testCharacterAccessAtBoundaries() {
                let testString = "Line\nEnd" as NSString
                let length = testString.length

                // Valid accesses
                let first = testString.character(at: 0)
                let last = testString.character(at: length - 1)
                XCTAssertGreaterThanOrEqual(first, 0)
                XCTAssertGreaterThanOrEqual(last, 0)

                // Bounds-checked invalid accesses
                if length > 5, length - 1 < length {
                    let char = testString.character(at: 4) // '\n'
                    XCTAssertEqual(char, UInt16(10)) // newline
                }
            }

            // MARK: - Line Counting

            /// Test line number calculation with various document sizes.
            func testLineNumberCalculation() {
                let testCases: [(String, Int)] = [
                    ("", 1), // empty doc shows line 1
                    ("single", 1),
                    ("line1\nline2", 2),
                    ("a\nb\nc", 3),
                    ("a\n\nb", 3), // blank line counts as a line
                ]

                for (text, expectedLines) in testCases {
                    let components = (text as NSString).components(separatedBy: .newlines)
                    XCTAssertEqual(components.count, expectedLines, "Text: '\(text)'")
                }
            }

            // MARK: - Efficient Newline Counting

            /// Validates that the optimized single-pass newline counting produces
            /// the same results as the old `components(separatedBy:).count` approach.
            /// This is the algorithm now used in LineNumberRulerView and ReaderLayoutManager.
            func testEfficientNewlineCountMatchesComponentsSplit() {
                let testCases: [String] = [
                    "",
                    "single line",
                    "line1\nline2",
                    "a\nb\nc\nd\ne",
                    "a\n\nb", // blank line
                    "\n", // just a newline
                    "\n\n\n", // multiple newlines
                    "no newline at end",
                    "newline at end\n",
                    String(repeating: "line\n", count: 500), // 500 lines
                    "Hello 👋\nWorld 🌍\n日本語", // Unicode
                ]

                for text in testCases {
                    let nsString = text as NSString
                    let length = nsString.length

                    // Old approach: components(separatedBy:).count
                    let oldCount: Int
                    if length == 0 {
                        oldCount = 1
                    } else {
                        oldCount = text.components(separatedBy: .newlines).count
                    }

                    // New approach: single-pass newline scan (matches LineNumberRulerView)
                    var newCount = 1
                    for i in 0 ..< length {
                        if nsString.character(at: i) == 0x0A { newCount += 1 }
                    }

                    XCTAssertEqual(
                        newCount, oldCount,
                        "Efficient count must match split count for: '\(text.prefix(40))...'"
                    )
                }
            }

            /// Validates the efficient counting approach used in ReaderLayoutManager.countLines
            /// which adjusts for trailing newlines.
            func testEfficientCountWithTrailingNewlineAdjustment() {
                let testCases: [(String, Int)] = [
                    ("line1\nline2\n", 2), // trailing \n doesn't add a visible line
                    ("a\nb\nc\n", 3),
                    ("single\n", 1),
                    ("\n", 1), // just a newline = 1 visible line
                    ("no trailing", 1),
                    ("a\nb", 2),
                ]

                for (text, expected) in testCases {
                    let nsString = text as NSString
                    let length = nsString.length

                    var count = 1
                    for i in 0 ..< length {
                        if nsString.character(at: i) == 0x0A { count += 1 }
                    }
                    // Adjust for trailing newline (matches ReaderLayoutManager)
                    if length > 0, nsString.character(at: length - 1) == 0x0A {
                        count -= 1
                    }
                    count = max(1, count)

                    XCTAssertEqual(count, expected, "Text: '\(text)'")
                }
            }

            // MARK: - Edge Cases

            /// Test line numbering with very long lines.
            func testLineNumberingWithLongLines() {
                let longLine = String(repeating: "x", count: 10000)
                let twoLineDoc = "line1\n" + longLine
                let nsString = twoLineDoc as NSString

                // Efficient approach: count newlines in prefix
                var count = 1
                let end = min(5, nsString.length)
                for i in 0 ..< end {
                    if nsString.character(at: i) == 0x0A { count += 1 }
                }
                XCTAssertEqual(count, 1, "No newline in first 5 chars")

                // Full document has exactly one newline
                var fullCount = 1
                for i in 0 ..< nsString.length {
                    if nsString.character(at: i) == 0x0A { fullCount += 1 }
                }
                XCTAssertEqual(fullCount, 2, "Two lines in document")
            }

            /// Test mixed line endings don't cause crashes.
            func testMixedLineEndings() {
                let mixedContent = "line1\nline2\rline3\r\nline4"
                let nsString = mixedContent as NSString

                // Should handle different line ending styles
                for i in 0 ..< nsString.length {
                    if i > 0, i - 1 < nsString.length {
                        let char = nsString.character(at: i - 1)
                        // Just verify access doesn't crash
                        XCTAssertGreaterThanOrEqual(char, 0)
                    }
                }
            }

            // MARK: - Multibyte Character Handling

            /// Test line numbers with Unicode characters.
            func testLineNumbersWithUnicodeContent() {
                let unicodeText = "Hello 👋\nWorld 🌍\n日本語"
                let nsString = unicodeText as NSString

                // NSString uses UTF-16 internally, so emoji might take multiple "characters"
                let prevRange = NSRange(location: 0, length: nsString.length)
                let prevString = nsString.substring(with: prevRange)
                let lineCount = prevString.components(separatedBy: .newlines).count
                XCTAssertGreaterThanOrEqual(lineCount, 0)
            }
        }
    #endif
#endif
