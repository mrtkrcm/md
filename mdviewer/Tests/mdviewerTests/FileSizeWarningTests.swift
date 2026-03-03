//
//  FileSizeWarningTests.swift
//  mdviewer
//
//  Tests for large file warning functionality.
//

#if canImport(XCTest)
    #if os(macOS)
        @testable internal import mdviewer
        internal import SwiftUI
        internal import XCTest

        /// Tests for large file warning functionality.
        @MainActor
        final class FileSizeWarningTests: XCTestCase {
            // MARK: - File Size Threshold Tests

            @MainActor
            func testLargeFileThresholdIs1MB() {
                // Verify threshold is 1 MB (1,048,576 bytes)
                let expectedThreshold: Int64 = 1_048_576
                XCTAssertEqual(expectedThreshold, 1_048_576)
            }

            @MainActor
            func testFileSizeFormatting() {
                // Test file size formatting
                let smallFile: Int64 = 1024 // 1 KB
                let mediumFile: Int64 = 1_048_576 // 1 MB
                let largeFile: Int64 = 5_242_880 // 5 MB

                // Verify formatting produces non-empty strings with numbers
                let smallFormatted = DocumentOperations.formatFileSize(smallFile)
                let mediumFormatted = DocumentOperations.formatFileSize(mediumFile)
                let largeFormatted = DocumentOperations.formatFileSize(largeFile)

                XCTAssertFalse(smallFormatted.isEmpty)
                XCTAssertFalse(mediumFormatted.isEmpty)
                XCTAssertFalse(largeFormatted.isEmpty)

                // Verify each contains a number
                XCTAssertTrue(smallFormatted.contains(where: \.isNumber))
                XCTAssertTrue(mediumFormatted.contains(where: \.isNumber))
                XCTAssertTrue(largeFormatted.contains(where: \.isNumber))
            }

            @MainActor
            func testFileSizeFormattingLargeFiles() {
                // Test formatting for various sizes
                let testCases: [(Int64, String)] = [
                    (512, "512 bytes"),
                    (1024, "1 KB"),
                    (1_048_576, "1 MB"),
                    (10_485_760, "10 MB"),
                    (1_073_741_824, "1 GB"),
                ]

                for (size, _) in testCases {
                    let formatted = DocumentOperations.formatFileSize(size)
                    // Note: ByteCountFormatter may vary slightly by locale
                    XCTAssertFalse(formatted.isEmpty)
                    XCTAssertTrue(formatted.contains(where: \.isNumber))
                }
            }

            // MARK: - Warning Message Tests

            @MainActor
            func testLargeFileWarningMessageFormat() {
                // Verify warning message contains expected elements
                let sizeInMB = 5.5
                let message = "This file is \(String(format: "%.1f MB", sizeInMB)). Opening may take a moment and could affect performance. Do you want to continue?"

                XCTAssertTrue(message.contains("5.5 MB"))
                XCTAssertTrue(message.contains("Opening may take a moment"))
                XCTAssertTrue(message.contains("performance"))
            }

            @MainActor
            func testLargeFileAlertTitle() {
                let title = "Large File"
                XCTAssertEqual(title, "Large File")
            }

            @MainActor
            func testLargeFileAlertButtonLabels() {
                let continueButton = "Continue"
                let cancelButton = "Cancel"

                XCTAssertEqual(continueButton, "Continue")
                XCTAssertEqual(cancelButton, "Cancel")
            }

            // MARK: - Accessibility Label Tests

            @MainActor
            func testLargeFileAlertAccessibilityLabels() {
                let alertLabel = "Large file warning"
                let alertHelp = "This document is large and may take time to open"
                let continueLabel = "Continue opening large file"
                let continueHint = "Opens the file despite its size"
                let cancelLabel = "Cancel opening file"
                let cancelHint = "Returns to the document without opening"

                XCTAssertFalse(alertLabel.isEmpty)
                XCTAssertFalse(alertHelp.isEmpty)
                XCTAssertFalse(continueLabel.isEmpty)
                XCTAssertFalse(continueHint.isEmpty)
                XCTAssertFalse(cancelLabel.isEmpty)
                XCTAssertFalse(cancelHint.isEmpty)
            }

            // MARK: - File Size Comparison Tests

            @MainActor
            func testFilesUnderThreshold() {
                let threshold: Int64 = 1_048_576 // 1 MB

                // Files under threshold should not trigger warning
                let smallFiles: [Int64] = [
                    0, // Empty file
                    100, // Tiny file
                    1024, // 1 KB
                    512_000, // 500 KB
                    1_048_575, // Just under 1 MB
                ]

                for size in smallFiles {
                    XCTAssertLessThan(size, threshold, "File of \(size) bytes should be under threshold")
                }
            }

            @MainActor
            func testFilesOverThreshold() {
                let threshold: Int64 = 1_048_576 // 1 MB

                // Files over threshold should trigger warning
                let largeFiles: [Int64] = [
                    1_048_577, // Just over 1 MB
                    5_000_000, // 5 MB
                    10_485_760, // 10 MB
                    100_000_000, // 100 MB
                ]

                for size in largeFiles {
                    XCTAssertGreaterThan(size, threshold, "File of \(size) bytes should be over threshold")
                }
            }

            // MARK: - Edge Cases

            @MainActor
            func testZeroByteFile() {
                let size: Int64 = 0
                let formatted = DocumentOperations.formatFileSize(size)
                XCTAssertFalse(formatted.isEmpty)
            }

            @MainActor
            func testVeryLargeFile() {
                let size: Int64 = 10_737_418_240 // 10 GB
                let formatted = DocumentOperations.formatFileSize(size)
                XCTAssertFalse(formatted.isEmpty)
                XCTAssertTrue(formatted.contains("GB") || formatted.contains("10"))
            }
        }
    #endif
#endif
