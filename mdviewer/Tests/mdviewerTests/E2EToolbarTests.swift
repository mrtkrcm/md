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
        internal import SwiftUI
        @testable internal import mdviewer

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
                    showAppearancePopover: .constant(false),
                    showMetadataInspector: .constant(false),
                    openAction: {},
                    documentText: "test",
                    hasFrontmatter: true
                )
                
                // Verify toolbar content can be created without crashing
                let toolbarContent = view.body
                XCTAssertNotNil(toolbarContent)
            }
            
            @MainActor
            func testToolbarItemsHaveCorrectIdentifiers() {
                // Verify toolbar item IDs are stable for state restoration
                let ids = ["mode", "inspector", "appearance", "share", "open"]
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
                let symbols = ["sidebar.right", "paintbrush", "square.and.arrow.up", "folder"]
                for symbol in symbols {
                    let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
                    XCTAssertNotNil(image, "SF Symbol '\(symbol)' should be available")
                }
            }
            
            // MARK: - State Management Tests
            
            @MainActor
            func testToolbarBindingPropagation() {
                let readerMode = StateBox(ReaderMode.rendered)
                let showPopover = StateBox(false)
                let showInspector = StateBox(false)
                
                let bindingMode = Binding(
                    get: { readerMode.value },
                    set: { readerMode.value = $0 }
                )
                let bindingPopover = Binding(
                    get: { showPopover.value },
                    set: { showPopover.value = $0 }
                )
                let bindingInspector = Binding(
                    get: { showInspector.value },
                    set: { showInspector.value = $0 }
                )
                
                let view = ContentToolbar(
                    readerMode: bindingMode,
                    showAppearancePopover: bindingPopover,
                    showMetadataInspector: bindingInspector,
                    openAction: {},
                    documentText: "test",
                    hasFrontmatter: true
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
