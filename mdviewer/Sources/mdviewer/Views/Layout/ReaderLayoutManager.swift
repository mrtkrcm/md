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
        private static let codeCornerRadius: CGFloat = 8
        private static let codeVPad: CGFloat = 12
        private static let bqBarWidth: CGFloat = 3
        private static let lineNumberGutterPadding: CGFloat = 12
        private static let lineNumberMinWidth: CGFloat = 32

        // MARK: - Decoration Span Types

        private enum SpanKind {
            case code(bg: NSColor)
            case blockquote(bg: NSColor, accent: NSColor, depth: Int)
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

            var i = charRange.location
            while i < charRange.location + charRange.length, i < totalLen {
                var effectiveRange = NSRange(location: i, length: 1)
                let intent = ts.attribute(
                    MarkdownRenderAttribute.presentationIntent,
                    at: i,
                    effectiveRange: &effectiveRange
                )
                    as? PresentationIntent
                let end = min(effectiveRange.location + effectiveRange.length, totalLen)

                let isCode = intent?.components.contains {
                    if case .codeBlock = $0.kind { return true }; return false
                } ?? false

                let bqDepth = ts
                    .attribute(MarkdownRenderAttribute.blockquoteDepth, at: i, effectiveRange: nil) as? Int ?? 0

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

                // Indent increases with nesting depth.
                let leftInset = CGFloat(depth - 1) * 16 + origin.x
                let drawRect = CGRect(
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
            let lineCount = countLines(
                in: text,
                range: NSRange(location: range.lowerBound, length: range.upperBound - range.lowerBound)
            )
            let digitCount = String(lineCount).count
            // Approximate width: each digit is ~0.6x font size, plus padding
            let fontSize = getCodeFontSize(in: text, at: range.lowerBound) ?? 14
            return max(CGFloat(digitCount) * fontSize * 0.6 + Self.lineNumberGutterPadding, Self.lineNumberMinWidth)
        }

        private func countLines(in text: NSTextStorage, range: NSRange) -> Int {
            var count = 0
            let substring = (text.string as NSString).substring(with: range)
            // Count non-empty lines
            let lines = substring.components(separatedBy: .newlines)
            count = lines.count
            // Adjust for trailing newline
            if substring.hasSuffix("\n") {
                count -= 1
            }
            return max(1, count)
        }

        private func getCodeFontSize(in text: NSTextStorage, at location: Int) -> CGFloat? {
            guard let font = text.attribute(.font, at: location, effectiveRange: nil) as? NSFont else {
                return nil
            }
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
            let charRange = NSRange(location: span.charStart, length: span.charEnd - span.charStart)
            let glyphRange = glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)

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
                    (text.string as NSString).character(at: lineStart - 1) == 0x0A

                if isFirstFragment {
                    let numberString = "\(lineNumber)" as NSString
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: NSFont.monospacedSystemFont(ofSize: fontSize * 0.85, weight: .regular),
                        .foregroundColor: lineNumberColor,
                    ]

                    let stringSize = numberString.size(withAttributes: attributes)
                    let x = origin.x + Self
                        .lineNumberGutterPadding / 2 +
                        (gutterWidth - stringSize.width - Self.lineNumberGutterPadding / 2) / 2
                    let y = usedRect.minY + origin.y + (usedRect.height - stringSize.height) / 2

                    numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
                    lineNumber += 1
                }
            }
        }

        private func getCodeFont(in text: NSTextStorage, at location: Int) -> NSFont? {
            text.attribute(.font, at: location, effectiveRange: nil) as? NSFont
        }
    }
#endif
