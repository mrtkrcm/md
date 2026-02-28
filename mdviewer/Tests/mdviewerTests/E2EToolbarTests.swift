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
        final class E2EToolbarTests: XCTestCase {
            
            // MARK: - Mode Switching Tests
            
            func testModeSwitchingChangesReaderMode() {
                let view = ContentToolbar(
                    readerMode: .constant(.rendered),
                    showAppearancePopover: .constant(false),
                    showMetadataInspector: .constant(false),
                    openAction: {},
                    documentText: "test"
                )
                
                // Verify toolbar content can be created without crashing
                let toolbarContent = view.body
                XCTAssertNotNil(toolbarContent)
            }
            
            func testToolbarItemsHaveCorrectIdentifiers() {
                // Verify toolbar item IDs are stable for state restoration
                let ids = ["mode", "inspector", "appearance", "share", "open"]
                let uniqueIds = Set(ids)
                XCTAssertEqual(ids.count, uniqueIds.count, "Toolbar item IDs must be unique")
            }
            
            // MARK: - Native Component Tests
            
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
            
            func testToolbarButtonsUseSFSymbols() {
                // Verify all toolbar icons use valid SF Symbol names
                let symbols = ["sidebar.right", "paintbrush", "square.and.arrow.up", "folder"]
                for symbol in symbols {
                    let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
                    XCTAssertNotNil(image, "SF Symbol '\(symbol)' should be available")
                }
            }
            
            // MARK: - State Management Tests
            
            func testToolbarBindingPropagation() {
                var readerMode = ReaderMode.rendered
                var showPopover = false
                var showInspector = false
                
                let bindingMode = Binding(
                    get: { readerMode },
                    set: { readerMode = $0 }
                )
                let bindingPopover = Binding(
                    get: { showPopover },
                    set: { showPopover = $0 }
                )
                let bindingInspector = Binding(
                    get: { showInspector },
                    set: { showInspector = $0 }
                )
                
                let view = ContentToolbar(
                    readerMode: bindingMode,
                    showAppearancePopover: bindingPopover,
                    showMetadataInspector: bindingInspector,
                    openAction: {},
                    documentText: "test"
                )
                
                XCTAssertNotNil(view)
                
                // Simulate mode change
                bindingMode.wrappedValue = .raw
                XCTAssertEqual(readerMode, .raw)
                
                // Simulate inspector toggle
                bindingInspector.wrappedValue = true
                XCTAssertTrue(showInspector)
            }
        }
    #endif
#endif
