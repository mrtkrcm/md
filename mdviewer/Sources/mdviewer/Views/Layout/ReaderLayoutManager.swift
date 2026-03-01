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
        private static let lineNumberGutterPadding: CGFloat = 12
        private static let lineNumberMinWidth: CGFloat = 32

        // MARK: - Decoration Span Types

        private enum SpanKind {
            case code(bg: NSColor)
            case blockquote(bg: NSColor, accent: NSColor, depth: Int)
            case tableHeader(bg: NSColor)
            case tableRow(alternating: Bool, bg: NSColor)
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

            // ── Collect decoration spans ──────────────────────────────────────────

            var codeSpans: [DecorationSpan] = []
            var bqSpans: [DecorationSpan] = []
            var tableSpans: [DecorationSpan] = []

            let scanStart = max(0, charRange.location)
            let scanEnd = min(charRange.location + charRange.length, totalLen)
            var i = scanStart
            while i < scanEnd {
                var effectiveRange = NSRange(location: i, length: 1)
                let intent = ts.attribute(
                    MarkdownRenderAttribute.presentationIntent,
                    at: i,
                    effectiveRange: &effectiveRange
                )
                    as? PresentationIntent
                let end = min(effectiveRange.location + effectiveRange.length, totalLen)
                guard end > i else { break } // prevent infinite loop on degenerate ranges

                let isCode = intent?.components.contains {
                    if case .codeBlock = $0.kind { return true }; return false
                } ?? false

                let bqDepth = ts
                    .attribute(MarkdownRenderAttribute.blockquoteDepth, at: i, effectiveRange: nil) as? Int ?? 0
                let tableHeaderBG = ts
                    .attribute(MarkdownRenderAttribute.tableHeaderBackground, at: i, effectiveRange: nil) as? NSColor
                let tableRowBG = ts
                    .attribute(MarkdownRenderAttribute.tableRowBackground, at: i, effectiveRange: nil) as? NSColor
                let tableRowAlternating = ts
                    .attribute(MarkdownRenderAttribute.tableRowAlternating, at: i, effectiveRange: nil) as? Bool ?? false

                if isCode, let bg = ts.attribute(.backgroundColor, at: i, effectiveRange: nil) as? NSColor {
                    if let last = codeSpans.last, last.charEnd >= i {
                        codeSpans[codeSpans.count - 1].charEnd = max(codeSpans[codeSpans.count - 1].charEnd, end)
                    } else {
                        codeSpans.append(DecorationSpan(
                            charStart: effectiveRange.location,
                            charEnd: end,
                            kind: .code(bg: bg)
                        ))
                    }
                } else if
                    bqDepth > 0,
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
                {
                    if let last = bqSpans.last, last.charEnd >= i {
                        bqSpans[bqSpans.count - 1].charEnd = max(bqSpans[bqSpans.count - 1].charEnd, end)
                    } else {
                        bqSpans.append(DecorationSpan(
                            charStart: effectiveRange.location,
                            charEnd: end,
                            kind: .blockquote(bg: bg, accent: accent, depth: bqDepth)
                        ))
                    }
                }

                if let headerBG = tableHeaderBG {
                    if let last = tableSpans.last, last.charEnd >= i,
                       case .tableHeader(_) = last.kind
                    {
                        tableSpans[tableSpans.count - 1].charEnd = max(tableSpans[tableSpans.count - 1].charEnd, end)
                    } else {
                        tableSpans.append(DecorationSpan(
                            charStart: effectiveRange.location,
                            charEnd: end,
                            kind: .tableHeader(bg: headerBG)
                        ))
                    }
                } else if
                    tableRowBG != nil
                        || ts.attribute(MarkdownRenderAttribute.tableBorder, at: i, effectiveRange: nil) != nil
                {
                    let rowBG = tableRowBG ?? .clear
                    if let last = tableSpans.last, last.charEnd >= i,
                       case .tableRow(_, _) = last.kind
                    {
                        tableSpans[tableSpans.count - 1].charEnd = max(tableSpans[tableSpans.count - 1].charEnd, end)
                    } else {
                        tableSpans.append(DecorationSpan(
                            charStart: effectiveRange.location,
                            charEnd: end,
                            kind: .tableRow(alternating: tableRowAlternating, bg: rowBG)
                        ))
                    }
                }

                i = end
            }

            let containerWidth = container.containerSize.width

            // ── Draw code block backgrounds and line numbers ─────────────────────
            for span in codeSpans {
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
            for span in bqSpans {
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
            for span in tableSpans {
                let rect = unionUsedRect(charStart: span.charStart, charEnd: span.charEnd, origin: origin)
                guard !rect.isNull else { continue }

                let paragraph = ts.attribute(.paragraphStyle, at: span.charStart, effectiveRange: nil) as? NSParagraphStyle
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
                    tableWidth = min(tableWidth, max(220, lastTab + 28))
                }

                let rowRect = CGRect(
                    x: origin.x + 8,
                    y: rect.minY - 2,
                    width: tableWidth,
                    height: rect.height + 4
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
                    borderColor.setStroke()
                    ctx.setLineWidth(1)
                    ctx.beginPath()
                    // Horizontal separators
                    ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.minY))
                    if case .tableHeader = span.kind {
                        ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.maxY))
                        ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.maxY))
                    }
                    // Outer vertical edges
                    ctx.move(to: CGPoint(x: rowRect.minX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.minX, y: rowRect.maxY))
                    ctx.move(to: CGPoint(x: rowRect.maxX, y: rowRect.minY))
                    ctx.addLine(to: CGPoint(x: rowRect.maxX, y: rowRect.maxY))

                    // Draw column guides up to the actual tab count in the row text.
                    if let paragraph, tabCount > 0 {
                        for tabStop in paragraph.tabStops.prefix(tabCount) {
                            let x = origin.x + tabStop.location
                            guard x > rowRect.minX, x < rowRect.maxX else { continue }
                            ctx.move(to: CGPoint(x: x, y: rowRect.minY))
                            ctx.addLine(to: CGPoint(x: x, y: rowRect.maxY))
                        }
                    }

                    ctx.strokePath()
                }

                ctx.restoreGState()
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
            guard location >= 0, location < text.length,
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
                    (lineStart > 0 && lineStart - 1 < text.length && (text.string as NSString).character(at: lineStart - 1) == 0x0A)

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
