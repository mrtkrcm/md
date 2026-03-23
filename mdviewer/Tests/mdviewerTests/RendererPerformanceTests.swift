//
//  RendererPerformanceTests.swift
//  mdviewer
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        @testable internal import mdviewer

        final class RendererPerformanceTests: XCTestCase {
            func testPrewarmDoesNotPolluteRenderStats() async {
                await MarkdownRenderService.shared.resetForTesting()

                await MarkdownRenderService.shared.prewarm()
                let stats = await MarkdownRenderService.shared.snapshotStats()

                XCTAssertEqual(stats.cacheHits, 0, "Prewarm should not count as a cache hit")
                XCTAssertEqual(stats.cacheMisses, 0, "Prewarm should not count as a render miss")
                XCTAssertEqual(stats.lastRenderDurationMs, 0, "Prewarm should not overwrite measured render stats")
            }

            func testRenderBudgetsForLargeDocument() async throws {
                if ProcessInfo.processInfo.environment["CI"] != nil {
                    throw XCTSkip("Performance budgets are advisory; skipped on shared CI runners.")
                }

                await MarkdownRenderService.shared.resetForTesting()

                let markdown = largeMarkdown(lines: 5000)
                let base = RenderRequest(
                    markdown: markdown,
                    readerFontFamily: .newYork,
                    readerFontSize: 16,
                    codeFontSize: 14,
                    appTheme: .basic,
                    colorScheme: .light,
                    textSpacing: .balanced,
                    readableWidth: ReaderColumnWidth.balanced.points,
                    showLineNumbers: false,
                    typographyPreferences: TypographyPreferences()
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
                // The ceiling is intentionally generous and tuned for the current code-path.
                XCTAssertLessThanOrEqual(coldMs, 650, "Cold render exceeded budget: \(coldMs) ms")
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
