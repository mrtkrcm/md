import SwiftUI
import CryptoKit
import Foundation
import OSLog
import os.log
import os.signpost
#if os(macOS)
@preconcurrency import AppKit

struct NativeMarkdownTextView: NSViewRepresentable {
    let markdown: String
    let readerFontFamily: ReaderFontFamily
    let readerFontSize: CGFloat
    let codeFontSize: CGFloat
    let appTheme: AppTheme
    let syntaxPalette: SyntaxPalette
    let colorScheme: ColorScheme

    func makeNSView(context: Context) -> NSScrollView {
        let textView = ReaderTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.focusRingType = .none
        textView.usesFindBar = true
        textView.isRichText = true
        textView.allowsUndo = false
        textView.textContainerInset = NSSize(width: 24, height: 24)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.focusRingType = .none
        scrollView.wantsLayer = true
        scrollView.layer?.borderWidth = 0
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        let request = RenderRequest(
            markdown: markdown,
            readerFontFamily: readerFontFamily,
            readerFontSize: readerFontSize,
            codeFontSize: codeFontSize,
            appTheme: appTheme,
            syntaxPalette: syntaxPalette,
            colorScheme: colorScheme
        )

        let coordinator = context.coordinator
        guard coordinator.currentRequest != request else { return }

        coordinator.currentRequest = request
        coordinator.generation += 1
        let generation = coordinator.generation
        coordinator.renderTask?.cancel()

        coordinator.renderTask = Task { @MainActor [weak textView] in
            let rendered = await MarkdownRenderService.shared.render(request)
            guard !Task.isCancelled else { return }
            guard
                coordinator.generation == generation,
                coordinator.currentRequest == request,
                let textView
            else { return }

            textView.textStorage?.setAttributedString(rendered.attributedString)
        }
    }

    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        coordinator.renderTask?.cancel()
        coordinator.renderTask = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        var currentRequest: RenderRequest?
        var generation: Int = 0
        var renderTask: Task<Void, Never>?
    }
}

private final class ReaderTextView: NSTextView {
    private let maxReadableWidth: CGFloat = 760
    private let minimumHorizontalInset: CGFloat = 24

    override func layout() {
        super.layout()

        guard let textContainer else { return }
        let availableWidth = bounds.width
        let targetWidth = min(maxReadableWidth, max(0, availableWidth - (minimumHorizontalInset * 2)))
        let horizontalInset = max(minimumHorizontalInset, (availableWidth - targetWidth) / 2)

        textContainer.containerSize = NSSize(
            width: targetWidth,
            height: .greatestFiniteMagnitude
        )
        textContainerInset = NSSize(width: horizontalInset, height: 24)
    }
}

struct RenderRequest: Hashable, Sendable {
    let markdown: String
    let readerFontFamily: ReaderFontFamily
    let readerFontSize: CGFloat
    let codeFontSize: CGFloat
    let appTheme: AppTheme
    let syntaxPalette: SyntaxPalette
    let colorScheme: ColorScheme

