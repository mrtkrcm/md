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
internal import SwiftUI

// MARK: - MermaidDiagramRenderer

/// Post-pipeline pass that converts mermaid code blocks to inline diagram images.
///
/// Must run after `TypographyApplier` and `SyntaxHighlighter` because it replaces
/// ranges in the attributed string; any subsequent text-based pass would operate
/// on the attachment character instead of the original code text.
struct MermaidDiagramRenderer {
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
        do {
            // Use the default scale (2x Retina). Width is constrained via attachment
            // bounds in attachmentString(for:containerWidth:) after rendering.
            return try MermaidRenderer.renderImage(source: source, theme: theme)
        } catch {
            // Fall through — the raw code block remains visible.
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
        let maxWidth = containerWidth - 32
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
        style.paragraphSpacing = 12
        style.paragraphSpacingBefore = 12
        style.firstLineHeadIndent = 16
        style.headIndent = 16
        result.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: result.length))

        return result
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
        }
    }
}
