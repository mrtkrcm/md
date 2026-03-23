//
//  MermaidDiagramRenderer.swift
//  mdviewer
//
//  Detects fenced code blocks with language "mermaid", renders each one to an
//  NSImage via BeautifulMermaid, and replaces the block in the attributed string
//  with an NSTextAttachment so the diagram appears inline in the reader view.
//

internal import AppKit
internal import BeautifulMermaid
internal import OSLog
internal import SwiftUI

// MARK: - MermaidDiagramRenderer

/// Post-pipeline pass that converts mermaid code blocks to inline diagram images.
///
/// Must run after `TypographyApplier` and `SyntaxHighlighter` because it replaces
/// ranges in the attributed string; any subsequent text-based pass would operate
/// on the attachment character instead of the original code text.
struct MermaidDiagramRenderer {
    private static let logger = Logger(subsystem: "mdviewer", category: "mermaid-render")
    private static let imageCache = MermaidImageCache()

    private enum Layout {
        static let horizontalInset = DesignTokens.Spacing.extraWide
        static let verticalBlockSpacing = DesignTokens.Spacing.relaxed
    }

    // MARK: - Public Interface

    /// Scans `text` for fenced code blocks tagged with language "mermaid" and
    /// replaces each one with a rendered `NSTextAttachment` image.
    ///
    /// Replacement is done back-to-front so earlier character offsets stay valid
    /// while later ranges are being removed.
    ///
    /// - Parameters:
    ///   - text: The attributed string produced by the render pipeline.
    ///   - request: The current render request (used for theme and container width).
    func renderDiagrams(in text: NSMutableAttributedString, request: RenderRequest) {
        let theme = diagramTheme(for: request.appTheme, scheme: request.colorScheme)
        let blocks = collectMermaidBlocks(in: text)
        guard !blocks.isEmpty else { return }

        // Replace back-to-front to preserve valid ranges for earlier blocks.
        for (range, source) in blocks.reversed() {
            guard let image = render(source: source, theme: theme, containerWidth: request.readableWidth)
            else { continue }
            let replacement = attachmentString(for: image, containerWidth: request.readableWidth)
            text.replaceCharacters(in: range, with: replacement)
        }
    }

    // MARK: - Block Detection

    /// Returns all mermaid code-block ranges and their source text, in document order.
    private func collectMermaidBlocks(
        in text: NSAttributedString
    ) -> [(range: NSRange, source: String)] {
        var results: [(NSRange, String)] = []
        let fullRange = NSRange(location: 0, length: text.length)

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, intentRange, _ in
            guard
                let intent = value as? PresentationIntent,
                intent.components.contains(where: {
                    if case .codeBlock(let lang) = $0.kind {
                        return lang?.lowercased() == "mermaid"
                    }
                    return false
                })
            else { return }

            let source = (text.string as NSString).substring(with: intentRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !source.isEmpty else { return }

            results.append((intentRange, source))
        }

        return results
    }

    // MARK: - Rendering

