//
//  RendererPerformanceTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        @testable internal import mdviewer

        final class RendererPerformanceTests: XCTestCase {
            func testRenderBudgetsForLargeDocument() async throws {
                if ProcessInfo.processInfo.environment["CI"] != nil {
                    throw XCTSkip("Performance budgets are advisory; skipped on shared CI runners.")
                }

                await MarkdownRenderService.shared.resetForTesting()

                let markdown = largeMarkdown(lines: 5_000)
                let base = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    syntaxPalette: .midnight,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false
                )

                // Cold render: first render, no cache entry.
                let coldMs = await elapsedMillis {
                    _ = await MarkdownRenderService.shared.render(base)
                }

                // Warm render: identical request — must be served from cache.
                let warmMs = await elapsedMillis {
                    _ = await MarkdownRenderService.shared.render(base)
                }

                // Budgets target debug binaries. Cold is a full 5 000-line attribution pass under
                // potential CPU contention (e.g., parallel swift build); warm is a pure cache lookup.
                // The ceiling is intentionally generous — it catches genuine regressions (>400 ms
                // indicates something structurally broken) while tolerating build-time CPU competition.
                XCTAssertLessThanOrEqual(coldMs, 400, "Cold render exceeded budget: \(coldMs) ms")
                XCTAssertLessThanOrEqual(warmMs, 35, "Warm (cache-hit) render exceeded budget: \(warmMs) ms")

                // Verify the warm hit was actually served from cache.
                let stats = await MarkdownRenderService.shared.snapshotStats()
                XCTAssertGreaterThanOrEqual(stats.cacheHits, 1, "Warm render should have been a cache hit")
            }

            private func elapsedMillis(_ operation: @escaping () async -> Void) async -> Int {
                let start = Date()
                await operation()
                return Int(Date().timeIntervalSince(start) * 1000)
            }

            private func largeMarkdown(lines: Int) -> String {
                var blocks: [String] = []
                blocks.reserveCapacity(lines / 10)

                for i in 0 ..< (lines / 10) {
                    blocks.append(
                        """
                        ## Section \(i)
                        Paragraph line with **bold** and _italic_.
                        ```swift
                        struct Item\(i) { let value = \(i) }
                        // inline comment \(i)
                        ```
                        """
                    )
                }

                return blocks.joined(separator: "\n\n")
            }
        }
    #endif
#endif
