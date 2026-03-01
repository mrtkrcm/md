//
//  ReaderLayoutManager.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - ReaderLayoutManager

    /// Custom layout manager that draws block-level decorations behind text:
    ///
    /// • **Code blocks**: a single rounded-rect background covering all lines.
    /// • **Blockquotes**: a left-border accent bar + tinted background covering all lines.
    ///
    /// Both are drawn *before* glyph rendering so text sits on top.  No `NSTextBlock` is
    /// used — that API's `drawBackground` is never invoked reliably in SwiftUI-hosted
    /// TK1 views on macOS 14+.
    final class ReaderLayoutManager: NSLayoutManager {
        private static let codeCornerRadius: CGFloat = 6
        private static let codeVPad: CGFloat = 8
        private static let codeHPadding: CGFloat = 12
        private static let bqBarWidth: CGFloat = 3
        private static let bqHPadding: CGFloat = 12
        private static let tableHPadding: CGFloat = 12
        private static let tableVPadding: CGFloat = 6
        private static let tableMinWidth: CGFloat = 280
        private static let tableWidthSlack: CGFloat = 36
        private static let lineNumberGutterPadding: CGFloat = 12
        private static let lineNumberMinWidth: CGFloat = 32

        // MARK: - Decoration Span Types

        private enum SpanKind {
            case code(bg: NSColor)
            case blockquote(bg: NSColor, accent: NSColor, depth: Int)
            case tableHeader(bg: NSColor)
            case tableRow(alternating: Bool, bg: NSColor)
            case horizontalRule(color: NSColor)
        }

        private struct DecorationSpan {
            var charStart: Int
            var charEnd: Int
            var kind: SpanKind
        }

        // MARK: - Drawing

        override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
            // Call super first for selection highlight and standard per-char backgrounds
            // (inline code pills, etc.).  We draw our custom decorations on top of that.
            super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

            guard
                let ts = textStorage,
                let container = textContainers.first,
                let ctx = NSGraphicsContext.current?.cgContext
            else { return }

            let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
            let totalLen = ts.length
            guard totalLen > 0 else { return }

            let spans = collectDecorationSpans(in: ts, charRange: charRange, totalLen: totalLen)
            let containerWidth = container.containerSize.width

            // ── Draw code block backgrounds and line numbers ─────────────────────
            for span in spans.code {
                guard case .code(let bg) = span.kind else { continue }
                let rect = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
                guard !rect.isNull else { continue }

                // Check if this code block has line numbers enabled
                let hasLineNumbers = ts.attribute(
                    MarkdownRenderAttribute.codeBlock,
                    at: span.charStart,
                    effectiveRange: nil
                ) != nil

                // Calculate gutter width for line numbers
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

                // Draw line numbers if enabled
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
                guard case .blockquote(let bg, let accent, let depth) = span.kind else { continue }
                let rect = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
                guard !rect.isNull else { continue }

                // Indent increases with nesting depth
                let leftInset = CGFloat(depth - 1) * 16 + origin.x
                let drawRect = CGRect(
                    x: leftInset,
                    y: rect.minY - 4,
                    width: containerWidth - leftInset,
                    height: rect.height + 8
                )

                ctx.saveGState()

                // Tinted background.
                bg.setFill()
                ctx.fill(drawRect)

                // Left accent bar.
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
                let rect = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
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

                var tableWidth = max(0, containerWidth - 16)
                if
                    tabCount > 0,
                    let paragraph,
                    paragraph.tabStops.count >= tabCount
                {
                    let lastTab = paragraph.tabStops[tabCount - 1].location
                    tableWidth = min(tableWidth, max(Self.tableMinWidth, lastTab + Self.tableWidthSlack))
                }

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

                    // Pass 1 — outer frame lines at full border opacity.
                    borderColor.setStroke()
                    ctx.beginPath()
                    // Top horizontal edge (every row)
                    ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.minY))
                    // Bottom horizontal edge: after header row, and always on the last span
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
                    // Outer vertical edges
                    ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.minX, y: rowRect.maxY))
                    ctx.move(to: CGPoint(x: rowRect.maxX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.maxY))
                    ctx.strokePath()

                    // Pass 2 — interior column dividers at reduced opacity.
                    // Column guides are secondary structure: dimming them lets the outer
                    // border read as the dominant visual container.
                    if let paragraph, tabCount > 0 {
                        let rawMultiplier: CGFloat
                        if span.charStart >= 0, span.charStart < ts.length {
                            rawMultiplier = ts.attribute(
                                MarkdownRenderAttribute.tableColumnDividerOpacity,
                                at: span.charStart,
                                effectiveRange: nil
                            ) as? CGFloat ?? 0.45
                        } else {
                            rawMultiplier = 0.45
                        }
                        // Clamp to a safe range — an out-of-bounds stored value must not
                        // produce a negative alpha or overflow the NSColor constructor.
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
                guard case .horizontalRule(let color) = span.kind else { continue }
                let rect = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
                guard !rect.isNull else { continue }

                // Center the hairline vertically in the line fragment.
                let lineY = floor(rect.midY) + 0.5

                // Inset horizontally to align with the readable column, matching
                // the text container inset used by ReaderTextView.
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
        }

        // MARK: - Span Collection

        private struct DecorationSpans {
            var code: [DecorationSpan] = []
            var bq: [DecorationSpan] = []
            var table: [DecorationSpan] = []
            var hr: [DecorationSpan] = []
        }

        /// Scans the visible character range and groups characters by their decoration kind.
        /// Extracted from `drawBackground` to keep that method within cyclomatic complexity limits.
        private func collectDecorationSpans(
            in ts: NSTextStorage,
            charRange: NSRange,
            totalLen: Int
        ) -> DecorationSpans {
            var spans = DecorationSpans()

            let scanStart = max(0, charRange.location)
            let scanEnd = min(charRange.location + charRange.length, totalLen)
            var i = scanStart

            while i < scanEnd {
                var effectiveRange = NSRange(location: i, length: 1)
                let intent = ts.attribute(
                    MarkdownRenderAttribute.presentationIntent,
                    at: i,
                    effectiveRange: &effectiveRange
                ) as? PresentationIntent
                let end = min(effectiveRange.location + effectiveRange.length, totalLen)
                guard end > i else { break }

                let isCode = intent?.components.contains {
                    if case .codeBlock = $0.kind { return true }; return false
                } ?? false

                let bqDepth = ts.attribute(
                    MarkdownRenderAttribute.blockquoteDepth, at: i, effectiveRange: nil
                ) as? Int ?? 0
                let tableHeaderBG = ts.attribute(
                    MarkdownRenderAttribute.tableHeaderBackground, at: i, effectiveRange: nil
                ) as? NSColor
                let tableRowBG = ts.attribute(
                    MarkdownRenderAttribute.tableRowBackground, at: i, effectiveRange: nil
                ) as? NSColor
                let tableRowAlternating = ts.attribute(
                    MarkdownRenderAttribute.tableRowAlternating, at: i, effectiveRange: nil
                ) as? Bool ?? false

                appendCodeSpan(
                    isCode: isCode, bg: ts.attribute(.backgroundColor, at: i, effectiveRange: nil) as? NSColor,
                    effectiveStart: effectiveRange.location, end: end, to: &spans.code, at: i
                )
                appendBQSpan(
                    depth: bqDepth, ts: ts, at: i, effectiveStart: effectiveRange.location,
                    end: end, to: &spans.bq
                )
                appendHRSpan(
                    ts: ts, at: i, effectiveStart: effectiveRange.location, end: end, to: &spans.hr
                )
                appendTableSpan(
                    headerBG: tableHeaderBG, rowBG: tableRowBG, alternating: tableRowAlternating,
                    ts: ts, at: i, effectiveStart: effectiveRange.location, end: end, to: &spans.table
                )

                i = end
            }
            return spans
        }

        private func appendCodeSpan(
            isCode: Bool,
            bg: NSColor?,
            effectiveStart: Int,
            end: Int,
            to spans: inout [DecorationSpan],
            at i: Int
        ) {
            guard isCode, let bg else { return }
            if let last = spans.last, last.charEnd >= i {
                spans[spans.count - 1].charEnd = max(spans[spans.count - 1].charEnd, end)
            } else {
                spans.append(DecorationSpan(charStart: effectiveStart, charEnd: end, kind: .code(bg: bg)))
            }
        }

        private func appendBQSpan(
            depth: Int,
            ts: NSTextStorage,
            at i: Int,
            effectiveStart: Int,
            end: Int,
            to spans: inout [DecorationSpan]
        ) {
            guard
                depth > 0,
                let bg = ts.attribute(
                    MarkdownRenderAttribute.blockquoteBackground,
                    at: i,
                    effectiveRange: nil
                ) as? NSColor,
                let accent = ts.attribute(
                    MarkdownRenderAttribute.blockquoteAccent,
                    at: i,
                    effectiveRange: nil
                ) as? NSColor
            else { return }
            if let last = spans.last, last.charEnd >= i {
                spans[spans.count - 1].charEnd = max(spans[spans.count - 1].charEnd, end)
            } else {
                spans.append(DecorationSpan(
                    charStart: effectiveStart,
                    charEnd: end,
                    kind: .blockquote(bg: bg, accent: accent, depth: depth)
                ))
            }
        }

        private func appendHRSpan(
            ts: NSTextStorage,
            at i: Int,
            effectiveStart: Int,
            end: Int,
            to spans: inout [DecorationSpan]
        ) {
            guard
                let color = ts.attribute(
                    MarkdownRenderAttribute.horizontalRule,
                    at: i,
                    effectiveRange: nil
                ) as? NSColor
            else { return }
            if let last = spans.last, last.charEnd >= i {
                spans[spans.count - 1].charEnd = max(spans[spans.count - 1].charEnd, end)
            } else {
                spans.append(DecorationSpan(
                    charStart: effectiveStart,
                    charEnd: end,
                    kind: .horizontalRule(color: color)
                ))
            }
        }

        private func appendTableSpan(
            headerBG: NSColor?,
            rowBG: NSColor?,
            alternating: Bool,
            ts: NSTextStorage,
            at i: Int,
            effectiveStart: Int,
            end: Int,
            to spans: inout [DecorationSpan]
        ) {
            if let headerBG {
                if let last = spans.last, last.charEnd >= i, case .tableHeader = last.kind {
                    spans[spans.count - 1].charEnd = max(spans[spans.count - 1].charEnd, end)
                } else {
                    spans.append(DecorationSpan(
                        charStart: effectiveStart,
                        charEnd: end,
                        kind: .tableHeader(bg: headerBG)
                    ))
                }
            } else if
                rowBG != nil || ts
                    .attribute(MarkdownRenderAttribute.tableBorder, at: i, effectiveRange: nil) != nil
            {
                let bg = rowBG ?? .clear
                if let last = spans.last, last.charEnd >= i, case .tableRow = last.kind {
                    spans[spans.count - 1].charEnd = max(spans[spans.count - 1].charEnd, end)
                } else {
                    spans.append(DecorationSpan(
                        charStart: effectiveStart,
                        charEnd: end,
                        kind: .tableRow(alternating: alternating, bg: bg)
                    ))
                }
            }
        }

        // MARK: - Helpers

        private func unionUsedRect(charStart: Int, charEnd: Int, origin: NSPoint) -> CGRect {
            let glRange = glyphRange(
                forCharacterRange: NSRange(location: charStart, length: charEnd - charStart),
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
            // Bounds check
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
            // Clamp range to valid bounds
            let safeLocation = max(0, min(range.location, nsString.length))
            let safeLength = max(0, min(range.length, nsString.length - safeLocation))
            guard safeLength > 0 else { return 1 }

            // Single-pass newline count — avoids allocating an array of split components
            let safeEnd = safeLocation + safeLength
            var count = 1
            for i in safeLocation ..< safeEnd {
                if nsString.character(at: i) == 0x0A { count += 1 }
            }
            // Adjust for trailing newline (it doesn't start a visible line)
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

            // Get text color (muted version for line numbers)
            let textColor = (text.attribute(.foregroundColor, at: span.charStart, effectiveRange: nil) as? NSColor) ??
                .secondaryLabelColor
            let lineNumberColor = textColor.withAlphaComponent(0.5)

            // Draw line numbers for each line fragment
            var lineNumber = 1
            enumerateLineFragments(forGlyphRange: glyphRange) { [weak self] _, usedRect, _, glyphRangeForLine, _ in
                guard let self else { return }

                // Check if this line fragment starts a new line (not a soft wrap)
                let charRangeForLine = characterRange(forGlyphRange: glyphRangeForLine, actualGlyphRange: nil)
                let lineStart = charRangeForLine.location

                // Only draw line number for the first fragment of each line
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
                    // Pixel-snap to avoid blurry text on non-Retina displays
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
