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
    let textSpacing: ReaderTextSpacing
    let readableWidth: CGFloat

    func makeNSView(context: Context) -> NSScrollView {
        // Force TextKit 1 (NSLayoutManager) — TextKit 2 (the macOS 14+ default) does not
        // call NSTextBlock.drawBackground(withFrame:), so blockquote/code NSTextBlock
        // backgrounds and borders are invisible without explicit TK1 opt-in.
        //
        // The correct TK1 initialisation sequence:
        //   NSTextStorage → NSLayoutManager → NSTextContainer → NSTextView
        // NSTextView's textStorage property then points to the same NSTextStorage,
        // so setAttributedString updates go through the correct layout pipeline.
        let textStorage    = NSTextStorage()
        let layoutManager  = ReaderLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer  = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.lineFragmentPadding    = 0
        textContainer.widthTracksTextView    = true
        layoutManager.addTextContainer(textContainer)

        // This designated initialiser adopts the textContainer (and its storage chain)
        // instead of creating a fresh TK2 text layout manager.
        let textView = ReaderTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.focusRingType = NSFocusRingType.none
        textView.usesFindBar = true
        textView.isRichText = true
        textView.allowsUndo = false
        textView.textContainerInset = NSSize(width: 24, height: 24)
        textView.preferredReadableWidth = readableWidth

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
        guard let textView = scrollView.documentView as? ReaderTextView else { return }
        textView.preferredReadableWidth = readableWidth

        let request = RenderRequest(
            markdown: markdown,
            readerFontFamily: readerFontFamily,
            readerFontSize: readerFontSize,
            codeFontSize: codeFontSize,
            appTheme: appTheme,
            syntaxPalette: syntaxPalette,
            colorScheme: colorScheme,
            textSpacing: textSpacing,
            readableWidth: readableWidth
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
            textView.updateContainerGeometry()
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
    var preferredReadableWidth: CGFloat = 760
    private let minimumHorizontalInset: CGFloat = 24

    // Triggered when the view is added to the window hierarchy — the scroll view
    // is guaranteed to exist here, so we can do the initial geometry pass.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        recomputeGeometry(force: true)
    }

    override func layout() {
        super.layout()
        recomputeGeometry(force: false)
    }

    // Called after content changes — always recomputes layout and frame.
    func updateContainerGeometry() {
        recomputeGeometry(force: true)
    }

    private func recomputeGeometry(force: Bool) {
        guard let textContainer else { return }

        // Prefer the scroll view's content width; fall back to our own bounds
        // for the brief window between init and insertion into the hierarchy.
        let availableWidth: CGFloat
        if let sv = enclosingScrollView {
            availableWidth = sv.contentSize.width
        } else if bounds.width > 0 {
            availableWidth = bounds.width
        } else {
            return  // nothing to measure yet
        }

        let targetWidth      = min(preferredReadableWidth, max(0, availableWidth - minimumHorizontalInset * 2))
        let hInset           = max(minimumHorizontalInset, (availableWidth - targetWidth) / 2)
        let newContainerSize = NSSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)

        // Skip redundant work when neither the column width nor the inset has changed.
        if !force,
           abs(textContainer.containerSize.width - newContainerSize.width) < 0.5,
           abs(textContainerInset.width - hInset) < 0.5 {
            return
        }

        textContainer.containerSize = newContainerSize
        textContainerInset          = NSSize(width: hInset, height: 24)

        // Compute full document height and resize the view so NSScrollView knows
        // the complete scroll extent.
        layoutManager?.ensureLayout(for: textContainer)
        let usedHeight  = layoutManager?.usedRect(for: textContainer).height ?? 0
        let totalHeight = usedHeight + textContainerInset.height * 2
        let viewWidth   = max(availableWidth, targetWidth + hInset * 2)
        setFrameSize(NSSize(width: viewWidth, height: max(totalHeight, 1)))
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
    let textSpacing: ReaderTextSpacing
    let readableWidth: CGFloat

    var cacheKey: String {
        let payload = [
            markdown,
            readerFontFamily.rawValue,
            String(format: "%.2f", readerFontSize),
            String(format: "%.2f", codeFontSize),
            appTheme.rawValue,
            syntaxPalette.rawValue,
            colorScheme == .dark ? "dark" : "light",
            textSpacing.rawValue,
            String(format: "%.0f", readableWidth)
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
        injectBlockSeparators(mutable)
        injectListMarkers(mutable)
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

    /// Inserts `\n` at every block boundary in the attributed string produced by
    /// `NSAttributedString(markdown:)`.
    ///
    /// The parser concatenates all block content with no separator characters —
    /// "H1H2ParagraphItem oneItem two…". `NSLayoutManager` requires actual `\n`
    /// to recognise paragraph breaks; `paragraphSpacing` alone has no effect
    /// without them.
    ///
    /// Each top-level block (heading, paragraph, list item, blockquote, code
    /// block) has a unique `PresentationIntent` identity on its first component.
    /// A `\n` is inserted before every run whose first-component identity differs
    /// from the previous run's.
    private func injectBlockSeparators(_ text: NSMutableAttributedString) {
        var blockIDs: [(location: Int, outerID: Int)] = []

        text.enumerateAttribute(
            Self.presentationIntentKey,
            in: NSRange(location: 0, length: text.length),
            options: []
        ) { val, range, _ in
            let outerID = (val as? PresentationIntent)?.components.first?.identity ?? 0
            blockIDs.append((location: range.location, outerID: outerID))
        }

        // Walk backwards so insertions don't invalidate earlier locations.
        let newline = NSAttributedString(string: "\n")
        for i in stride(from: blockIDs.count - 1, through: 1, by: -1) {
            guard blockIDs[i].outerID != blockIDs[i - 1].outerID else { continue }
            text.insert(newline, at: blockIDs[i].location)
        }
    }

    /// Prepends bullet/number markers to list item runs.
    ///
    /// The markdown parser strips list markers from the text; they must be
    /// re-injected before typography so the font pass can style them uniformly.
    /// Markers are prepended with a tab so `headIndent` creates a hanging layout.
    private func injectListMarkers(_ text: NSMutableAttributedString) {
        struct ListRun {
            let location: Int
            let ordinal: Int        // 1-based ordinal within the list
            let isOrdered: Bool
        }

        var listRuns: [ListRun] = []
        text.enumerateAttribute(
            Self.presentationIntentKey,
            in: NSRange(location: 0, length: text.length),
            options: []
        ) { val, range, _ in
            guard let intent = val as? PresentationIntent else { return }
            var ordinal = 0
            var isOrdered = false
            for component in intent.components {
                switch component.kind {
                case .listItem(let o): ordinal = o
                case .orderedList:     isOrdered = true
                default: break
                }
            }
            guard ordinal > 0 else { return }
            listRuns.append(ListRun(location: range.location, ordinal: ordinal, isOrdered: isOrdered))
        }

        // Insert backwards to preserve locations.
        for run in listRuns.reversed() {
            let marker = run.isOrdered ? "\(run.ordinal).\t" : "•\t"
            let markerAttr = NSAttributedString(string: marker)
            text.insert(markerAttr, at: run.location)
        }
    }

    // Foundation key names for markdown semantic intents (macOS 12+).
    // NSAttributedString(markdown:) does not emit NSFont attributes on macOS 14+;
    // all structure is conveyed via these two keys only.
    private static let presentationIntentKey   = NSAttributedString.Key("NSPresentationIntent")
    private static let inlinePresentationIntentKey = NSAttributedString.Key("NSInlinePresentationIntent")

    // Heading font scales relative to body size.
    private static let headingScales: [Int: CGFloat] = [1: 2.0, 2: 1.5, 3: 1.25, 4: 1.1, 5: 1.0, 6: 1.0]

    private func applyTypography(_ text: NSMutableAttributedString, request: RenderRequest) {
        let fullRange = NSRange(location: 0, length: text.length)
        let palette   = NativeThemePalette(theme: request.appTheme, scheme: request.colorScheme)
        let spacing   = request.textSpacing

        // ── Fonts: one pass over PresentationIntent runs ─────────────────────
        // The parser emits zero NSFont attributes; we must derive every font
        // from the semantic intent stack attached to each run.
        let bodySize = request.readerFontSize
        let codeSize = request.codeFontSize
        let family   = request.readerFontFamily

        let bodyFont = family.nsFont(size: bodySize)
        let codeFont = family.nsFont(size: codeSize, monospaced: true)

        text.enumerateAttribute(Self.presentationIntentKey, in: fullRange, options: []) { value, range, _ in
            guard let intent = value as? PresentationIntent else {
                text.addAttribute(.font, value: bodyFont, range: range)
                return
            }

            var headingLevel = 0
            var isCodeBlock  = false

            for component in intent.components {
                switch component.kind {
                case .header(let level): headingLevel = level
                case .codeBlock:         isCodeBlock  = true
                default:                 break
                }
            }

            if isCodeBlock {
                text.addAttribute(.font, value: codeFont, range: range)
            } else if headingLevel > 0 {
                let scale = Self.headingScales[headingLevel, default: 1.0]
                let font  = family.nsFont(size: bodySize * scale, traits: .bold)
                text.addAttribute(.font, value: font, range: range)
            } else {
                text.addAttribute(.font, value: bodyFont, range: range)
            }
        }

        // ── Inline emphasis / code override ──────────────────────────────────
        // InlinePresentationIntent raw value is an NSNumber bit-field.
        text.enumerateAttribute(Self.inlinePresentationIntentKey, in: fullRange, options: []) { value, range, _ in
            guard let raw = value as? NSNumber else { return }
            let intent = InlinePresentationIntent(rawValue: UInt(raw.intValue))

            if intent.contains(.code) {
                text.addAttribute(.font, value: codeFont, range: range)
                return
            }
            let bold   = intent.contains(.stronglyEmphasized)
            let italic = intent.contains(.emphasized)
            guard bold || italic else { return }

            let current = (text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont) ?? bodyFont
            var traits  = current.fontDescriptor.symbolicTraits
            if bold   { traits.insert(.bold)   }
            if italic { traits.insert(.italic) }
            let desc = current.fontDescriptor.withSymbolicTraits(traits)
            text.addAttribute(.font, value: NSFont(descriptor: desc, size: current.pointSize) ?? current, range: range)
        }

        // ── Paragraph styles ──────────────────────────────────────────────────
        // Collect intent runs first to avoid mutating inside enumeration closure.
        var intentRuns: [(NSRange, PresentationIntent?)] = []
        text.enumerateAttribute(Self.presentationIntentKey, in: fullRange, options: []) { value, range, _ in
            intentRuns.append((range, value as? PresentationIntent))
        }

        for (range, intent) in intentRuns {
            let ps = buildParagraphStyle(for: intent, spacing: spacing, bodySize: bodySize)
            text.addAttribute(.paragraphStyle, value: ps, range: range)

            // Stamp blockquote decoration keys so ReaderLayoutManager can draw
            // the left-accent bar and tinted background without NSTextBlock.
            let bqDepth = intent?.components.reduce(0) { acc, c in
                if case .blockQuote = c.kind { return acc + 1 }; return acc
            } ?? 0
            if bqDepth > 0 {
                text.addAttribute(bqDepthKey,           value: bqDepth,                    range: range)
                text.addAttribute(bqAccentColorKey,     value: palette.blockquoteAccent,   range: range)
                text.addAttribute(bqBackgroundColorKey, value: palette.blockquoteBackground, range: range)
            }
        }

        // ── Colour and kern: full-range baseline ──────────────────────────────
        text.addAttribute(.foregroundColor, value: palette.textPrimary, range: fullRange)
        text.addAttribute(.kern,            value: spacing.kern,        range: fullRange)

        // ── Theme-aware link colors ──────────────────────────────────────────
        // NSAttributedString(markdown:) applies system linkColor; we override with theme.
        text.enumerateAttribute(.link, in: fullRange, options: []) { _, range, _ in
            text.addAttribute(.foregroundColor, value: palette.link, range: range)
        }

        // ── Heading colors ───────────────────────────────────────────────────
        text.enumerateAttribute(Self.presentationIntentKey, in: fullRange, options: []) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }
            let isHeading = intent.components.contains { component in
                if case .header = component.kind { return true }
                return false
            }
            if isHeading {
                text.addAttribute(.foregroundColor, value: palette.heading, range: range)
            }
        }
    }

    /// Builds a complete NSParagraphStyle for one PresentationIntent run.
    ///
    /// Rhythm contract (at 16pt body, balanced spacing — lineSpacing=7, paragraphSpacing=16):
    ///   Body line-height  ≈ 23pt  (16 + 7)
    ///   Body para gap     = 16pt  (≈ 0.7 lines — one clear breath between paragraphs)
    ///   H1 above          = 40pt  (2.5× body — strong section break)
    ///   H1 below          =  8pt  (pull content close under heading)
    ///   H2 above          = 32pt
    ///   H3 above          = 24pt
    ///   Code block above  = 16pt  (matches body para gap)
    ///   Code block below  = 16pt
    ///   Blockquote above  = 12pt  (slightly inset from body rhythm)
    ///   List item gap     =  6pt  (tight — items are related)
    private func buildParagraphStyle(
        for intent: PresentationIntent?,
        spacing: ReaderTextSpacing,
        bodySize: CGFloat
    ) -> NSParagraphStyle {
        let ps = NSMutableParagraphStyle()
        let gap = spacing.paragraphSpacing   // inter-block gap baseline

        // Body defaults — every block starts here and overrides what it needs.
        ps.lineSpacing            = spacing.lineSpacing
        ps.paragraphSpacing       = gap
        ps.paragraphSpacingBefore = 0
        ps.hyphenationFactor      = spacing.hyphenationFactor
        ps.lineBreakMode          = .byWordWrapping

        guard let intent else { return ps }

        var headingLevel = 0
        var isCodeBlock  = false
        var bqDepth      = 0
        var listDepth    = 0

        for component in intent.components {
            switch component.kind {
            case .header(let l): headingLevel = l
            case .codeBlock:     isCodeBlock  = true
            case .blockQuote:    bqDepth     += 1
            case .unorderedList: listDepth   += 1
            case .orderedList:   listDepth   += 1
            default: break
            }
        }

        // ── Headings ─────────────────────────────────────────────────────────
        // Space above = 1.5–2.5× body size scaled by heading level.
        // Space below = 0.3× heading size (tight coupling to following content).
        // Line spacing is small and fixed — headings rarely wrap.
        if headingLevel > 0 {
            let scale    = Self.headingScales[headingLevel, default: 1.0]
            let headSize = bodySize * scale
            // Above: drops from 2.5× body for H1 down to 1.5× for H3+
            let aboveScale: CGFloat = headingLevel == 1 ? 2.5
                                    : headingLevel == 2 ? 2.0
                                    : 1.5
            ps.paragraphSpacingBefore = bodySize * aboveScale
            ps.paragraphSpacing       = headSize * 0.3
            ps.lineSpacing            = 2
            ps.hyphenationFactor      = 0
            return ps
        }

        // ── Code blocks ───────────────────────────────────────────────────────
        // Tighter line spacing (mono is denser), same inter-block gap as body.
        // Left indent matches the layout manager's codeVPad so text sits centred
        // within the rounded rect drawn by ReaderLayoutManager.
        if isCodeBlock {
            ps.lineSpacing            = max(spacing.lineSpacing * 0.6, 3)
            ps.paragraphSpacingBefore = gap
            ps.paragraphSpacing       = gap
            ps.firstLineHeadIndent    = 14
            ps.headIndent             = 14
            ps.hyphenationFactor      = 0
            return ps
        }

        // ── Blockquotes ───────────────────────────────────────────────────────
        // Slightly inset from body rhythm — blockquotes are subsidiary content.
        // Left indent clears the accent bar drawn by ReaderLayoutManager.
        if bqDepth > 0 {
            let barWidth: CGFloat = 3
            let leftPad:  CGFloat = 14 + CGFloat(bqDepth - 1) * 18
            ps.firstLineHeadIndent    = barWidth + leftPad
            ps.headIndent             = barWidth + leftPad
            ps.lineSpacing            = spacing.lineSpacing
            ps.paragraphSpacingBefore = gap * 0.6
            ps.paragraphSpacing       = gap * 0.6
            ps.hyphenationFactor      = spacing.hyphenationFactor
            return ps
        }

        // ── Lists ─────────────────────────────────────────────────────────────
        // Items within a list are related — tight gap (0.35× body gap).
        // Hanging indent: marker sits at firstLineHeadIndent, body at headIndent.
        if listDepth > 0 {
            let markerWidth: CGFloat  = 20
            let perLevel: CGFloat     = 20
            let indent: CGFloat       = CGFloat(listDepth - 1) * perLevel + markerWidth
            let tabStop = NSTextTab(textAlignment: .left, location: indent)
            ps.tabStops            = [tabStop]
            ps.defaultTabInterval  = markerWidth
            ps.firstLineHeadIndent = indent - markerWidth
            ps.headIndent          = indent
            ps.lineSpacing         = spacing.lineSpacing
            ps.paragraphSpacing    = gap * 0.35
            return ps
        }

        // ── Body paragraph ────────────────────────────────────────────────────
        // No spacingBefore — only paragraphSpacing (below) separates body blocks.
        return ps
    }

    private func applyCodeStyling(_ text: NSMutableAttributedString, request: RenderRequest) {
        let syntax = request.syntaxPalette.nativeSyntax
        let themePalette = NativeThemePalette(theme: request.appTheme, scheme: request.colorScheme)
        let fullRange = NSRange(location: 0, length: text.length)

        // Collect fenced code block ranges (identified by PresentationIntent.codeBlock)
        var fencedCodeRanges: [NSRange] = []
        text.enumerateAttribute(Self.presentationIntentKey, in: fullRange, options: []) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }
            let isCodeBlock = intent.components.contains { component in
                if case .codeBlock = component.kind { return true }
                return false
            }
            if isCodeBlock {
                fencedCodeRanges.append(range)
            }
        }

        // Helper to check if a range is within any fenced code block
        func isFencedCode(_ range: NSRange) -> Bool {
            fencedCodeRanges.contains { NSIntersectionRange($0, range).length > 0 }
        }

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

            if isFencedCode(effectiveRange) {
                // Fenced code blocks: use unified background, let ReaderLayoutManager draw it
                text.addAttribute(.backgroundColor, value: themePalette.codeBackground, range: effectiveRange)
                applySyntaxHighlight(to: text, in: effectiveRange, syntax: syntax)
            } else {
                // Inline code: use subtle background pill
                text.addAttribute(.backgroundColor, value: themePalette.inlineCodeBackground, range: effectiveRange)
            }
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
    let textSecondary: NSColor
    let link: NSColor
    let heading: NSColor
    let codeBackground: NSColor
    let codeBorder: NSColor
    let blockquoteAccent: NSColor
    let blockquoteBackground: NSColor
    let inlineCodeBackground: NSColor

    init(theme: AppTheme, scheme: ColorScheme) {
        switch (theme, scheme) {
        case (.github, .light):
            textPrimary          = NSColor(red: 0.14, green: 0.16, blue: 0.20, alpha: 1)
            textSecondary        = NSColor(red: 0.40, green: 0.42, blue: 0.46, alpha: 1)
            link                 = NSColor(red: 0.10, green: 0.46, blue: 0.82, alpha: 1)
            heading              = NSColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1)
            codeBackground       = NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
            codeBorder           = NSColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
            blockquoteAccent     = NSColor(red: 0.22, green: 0.51, blue: 0.82, alpha: 1)
            blockquoteBackground = NSColor(red: 0.22, green: 0.51, blue: 0.82, alpha: 0.06)
            inlineCodeBackground = NSColor(red: 0.22, green: 0.51, blue: 0.82, alpha: 0.08)
        case (.github, .dark):
            textPrimary          = NSColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1)
            textSecondary        = NSColor(red: 0.60, green: 0.62, blue: 0.66, alpha: 1)
            link                 = NSColor(red: 0.53, green: 0.75, blue: 0.98, alpha: 1)
            heading              = NSColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1)
            codeBackground       = NSColor(red: 0.17, green: 0.18, blue: 0.20, alpha: 1)
            codeBorder           = NSColor(red: 0.28, green: 0.29, blue: 0.32, alpha: 1)
            blockquoteAccent     = NSColor(red: 0.35, green: 0.62, blue: 0.90, alpha: 1)
            blockquoteBackground = NSColor(red: 0.35, green: 0.62, blue: 0.90, alpha: 0.08)
            inlineCodeBackground = NSColor(red: 0.35, green: 0.62, blue: 0.90, alpha: 0.10)
        case (.docC, .light):
            textPrimary          = NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
            textSecondary        = NSColor(red: 0.38, green: 0.38, blue: 0.42, alpha: 1)
            link                 = NSColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
            heading              = NSColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1)
            codeBackground       = NSColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1)
            codeBorder           = NSColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1)
            blockquoteAccent     = NSColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
            blockquoteBackground = NSColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 0.05)
            inlineCodeBackground = NSColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 0.08)
        case (.docC, .dark):
            textPrimary          = NSColor(red: 0.93, green: 0.93, blue: 0.94, alpha: 1)
            textSecondary        = NSColor(red: 0.60, green: 0.60, blue: 0.64, alpha: 1)
            link                 = NSColor(red: 0.25, green: 0.60, blue: 1.00, alpha: 1)
            heading              = NSColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
            codeBackground       = NSColor(red: 0.14, green: 0.15, blue: 0.17, alpha: 1)
            codeBorder           = NSColor(red: 0.26, green: 0.27, blue: 0.30, alpha: 1)
            blockquoteAccent     = NSColor(red: 0.25, green: 0.60, blue: 1.00, alpha: 1)
            blockquoteBackground = NSColor(red: 0.25, green: 0.60, blue: 1.00, alpha: 0.08)
            inlineCodeBackground = NSColor(red: 0.25, green: 0.60, blue: 1.00, alpha: 0.10)
        case (.basic, .light):
            textPrimary          = .labelColor
            textSecondary        = .secondaryLabelColor
            link                 = .linkColor
            heading              = .labelColor
            codeBackground       = NSColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
            codeBorder           = NSColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
            blockquoteAccent     = NSColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
            blockquoteBackground = NSColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.04)
            inlineCodeBackground = NSColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 0.08)
        case (.basic, .dark):
            textPrimary          = .labelColor
            textSecondary        = .secondaryLabelColor
            link                 = .linkColor
            heading              = .labelColor
            codeBackground       = NSColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
            codeBorder           = NSColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1)
            blockquoteAccent     = NSColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
            blockquoteBackground = NSColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.05)
            inlineCodeBackground = NSColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 0.08)
        @unknown default:
            textPrimary          = .labelColor
            textSecondary        = .secondaryLabelColor
            link                 = .linkColor
            heading              = .labelColor
            codeBackground       = scheme == .dark
                ? NSColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
                : NSColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
            codeBorder           = scheme == .dark
                ? NSColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1)
                : NSColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
            blockquoteAccent     = NSColor(red: scheme == .dark ? 0.45 : 0.55,
                                           green: scheme == .dark ? 0.45 : 0.55,
                                           blue: scheme == .dark ? 0.45 : 0.55, alpha: 1)
            blockquoteBackground = NSColor(red: scheme == .dark ? 1.0 : 0.0,
                                           green: scheme == .dark ? 1.0 : 0.0,
                                           blue: scheme == .dark ? 1.0 : 0.0,
                                           alpha: scheme == .dark ? 0.05 : 0.04)
            inlineCodeBackground = NSColor(red: scheme == .dark ? 0.45 : 0.55,
                                           green: scheme == .dark ? 0.45 : 0.55,
                                           blue: scheme == .dark ? 0.45 : 0.55,
                                           alpha: 0.08)
        }
    }
}

