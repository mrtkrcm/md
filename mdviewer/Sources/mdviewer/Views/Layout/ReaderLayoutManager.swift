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
        private static let codeVPad: CGFloat = 6
        private static let bqBarWidth: CGFloat = 3

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

            enum SpanKind {
                case code(bg: NSColor)
                case blockquote(bg: NSColor, accent: NSColor, depth: Int)
            }
            struct Span { var charStart: Int; var charEnd: Int; var kind: SpanKind }

            var codeSpans: [Span] = []
            var bqSpans: [Span] = []

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
                        codeSpans.append(Span(charStart: effectiveRange.location, charEnd: end, kind: .code(bg: bg)))
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
                        bqSpans.append(Span(
                            charStart: effectiveRange.location,
                            charEnd: end,
                            kind: .blockquote(bg: bg, accent: accent, depth: bqDepth)
                        ))
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
                ctx.addPath(CGPath(
                    roundedRect: drawRect,
                    cornerWidth: Self.codeCornerRadius,
                    cornerHeight: Self.codeCornerRadius,
                    transform: nil
                ))
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
    }
#endif