    /// Renders a mermaid diagram source string to an NSImage.
    ///
    /// Returns `nil` and logs a warning if BeautifulMermaid cannot parse or
    /// render the source, allowing the caller to leave the raw code block visible.
    private func render(
        source: String,
        theme: DiagramTheme,
        containerWidth: CGFloat
    ) -> NSImage? {
        let cacheKey = cacheKey(for: source, theme: theme)
        if let cached = Self.imageCache.object(forKey: cacheKey as NSString) {
            return cached
        }

        do {
            // Use the default scale (2x Retina). Width is constrained via attachment
            // bounds in attachmentString(for:containerWidth:) after rendering.
            guard let image = try MermaidRenderer.renderImage(source: source, theme: theme) else {
                Self.logger.warning("Mermaid render returned no image")
                return nil
            }
            Self.imageCache.setObject(image, forKey: cacheKey as NSString)
            return image
        } catch {
            Self.logger.warning("Mermaid render failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Attachment Construction

    /// Wraps an NSImage in a paragraph-style-aware NSTextAttachment string, inset
    /// to match the table/blockquote margin convention (16pt on each side).
    private func attachmentString(
        for image: NSImage,
        containerWidth: CGFloat
    ) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image

        // Always set explicit bounds so NSLayoutManager allocates correct vertical
        // space for the image. Without explicit bounds, NSTextAttachment defaults to
        // CGRect.zero which causes the layout manager to clip tall images at the
        // bottom of the line fragment (mermaid diagrams can be several hundred points
        // tall). Scale down if wider than the readable column, preserve aspect ratio.
        let maxWidth = max(0, containerWidth - (Layout.horizontalInset * 2))
        let scale: CGFloat = image.size.width > maxWidth ? maxWidth / image.size.width : 1.0
        attachment.bounds = CGRect(
            x: 0, y: 0,
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let result = NSMutableAttributedString(attachment: attachment)

        // Wrap with a paragraph style that adds breathing room above and below
        // the diagram, matching the vertical rhythm of other block elements.
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = Layout.verticalBlockSpacing
        style.paragraphSpacingBefore = Layout.verticalBlockSpacing
        style.firstLineHeadIndent = Layout.horizontalInset
        style.headIndent = Layout.horizontalInset
        result.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: result.length))

        return result
    }

    private func cacheKey(for source: String, theme: DiagramTheme) -> String {
        let themeIdentifier = String(describing: theme)
        return "\(themeIdentifier)::\(source.hashValue)"
    }

    // MARK: - Theme Mapping

    /// Maps an `AppTheme` + `ColorScheme` pair to the closest `DiagramTheme` preset.
    ///
    /// Every mdviewer theme has a direct counterpart in BeautifulMermaid's built-in
    /// theme catalogue. Dark variants are used when `scheme == .dark`; otherwise
    /// the light variant is selected. Themes without a distinct light/dark split
    /// (dracula, monokai) always use their canonical colour set regardless of scheme.
    private func diagramTheme(for appTheme: AppTheme, scheme: ColorScheme) -> DiagramTheme {
        switch appTheme {
        case .basic:
            return scheme == .dark ? .zincDark : .zincLight
        case .github:
            return scheme == .dark ? .githubDark : .githubLight
        case .docC:
            return scheme == .dark ? .zincDark : .zincLight
        case .solarized:
            return scheme == .dark ? .solarizedDark : .solarizedLight
        case .gruvbox:
            return scheme == .dark ? .gruvboxDark : .gruvboxLight
        case .dracula:
            return .dracula
        case .monokai:
            return scheme == .dark ? .oneDark : .zincLight
        case .nord:
            return scheme == .dark ? .nord : .nordLight
        case .onedark:
            return scheme == .dark ? .oneDark : .zincLight
        case .tokyonight:
            return scheme == .dark ? .tokyoNight : .tokyoNightLight
        case .catppuccin:
            return scheme == .dark ? .nord : .zincLight
        case .rosepine:
            return scheme == .dark ? .nord : .zincLight
        }
    }
}

private final class MermaidImageCache: @unchecked Sendable {
    private let cache = NSCache<NSString, NSImage>()

    init() {
        cache.countLimit = Self.countLimit
        cache.totalCostLimit = Self.totalCostLimit
    }

    func object(forKey key: NSString) -> NSImage? {
        cache.object(forKey: key)
    }

    func setObject(_ image: NSImage, forKey key: NSString) {
        cache.setObject(image, forKey: key, cost: imageCost(for: image))
    }

    private func imageCost(for image: NSImage) -> Int {
        if let data = image.tiffRepresentation {
            return data.count
        }
        let width = max(1, Int(image.size.width))
        let height = max(1, Int(image.size.height))
        return width * height * 4
    }

    private static var countLimit: Int {
        let envValue = ProcessInfo.processInfo.environment["MDVIEWER_MERMAID_CACHE_COUNT_LIMIT"]
        if let envValue, let parsed = Int(envValue), parsed > 0 {
            return parsed
        }
        return 64
    }

    private static var totalCostLimit: Int {
        let envValue = ProcessInfo.processInfo.environment["MDVIEWER_MERMAID_CACHE_TOTAL_COST_MB"]
        if let envValue, let parsed = Int(envValue), parsed > 0 {
            return parsed * 1024 * 1024
        }
        return 24 * 1024 * 1024
    }
}
