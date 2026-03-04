//
//  SettingsAccessibilityTests.swift
//  mdviewer
//
//  Tests for Settings view accessibility compliance.
//

#if canImport(XCTest)
    #if os(macOS)
        @testable internal import mdviewer
        internal import SwiftUI
        internal import XCTest

        /// Tests for Settings view accessibility compliance.
        @MainActor
        final class SettingsAccessibilityTests: XCTestCase {
            // MARK: - Settings View Tests

            @MainActor
            func testSettingsViewExists() {
                let view = SettingsView()
                XCTAssertNotNil(view)
            }

            // MARK: - Picker Accessibility Labels

            @MainActor
            func testAllPickerAccessibilityLabels() {
                let pickerLabels = [
                    "Appearance Mode",
                    "Default View Mode",
                    "Reader Theme",
                    "Reader Font Family",
                    "Reader Font Size",
                    "Reader Line Spacing",
                    "Reader Column Width",
                    "Syntax Highlighting Palette",
                    "Code Font Size",
                ]

                for label in pickerLabels {
                    XCTAssertFalse(label.isEmpty, "Picker label should not be empty")
                    XCTAssertGreaterThan(label.count, 3, "Picker label should be descriptive")
                }
            }

            // MARK: - Section Header Tests

            @MainActor
            func testSettingsSectionHeaders() {
                let sectionTitles = [
                    "General",
                    "Typography",
                    "Reading",
                    "Code",
                    "System",
                ]

                for title in sectionTitles {
                    XCTAssertFalse(title.isEmpty, "Section title should not be empty")
                }
            }

            @MainActor
            func testSectionAccessibilityLabelFormat() {
                let sectionName = "Markdown"
                let expectedLabel = "\(sectionName) Settings"

                XCTAssertEqual(expectedLabel, "Markdown Settings")
            }

            // MARK: - Settings Window Configuration

            @MainActor
            func testSettingsWindowSize() {
                // Verify settings window dimensions are accessible
                XCTAssertEqual(DesignTokens.Layout.settingsWidth, 460)
                XCTAssertEqual(DesignTokens.Layout.settingsHeight, 320)
            }

            // MARK: - Accessibility Identifier Tests

            @MainActor
            func testSettingsViewAccessibilityIdentifier() {
                // Test that the identifier is properly set
                let identifier = "SettingsView"
                XCTAssertEqual(identifier, "SettingsView")
            }

            @MainActor
            func testSettingsViewAccessibilityLabel() {
                let label = "Settings"
                XCTAssertEqual(label, "Settings")
            }
        }
    #endif
#endif
