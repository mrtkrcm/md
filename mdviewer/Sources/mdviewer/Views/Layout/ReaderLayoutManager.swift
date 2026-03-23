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
        private static let lineNumberGutterPadding: CGFloat = 12
        private static let lineNumberMinWidth: CGFloat = 32

        // MARK: - Cache

        private struct DecorationRangeKey: Hashable {
            let charStart: Int
            let charEnd: Int
        }

        private struct CachedDecoration {
            let spans: DecorationSpans
            let usedRects: [DecorationRangeKey: CGRect]
            let generation: Int
            let containerWidth: CGFloat
        }

        private var decorationCache: CachedDecoration?
        private var decorationCacheGeneration = 0

        // MARK: - Decoration Span Types

        private struct TableDecoration: Hashable {
            let backgroundColor: NSColor?
            let borderColor: NSColor?
            let dividerColor: NSColor?
            let naturalWidth: CGFloat
            let rowInsets: TableLayoutMetrics.RowInsets
            let drawsBottomEdge: Bool
            let dividerLocations: [CGFloat]
        }

        private enum SpanKind: Hashable {
            case code(bg: NSColor)
            case blockquote(bg: NSColor, accent: NSColor, depth: Int)
            case table(decoration: TableDecoration)
            case horizontalRule(color: NSColor)
        }

        private struct DecorationSpan: Hashable {
            var charStart: Int
            var charEnd: Int
            var kind: SpanKind

            var rangeKey: DecorationRangeKey {
                DecorationRangeKey(charStart: charStart, charEnd: charEnd)
            }
        }

        private struct DecorationSpans {
            var code: [DecorationSpan] = []
            var bq: [DecorationSpan] = []
            var table: [DecorationSpan] = []
            var hr: [DecorationSpan] = []
        }

        static func blockquoteDrawRect(
            usedRect: CGRect,
            origin: NSPoint,
            containerWidth: CGFloat,
            depth: Int
        ) -> CGRect {
            let nestingInset = CGFloat(max(0, depth - 1)) * 16
            return CGRect(
                x: origin.x + nestingInset,
                y: usedRect.minY - 4,
                width: max(0, containerWidth - nestingInset),
                height: usedRect.height + 8
            )
        }

        static func tableRowDrawRect(
            usedRect: CGRect,
            origin: NSPoint,
            containerWidth: CGFloat,
            naturalTableWidth: CGFloat,
            rowInsets: TableLayoutMetrics.RowInsets
        ) -> CGRect {
            let tableWidth = min(
                containerWidth,
                max(TableLayoutMetrics.minimumTableWidth, naturalTableWidth)
            )

            return CGRect(
                x: origin.x,
                y: usedRect.minY - rowInsets.top,
                width: tableWidth,
                height: usedRect.height + rowInsets.top + rowInsets.bottom
            )
        }

        func invalidateDecorationCache() {
            decorationCacheGeneration &+= 1
            decorationCache = nil
        }

        override func processEditing(
            for textStorage: NSTextStorage,
            edited editMask: NSTextStorageEditActions,
            range newCharRange: NSRange,
            changeInLength delta: Int,
            invalidatedRange invalidatedCharRange: NSRange
        ) {
            invalidateDecorationCache()
            super.processEditing(
                for: textStorage,
                edited: editMask,
                range: newCharRange,
                changeInLength: delta,
                invalidatedRange: invalidatedCharRange
            )
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

            // ── Validate and Update Cache ────────────────────────────────────────
            let spans: DecorationSpans
            var usedRects: [DecorationRangeKey: CGRect]

            if
                let cached = decorationCache,
                cached.generation == decorationCacheGeneration,
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
                    generation: decorationCacheGeneration,
                    containerWidth: containerWidth
                )
            }

            // Only draw spans that intersect with the current glyph range
            let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

            // ── Draw code block backgrounds and line numbers ─────────────────────
            for span in spans.code {
                guard span.charEnd > charRange.location, span.charStart < NSMaxRange(charRange) else { continue }
                guard case .code(let bg) = span.kind else { continue }

                let rect = cachedUsedRect(for: span, usedRects: &usedRects, origin: origin)
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

                let rect = cachedUsedRect(for: span, usedRects: &usedRects, origin: origin)
                guard !rect.isNull else { continue }

                let drawRect = Self.blockquoteDrawRect(
                    usedRect: rect,
                    origin: origin,
                    containerWidth: containerWidth,
                    depth: depth
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
            for span in spans.table {
                guard span.charEnd > charRange.location, span.charStart < NSMaxRange(charRange) else { continue }
                guard case .table(let decoration) = span.kind else { continue }

                let rect = cachedUsedRect(for: span, usedRects: &usedRects, origin: origin)
                guard !rect.isNull else { continue }

                let rowRect = Self.tableRowDrawRect(
                    usedRect: rect,
                    origin: origin,
                    containerWidth: containerWidth,
                    naturalTableWidth: decoration.naturalWidth,
                    rowInsets: decoration.rowInsets
                )
                guard rowRect.width > 0, rowRect.height > 0 else { continue }

                ctx.saveGState()
                if let backgroundColor = decoration.backgroundColor {
                    backgroundColor.setFill()
                    ctx.fill(rowRect)
                }

                if let borderColor = decoration.borderColor {
                    ctx.setLineWidth(0.5)
                    borderColor.setStroke()
                    ctx.beginPath()
                    ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.minY))
                    if decoration.drawsBottomEdge {
                        ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.maxY))
                        ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.maxY))
                    }
                    ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.minX, y: rowRect.maxY))
                    ctx.move(to: CGPoint(x: rowRect.maxX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.maxY))
                    ctx.strokePath()

                    if let dividerColor = decoration.dividerColor, !decoration.dividerLocations.isEmpty {
                        dividerColor.setStroke()
                        ctx.beginPath()
                        for dividerLocation in decoration.dividerLocations {
                            let x = origin.x + dividerLocation
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

                let rect = cachedUsedRect(for: span, usedRects: &usedRects, origin: origin)
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
                generation: decorationCacheGeneration,
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
            let nsString = ts.string as NSString
            var seenTableRows: Set<NSRange> = []

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
                        let lineRange = nsString.lineRange(for: NSRange(location: range.location, length: 0))
                        guard seenTableRows.insert(lineRange).inserted else { continue }
                        guard let decoration = tableDecoration(in: ts, at: range.location, isHeader: true) else {
                            continue
                        }
                        spans.table.append(DecorationSpan(
                            charStart: lineRange.location,
                            charEnd: NSMaxRange(lineRange),
                            kind: .table(decoration: decoration)
                        ))
                    case .tableRow:
                        let lineRange = nsString.lineRange(for: NSRange(location: range.location, length: 0))
                        guard seenTableRows.insert(lineRange).inserted else { continue }
                        guard let decoration = tableDecoration(in: ts, at: range.location, isHeader: false) else {
                            continue
                        }
                        spans.table.append(DecorationSpan(
                            charStart: lineRange.location,
                            charEnd: NSMaxRange(lineRange),
                            kind: .table(decoration: decoration)
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

        private func tableDecoration(
            in textStorage: NSTextStorage,
            at location: Int,
            isHeader: Bool
        ) -> TableDecoration? {
            guard
                let paragraphStyle = textStorage.attribute(
                    .paragraphStyle,
                    at: location,
                    effectiveRange: nil
                ) as? NSParagraphStyle
            else { return nil }

            let columnCount = textStorage.attribute(
                MarkdownRenderAttribute.tableColumnCount,
                at: location,
                effectiveRange: nil
            ) as? Int ?? 1
            let isTerminalRow = textStorage.attribute(
                MarkdownRenderAttribute.tableTerminalRow,
                at: location,
                effectiveRange: nil
            ) as? Bool ?? false
            let borderColor = textStorage.attribute(
                MarkdownRenderAttribute.tableBorder,
                at: location,
                effectiveRange: nil
            ) as? NSColor
            let dividerOpacity = max(
                0.0,
                min(
                    1.0,
                    textStorage.attribute(
                        MarkdownRenderAttribute.tableColumnDividerOpacity,
                        at: location,
                        effectiveRange: nil
                    ) as? CGFloat ?? 0.45
                )
            )
            let leadingInset = max(
                TableLayoutMetrics.contentInset,
                paragraphStyle.firstLineHeadIndent,
                paragraphStyle.headIndent
            )
            let tabStopLocations = TableLayoutMetrics.tabStopLocations(
                paragraphStyle: paragraphStyle,
                columnCount: columnCount
            )
            let naturalWidth = TableLayoutMetrics.naturalTableWidth(
                leadingInset: leadingInset,
                dividerLocations: tabStopLocations,
                columnCount: columnCount
            )
            let dividerLocations = TableLayoutMetrics.dividerLocations(
                paragraphStyle: paragraphStyle,
                columnCount: columnCount
            )
            let rowInsets = TableLayoutMetrics.rowInsets(
                paragraphStyle: paragraphStyle,
                isTerminalRow: isTerminalRow
            )
            let dividerColor = borderColor?.withAlphaComponent((borderColor?.alphaComponent ?? 0) * dividerOpacity)

            return TableDecoration(
                backgroundColor: resolvedTableBackground(in: textStorage, at: location, isHeader: isHeader),
                borderColor: borderColor,
                dividerColor: dividerColor,
                naturalWidth: naturalWidth,
                rowInsets: rowInsets,
                drawsBottomEdge: isHeader || isTerminalRow,
                dividerLocations: dividerLocations
            )
        }

        private func resolvedTableBackground(
            in textStorage: NSTextStorage,
            at location: Int,
            isHeader: Bool
        ) -> NSColor? {
            if isHeader {
                return textStorage.attribute(
                    MarkdownRenderAttribute.tableHeaderBackground,
                    at: location,
                    effectiveRange: nil
                ) as? NSColor
            }

            if
                let alternatingBackground = textStorage.attribute(
                    MarkdownRenderAttribute.tableRowBackground,
                    at: location,
                    effectiveRange: nil
                ) as? NSColor
            {
                return alternatingBackground
            }

            return textStorage.attribute(
                MarkdownRenderAttribute.tableBodyBackground,
                at: location,
                effectiveRange: nil
            ) as? NSColor
        }

        private func cachedUsedRect(
            for span: DecorationSpan,
            usedRects: inout [DecorationRangeKey: CGRect],
            origin: NSPoint
        ) -> CGRect {
            if let cachedRect = usedRects[span.rangeKey] {
                return cachedRect
            }

            let rect = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
            usedRects[span.rangeKey] = rect
            return rect
        }

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
