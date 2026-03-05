//
//  ReaderLayoutManager.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - ReaderLayoutManager

    /// Custom layout manager that draws block-level decorations behind text:
    /// Supports 120fps scrolling through decoration caching and optimized scanning.
    final class ReaderLayoutManager: NSLayoutManager {
        private static let codeCornerRadius: CGFloat = 6
        private static let codeVPad: CGFloat = 8
        private static let codeHPadding: CGFloat = 12
        private static let bqBarWidth: CGFloat = 3
        private static let bqHPadding: CGFloat = 12
        private static let tableHPadding: CGFloat = 12
        private static let tableVPadding: CGFloat = 6
        private static let tableMinWidth: CGFloat = 280
        private static let lineNumberGutterPadding: CGFloat = 12
        private static let lineNumberMinWidth: CGFloat = 32

        // MARK: - Cache

        private struct CachedDecoration {
            let spans: DecorationSpans
            let usedRects: [Int: CGRect] // Key: hash of span
            let textHash: Int
            let containerWidth: CGFloat
        }

        private var decorationCache: CachedDecoration?

        // MARK: - Decoration Span Types

        private enum SpanKind: Hashable {
            case code(bg: NSColor)
            case blockquote(bg: NSColor, accent: NSColor, depth: Int)
            case tableHeader(bg: NSColor)
            case tableRow(alternating: Bool, bg: NSColor)
            case horizontalRule(color: NSColor)
        }

        private struct DecorationSpan: Hashable {
            var charStart: Int
            var charEnd: Int
            var kind: SpanKind
        }

        private struct DecorationSpans {
            var code: [DecorationSpan] = []
            var bq: [DecorationSpan] = []
            var table: [DecorationSpan] = []
            var hr: [DecorationSpan] = []
        }

        // MARK: - Drawing

        override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
            // Call super first for selection highlight and standard per-char backgrounds
            super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

            guard
                let ts = textStorage,
                let container = textContainers.first,
                let ctx = NSGraphicsContext.current?.cgContext
            else { return }

            let totalLen = ts.length
            guard totalLen > 0 else { return }

            let containerWidth = container.containerSize.width
            let textHash = ts.string.hashValue

            // ── Validate and Update Cache ────────────────────────────────────────
            let spans: DecorationSpans
            var usedRects: [Int: CGRect]

            if
                let cached = decorationCache,
                cached.textHash == textHash,
                abs(cached.containerWidth - containerWidth) < 0.1
            {
                spans = cached.spans
                usedRects = cached.usedRects
            } else {
                // Full scan when text or layout changes
                let fullRange = NSRange(location: 0, length: totalLen)
                spans = collectDecorationSpans(in: ts, charRange: fullRange, totalLen: totalLen)
                usedRects = [:]
                decorationCache = CachedDecoration(
                    spans: spans,
                    usedRects: usedRects,
                    textHash: textHash,
                    containerWidth: containerWidth
                )
            }

            // Only draw spans that intersect with the current glyph range
            let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

            // ── Draw code block backgrounds and line numbers ─────────────────────
            for span in spans.code {
                guard span.charEnd > charRange.location, span.charStart < NSMaxRange(charRange) else { continue }
                guard case .code(let bg) = span.kind else { continue }

                let spanHash = span.hashValue
                let rect = usedRects[spanHash] ?? {
                    let r = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
                    usedRects[spanHash] = r
                    return r
                }()
                guard !rect.isNull else { continue }

                let hasLineNumbers = ts.attribute(
                    MarkdownRenderAttribute.codeBlock,
                    at: span.charStart,
                    effectiveRange: nil
                ) != nil

                let gutterWidth: CGFloat
                if hasLineNumbers {
                    gutterWidth = calculateLineNumberGutterWidth(text: ts, range: span.charStart ..< span.charEnd)
                } else {
                    gutterWidth = 0
                }

                let drawRect = CGRect(
                    x: origin.x,
                    y: rect.minY - Self.codeVPad,
                    width: containerWidth,
                    height: rect.height + Self.codeVPad * 2
                )
                ctx.saveGState()
                bg.setFill()
                ctx.addPath(CGPath(
                    roundedRect: drawRect,
                    cornerWidth: Self.codeCornerRadius,
                    cornerHeight: Self.codeCornerRadius,
                    transform: nil
                ))
                ctx.fillPath()

                if hasLineNumbers {
                    drawLineNumbers(
                        for: span,
                        in: ts,
                        origin: origin,
                        containerWidth: containerWidth,
                        gutterWidth: gutterWidth,
                        ctx: ctx
                    )
                }

                ctx.restoreGState()
            }

            // ── Draw blockquote backgrounds + left accent bar ─────────────────────
            for span in spans.bq {
                guard span.charEnd > charRange.location, span.charStart < NSMaxRange(charRange) else { continue }
                guard case .blockquote(let bg, let accent, let depth) = span.kind else { continue }

                let spanHash = span.hashValue
                let rect = usedRects[spanHash] ?? {
                    let r = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
                    usedRects[spanHash] = r
                    return r
                }()
                guard !rect.isNull else { continue }

                let leftInset = CGFloat(depth - 1) * 16 + origin.x
                let drawRect = CGRect(
                    x: leftInset,
                    y: rect.minY - 4,
                    width: containerWidth - leftInset,
                    height: rect.height + 8
                )

                ctx.saveGState()
                bg.setFill()
                ctx.fill(drawRect)

                let barRect = CGRect(
                    x: drawRect.minX,
                    y: drawRect.minY,
                    width: Self.bqBarWidth,
                    height: drawRect.height
                )
                accent.setFill()
                ctx.fill(barRect)
                ctx.restoreGState()
            }

            // ── Draw table surfaces and separators ───────────────────────────────
            for (spanIndex, span) in spans.table.enumerated() {
                guard span.charEnd > charRange.location, span.charStart < NSMaxRange(charRange) else { continue }

                let spanHash = span.hashValue
                let rect = usedRects[spanHash] ?? {
                    let r = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
                    usedRects[spanHash] = r
                    return r
                }()
                guard !rect.isNull else { continue }

                let isLastTableSpan = spanIndex == spans.table.count - 1

                let paragraph = ts.attribute(
                    .paragraphStyle,
                    at: span.charStart,
                    effectiveRange: nil
                ) as? NSParagraphStyle
                let lineRange = (ts.string as NSString).lineRange(for: NSRange(location: span.charStart, length: 0))
                let lineText = (ts.string as NSString).substring(with: lineRange)
                let tabCount = lineText.reduce(into: 0) { partialResult, char in
                    if char == "\t" { partialResult += 1 }
                }

                let tableWidth = max(Self.tableMinWidth, containerWidth - 16)

                let rowRect = CGRect(
                    x: origin.x + Self.tableHPadding,
                    y: rect.minY - Self.tableVPadding,
                    width: tableWidth,
                    height: rect.height + (Self.tableVPadding * 2)
                )
                guard rowRect.width > 0, rowRect.height > 0 else { continue }

                let borderColor = ts
                    .attribute(MarkdownRenderAttribute.tableBorder, at: span.charStart, effectiveRange: nil) as? NSColor

                ctx.saveGState()
                switch span.kind {
                case .tableHeader(let bg):
                    bg.setFill()
                    ctx.fill(rowRect)

                case .tableRow(let alternating, let bg):
                    if alternating {
                        bg.setFill()
                        ctx.fill(rowRect)
                    }

                default:
                    break
                }

                if let borderColor {
                    ctx.setLineWidth(0.5)
                    borderColor.setStroke()
                    ctx.beginPath()
                    ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.minY))
                    let drawsBottomEdge: Bool
                    if case .tableHeader = span.kind {
                        drawsBottomEdge = true
                    } else {
                        drawsBottomEdge = isLastTableSpan
                    }
                    if drawsBottomEdge {
                        ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.maxY))
                        ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.maxY))
                    }
                    ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.minX, y: rowRect.maxY))
                    ctx.move(to: CGPoint(x: rowRect.maxX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.maxY))
                    ctx.strokePath()

                    if let paragraph, tabCount > 0 {
                        let rawMultiplier = ts.attribute(
                            MarkdownRenderAttribute.tableColumnDividerOpacity,
                            at: span.charStart,
                            effectiveRange: nil
                        ) as? CGFloat ?? 0.45
                        let dividerMultiplier = max(0.0, min(1.0, rawMultiplier))

                        borderColor.withAlphaComponent(borderColor.alphaComponent * dividerMultiplier).setStroke()
                        ctx.beginPath()
                        for tabStop in paragraph.tabStops.prefix(tabCount) {
                            let x = origin.x + tabStop.location
                            guard x > rowRect.minX, x < rowRect.maxX else { continue }
                            ctx.move(to: CGPoint(x: x, y: rowRect.minY))
                            ctx.addLine(to: CGPoint(x: x, y: rowRect.maxY))
                        }
                        ctx.strokePath()
                    }
                }
                ctx.restoreGState()
            }

            // ── Draw horizontal rules ─────────────────────────────────────────────
            for span in spans.hr {
                guard span.charEnd > charRange.location, span.charStart < NSMaxRange(charRange) else { continue }
                guard case .horizontalRule(let color) = span.kind else { continue }

                let spanHash = span.hashValue
                let rect = usedRects[spanHash] ?? {
                    let r = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
                    usedRects[spanHash] = r
                    return r
                }()
                guard !rect.isNull else { continue }

                let lineY = floor(rect.midY) + 0.5
                let hInset = origin.x + 4
                let lineWidth = max(0, containerWidth - 8)
                guard lineWidth > 0 else { continue }

                ctx.saveGState()
                color.setStroke()
                ctx.setLineWidth(0.5)
                ctx.beginPath()
                ctx.move(to: CGPoint(x: hInset, y: lineY))
                ctx.addLine(to: CGPoint(x: hInset + lineWidth, y: lineY))
                ctx.strokePath()
                ctx.restoreGState()
            }

            decorationCache = CachedDecoration(
                spans: spans,
                usedRects: usedRects,
                textHash: textHash,
                containerWidth: containerWidth
            )
        }

        // MARK: - Span Collection

        private func collectDecorationSpans(
            in ts: NSTextStorage,
            charRange: NSRange,
            totalLen: Int
        ) -> DecorationSpans {
            var spans = DecorationSpans()

            ts.enumerateAttribute(
                MarkdownRenderAttribute.presentationIntent,
                in: charRange,
                options: []
            ) { value, range, _ in
                guard let intent = value as? PresentationIntent else { return }

                let isCode = intent.components.contains {
                    if case .codeBlock = $0.kind { return true }; return false
                }

                if isCode {
                    if let bg = ts.attribute(.backgroundColor, at: range.location, effectiveRange: nil) as? NSColor {
                        spans.code.append(DecorationSpan(
                            charStart: range.location,
                            charEnd: NSMaxRange(range),
                            kind: .code(bg: bg)
                        ))
                    }
                }

                var blockquoteCount = 0
                for component in intent.components {
                    if case .blockQuote = component.kind {
                        blockquoteCount += 1
                    }
                }

                if blockquoteCount > 0 {
                    if
                        let bg = ts.attribute(
                            MarkdownRenderAttribute.blockquoteBackground,
                            at: range.location,
                            effectiveRange: nil
                        ) as? NSColor,
                        let accent = ts.attribute(
                            MarkdownRenderAttribute.blockquoteAccent,
                            at: range.location,
                            effectiveRange: nil
                        ) as? NSColor
                    {
                        spans.bq.append(DecorationSpan(
                            charStart: range.location,
                            charEnd: NSMaxRange(range),
                            kind: .blockquote(bg: bg, accent: accent, depth: blockquoteCount)
                        ))
                    }
                }

                for component in intent.components {
                    switch component.kind {
                    case .tableHeaderRow:
                        if
                            let bg = ts.attribute(
                                MarkdownRenderAttribute.tableHeaderBackground,
                                at: range.location,
                                effectiveRange: nil
                            ) as? NSColor
                        {
                            spans.table.append(DecorationSpan(
                                charStart: range.location,
                                charEnd: NSMaxRange(range),
                                kind: .tableHeader(bg: bg)
                            ))
                        }
                    case .tableRow:
                        let bg = ts.attribute(
                            MarkdownRenderAttribute.tableRowBackground,
                            at: range.location,
                            effectiveRange: nil
                        ) as? NSColor ?? .clear
                        let alternating = ts.attribute(
                            MarkdownRenderAttribute.tableRowAlternating,
                            at: range.location,
                            effectiveRange: nil
                        ) as? Bool ?? false
                        spans.table.append(DecorationSpan(
                            charStart: range.location,
                            charEnd: NSMaxRange(range),
                            kind: .tableRow(alternating: alternating, bg: bg)
                        ))
                    default:
                        break
                    }
                }

                let isHR = intent.components.contains {
                    if case .thematicBreak = $0.kind { return true }; return false
                }
                if isHR {
                    if
                        let color = ts.attribute(
                            MarkdownRenderAttribute.horizontalRule,
                            at: range.location,
                            effectiveRange: nil
                        ) as? NSColor
                    {
                        spans.hr.append(DecorationSpan(
                            charStart: range.location,
                            charEnd: NSMaxRange(range),
                            kind: .horizontalRule(color: color)
                        ))
                    }
                }
            }

            return spans
        }

        // MARK: - Helpers

        private func unionUsedRect(charStart: Int, charEnd: Int, origin: NSPoint) -> CGRect {
            let length = charEnd - charStart
            guard length > 0 else { return .null }
            let glRange = glyphRange(
                forCharacterRange: NSRange(location: charStart, length: length),
                actualCharacterRange: nil
            )
            var result = CGRect.null
            enumerateLineFragments(forGlyphRange: glRange) { _, usedRect, _, _, _ in
                let r = CGRect(
                    x: usedRect.minX + origin.x,
                    y: usedRect.minY + origin.y,
                    width: usedRect.width,
                    height: usedRect.height
                )
                result = result.isNull ? r : result.union(r)
            }
            return result
        }

        private func calculateLineNumberGutterWidth(text: NSTextStorage, range: Range<Int>) -> CGFloat {
            let safeRange = range.clamped(to: 0 ..< max(1, text.length))
            guard !safeRange.isEmpty else { return Self.lineNumberMinWidth }

            let lineCount = countLines(
                in: text,
                range: NSRange(location: safeRange.lowerBound, length: safeRange.upperBound - safeRange.lowerBound)
            )
            let digitCount = max(1, String(lineCount).count)
            let fontSize = getCodeFontSize(in: text, at: safeRange.lowerBound) ?? 14
            return max(CGFloat(digitCount) * fontSize * 0.6 + Self.lineNumberGutterPadding, Self.lineNumberMinWidth)
        }

        private func countLines(in text: NSTextStorage, range: NSRange) -> Int {
            let nsString = text.string as NSString
            let safeLocation = max(0, min(range.location, nsString.length))
            let safeLength = max(0, min(range.length, nsString.length - safeLocation))
            guard safeLength > 0 else { return 1 }

            let safeEnd = safeLocation + safeLength
            var count = 1
            for i in safeLocation ..< safeEnd {
                if nsString.character(at: i) == 0x0A { count += 1 }
            }
            if safeLength > 0, nsString.character(at: safeEnd - 1) == 0x0A {
                count -= 1
            }
            return max(1, count)
        }

        private func getCodeFontSize(in text: NSTextStorage, at location: Int) -> CGFloat? {
            guard
                location >= 0, location < text.length,
                let font = text.attribute(.font, at: location, effectiveRange: nil) as? NSFont
            else { return nil }
            return font.pointSize
        }

        private func drawLineNumbers(
            for span: DecorationSpan,
            in text: NSTextStorage,
            origin: NSPoint,
            containerWidth: CGFloat,
            gutterWidth: CGFloat,
            ctx: CGContext
        ) {
            guard span.charStart >= 0, span.charEnd > span.charStart, span.charEnd <= text.length else { return }

            let charRange = NSRange(location: span.charStart, length: span.charEnd - span.charStart)
            let glyphRange = glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
            guard glyphRange.length > 0 else { return }

            guard let font = getCodeFont(in: text, at: span.charStart) else { return }
            let fontSize = font.pointSize
            let lineNumberColor = NSColor.tertiaryLabelColor

            var lineNumber = 1
            enumerateLineFragments(forGlyphRange: glyphRange) { [weak self] _, usedRect, _, glyphRangeForLine, _ in
                guard let self else { return }

                let charRangeForLine = characterRange(forGlyphRange: glyphRangeForLine, actualGlyphRange: nil)
                let lineStart = charRangeForLine.location

                let isFirstFragment = (lineStart == span.charStart) ||
                    (lineStart > 0 && lineStart - 1 < text.length && (text.string as NSString)
                        .character(at: lineStart - 1) == 0x0A)

                if isFirstFragment {
                    let numberString = "\(lineNumber)" as NSString
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: NSFont.monospacedSystemFont(ofSize: fontSize * 0.85, weight: .regular),
                        .foregroundColor: lineNumberColor,
                    ]

                    let stringSize = numberString.size(withAttributes: attributes)
                    let gutterCenter: CGFloat = (gutterWidth - stringSize.width - Self.lineNumberGutterPadding / 2) / 2
                    let x = floor(origin.x + Self.lineNumberGutterPadding / 2 + gutterCenter)
                    let verticalCenter: CGFloat = (usedRect.height - stringSize.height) / 2
                    let y = floor(usedRect.minY + origin.y + verticalCenter)

                    numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
                    lineNumber += 1
                }
            }
        }

        private func getCodeFont(in text: NSTextStorage, at location: Int) -> NSFont? {
            guard location >= 0, location < text.length else { return nil }
            return text.attribute(.font, at: location, effectiveRange: nil) as? NSFont
        }
    }
#endif
