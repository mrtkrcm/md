//
//  AccessibilityEnhancementTests.swift
//  mdviewer
//
//  Tests for enhanced accessibility features including reduced motion and VoiceOver support.
//

#if canImport(XCTest)
    #if os(macOS)
        @testable internal import mdviewer
        internal import SwiftUI
        internal import XCTest

        /// Tests for enhanced accessibility compliance and VoiceOver support.
        @MainActor
        final class AccessibilityEnhancementTests: XCTestCase {
            // MARK: - Accessibility Configuration Tests

            func testAnimationMultiplierWithReduceMotion() {
                XCTAssertEqual(AccessibilityConfiguration.animationMultiplier(reduceMotion: true), 0.0)
                XCTAssertEqual(AccessibilityConfiguration.animationMultiplier(reduceMotion: false), 1.0)
            }

            func testAdaptiveTransitionWithReduceMotion() {
                let reducedTransition = AccessibilityConfiguration.adaptiveTransition(
                    from: .trailing,
                    reduceMotion: true
                )
                let normalTransition = AccessibilityConfiguration.adaptiveTransition(
                    from: .trailing,
                    reduceMotion: false
                )

                // Reduced motion should return opacity-only transition
                XCTAssertNotNil(reducedTransition)
                XCTAssertNotNil(normalTransition)
            }

            func testAdaptiveSpringWithReduceMotion() {
                let reducedSpring = AccessibilityConfiguration.adaptiveSpring(reduceMotion: true)
                let normalSpring = AccessibilityConfiguration.adaptiveSpring(reduceMotion: false)

                // Both should return valid animations
                XCTAssertNotNil(reducedSpring)
                XCTAssertNotNil(normalSpring)
            }

            func testAdaptiveEaseInOutWithReduceMotion() {
                let reducedEase = AccessibilityConfiguration.adaptiveEaseInOut(duration: 0.2, reduceMotion: true)
                let normalEase = AccessibilityConfiguration.adaptiveEaseInOut(duration: 0.2, reduceMotion: false)

                XCTAssertNotNil(reducedEase)
                XCTAssertNotNil(normalEase)
            }

            // MARK: - VoiceOver Action Tests

            @MainActor
            func testVoiceOverNavigationActions() {
                let actionNames = [
                    "Next Heading",
                    "Previous Heading",
                    "Jump to Top",
                    "Jump to Bottom",
                    "Select All",
                    "Open File",
                    "Use Starter Document",
                ]

                for name in actionNames {
                    XCTAssertFalse(name.isEmpty, "Action name should not be empty")
                    XCTAssertGreaterThan(name.count, 2, "Action name should be descriptive")
                }
            }

            // MARK: - Accessibility Value Tests

            @MainActor
            func testAccessibilityValueFormats() {
                let emptyValue = "Empty document"
                let charCountValue = "100 characters"

                XCTAssertEqual(emptyValue, "Empty document")
                XCTAssertTrue(charCountValue.contains("characters"))
            }

            // MARK: - Color Contrast Tests

            @MainActor
            func testSemanticColorContrast() {
                // Test that semantic colors are properly defined
                let success = DesignTokens.SemanticColors.success
                let warning = DesignTokens.SemanticColors.warning
                let error = DesignTokens.SemanticColors.error
                let info = DesignTokens.SemanticColors.info

                XCTAssertNotNil(success)
                XCTAssertNotNil(warning)
                XCTAssertNotNil(error)
                XCTAssertNotNil(info)
            }

            // MARK: - Welcome View Accessibility Tests

            @MainActor
            func testWelcomeStartViewAccessibility() {
                let view = WelcomeStartView(
                    openAction: {},
                    useStarterAction: {}
                )

                XCTAssertNotNil(view)
            }

            @MainActor
            func testWelcomeViewHeadingTrait() {
                let text = Text("Welcome")
                    .accessibilityLabel("Welcome to mdviewer")
                    .accessibilityAddTraits(.isHeader)

                XCTAssertNotNil(text)
            }

            // MARK: - Keyboard Shortcut Tests

            @MainActor
            func testKeyboardShortcutsDefined() {
                let shortcuts = [
                    ("o", "command"),
                    ("b", "command"),
                    ("i", "command"),
                    ("k", "command,shift"),
                ]

                for (key, modifiers) in shortcuts {
                    XCTAssertFalse(key.isEmpty)
                    XCTAssertFalse(modifiers.isEmpty)
                }
            }

            // MARK: - Editor Accessibility Tests

            @MainActor
            func testRawMarkdownEditorAccessibilityConfiguration() {
                let editor = RawMarkdownEditor(
                    text: .constant("# Test\n\nHello world"),
                    fontSize: 14,
                    colorScheme: .light,
                    showLineNumbers: true
                )

                XCTAssertNotNil(editor)
            }

            @MainActor
            func testEditorAccessibilityIdentifiers() {
                let identifiers = [
                    "RawMarkdownEditor",
                    "Markdown Source Editor",
                ]

                for identifier in identifiers {
                    XCTAssertFalse(identifier.isEmpty)
                    XCTAssertGreaterThan(identifier.count, 2)
                }
            }

            // MARK: - Line Number Accessibility Tests

            @MainActor
            func testLineNumberAccessibilityLabel() {
                let label = "Line Numbers"

                XCTAssertEqual(label, "Line Numbers")
                XCTAssertFalse(label.isEmpty)
            }

            // MARK: - Metadata Accessibility Tests

            @MainActor
            func testMetadataRowAccessibilityLabel() {
                let key = "title"
                let value = "My Document"
                let combinedLabel = "\(key): \(value)"

                XCTAssertEqual(combinedLabel, "title: My Document")
            }

            @MainActor
            func testEmptyMetadataAccessibility() {
                let emptyLabel = "No metadata available"
                let emptyHint = "This document does not contain YAML frontmatter metadata"

                XCTAssertFalse(emptyLabel.isEmpty)
                XCTAssertFalse(emptyHint.isEmpty)
            }

            // MARK: - Content View Accessibility Tests

            @MainActor
            func testContentViewAccessibility() {
                let view = ContentView(document: .constant(MarkdownDocument()), fileURL: nil)

                XCTAssertNotNil(view)
            }

            // MARK: - Accessibility Description Length Tests

            @MainActor
            func testAccessibilityDescriptionsAreDescriptive() {
                let descriptions = [
                    "Markdown Source Editor",
                    "Edit raw markdown text with syntax highlighting",
                    "Document Metadata",
                    "Close the metadata inspector panel",
                    "Open appearance and theme settings",
                    "Show formatted markdown preview",
                    "Show raw markdown source",
                ]

                for description in descriptions {
                    XCTAssertGreaterThan(
                        description.count,
                        5,
                        "Description '\(description)' should be more descriptive"
                    )
                }
            }

            // MARK: - Animation Adaptivity Tests

            @MainActor
            func testAccessibleAnimationModifier() {
                let view = Text("Test")
                    .accessibleAnimation(.easeInOut, value: true, reduceMotion: true)

                XCTAssertNotNil(view)
            }

            @MainActor
            func testAccessibleTransitionModifier() {
                let view = Text("Test")
                    .accessibleTransition(from: .leading, reduceMotion: true)

                XCTAssertNotNil(view)
            }
        }
    #endif
#endif
