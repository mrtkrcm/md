//
//  FolderSidebarViewTests.swift
//  mdviewer
//
//  Tests for folder sidebar functionality.
//

#if canImport(XCTest)
    @testable internal import mdviewer
    internal import SwiftUI
    internal import XCTest

    /// Tests for FolderSidebarView and FolderItem.
    @MainActor
    final class FolderSidebarViewTests: XCTestCase {
        // MARK: - FolderItem Tests

        func testFolderItemInitialization() {
            let url = URL(fileURLWithPath: "/test/file.md")
            let item = FolderItem(url: url, isDirectory: false)

            XCTAssertEqual(item.name, "file.md")
            XCTAssertFalse(item.isDirectory)
            XCTAssertEqual(item.icon, "doc.text")
            XCTAssertEqual(item.url, url)
        }

        func testFolderItemDirectoryInitialization() {
            let url = URL(fileURLWithPath: "/test/folder")
            let item = FolderItem(url: url, isDirectory: true)

            XCTAssertEqual(item.name, "folder")
            XCTAssertTrue(item.isDirectory)
            XCTAssertEqual(item.icon, "folder.fill")
        }

        func testFolderItemEquality() {
            let url = URL(fileURLWithPath: "/test/file.md")
            let item1 = FolderItem(url: url, isDirectory: false)
            let item2 = FolderItem(url: url, isDirectory: false)

            // FolderItem equality is based on URL path only
            XCTAssertEqual(item1, item2)
        }

        func testFolderItemInequality() {
            let url1 = URL(fileURLWithPath: "/test/file1.md")
            let url2 = URL(fileURLWithPath: "/test/file2.md")
            let item1 = FolderItem(url: url1, isDirectory: false)
            let item2 = FolderItem(url: url2, isDirectory: false)

            XCTAssertNotEqual(item1, item2)
        }

        func testFolderItemSendable() {
            let url = URL(fileURLWithPath: "/test/file.md")
            let item = FolderItem(url: url, isDirectory: false)

            // Compile-time check that FolderItem is Sendable
            let _: any Sendable = item
            XCTAssertTrue(true)
        }

        // MARK: - FolderSidebarView Initialization Tests

        func testFolderSidebarViewInitialization() {
            let fileURL = URL(fileURLWithPath: "/test/file.md")
            let view = FolderSidebarView(fileURL: fileURL)

            XCTAssertNotNil(view)
        }

        func testFolderSidebarViewWithCallback() {
            let fileURL = URL(fileURLWithPath: "/test/file.md")
            var callbackCalled = false

            let view = FolderSidebarView(fileURL: fileURL) { _ in
                callbackCalled = true
            }

            XCTAssertNotNil(view)
            // Verify callback closure is captured (not testing invocation)
            XCTAssertFalse(callbackCalled)
        }

        // MARK: - Accessibility Tests

        func testFolderItemAccessibilityLabels() {
            let url = URL(fileURLWithPath: "/test/document.md")
            let item = FolderItem(url: url, isDirectory: false)

            XCTAssertEqual(item.name, "document.md")
            XCTAssertFalse(item.isDirectory)
        }

        func testFolderItemDirectoryAccessibility() {
            let url = URL(fileURLWithPath: "/test/MyFolder")
            let item = FolderItem(url: url, isDirectory: true)

            XCTAssertEqual(item.name, "MyFolder")
            XCTAssertTrue(item.isDirectory)
        }

        // MARK: - Performance Tests

        func testFolderItemCreationPerformance() {
            let url = URL(fileURLWithPath: "/test/file.md")

            measure {
                for _ in 0 ..< 1000 {
                    _ = FolderItem(url: url, isDirectory: false)
                }
            }
        }
    }
#endif
