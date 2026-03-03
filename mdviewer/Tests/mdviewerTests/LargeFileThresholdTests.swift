//
//  LargeFileThresholdTests.swift
//  mdviewer
//
//  Tests for LargeFileThreshold enum and user-configurable thresholds.
//

#if canImport(XCTest)
    #if os(macOS)
        @testable internal import mdviewer
        internal import XCTest

        /// Tests for LargeFileThreshold enum.
        @MainActor
        final class LargeFileThresholdTests: XCTestCase {
            // MARK: - Enum Values

            @MainActor
            func testAllCasesExist() {
                let allCases = LargeFileThreshold.allCases
                XCTAssertEqual(allCases.count, 6)
                XCTAssertTrue(allCases.contains(.never))
                XCTAssertTrue(allCases.contains(.kb500))
                XCTAssertTrue(allCases.contains(.mb1))
                XCTAssertTrue(allCases.contains(.mb2))
                XCTAssertTrue(allCases.contains(.mb5))
                XCTAssertTrue(allCases.contains(.mb10))
            }

            @MainActor
            func testRawValues() {
                XCTAssertEqual(LargeFileThreshold.never.rawValue, 0)
                XCTAssertEqual(LargeFileThreshold.kb500.rawValue, 512_000)
                XCTAssertEqual(LargeFileThreshold.mb1.rawValue, 1_048_576)
                XCTAssertEqual(LargeFileThreshold.mb2.rawValue, 2_097_152)
                XCTAssertEqual(LargeFileThreshold.mb5.rawValue, 5_242_880)
                XCTAssertEqual(LargeFileThreshold.mb10.rawValue, 10_485_760)
            }

            @MainActor
            func testLabels() {
                XCTAssertEqual(LargeFileThreshold.never.label, "Never")
                XCTAssertEqual(LargeFileThreshold.kb500.label, "500 KB")
                XCTAssertEqual(LargeFileThreshold.mb1.label, "1 MB")
                XCTAssertEqual(LargeFileThreshold.mb2.label, "2 MB")
                XCTAssertEqual(LargeFileThreshold.mb5.label, "5 MB")
                XCTAssertEqual(LargeFileThreshold.mb10.label, "10 MB")
            }

            @MainActor
            func testBytes() {
                XCTAssertNil(LargeFileThreshold.never.bytes)
                XCTAssertEqual(LargeFileThreshold.kb500.bytes, 512_000)
                XCTAssertEqual(LargeFileThreshold.mb1.bytes, 1_048_576)
                XCTAssertEqual(LargeFileThreshold.mb2.bytes, 2_097_152)
                XCTAssertEqual(LargeFileThreshold.mb5.bytes, 5_242_880)
                XCTAssertEqual(LargeFileThreshold.mb10.bytes, 10_485_760)
            }

            // MARK: - Should Warn Logic

            @MainActor
            func testShouldWarnNever() {
                let threshold: LargeFileThreshold = .never
                XCTAssertFalse(threshold.shouldWarn(for: 0))
                XCTAssertFalse(threshold.shouldWarn(for: 1_000_000))
                XCTAssertFalse(threshold.shouldWarn(for: 1_000_000_000))
            }

            @MainActor
            func testShouldWarn500KB() {
                let threshold: LargeFileThreshold = .kb500
                XCTAssertFalse(threshold.shouldWarn(for: 100_000)) // Under threshold
                XCTAssertFalse(threshold.shouldWarn(for: 512_000)) // At threshold
                XCTAssertTrue(threshold.shouldWarn(for: 512_001)) // Over threshold
                XCTAssertTrue(threshold.shouldWarn(for: 1_000_000)) // Well over
            }

            @MainActor
            func testShouldWarn1MB() {
                let threshold: LargeFileThreshold = .mb1
                XCTAssertFalse(threshold.shouldWarn(for: 500_000))
                XCTAssertFalse(threshold.shouldWarn(for: 1_048_576))
                XCTAssertTrue(threshold.shouldWarn(for: 1_048_577))
                XCTAssertTrue(threshold.shouldWarn(for: 5_000_000))
            }

            @MainActor
            func testShouldWarn10MB() {
                let threshold: LargeFileThreshold = .mb10
                XCTAssertFalse(threshold.shouldWarn(for: 5_000_000))
                XCTAssertFalse(threshold.shouldWarn(for: 10_485_760))
                XCTAssertTrue(threshold.shouldWarn(for: 10_485_761))
                XCTAssertTrue(threshold.shouldWarn(for: 100_000_000))
            }

            // MARK: - UserDefaults Support

            @MainActor
            func testFromRawValue() {
                XCTAssertEqual(LargeFileThreshold.from(rawValue: 0), .never)
                XCTAssertEqual(LargeFileThreshold.from(rawValue: 512_000), .kb500)
                XCTAssertEqual(LargeFileThreshold.from(rawValue: 1_048_576), .mb1)
                XCTAssertEqual(LargeFileThreshold.from(rawValue: 2_097_152), .mb2)
                XCTAssertEqual(LargeFileThreshold.from(rawValue: 5_242_880), .mb5)
                XCTAssertEqual(LargeFileThreshold.from(rawValue: 10_485_760), .mb10)
            }

            @MainActor
            func testFromInvalidRawValue() {
                // Should default to 1MB for invalid values
                XCTAssertEqual(LargeFileThreshold.from(rawValue: -1), .mb1)
                XCTAssertEqual(LargeFileThreshold.from(rawValue: 999), .mb1)
                XCTAssertEqual(LargeFileThreshold.from(rawValue: 999_999), .mb1)
            }

            // MARK: - Default Value

            @MainActor
            func testDefaultThresholdForInvalidValue() {
                // When rawValue is invalid, should default to 1MB
                let threshold = LargeFileThreshold.from(rawValue: 999_999)
                XCTAssertEqual(threshold, .mb1, "Invalid threshold should default to 1MB")
            }

            // MARK: - AppPreferences Integration

            @MainActor
            func testPreferencesHasLargeFileThreshold() {
                // Verify the preference exists and is observable
                let prefs = AppPreferences.shared
                let threshold = prefs.largeFileThreshold
                XCTAssertNotNil(threshold)
                // Verify it's one of the valid cases
                XCTAssertTrue(LargeFileThreshold.allCases.contains(threshold))
            }
        }
    #endif
#endif
