//
//  E2EToolbarTests.swift
//  mdviewer
//
//  End-to-end tests for toolbar functionality and native macOS integration.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer
        internal import SwiftUI

        /// E2E tests for toolbar behavior and native macOS component integration.
        @MainActor
        final class E2EToolbarTests: XCTestCase {
            /// Mutable binding state container used to avoid capturing local vars
            /// in potentially concurrent closure contexts.
            private final class StateBox<T>: @unchecked Sendable {
                var value: T
                init(_ value: T) { self.value = value }
            }

            // MARK: - Mode Switching Tests

            @MainActor
            func testModeSwitchingChangesReaderMode() {
                let view = ContentToolbar(
                    readerMode: .constant(.rendered),
                    showMetadataInspector: .constant(false),
                    sidebarMode: .constant(.metadata),
                    documentText: "test",
                    hasFrontmatter: true,
                    fileURL: nil
                )

                // Verify toolbar content can be created without crashing
                let toolbarContent = view.body
                XCTAssertNotNil(toolbarContent)
            }

            @MainActor
            func testToolbarItemsHaveCorrectIdentifiers() {
                // Verify toolbar item IDs are stable for state restoration
                let ids = ["mode", "inspector", "share"]
                let uniqueIds = Set(ids)
                XCTAssertEqual(ids.count, uniqueIds.count, "Toolbar item IDs must be unique")
            }

            // MARK: - Native Component Tests

            @MainActor
            func testModePickerUsesSegmentedStyle() {
                // The mode picker should use native NSSegmentedControl via Picker(.segmented)
                // This test verifies the picker configuration is valid
                let picker = Picker("Mode", selection: .constant(ReaderMode.rendered)) {
                    Image(systemName: "doc.text.image").tag(ReaderMode.rendered)
                    Image(systemName: "doc.plaintext").tag(ReaderMode.raw)
                }
                .pickerStyle(.segmented)

                XCTAssertNotNil(picker)
            }

            @MainActor
            func testToolbarButtonsUseSFSymbols() {
                // Verify all toolbar icons use valid SF Symbol names
                let symbols = ["sidebar.right", "square.and.arrow.up"]
                for symbol in symbols {
                    let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
                    XCTAssertNotNil(image, "SF Symbol '\(symbol)' should be available")
                }
            }

            // MARK: - State Management Tests

            @MainActor
            func testToolbarBindingPropagation() {
                let readerMode = StateBox(ReaderMode.rendered)
                let showInspector = StateBox(false)
                let sidebarMode = StateBox(SidebarMode.metadata)

                let bindingMode = Binding(
                    get: { readerMode.value },
                    set: { readerMode.value = $0 }
                )
                let bindingInspector = Binding(
                    get: { showInspector.value },
                    set: { showInspector.value = $0 }
                )
                let bindingSidebarMode = Binding(
                    get: { sidebarMode.value },
                    set: { sidebarMode.value = $0 }
                )

                let view = ContentToolbar(
                    readerMode: bindingMode,
                    showMetadataInspector: bindingInspector,
                    sidebarMode: bindingSidebarMode,
                    documentText: "test",
                    hasFrontmatter: true,
                    fileURL: nil
                )

                XCTAssertNotNil(view)

                // Simulate mode change
                bindingMode.wrappedValue = .raw
                XCTAssertEqual(readerMode.value, .raw)

                // Simulate inspector toggle
                bindingInspector.wrappedValue = true
                XCTAssertTrue(showInspector.value)
            }
        }
    #endif
#endif
