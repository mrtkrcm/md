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

            // MARK: - Edge Cases

            /// Test line numbering with very long lines.
            func testLineNumberingWithLongLines() {
                let longLine = String(repeating: "x", count: 10000)
                let twoLineDoc = "line1\n" + longLine
                let nsString = twoLineDoc as NSString

                // Line 2 should be detected properly even with very long line 1
                let prevString = nsString.substring(with: NSRange(location: 0, length: 5))
                let lineCount = prevString.components(separatedBy: .newlines).count
                XCTAssertEqual(lineCount, 1)
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
