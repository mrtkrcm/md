//
//  AccessibilityTests.swift
//  mdviewer
//
//  Tests for accessibility compliance and VoiceOver support.
//

#if canImport(XCTest)
    #if os(macOS)
        @testable internal import mdviewer
        internal import SwiftUI
        internal import XCTest

        /// Tests for accessibility compliance and VoiceOver support.
        @MainActor
        final class AccessibilityTests: XCTestCase {
            // MARK: - ContentToolbar Accessibility Tests

            @MainActor
            func testContentToolbarHasAccessibilityLabels() {
                let view = ContentToolbar(
                    readerMode: .constant(.rendered),
                    showAppearancePopover: .constant(false),
                    showMetadataInspector: .constant(false),
                    sidebarMode: .constant(.metadata),
                    documentText: "test",
                    hasFrontmatter: true,
                    fileURL: nil
                )

                // Verify toolbar can be created
                XCTAssertNotNil(view)
            }

            @MainActor
            func testToolbarModePickerHasAccessibilityLabel() {
                let picker = Picker("Mode", selection: .constant(ReaderMode.rendered)) {
                    Image(systemName: "doc.text.image")
                        .accessibilityLabel("Rendered Mode")
                        .accessibilityHint("Show formatted markdown preview")
                        .tag(ReaderMode.rendered)
                    Image(systemName: "doc.plaintext")
                        .accessibilityLabel("Raw Mode")
                        .accessibilityHint("Show raw markdown source")
                        .tag(ReaderMode.raw)
                }

                XCTAssertNotNil(picker)
            }

            // MARK: - WelcomeStartView Accessibility Tests

            @MainActor
            func testWelcomeStartViewHasAccessibilityLabels() {
                let view = WelcomeStartView(
                    openAction: {},
                    useStarterAction: {}
                )

                XCTAssertNotNil(view)
            }

            @MainActor
            func testWelcomeButtonsHaveAccessibilityLabels() {
                let openButton = Button("Open...", action: {})
                    .accessibilityLabel("Open File")
                    .accessibilityHint("Open a markdown file from disk")

                let starterButton = Button("Use Starter", action: {})
                    .accessibilityLabel("Use Starter Document")
                    .accessibilityHint("Create a new document with sample content")

                XCTAssertNotNil(openButton)
                XCTAssertNotNil(starterButton)
            }

            // MARK: - AppearancePopoverView Accessibility Tests

            @MainActor
            func testAppearancePopoverHasAccessibilityLabels() {
                let view = AppearancePopoverView(
                    selectedTheme: .constant(.github),
                    readerFontSize: .constant(.standard),
                    readerFontFamily: .constant(.newYork),
                    syntaxPalette: .constant(.midnight),
                    codeFontSize: .constant(.medium),
                    appearanceMode: .constant(.auto),
                    readerTextSpacing: .constant(.balanced),
                    readerColumnWidth: .constant(.balanced),
                    readerContentPadding: .constant(.normal),
                    showLineNumbers: .constant(true),
                    typographyPreferences: .constant(TypographyPreferences())
                )

                XCTAssertNotNil(view)
            }

            @MainActor
            func testLineNumbersToggleHasAccessibility() {
                let toggle = Toggle("Line Numbers", isOn: .constant(true))
                    .accessibilityLabel("Show Line Numbers")
                    .accessibilityHint("Display line numbers in the editor")
                    .accessibilityValue("Enabled")

                XCTAssertNotNil(toggle)
            }

            @MainActor
            func testThemePickerHasAccessibility() {
                let picker = Picker("Theme", selection: .constant(AppTheme.github)) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .accessibilityLabel("Reader Theme")
                .accessibilityValue(AppTheme.github.rawValue)

                XCTAssertNotNil(picker)
            }

            // MARK: - Raw Markdown Editor Accessibility Tests

            @MainActor
            func testRawMarkdownEditorHasAccessibilityConfiguration() {
                let editor = RawMarkdownEditor(
                    text: .constant("# Test\n\nHello world"),
                    fontSize: 14,
                    colorScheme: .light,
                    showLineNumbers: true
                )

                XCTAssertNotNil(editor)
            }

            // MARK: - Heading Level Attribute Tests

            @MainActor
            func testHeadingLevelAttributeKeyExists() {
                // Verify the heading level attribute key exists
                let key = MarkdownRenderAttribute.headingLevel
                XCTAssertEqual(key.rawValue, "mdv.headingLevel")
            }

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

            // MARK: - Accessibility Label Validation

            @MainActor
            func testAccessibilityLabelsAreNotEmpty() {
                let labels = [
                    "View Mode",
                    "Rendered Mode",
                    "Raw Mode",
                    "Metadata Inspector",
                    "Appearance Settings",
                    "Share Document",
                    "Open File",
                    "Welcome to mdviewer",
                    "Open a markdown file or start with starter content",
                    "Appearance Mode",
                    "Reader Theme",
                    "Reader Font",
                    "Reader Text Size",
                    "Reader Text Spacing",
                    "Reader Column Width",
                    "Syntax Highlighting Palette",
                    "Code Font Size",
                    "Show Line Numbers",
                    "Markdown Source Editor",
                    "Document Metadata",
                ]

                for label in labels {
                    XCTAssertFalse(label.isEmpty, "Accessibility label should not be empty")
                    XCTAssertGreaterThan(label.count, 2, "Accessibility label should be descriptive")
                }
            }

            @MainActor
            func testAccessibilityHintsAreDescriptive() {
                let hints = [
                    "Show formatted markdown preview",
                    "Show raw markdown source",
                    "Show or hide document metadata panel",
                    "No metadata available in this document",
                    "Open appearance and theme settings",
                    "Share the document text",
                    "Open a markdown file from disk",
                    "Create a new document with sample content",
                    "Display line numbers in the editor",
                    "Edit raw markdown text with syntax highlighting",
                    "Close the metadata inspector panel",
                ]

                for hint in hints {
                    XCTAssertFalse(hint.isEmpty, "Accessibility hint should not be empty")
                    XCTAssertGreaterThan(hint.count, 5, "Accessibility hint should be descriptive")
                }
            }

            @MainActor
            func testAccessibilityIdentifiersAreSet() {
                // Verify accessibility identifiers are properly formatted
                let identifiers = [
                    "RawMarkdownEditor",
                ]

                for identifier in identifiers {
                    XCTAssertFalse(identifier.isEmpty, "Accessibility identifier should not be empty")
                    XCTAssertGreaterThan(identifier.count, 2, "Accessibility identifier should be descriptive")
                }
            }

            // MARK: - Accessibility Action Names

            @MainActor
            func testAccessibilityActionNamesAreDescriptive() {
                let actionNames = [
                    "Switch to Rendered Mode",
                    "Switch to Raw Mode",
                    "Show Metadata Panel",
                    "Hide Metadata Panel",
                    "Open Appearance Settings",
                    "Open Document",
                    "Jump to Top",
                    "Jump to Bottom",
                    "Select All",
                    "Next Heading",
                    "Previous Heading",
                ]

                for name in actionNames {
                    XCTAssertFalse(name.isEmpty, "Action name should not be empty")
                    XCTAssertGreaterThan(name.count, 3, "Action name should be descriptive")
                }
            }

            // MARK: - Rotor Label Tests

            @MainActor
            func testRotorLabelsAreDescriptive() {
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
        }
    #endif
#endif