// MARK: - Custom attribute keys for blockquote decoration

/// Stored on blockquote character ranges by the renderer.
/// The layout manager reads these during drawing — no NSTextBlock needed.
private let bqAccentColorKey     = NSAttributedString.Key("mdv.blockquoteAccent")
private let bqBackgroundColorKey = NSAttributedString.Key("mdv.blockquoteBackground")
private let bqDepthKey           = NSAttributedString.Key("mdv.blockquoteDepth")

// MARK: - Custom layout manager

/// Draws blockquote and code-block decorations as unified geometry rather than
/// per-character or per-line rects.
///
/// • **Code blocks**: a single rounded-rect background covering all lines.
/// • **Blockquotes**: a left-border accent bar + tinted background covering all lines.
///
/// Both are drawn *before* glyph rendering so text sits on top.  No `NSTextBlock` is
/// used — that API's `drawBackground` is never invoked reliably in SwiftUI-hosted
/// TK1 views on macOS 14+.
private final class ReaderLayoutManager: NSLayoutManager {

    private static let codeCornerRadius: CGFloat = 6
    private static let codeVPad:         CGFloat = 6
    private static let bqBarWidth:       CGFloat = 3

    private static let piKey = NSAttributedString.Key("NSPresentationIntent")

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        // Call super first for selection highlight and standard per-char backgrounds
        // (inline code pills, etc.).  We draw our custom decorations on top of that.
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard
            let ts        = textStorage,
            let container = textContainers.first,
            let ctx       = NSGraphicsContext.current?.cgContext
        else { return }

        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        let totalLen  = ts.length
        guard totalLen > 0 else { return }

