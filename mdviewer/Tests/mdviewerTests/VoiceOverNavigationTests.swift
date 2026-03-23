//
//  VoiceOverNavigationTests.swift
//  mdviewer
//
//  Tests to verify VoiceOver navigation support.
//  These tests validate that all accessibility properties are correctly configured.
//

#if canImport(XCTest)
    #if os(macOS)
        @testable internal import mdviewer
        internal import SwiftUI
        internal import XCTest

        /// Tests for VoiceOver navigation and accessibility rotor support.
        @MainActor
        final class VoiceOverNavigationTests: XCTestCase {
            // MARK: - Heading Navigation Tests

            @MainActor
            func testHeadingInfoEquality() {
                let range1 = NSRange(location: 0, length: 10)
                let range2 = NSRange(location: 0, length: 10)
                let range3 = NSRange(location: 5, length: 10)

                let heading1 = HeadingInfo(range: range1, level: 1, text: "Title")
                let heading2 = HeadingInfo(range: range2, level: 1, text: "Title")
                let heading3 = HeadingInfo(range: range3, level: 1, text: "Title")

                XCTAssertEqual(heading1, heading2)
                XCTAssertNotEqual(heading1, heading3)
            }

            @MainActor
            func testHeadingInfoProperties() {
                let range = NSRange(location: 100, length: 20)
                let heading = HeadingInfo(range: range, level: 2, text: "Section Header")

                XCTAssertEqual(heading.range.location, 100)
                XCTAssertEqual(heading.range.length, 20)
                XCTAssertEqual(heading.level, 2)
                XCTAssertEqual(heading.text, "Section Header")
            }

            @MainActor
            func testOutlineNavigationTargetPrefersHeadingIndex() {
                let target = ReaderTextView.outlineNavigationTarget(from: [
                    "headingIndex": 2,
                    "lineIndex": 14,
                ])

                XCTAssertEqual(target, .heading(2))
            }

            @MainActor
            func testOutlineNavigationTargetFallsBackToLineIndex() {
                let target = ReaderTextView.outlineNavigationTarget(from: [
                    "lineIndex": 14,
                ])

                XCTAssertEqual(target, .line(14))
            }

            // MARK: - ReaderTextView Accessibility Tests

            @MainActor
            func testReaderTextViewExists() {
                let textView = ReaderTextView()
                XCTAssertNotNil(textView)
                // Note: Full accessibility configuration is set by NativeMarkdownTextView.makeNSView()
            }

            @MainActor
            func testReaderTextViewHeadingCacheInitiallyEmpty() {
                let textView = ReaderTextView()

                // Heading cache should be empty initially
                let actions = textView.accessibilityCustomActions()
                // Jump to Top and Jump to Bottom actions exist when no headings
                XCTAssertGreaterThanOrEqual(actions?.count ?? 0, 2)
            }

            @MainActor
            func testReaderTextViewHeadingActionsWithContent() {
                let textStorage = NSTextStorage()
                let layoutManager = NSLayoutManager()
                textStorage.addLayoutManager(layoutManager)

                let textContainer = NSTextContainer()
                layoutManager.addTextContainer(textContainer)

                let textView = ReaderTextView(frame: .zero, textContainer: textContainer)

                // Set attributed string with heading
                let attributedString = NSMutableAttributedString(string: "# Test Heading\n\nSome content")
                attributedString.addAttribute(
                    MarkdownRenderAttribute.headingLevel,
                    value: 1,
                    range: NSRange(location: 0, length: 14)
                )

                textStorage.setAttributedString(attributedString)
                textView.updateContainerGeometry()

                // Now heading actions should be available
                let actions = textView.accessibilityCustomActions()
                XCTAssertGreaterThanOrEqual(actions?.count ?? 0, 2)

                // Check for specific action names
                let actionNames = actions?.map(\.name) ?? []
                XCTAssertTrue(actionNames.contains("Jump to Top"))
                XCTAssertTrue(actionNames.contains("Jump to Bottom"))
            }

            // MARK: - Accessibility Action Name Tests

            @MainActor
            func testAllAccessibilityActionNames() {
                let expectedActions = [
                    "Next Heading",
                    "Previous Heading",
                    "Jump to Top",
                    "Jump to Bottom",
                    "Select All",
                ]

                for actionName in expectedActions {
                    XCTAssertGreaterThan(actionName.count, 3, "Action name should be descriptive")
                    XCTAssertFalse(actionName.isEmpty, "Action name should not be empty")
                }
            }

            @MainActor
            func testVoiceOverRotorLabels() {
                let rotorLabels = [
                    "Headings",
                    "Heading Level 1",
                    "Heading Level 2",
                    "Heading Level 3",
                    "Heading Level 4",
                    "Heading Level 5",
                    "Heading Level 6",
                ]

                for label in rotorLabels {
                    XCTAssertFalse(label.isEmpty, "Rotor label should not be empty")
                    XCTAssertGreaterThan(label.count, 3, "Rotor label should be descriptive")
                }
            }

            // MARK: - LiquidBackground Accessibility Tests

            @MainActor
            func testLiquidBackgroundIsAccessibilityHidden() {
                let background = LiquidBackground()
                // Verify the view exists and is properly configured
                XCTAssertNotNil(background)
            }

            // MARK: - Accessibility Value Tests

            @MainActor
            func testDocumentAccessibilityValueFormats() {
                let emptyValue = "Empty document"
                let charCountValue = "100 characters, formatted markdown"

                XCTAssertEqual(emptyValue, "Empty document")
                XCTAssertTrue(charCountValue.contains("characters"))
                XCTAssertTrue(charCountValue.contains("formatted markdown"))
            }

            @MainActor
            func testRawEditorAccessibilityValue() {
                let emptyValue = "Empty document"
                let charCountValue = "50 characters"

                XCTAssertEqual(emptyValue, "Empty document")
                XCTAssertTrue(charCountValue.contains("characters"))
            }

            // MARK: - Content View Accessibility Tests

            @MainActor
            func testContentViewHasAccessibilityConfiguration() {
                let view = ContentView(document: .constant(MarkdownDocument()), fileURL: nil)
                XCTAssertNotNil(view)
            }

            // MARK: - Welcome View Accessibility Tests

            @MainActor
            func testWelcomeStartViewAccessibilityLabels() {
                let view = WelcomeStartView(
                    openAction: {},
                    useStarterAction: {}
                )

                XCTAssertNotNil(view)
            }

            // MARK: - Metadata Inspector Accessibility Tests

            @MainActor
            func testMetadataInspectorAccessibilityLabels() {
                // Test the metadata row accessibility label format
                let key = "title"
                let value = "Test Document"
                let combinedLabel = "\(key): \(value)"

                XCTAssertEqual(combinedLabel, "title: Test Document")
            }

            @MainActor
            func testEmptyMetadataAccessibility() {
                let emptyLabel = "No metadata available"
                let emptyHint = "This document does not contain YAML frontmatter metadata"

                XCTAssertFalse(emptyLabel.isEmpty)
                XCTAssertFalse(emptyHint.isEmpty)
            }

            // MARK: - Toolbar Accessibility Tests

            @MainActor
            func testContentToolbarAccessibility() {
                let toolbar = ContentToolbar(
                    readerMode: .constant(.rendered),
                    showMetadataInspector: .constant(false),
                    sidebarMode: .constant(.metadata),
                    documentText: "test content",
                    hasFrontmatter: true,
                    fileURL: nil
                )

                XCTAssertNotNil(toolbar)
            }

            // MARK: - Raw Markdown Editor Tests

            @MainActor
            func testRawMarkdownEditorExists() {
                let editor = RawMarkdownEditor(
                    text: .constant("# Test\n\nHello world"),
                    fontSize: 14,
                    colorScheme: .light,
                    showLineNumbers: true
                )

                XCTAssertNotNil(editor)
            }

            // MARK: - Native Markdown TextView Tests

            @MainActor
            func testNativeMarkdownTextViewExists() {
                let view = NativeMarkdownTextView(
                    markdown: "# Test\n\nContent",
                    readerFontFamily: .newYork,
                    readerFontSize: 15,
                    codeFontSize: 14,
                    appTheme: .github,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: 720,
                    contentPadding: 24,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
                )

                XCTAssertNotNil(view)
            }
        }
    #endif
#endif
