#if canImport(XCTest)
import XCTest
#if os(macOS)
@testable import mdviewer

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
            readableWidth: ReaderColumnWidth.balanced.points
        )

        let coldMs = await elapsedMillis {
            _ = await MarkdownRenderService.shared.render(base)
        }
        let warmMs = await elapsedMillis {
            _ = await MarkdownRenderService.shared.render(base)
        }

        let themeChanged = RenderRequest(
            markdown: markdown,
            readerFontFamily: .newYork,
            readerFontSize: 16,
            codeFontSize: 14,
            appTheme: .github,
            syntaxPalette: .midnight,
            colorScheme: .light,
            textSpacing: .balanced,
            readableWidth: ReaderColumnWidth.balanced.points
        )

        let themeSwitchMs = await elapsedMillis {
            _ = await MarkdownRenderService.shared.render(themeChanged)
        }

        XCTAssertLessThanOrEqual(coldMs, 150, "Cold render exceeded budget: \(coldMs) ms")
        XCTAssertLessThanOrEqual(warmMs, 35, "Warm render exceeded budget: \(warmMs) ms")
        XCTAssertLessThanOrEqual(themeSwitchMs, 80, "Theme switch render exceeded budget: \(themeSwitchMs) ms")
    }

    private func elapsedMillis(_ operation: @escaping () async -> Void) async -> Int {
        let start = Date()
        await operation()
        return Int(Date().timeIntervalSince(start) * 1000)
    }

    private func largeMarkdown(lines: Int) -> String {
        var blocks: [String] = []
        blocks.reserveCapacity(lines / 10)

        for i in 0..<(lines / 10) {
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
