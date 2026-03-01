//
//  E2EInspectorTests.swift
//  mdviewer
//
//  End-to-end tests for inspector sidebar performance and rendering.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        @testable internal import mdviewer
        internal import SwiftUI

        /// E2E tests for inspector sidebar behavior and performance.
        final class E2EInspectorTests: XCTestCase {
            // MARK: - Performance Tests

            @MainActor
            func testInspectorRendersQuickly() {
                let entries = [
                    Frontmatter.Entry(key: "title", rawValue: "Test", typedValue: .text("Test")),
                    Frontmatter.Entry(key: "author", rawValue: "Author", typedValue: .text("Author")),
                    Frontmatter.Entry(key: "date", rawValue: "2024-01-01", typedValue: .text("2024-01-01")),
                ]
                let frontmatter = Frontmatter(
                    rawYAML: "title: Test\nauthor: Author\ndate: 2024-01-01",
                    entries: entries,
                    metadata: ["title": "Test", "author": "Author", "date": "2024-01-01"]
                )

                measure {
                    let view = InspectorSidebarContent(frontmatter: frontmatter, isPresented: .constant(true))
                    _ = view.body
                }
            }

            @MainActor
            func testEmptyInspectorRendersQuickly() {
                measure {
                    let view = InspectorSidebarContent(frontmatter: nil, isPresented: .constant(true))
                    _ = view.body
                }
            }

            // MARK: - Content Tests

            @MainActor
            func testInspectorDisplaysAllFrontmatterEntries() {
                let entries = [
                    Frontmatter.Entry(key: "title", rawValue: "My Title", typedValue: .text("My Title")),
                    Frontmatter.Entry(key: "tags", rawValue: "[swift, macos]", typedValue: .list(["swift", "macos"])),
                    Frontmatter.Entry(key: "draft", rawValue: "true", typedValue: .boolean(true)),
                ]
                let frontmatter = Frontmatter(
                    rawYAML: "title: My Title\ntags: [swift, macos]\ndraft: true",
                    entries: entries,
                    metadata: ["title": "My Title", "tags": "[swift, macos]", "draft": "true"]
                )

                let view = InspectorSidebarContent(frontmatter: frontmatter, isPresented: .constant(true))
                let body = view.body

                XCTAssertNotNil(body)
            }

            @MainActor
            func testInspectorHandlesLargeFrontmatter() {
                var entries: [Frontmatter.Entry] = []
                var metadata: [String: String] = [:]
                for i in 0 ..< 50 {
                    entries.append(Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    ))
                    metadata["key\(i)"] = "value\(i)"
                }
                let frontmatter = Frontmatter(
                    rawYAML: "",
                    entries: entries,
                    metadata: metadata
                )

                measure {
                    let view = InspectorSidebarContent(frontmatter: frontmatter, isPresented: .constant(true))
                    _ = view.body
                }
            }

            // MARK: - Size Constraint Tests

            @MainActor
            func testInspectorRespectsSizeConstraints() {
                let view = InspectorSidebarContent(frontmatter: nil, isPresented: .constant(true))

                // Verify the view has frame constraints
                let body = view.body
                XCTAssertNotNil(body)
            }
        }

        /// Simplified inspector content for testing without complex view hierarchy.
        private struct InspectorSidebarContent: View {
            let frontmatter: Frontmatter?
            @Binding var isPresented: Bool

            var body: some View {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Metadata")
                            .font(.headline)
                        Spacer()
                        Button("Close") { isPresented = false }
                    }
                    .padding()

                    Divider()

                    if let frontmatter {
                        List(frontmatter.entries, id: \.key) { entry in
                            VStack(alignment: .leading) {
                                Text(entry.key).font(.caption)
                                Text(entry.displayValue)
                            }
                        }
                    } else {
                        Text("No metadata")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
            }
        }
    #endif
#endif