        // ── Collect decoration spans ──────────────────────────────────────────

        enum SpanKind {
            case code(bg: NSColor)
            case blockquote(bg: NSColor, accent: NSColor, depth: Int)
        }
        struct Span { var charStart: Int; var charEnd: Int; var kind: SpanKind }

        var codeSpans: [Span] = []
        var bqSpans:   [Span] = []

        var i = charRange.location
        while i < charRange.location + charRange.length, i < totalLen {
            var effectiveRange = NSRange(location: i, length: 1)
            let intent = ts.attribute(Self.piKey, at: i, effectiveRange: &effectiveRange)
                as? PresentationIntent
            let end = min(effectiveRange.location + effectiveRange.length, totalLen)

            let isCode = intent?.components.contains {
                if case .codeBlock = $0.kind { return true }; return false
            } ?? false

            let bqDepth = ts.attribute(bqDepthKey, at: i, effectiveRange: nil) as? Int ?? 0

            if isCode, let bg = ts.attribute(.backgroundColor, at: i, effectiveRange: nil) as? NSColor {
                if let last = codeSpans.last, last.charEnd >= i {
                    codeSpans[codeSpans.count - 1].charEnd = max(codeSpans[codeSpans.count - 1].charEnd, end)
                } else {
                    codeSpans.append(Span(charStart: effectiveRange.location, charEnd: end, kind: .code(bg: bg)))
                }
            } else if bqDepth > 0,
                      let bg     = ts.attribute(bqBackgroundColorKey, at: i, effectiveRange: nil) as? NSColor,
                      let accent = ts.attribute(bqAccentColorKey,     at: i, effectiveRange: nil) as? NSColor {
                if let last = bqSpans.last, last.charEnd >= i {
                    bqSpans[bqSpans.count - 1].charEnd = max(bqSpans[bqSpans.count - 1].charEnd, end)
                } else {
                    bqSpans.append(Span(charStart: effectiveRange.location, charEnd: end,
                                        kind: .blockquote(bg: bg, accent: accent, depth: bqDepth)))
                }
            }

            i = end
        }

