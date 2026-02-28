//
//  MarkdownRendering.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Render Statistics

/// Snapshot of render-pipeline performance metrics.
///
/// Returned by ``MarkdownRendering/snapshotStats()`` to allow callers to monitor
/// cache efficiency without depending on the concrete service type.
struct RenderStats: Sendable {
    /// Number of times a render result was served from cache.
    var cacheHits: Int = 0
    /// Number of times a render required full pipeline processing.
    var cacheMisses: Int = 0
    /// Duration of the most recent render operation in milliseconds.
    var lastRenderDurationMs: Int = 0
}

// MARK: - Markdown Rendering Protocol

/// Protocol defining the interface for Markdown rendering services.
///
/// Implementations provide thread-safe, cached rendering of Markdown content
/// with support for themes, typography, and syntax highlighting.
///
/// ## Concurrency
/// All methods are actor-isolated and safe to call from any context.
///
/// ## Usage
/// ```swift
/// let renderer: MarkdownRendering = MarkdownRenderService.shared
/// let rendered = await renderer.render(request)
/// ```
protocol MarkdownRendering: Actor {
    /// Renders a Markdown document according to the provided request.
    ///
    /// - Parameter request: The render request containing markdown content and styling options
    /// - Returns: A rendered markdown result with attributed string
    func render(_ request: RenderRequest) -> RenderedMarkdown

    /// Returns a snapshot of current cache statistics for monitoring performance.
    ///
    /// - Returns: A ``RenderStats`` value with cache hits, misses, and last duration
    func snapshotStats() -> RenderStats
}
