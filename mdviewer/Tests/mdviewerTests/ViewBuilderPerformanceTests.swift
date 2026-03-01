//
//  ViewBuilderPerformanceTests.swift
//  mdviewer
//
//  Performance tests for SwiftUI view rendering using @ViewBuilder patterns.
//  Includes baselines for regression detection and memory allocation tracking.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        @testable internal import mdviewer
        internal import SwiftUI

        /// Performance tests for SwiftUI @ViewBuilder rendering patterns.
        /// Measures actual view hierarchy construction, body evaluation, and memory allocations.
        ///
        /// Baselines are set for debug builds on Apple Silicon (M-series).
        /// To update baselines: swift test --filter ViewBuilderPerformanceTests
        /// Then accept new baselines in Xcode or via xcrun xccov.
        final class ViewBuilderPerformanceTests: XCTestCase {
            // MARK: - Inspector Sidebar Performance (Wall Clock Time)

            @MainActor
            func testInspectorSidebarBodyEvaluation() {
                let entries = (0 ..< 20).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }
                let frontmatter = Frontmatter(
                    rawYAML: "",
                    entries: entries,
                    metadata: [:]
                )

                measure(metrics: [XCTClockMetric()]) {
                    // @ViewBuilder body evaluation - the critical path for SwiftUI
                    let view = InspectorSidebar(frontmatter: frontmatter, isPresented: .constant(true))
                    _ = view.body
                }
            }

            @MainActor
            func testMetadataRowBodyEvaluation() {
                let entry = Frontmatter.Entry(
                    key: "title",
                    rawValue: "Sample Document",
                    typedValue: .text("Sample Document")
                )

                measure(metrics: [XCTClockMetric()]) {
                    // Isolated row component - should be extremely fast
                    let view = MetadataRow(entry: entry)
                    _ = view.body
                }
            }

            @MainActor
            func testEmptyMetadataStateBodyEvaluation() {
                measure(metrics: [XCTClockMetric()]) {
                    let view = EmptyMetadataState()
                    _ = view.body
                }
            }

            // MARK: - LazyVStack vs VStack Performance (Wall Clock Time)

            @MainActor
            func testLazyVStackContainerPerformance() {
                let entries = (0 ..< 100).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }

                measure(metrics: [XCTClockMetric()]) {
                    // LazyVStack container - only renders visible items
                    let view = LazyVStackContainer(entries: entries)
                    _ = view.body
                }
            }

            @MainActor
            func testRegularVStackContainerPerformance() {
                let entries = (0 ..< 100).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }

                measure(metrics: [XCTClockMetric()]) {
                    // VStack container - renders all items eagerly
                    let view = RegularVStackContainer(entries: entries)
                    _ = view.body
                }
            }

            // MARK: - View Isolation Performance (Wall Clock Time)

            @MainActor
            func testIsolatedSubviewsPerformance() {
                let entries = (0 ..< 50).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }

                measure(metrics: [XCTClockMetric()]) {
                    // Using isolated MetadataRow structs
                    let view = StructuredMetadataView(entries: entries)
                    _ = view.body
                }
            }

            // MARK: - Complex Frontmatter Types (Wall Clock Time)

            @MainActor
            func testComplexTypedFrontmatter() {
                let entries: [Frontmatter.Entry] = [
                    .init(key: "title", rawValue: "Doc", typedValue: .text("Doc")),
                    .init(
                        key: "url",
                        rawValue: "https://example.com",
                        typedValue: .url(URL(string: "https://example.com")!)
                    ),
                    .init(key: "date", rawValue: "2024-01-15", typedValue: .date(Date())),
                    .init(key: "tags", rawValue: "[a,b,c]", typedValue: .list(["swift", "macos", "markdown"])),
                    .init(key: "published", rawValue: "true", typedValue: .boolean(true)),
                    .init(key: "count", rawValue: "42", typedValue: .number(42)),
                ]
                let frontmatter = Frontmatter(rawYAML: "", entries: entries, metadata: [:])

                measure(metrics: [XCTClockMetric()]) {
                    let view = InspectorSidebar(frontmatter: frontmatter, isPresented: .constant(true))
                    _ = view.body
                }
            }

            // MARK: - Memory Allocation Tests

            @MainActor
            func testInspectorSidebarMemoryAllocations() {
                let entries = (0 ..< 20).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }
                let frontmatter = Frontmatter(
                    rawYAML: "",
                    entries: entries,
                    metadata: [:]
                )

                measure(metrics: [XCTMemoryMetric()]) {
                    let view = InspectorSidebar(frontmatter: frontmatter, isPresented: .constant(true))
                    _ = view.body
                }
            }

            @MainActor
            func testMetadataRowMemoryAllocations() {
                let entry = Frontmatter.Entry(
                    key: "title",
                    rawValue: "Sample Document",
                    typedValue: .text("Sample Document")
                )

                measure(metrics: [XCTMemoryMetric()]) {
                    let view = MetadataRow(entry: entry)
                    _ = view.body
                }
            }

            @MainActor
            func testLazyVStackMemoryVsVStack() {
                let entries = (0 ..< 50).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }

                // Measure LazyVStack allocations
                measure(metrics: [XCTMemoryMetric()]) {
                    let view = LazyVStackContainer(entries: entries)
                    _ = view.body
                }
            }

            @MainActor
            func testRegularVStackMemoryVsLazy() {
                let entries = (0 ..< 50).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }

                // Measure VStack allocations
                measure(metrics: [XCTMemoryMetric()]) {
                    let view = RegularVStackContainer(entries: entries)
                    _ = view.body
                }
            }

            // MARK: - CPU Time Tests (for comparison with wall clock)

            @MainActor
            func testInspectorSidebarCPUTime() {
                let entries = (0 ..< 20).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }
                let frontmatter = Frontmatter(
                    rawYAML: "",
                    entries: entries,
                    metadata: [:]
                )

                measure(metrics: [XCTCPUMetric()]) {
                    let view = InspectorSidebar(frontmatter: frontmatter, isPresented: .constant(true))
                    _ = view.body
                }
            }

            // MARK: - Storage Metric Tests (Disk I/O)

            @MainActor
            func testInspectorSidebarStorageImpact() {
                let entries = (0 ..< 20).map { i in
                    Frontmatter.Entry(
                        key: "key\(i)",
                        rawValue: "value\(i)",
                        typedValue: .text("value\(i)")
                    )
                }
                let frontmatter = Frontmatter(
                    rawYAML: "",
                    entries: entries,
                    metadata: [:]
                )

                measure(metrics: [XCTStorageMetric()]) {
                    let view = InspectorSidebar(frontmatter: frontmatter, isPresented: .constant(true))
                    _ = view.body
                }
            }
        }

        // MARK: - Test Helpers (matching ContentView implementation)

        /// Test helper matching the actual InspectorSidebar implementation
        private struct InspectorSidebar: View {
            let frontmatter: Frontmatter?
            @Binding var isPresented: Bool

            var body: some View {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Metadata")
                            .font(.headline)
                        Spacer()
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()

                    if let frontmatter {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(frontmatter.entries, id: \.key) { entry in
                                    MetadataRow(entry: entry)
                                }
                            }
                        }
                    } else {
                        EmptyMetadataState()
                    }
                }
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
            }
        }

        private struct MetadataRow: View {
            let entry: Frontmatter.Entry

            var body: some View {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.displayValue)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }

        private struct EmptyMetadataState: View {
            var body: some View {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tag.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No Metadata")
                        .font(.headline)
                    Text("This document has no YAML frontmatter")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }

        private struct StructuredMetadataView: View {
            let entries: [Frontmatter.Entry]

            var body: some View {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(entries, id: \.key) { entry in
                        MetadataRow(entry: entry)
                    }
                }
            }
        }

        // MARK: - VStack Comparison Containers

        private struct LazyVStackContainer: View {
            let entries: [Frontmatter.Entry]

            var body: some View {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(entries, id: \.key) { entry in
                        MetadataRow(entry: entry)
                    }
                }
            }
        }

        private struct RegularVStackContainer: View {
            let entries: [Frontmatter.Entry]

            var body: some View {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(entries, id: \.key) { entry in
                        MetadataRow(entry: entry)
                    }
                }
            }
        }
    #endif
#endif
