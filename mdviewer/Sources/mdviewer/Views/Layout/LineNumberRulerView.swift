//
//  LineNumberRulerView.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - Line Number Ruler

    /// A custom ruler view that displays line numbers for NSTextView
    final class LineNumberRulerView: NSRulerView {
        private var font: NSFont = .monospacedSystemFont(ofSize: 11, weight: .regular)
        private var textColor: NSColor = .secondaryLabelColor
        private var separatorColor: NSColor = .separatorColor
        private var backgroundColor: NSColor = .controlBackgroundColor
        /// Cache line-number string sizes by digit count to avoid redundant text measurement
        private var cachedSizesByDigitCount: [Int: NSSize] = [:]

        init(scrollView: NSScrollView?) {
            super.init(scrollView: scrollView, orientation: .verticalRuler)
            ruleThickness = 40
            needsDisplay = true

            // Accessibility configuration
            setAccessibilityLabel("Line Numbers")
            setAccessibilityRole(.staticText)
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func awakeFromNib() {
            super.awakeFromNib()
            MainActor.assumeIsolated {
                self.ruleThickness = 40
            }
        }

        /// Define the required thickness for the ruler
        override var requiredThickness: CGFloat {
            40
        }

        override func draw(_ dirtyRect: NSRect) {
            // Fill background
            backgroundColor.setFill()
            dirtyRect.fill()

            // Draw separator line on the right edge
            let separatorPath = NSBezierPath()
            separatorPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: dirtyRect.minY))
            separatorPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: dirtyRect.maxY))
            separatorColor.withAlphaComponent(0.3).setStroke()
            separatorPath.lineWidth = 0.5
            separatorPath.stroke()

            // Draw line numbers
            drawLineNumbers(in: dirtyRect)
        }

        func applyStyle(
            textColor: NSColor,
            separatorColor: NSColor,
            backgroundColor: NSColor
        ) {
            self.textColor = textColor
            self.separatorColor = separatorColor
            self.backgroundColor = backgroundColor
            needsDisplay = true
        }

        private func drawLineNumbers(in rect: NSRect) {
            guard
                let textView = clientView as? NSTextView,
                let layoutManager = textView.layoutManager,
                let textContainer = textView.textContainer else { return }

            // Get the visible glyph range
            let visibleRect = textView.visibleRect
            let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
            let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

            guard glyphRange.length > 0 || textView.string.isEmpty else { return }

            let string = textView.string as NSString
            var lineNumber = 1

            // Count lines up to the visible range start via single-pass newline scan
            if characterRange.location > 0 {
                let end = min(characterRange.location, string.length)
                for i in 0 ..< end {
                    if string.character(at: i) == 0x0A { lineNumber += 1 }
                }
            }

            // Get the text view's coordinate conversion
            layoutManager
                .enumerateLineFragments(forGlyphRange: glyphRange) { [weak self] lineRect, _, _, glyphRangeForLine, _ in
                    guard let self else { return }

                    // Get the character range for this line fragment
                    let charRange = layoutManager.characterRange(
                        forGlyphRange: glyphRangeForLine,
                        actualGlyphRange: nil
                    )
                    let lineStart = charRange.location

                    // Only draw line number for the first fragment of each line (not soft wraps)
                    let isFirstFragment = lineStart == 0 ||
                        (lineStart > 0 && lineStart - 1 < string.length && string.character(at: lineStart - 1) == 0x0A)

                    if isFirstFragment {
                        // Convert the line rect to ruler coordinates
                        let convertedRect = textView.convert(lineRect, to: self)

                        // Only draw if visible in the ruler's dirty rect
                        if convertedRect.intersects(rect) {
                            let numberString = "\(lineNumber)" as NSString
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: font,
                                .foregroundColor: textColor,
                            ]
                            let digitCount = numberString.length
                            let stringSize: NSSize
                            if let cached = cachedSizesByDigitCount[digitCount] {
                                stringSize = cached
                            } else {
                                let measured = numberString.size(withAttributes: attributes)
                                cachedSizesByDigitCount[digitCount] = measured
                                stringSize = measured
                            }

                            // Right-align the number with padding; pixel-snap to avoid blurry text
                            let x = floor(max(2, ruleThickness - stringSize.width - 8))
                            let y = floor(convertedRect.minY + (convertedRect.height - stringSize.height) / 2)

                            numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
                        }

                        lineNumber += 1
                    }
                }

            // Handle empty document case - show line 1
            if textView.string.isEmpty {
                let numberString = "1" as NSString
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: textColor,
                ]
                let stringSize = numberString.size(withAttributes: attributes)
                let x = floor(ruleThickness - stringSize.width - 8)
                let y = floor(textView.textContainerInset.height + (font.pointSize - stringSize.height) / 2)
                numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
            }
        }
    }
#endif