    var cacheKey: String {
        let payload = [
            markdown,
            readerFontFamily.rawValue,
            String(format: "%.2f", readerFontSize),
            String(format: "%.2f", codeFontSize),
            appTheme.rawValue,
            syntaxPalette.rawValue,
            colorScheme == .dark ? "dark" : "light"
        ].joined(separator: "|")

        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

final class RenderedMarkdown: @unchecked Sendable {
    let attributedString: NSAttributedString

    init(attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }
}

actor MarkdownRenderService {
    static let shared = MarkdownRenderService()

    struct Stats: Sendable {
        var cacheHits: Int = 0
        var cacheMisses: Int = 0
        var lastRenderDurationMs: Int = 0
    }

    private struct SyntaxRule {
        let regex: NSRegularExpression
        let color: (NativeSyntaxStyle) -> NSColor
    }

    private let logger = Logger(subsystem: "mdviewer", category: "render")
    private let signpostLog = OSLog(subsystem: "mdviewer", category: "render-signpost")
    private let textBlocksKey = NSAttributedString.Key("NSAttributedStringTextBlocks")

    private let cache: NSCache<NSString, RenderedMarkdown>
    private let syntaxRules: [SyntaxRule]
    private let stringRegex: NSRegularExpression?
    private let lineCommentRegex: NSRegularExpression?
    private let blockCommentRegex: NSRegularExpression?
    private var stats = Stats()

    init() {
        let cache = NSCache<NSString, RenderedMarkdown>()
        cache.countLimit = 32
        cache.totalCostLimit = 20 * 1024 * 1024
        self.cache = cache

        var builtRules: [SyntaxRule] = []
        if let regex = try? NSRegularExpression(pattern: #"\b(let|var|func|struct|class|enum|protocol|extension|import|if|else|for|while|guard|switch|case|default|return|throw|throws|try|catch|in|where|async|await|actor|defer|do|repeat|break|continue|fallthrough|typealias|associatedtype|some|any|mutating|nonmutating|init|deinit|subscript|static|final|private|fileprivate|internal|public|open)\b"#) {
            builtRules.append(SyntaxRule(regex: regex, color: { $0.keyword }))
        }
        if let regex = try? NSRegularExpression(pattern: #"\b(0x[0-9A-Fa-f]+|[0-9]+(?:\.[0-9]+)?)\b"#) {
            builtRules.append(SyntaxRule(regex: regex, color: { $0.number }))
        }
        if let regex = try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]+)\b"#) {
            builtRules.append(SyntaxRule(regex: regex, color: { $0.type }))
        }
        if let regex = try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#) {
            builtRules.append(SyntaxRule(regex: regex, color: { $0.call }))
        }

        let stringRegex = try? NSRegularExpression(pattern: #""([^"\\]|\\.)*""#)
        let lineCommentRegex = try? NSRegularExpression(pattern: #"//.*"#, options: [.anchorsMatchLines])
        let blockCommentRegex = try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#)

        syntaxRules = builtRules
        self.stringRegex = stringRegex
        self.lineCommentRegex = lineCommentRegex
        self.blockCommentRegex = blockCommentRegex

        if stringRegex == nil || lineCommentRegex == nil || blockCommentRegex == nil || builtRules.isEmpty {
            logger.error("Renderer regex initialization was partial. Some highlighting rules are disabled.")
        }
    }

    func render(_ request: RenderRequest) -> RenderedMarkdown {
        let cacheKey = NSString(string: request.cacheKey)
        if let cached = cache.object(forKey: cacheKey) {
            stats.cacheHits += 1
            return cached
        }
        stats.cacheMisses += 1

        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "MarkdownRender", signpostID: signpostID, "chars=%d", request.markdown.utf8.count)
        let start = Date()

        let parsed = parseMarkdown(request.markdown)
        let mutable = NSMutableAttributedString(attributedString: parsed)
        applyTypography(mutable, request: request)
        applyCodeStyling(mutable, request: request)

        os_signpost(.end, log: signpostLog, name: "MarkdownRender", signpostID: signpostID)
        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
        stats.lastRenderDurationMs = elapsedMs
        logger.debug("Rendered markdown chars=\(request.markdown.count, privacy: .public) elapsedMs=\(elapsedMs, privacy: .public)")

        let rendered = RenderedMarkdown(attributedString: mutable)
        cache.setObject(rendered, forKey: cacheKey, cost: mutable.length * 2)
        return rendered
    }

    func snapshotStats() -> Stats {
        stats
    }

    func resetForTesting() {
        cache.removeAllObjects()
        stats = Stats()
    }

    private func parseMarkdown(_ markdown: String) -> NSAttributedString {
        let parsed = FrontmatterParser.parse(markdown)
        return (try? NSAttributedString(
            markdown: Data(parsed.renderedMarkdown.utf8),
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            ),
            baseURL: nil
        )) ?? NSAttributedString(string: parsed.renderedMarkdown)
    }

    private func applyTypography(_ text: NSMutableAttributedString, request: RenderRequest) {
        let fullRange = NSRange(location: 0, length: text.length)
        let palette = NativeThemePalette(theme: request.appTheme, scheme: request.colorScheme)

        text.removeAttribute(textBlocksKey, range: fullRange)

        text.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            let existing = (value as? NSFont) ?? NSFont.systemFont(ofSize: request.readerFontSize)
            let isCode = existing.fontDescriptor.symbolicTraits.contains(.monoSpace)
            let targetBase = isCode
                ? request.readerFontFamily.nsFont(size: request.codeFontSize, monospaced: true)
                : request.readerFontFamily.nsFont(size: max(12, existing.pointSize * (request.readerFontSize / 13)))

            let descriptor = targetBase.fontDescriptor.withSymbolicTraits(existing.fontDescriptor.symbolicTraits)
            let target = NSFont(descriptor: descriptor, size: targetBase.pointSize) ?? targetBase
            text.addAttribute(.font, value: target, range: range)
        }

        text.addAttribute(.foregroundColor, value: palette.textPrimary, range: fullRange)
        text.addAttribute(.kern, value: 0.1, range: fullRange)
    }

    private func applyCodeStyling(_ text: NSMutableAttributedString, request: RenderRequest) {
        let syntax = request.syntaxPalette.nativeSyntax
        let themePalette = NativeThemePalette(theme: request.appTheme, scheme: request.colorScheme)

        var location = 0
        while location < text.length {
            var effectiveRange = NSRange(location: 0, length: 0)
            let attributes = text.attributes(at: location, effectiveRange: &effectiveRange)
            defer { location = effectiveRange.location + effectiveRange.length }

            guard
                effectiveRange.length > 0,
                let font = attributes[.font] as? NSFont,
                font.fontDescriptor.symbolicTraits.contains(.monoSpace)
            else { continue }

            text.addAttribute(.backgroundColor, value: themePalette.codeBackground, range: effectiveRange)
            applySyntaxHighlight(to: text, in: effectiveRange, syntax: syntax)
        }
    }

    private func applySyntaxHighlight(to text: NSMutableAttributedString, in range: NSRange, syntax: NativeSyntaxStyle) {
        guard range.location + range.length <= text.length else { return }
        var protectedRanges: [NSRange] = []

        func applyProtected(regex: NSRegularExpression?, color: NSColor) {
            guard let regex else { return }
            regex.enumerateMatches(in: text.string, options: [], range: range) { result, _, _ in
                guard let target = result?.range, target.length > 0 else { return }
                text.addAttribute(.foregroundColor, value: color, range: target)
                protectedRanges.append(target)
            }
        }

        applyProtected(regex: stringRegex, color: syntax.string)
        applyProtected(regex: blockCommentRegex, color: syntax.comment)
        applyProtected(regex: lineCommentRegex, color: syntax.comment)

        for rule in syntaxRules {
            rule.regex.enumerateMatches(in: text.string, options: [], range: range) { result, _, _ in
                guard let target = result?.range, target.length > 0 else { return }
                let intersectsProtected = protectedRanges.contains { NSIntersectionRange($0, target).length > 0 }
                guard !intersectsProtected else { return }
                text.addAttribute(.foregroundColor, value: rule.color(syntax), range: target)
            }
        }
    }
}

