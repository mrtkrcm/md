//
//  MarkdownRenderService.swift
//  mdviewer
//

internal import Foundation
internal import OSLog
internal import os.signpost
internal import SwiftUI

#if os(macOS)
    @preconcurrency internal import AppKit

    // MARK: - MarkdownRenderService

    /// Renders Markdown text into attributed strings with syntax highlighting and theming.
    ///
    /// This actor provides a thread-safe, cached rendering pipeline for Markdown content.
    /// It orchestrates multiple pipeline stages: parsing, typography application, code styling,
    /// and syntax highlighting.
    ///
    /// ## Usage
    /// ```swift
    /// let service = MarkdownRenderService.shared
    /// let rendered = await service.render(request)
    /// ```
    ///
    /// ## Architecture
    /// The service uses a pipeline architecture with injectable components:
    /// - `parser`: Converts raw Markdown to attributed strings
    /// - `blockSeparatorInjector`: Adds visual separators between blocks
    /// - `typographyApplier`: Applies fonts, colors, and spacing
    /// - `syntaxHighlighter`: Highlights code blocks
    ///
    /// ## Thread Safety
    /// All methods are actor-isolated and safe to call from any context.
    actor MarkdownRenderService: MarkdownRendering {
        /// Shared singleton instance.
        ///
        /// Use this for standard rendering throughout the app.
        static let shared = MarkdownRenderService()

        /// Statistics for monitoring render performance.
        struct Stats: Sendable {
            /// Number of times a render result was served from cache
            var cacheHits: Int = 0
            /// Number of times a render required full processing
            var cacheMisses: Int = 0
            /// Duration of the last render operation in milliseconds
            var lastRenderDurationMs: Int = 0
        }

        // MARK: - Dependencies

        private let parser: MarkdownParsing
        private let blockSeparatorInjector: BlockSeparatorInjecting
        private let typographyApplier: TypographyApplying
        private let syntaxHighlighter: SyntaxHighlighting

        // MARK: - Internal State

        private let logger = Logger(subsystem: "mdviewer", category: "render")
        private let signpostLog = OSLog(subsystem: "mdviewer", category: "render-signpost")
        private let cache: NSCache<NSString, RenderedMarkdown>
        private var stats = Stats()

        // MARK: - Initialization

        /// Creates a new render service with the specified pipeline components.
        ///
        /// - Parameters:
        ///   - parser: Component for parsing Markdown (default: `MarkdownParser()`)
        ///   - blockSeparatorInjector: Component for injecting block separators (default: `BlockSeparatorInjector()`)
        ///   - typographyApplier: Component for applying typography (default: `TypographyApplier()`)
        ///   - syntaxHighlighter: Component for syntax highlighting (default: `SyntaxHighlighter()`)
        init(
            parser: MarkdownParsing = MarkdownParser(),
            blockSeparatorInjector: BlockSeparatorInjecting = BlockSeparatorInjector(),
            typographyApplier: TypographyApplying = TypographyApplier(),
            syntaxHighlighter: SyntaxHighlighting = SyntaxHighlighter()
        ) {
            self.parser = parser
            self.blockSeparatorInjector = blockSeparatorInjector
            self.typographyApplier = typographyApplier
            self.syntaxHighlighter = syntaxHighlighter

            // Configure cache with 32-item limit and 20MB cost limit
            let cache = NSCache<NSString, RenderedMarkdown>()
            cache.countLimit = 32
            cache.totalCostLimit = 20 * 1024 * 1024
            self.cache = cache

            logger.debug("MarkdownRenderService initialized with pipeline components")
        }

        // MARK: - MarkdownRendering Protocol

        /// Renders a Markdown document according to the provided request.
        ///
        /// - Parameter request: The render request containing markdown content and styling options
        /// - Returns: A rendered markdown result with attributed string
        func render(_ request: RenderRequest) -> RenderedMarkdown {
            // Check cache first
            let cacheKey = NSString(string: request.cacheKey)
            if let cached = cache.object(forKey: cacheKey) {
                stats.cacheHits += 1
                logger
                    .debug("Cache hit for key: \(cacheKey.substring(to: min(8, cacheKey.length)), privacy: .public)...")
                return cached
            }
            stats.cacheMisses += 1

            // Begin performance tracking
            let signpostID = OSSignpostID(log: signpostLog)
            os_signpost(
                .begin,
                log: signpostLog,
                name: "MarkdownRender",
                signpostID: signpostID,
                "chars=%d",
                request.markdown.utf8.count
            )
            let start = Date()

            // Execute render pipeline
            let mutable = executeRenderPipeline(request: request)

            // End performance tracking
            os_signpost(.end, log: signpostLog, name: "MarkdownRender", signpostID: signpostID)
            let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
            stats.lastRenderDurationMs = elapsedMs

            // Create and cache result
            let rendered = RenderedMarkdown(attributedString: mutable)
            let cost = mutable.length * MemoryLayout<unichar>.size
            cache.setObject(rendered, forKey: cacheKey, cost: cost)

            logger
                .debug(
                    "Rendered markdown chars=\(request.markdown.count, privacy: .public) elapsedMs=\(elapsedMs, privacy: .public) cacheSize=\(cost, privacy: .public)"
                )

            return rendered
        }

        /// Returns current cache statistics for monitoring performance.
        ///
        /// - Returns: Statistics including cache hits, misses
        func snapshotStats() -> Stats {
            stats
        }

        // MARK: - Private Methods

        /// Executes the full render pipeline for a request.
        ///
        /// - Parameter request: The render request
        /// - Returns: A mutable attributed string with all styling applied
        private func executeRenderPipeline(request: RenderRequest) -> NSMutableAttributedString {
            // Parse frontmatter first to strip it from rendered output
            let parsedMarkdown = FrontmatterParser.parse(request.markdown)
            let markdownToRender = parsedMarkdown.renderedMarkdown

            // Parse markdown to attributed string
            let parsed: NSAttributedString
            do {
                parsed = try parser.parse(markdownToRender)
            } catch {
                logger.error("Markdown parsing failed: \(error.localizedDescription)")
                parsed = NSAttributedString(string: markdownToRender)
            }

            let mutable = NSMutableAttributedString(attributedString: parsed)

            // Apply pipeline stages
            blockSeparatorInjector.injectSeparators(into: mutable)
            typographyApplier.applyTypography(to: mutable, request: request)
            applyCodeStyling(mutable, request: request)

            return mutable
        }

        /// Applies code-specific styling and syntax highlighting.
        ///
        /// - Parameters:
        ///   - text: The attributed string to modify
        ///   - request: The render request containing code styling preferences
        private func applyCodeStyling(_ text: NSMutableAttributedString, request: RenderRequest) {
            let syntax = request.syntaxPalette.nativeSyntax
            let fullRange = NSRange(location: 0, length: text.length)

            // Collect code block ranges first
            var codeBlockRanges: [NSRange] = []
            text.enumerateAttribute(
                MarkdownRenderAttribute.presentationIntent,
                in: fullRange,
                options: []
            ) { value, range, _ in
                guard let intent = value as? PresentationIntent else { return }

                for component in intent.components {
                    if case .codeBlock = component.kind {
                        codeBlockRanges.append(range)
                    }
                }
            }

            // Apply highlighting to collected ranges
            for range in codeBlockRanges {
                syntaxHighlighter.highlight(text, in: range, syntax: syntax)
            }
        }

        // MARK: - Testing Support

        /// Resets the service state for testing.
        ///
        /// Clears the cache and resets statistics.
        func resetForTesting() {
            cache.removeAllObjects()
            stats = Stats()
            logger.debug("Service reset for testing")
        }
    }

#endif