        let containerWidth = container.containerSize.width

        // ── Draw code block backgrounds ───────────────────────────────────────
        for span in codeSpans {
            guard case .code(let bg) = span.kind else { continue }
            let rect = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
            guard !rect.isNull else { continue }

            let drawRect = CGRect(
                x: origin.x,
                y: rect.minY - Self.codeVPad,
                width: containerWidth,
                height: rect.height + Self.codeVPad * 2
            )
            ctx.saveGState()
            bg.setFill()
            ctx.addPath(CGPath(roundedRect: drawRect,
                               cornerWidth: Self.codeCornerRadius,
                               cornerHeight: Self.codeCornerRadius,
                               transform: nil))
            ctx.fillPath()
            ctx.restoreGState()
        }

        // ── Draw blockquote backgrounds + left accent bar ─────────────────────
        for span in bqSpans {
            guard case .blockquote(let bg, let accent, let depth) = span.kind else { continue }
            let rect = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
            guard !rect.isNull else { continue }

            // Indent increases with nesting depth.
            let leftInset = CGFloat(depth - 1) * 16 + origin.x
            let drawRect  = CGRect(
                x: leftInset,
                y: rect.minY - 2,
                width: containerWidth - leftInset + origin.x,
                height: rect.height + 4
            )

            ctx.saveGState()

            // Tinted background.
            bg.setFill()
            ctx.fill(drawRect)

            // Left accent bar.
            let barRect = CGRect(x: drawRect.minX, y: drawRect.minY,
                                 width: Self.bqBarWidth, height: drawRect.height)
            accent.setFill()
            ctx.fill(barRect)

            ctx.restoreGState()
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func unionUsedRect(charStart: Int, charEnd: Int, origin: NSPoint) -> CGRect {
        let glRange = glyphRange(
            forCharacterRange: NSRange(location: charStart, length: charEnd - charStart),
            actualCharacterRange: nil
        )
        var result = CGRect.null
        enumerateLineFragments(forGlyphRange: glRange) { _, usedRect, _, _, _ in
            let r = CGRect(x: usedRect.minX + origin.x, y: usedRect.minY + origin.y,
                           width: usedRect.width, height: usedRect.height)
            result = result.isNull ? r : result.union(r)
        }
        return result
    }
}
#endif