private struct NativeThemePalette {
    let textPrimary: NSColor
    let codeBackground: NSColor

    init(theme: AppTheme, scheme: ColorScheme) {
        switch (theme, scheme) {
        case (.github, .light):
            textPrimary = NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.20, alpha: 1)
            codeBackground = NSColor(calibratedWhite: 0.96, alpha: 1)
        case (.github, .dark):
            textPrimary = NSColor(calibratedWhite: 0.90, alpha: 1)
            codeBackground = NSColor(calibratedRed: 0.17, green: 0.18, blue: 0.20, alpha: 1)
        case (.docC, .light):
            textPrimary = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 1)
            codeBackground = NSColor(calibratedWhite: 0.95, alpha: 1)
        case (.docC, .dark):
            textPrimary = NSColor(calibratedWhite: 0.93, alpha: 1)
            codeBackground = NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.17, alpha: 1)
        case (.basic, .light):
            textPrimary = .labelColor
            codeBackground = NSColor(calibratedWhite: 0.95, alpha: 1)
        case (.basic, .dark):
            textPrimary = .labelColor
            codeBackground = NSColor(calibratedWhite: 0.2, alpha: 1)
        @unknown default:
            textPrimary = .labelColor
            codeBackground = scheme == .dark
                ? NSColor(calibratedWhite: 0.2, alpha: 1)
                : NSColor(calibratedWhite: 0.95, alpha: 1)
        }
    }
}
#endif
