//
//  MarkdownRenderService.swift
//  mdviewer
//

internal import Foundation
internal import os.signpost
internal import OSLog
internal import SwiftUI

#if os(macOS)
    internal import AppKit

    // MARK: - ParsedMarkdownStructure

    /// Cached intermediate representation of parsed markdown structure.
    /// Contains the parsed attributed string with block separators injected,
    /// but before theme-specific colors are applied. This enables sharing
    /// parsed structure across windows and theme changes.
    final class ParsedMarkdownStructure {
        let attributedString: NSAttributedString
        let timestamp: Date

        init(attributedString: NSAttributedString, timestamp: Date = Date()) {
            self.attributedString = attributedString
            self.timestamp = timestamp
        }
    }

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

        // MARK: - Dependencies

        private let parser: MarkdownParsing
        private let blockSeparatorInjector: BlockSeparatorInjecting
        private let typographyApplier: TypographyApplying
        private let syntaxHighlighter: SyntaxHighlighting
        private let mermaidRenderer: MermaidDiagramRenderer

        // MARK: - Internal State

        private let logger = Logger(subsystem: "mdviewer", category: "render")
        private let signpostLog = OSLog(subsystem: "mdviewer", category: "render-signpost")
        /// Cache for fully-rendered markdown (including theme colors)
        private let cache: NSCache<NSString, RenderedMarkdown>
        /// Cache for parsed markdown structure (theme-agnostic, reusable across theme changes)
        private let structureCache: NSCache<NSString, ParsedMarkdownStructure>
        private var stats = RenderStats()
        private var hasPrewarmed = false

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
            syntaxHighlighter: SyntaxHighlighting = SyntaxHighlighter(),
            mermaidRenderer: MermaidDiagramRenderer = MermaidDiagramRenderer()
        ) {
            self.parser = parser
            self.blockSeparatorInjector = blockSeparatorInjector
            self.typographyApplier = typographyApplier
            self.syntaxHighlighter = syntaxHighlighter
            self.mermaidRenderer = mermaidRenderer

            // Configure themed cache with 32-item limit and 20MB cost limit
            let cache = NSCache<NSString, RenderedMarkdown>()
            cache.countLimit = 32
            cache.totalCostLimit = 20 * 1024 * 1024
            self.cache = cache

            // Configure structure cache for theme-agnostic parsed content
            // Larger count limit since these are reusable across themes
            let structureCache = NSCache<NSString, ParsedMarkdownStructure>()
            structureCache.countLimit = 64
            structureCache.totalCostLimit = 30 * 1024 * 1024
            self.structureCache = structureCache

            logger.debug("MarkdownRenderService initialized with pipeline components")
        }

        // MARK: - MarkdownRendering Protocol

        /// Renders a Markdown document according to the provided request.
        ///
        /// Uses a two-tier caching strategy:
        /// 1. Themed cache: Full render results with theme colors (fastest)
        /// 2. Structure cache: Parsed markdown without theme colors (reusable across themes)
        ///
        /// - Parameter request: The render request containing markdown content and styling options
        /// - Returns: A rendered markdown result with attributed string
        func render(_ request: RenderRequest) -> RenderedMarkdown {
            // Tier 1: Check themed cache first (includes theme colors)
            let cacheKey = NSString(string: request.cacheKey)
            if let cached = cache.object(forKey: cacheKey) {
                stats.cacheHits += 1
                logger.debug("Themed cache hit for key: \(String(request.cacheKey.prefix(8)), privacy: .public)...")
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

            // Tier 2: Try to reuse parsed structure from theme-agnostic cache
            let structureKey = NSString(string: request.structureCacheKey)
            let mutable: NSMutableAttributedString

            if let cachedStructure = structureCache.object(forKey: structureKey) {
                // Reuse cached structure and apply theme colors
                os_signpost(.begin, log: signpostLog, name: "ApplyThemeToStructure", signpostID: signpostID)
                mutable = NSMutableAttributedString(attributedString: cachedStructure.attributedString)
                applyTypographyAndStyling(to: mutable, request: request)
                os_signpost(.end, log: signpostLog, name: "ApplyThemeToStructure", signpostID: signpostID)
                logger.debug("Structure cache hit, applying theme colors only")
            } else {
                // Cold render: build the theme-agnostic structure once, cache it,
                // then style a mutable copy for the current request.
                let structureToCache = executeStructureOnlyPipeline(request: request)
                structureCache.setObject(
                    ParsedMarkdownStructure(attributedString: structureToCache),
                    forKey: structureKey,
                    cost: structureToCache.length * MemoryLayout<unichar>.size
                )
                mutable = NSMutableAttributedString(attributedString: structureToCache)
                applyTypographyAndStyling(to: mutable, request: request)
            }

            // End performance tracking
            os_signpost(.end, log: signpostLog, name: "MarkdownRender", signpostID: signpostID)
            let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
            stats.lastRenderDurationMs = elapsedMs

            // Create and cache themed result
            let rendered = RenderedMarkdown(attributedString: mutable)
            let cost = mutable.length * MemoryLayout<unichar>.size
            cache.setObject(rendered, forKey: cacheKey, cost: cost)

            logger
                .debug(
                    "Rendered markdown chars=\(request.markdown.count, privacy: .public) elapsedMs=\(elapsedMs, privacy: .public) cacheSize=\(cost, privacy: .public)"
                )

            return rendered
        }

        /// Returns a snapshot of current cache statistics for monitoring performance.
        ///
        /// - Returns: A ``RenderStats`` value with cache hits, misses, and last duration
        func snapshotStats() -> RenderStats {
            stats
        }

        /// Warms the render pipeline without polluting render statistics.
        ///
        /// This primes parser, layout, typography, and syntax highlighting code paths so
        /// the first real document render does less cold-start work on the critical path.
        func prewarm() {
            guard !hasPrewarmed else { return }
            hasPrewarmed = true

            let warmupRequest = RenderRequest(
                markdown: """
                ## Warmup

                ```swift
                let warmup = true
                ```
                """,
                readerFontFamily: .newYork,
                readerFontSize: ReaderFontSize.standard.points,
                codeFontSize: CodeFontSize.medium.points,
                appTheme: .basic,
                colorScheme: .light,
                textSpacing: .balanced,
                readableWidth: ReaderColumnWidth.balanced.points,
                showLineNumbers: false,
                typographyPreferences: TypographyPreferences()
            )

            let structure = executeStructureOnlyPipeline(request: warmupRequest)
            let mutable = NSMutableAttributedString(attributedString: structure)
            applyTypographyAndStyling(to: mutable, request: warmupRequest)
            logger.debug("MarkdownRenderService prewarm completed")
        }

        // MARK: - Private Methods

        /// Applies code-specific styling and syntax highlighting.
        ///
        /// - Parameters:
        ///   - text: The attributed string to modify
        ///   - request: The render request containing code styling preferences
        private func applyCodeStyling(_ text: NSMutableAttributedString, request: RenderRequest) {
            let syntax = request.appTheme.nativeSyntax
            let fullRange = NSRange(location: 0, length: text.length)
            // SyntaxHighlighter already discovers code block subranges (and languages) from
            // presentation intents. Calling it once over the full text avoids a redundant
            // pre-scan and temporary range allocation on every render.
            syntaxHighlighter.highlight(text, in: fullRange, syntax: syntax)
        }

        /// Applies typography and styling to a pre-parsed attributed string.
        /// Used when reusing cached structure for theme changes.
        private func applyTypographyAndStyling(to mutable: NSMutableAttributedString, request: RenderRequest) {
            let pipelineSignpostID = OSSignpostID(log: signpostLog)

            os_signpost(.begin, log: signpostLog, name: "ApplyTypography", signpostID: pipelineSignpostID)
            typographyApplier.applyTypography(to: mutable, request: request)
            os_signpost(.end, log: signpostLog, name: "ApplyTypography", signpostID: pipelineSignpostID)

            os_signpost(.begin, log: signpostLog, name: "ApplyCodeStyling", signpostID: pipelineSignpostID)
            applyCodeStyling(mutable, request: request)
            os_signpost(.end, log: signpostLog, name: "ApplyCodeStyling", signpostID: pipelineSignpostID)

            // Mermaid pass runs last
            os_signpost(.begin, log: signpostLog, name: "RenderMermaid", signpostID: pipelineSignpostID)
            mermaidRenderer.renderDiagrams(in: mutable, request: request)
            os_signpost(.end, log: signpostLog, name: "RenderMermaid", signpostID: pipelineSignpostID)
        }

        /// Executes only the parsing and block separator injection phases.
        /// Returns an attributed string ready for theme-specific styling.
        private func executeStructureOnlyPipeline(request: RenderRequest) -> NSAttributedString {
            let parsedMarkdown = FrontmatterParser.parse(request.markdown)
            let markdownToRender = parsedMarkdown.renderedMarkdown

            // Parse markdown to attributed string
            let parsed: NSAttributedString
            do {
                parsed = try parser.parse(markdownToRender)
            } catch {
                logger.error("Markdown parsing failed: \(error.localizedDescription)")
                return NSAttributedString(string: markdownToRender)
            }

            let mutable = NSMutableAttributedString(attributedString: parsed)

            // Inject block separators (theme-agnostic)
            let signpostID = OSSignpostID(log: signpostLog)
            os_signpost(.begin, log: signpostLog, name: "InjectSeparators", signpostID: signpostID)
            blockSeparatorInjector.injectSeparators(into: mutable)
            os_signpost(.end, log: signpostLog, name: "InjectSeparators", signpostID: signpostID)

            return mutable
        }

        // MARK: - Testing Support

        /// Resets the service state for testing.
        ///
        /// Clears both caches and resets statistics.
        func resetForTesting() {
            cache.removeAllObjects()
            structureCache.removeAllObjects()
            stats = RenderStats()
            hasPrewarmed = false
            logger.debug("Service reset for testing")
        }
    }

#endif
