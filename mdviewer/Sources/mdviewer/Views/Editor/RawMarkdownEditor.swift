//
//  RawMarkdownEditor.swift
//  mdviewer
//

internal import AppKit
internal import OSLog
internal import SwiftUI

// MARK: - Raw Markdown Editor

/// SwiftUI wrapper using native NSTextView for markdown editing.
/// Provides comprehensive syntax highlighting, proper spacing, and full VoiceOver support.
struct RawMarkdownEditor: View {
    @Binding var text: String
    let fontSize: CGFloat
    let colorScheme: ColorScheme
    let showLineNumbers: Bool
    var onScroll: ((CGFloat, CGFloat, CGFloat) -> Void)?

    var body: some View {
        RawEditorRepresentable(
            text: $text,
            fontSize: fontSize,
            colorScheme: colorScheme,
            showLineNumbers: showLineNumbers,
            onScroll: onScroll
        )
        .background(colorScheme == .dark ? Color.black : Color.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Markdown Source Editor")
        .accessibilityHint("Edit raw markdown text with syntax highlighting")
        .accessibilityIdentifier("RawMarkdownEditor")
        // Provide dynamic value updates for VoiceOver
        .accessibilityValue(text.isEmpty ? "Empty document" : "\(text.count) characters")
    }
}

// MARK: - Raw Editor Representable

/// Custom NSViewRepresentable with integrated line numbers and syntax highlighting.
private struct RawEditorRepresentable: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let colorScheme: ColorScheme
    let showLineNumbers: Bool
    var onScroll: ((CGFloat, CGFloat, CGFloat) -> Void)?

    private let logger = Logger(subsystem: "mdviewer", category: "RawEditor")

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = ScrollTrackingScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = colorScheme == .dark ? .black : .white
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.onScroll = onScroll

        // Configure line numbers if enabled
        if showLineNumbers {
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }

        let textView = RawEditorTextView()
        textView.isRichText = true
        textView.usesFindBar = true
        textView.allowsUndo = true
        textView.drawsBackground = true
        textView.focusRingType = .none
        textView.isEditable = true
        textView.isSelectable = true

        // Configure accessibility for VoiceOver
        textView.setAccessibilityLabel("Markdown Source Editor")
        textView.setAccessibilityRole(.textArea)
        textView.setAccessibilityIdentifier("RawMarkdownEditor")

        // Zero top inset, small horizontal padding
        textView.textContainerInset = NSSize(width: 8, height: 0)
        textView.textContainer?.lineFragmentPadding = 4

        // Layout
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        // Store configuration
        textView.fontSize = fontSize
        textView.colorScheme = colorScheme

        scrollView.documentView = textView

        // Set text and apply highlighting
        textView.string = text
        applyHighlighting(to: textView)

        // Set up line number ruler
        if showLineNumbers {
            let ruler = RawLineNumberRulerView(scrollView: scrollView)
            ruler.fontSize = fontSize
            ruler.colorScheme = colorScheme
            scrollView.verticalRulerView = ruler

            // Add navigation actions
            textView.setAccessibilityCustomActions([
                NSAccessibilityCustomAction(
                    name: "Jump to Top",
                    target: textView,
                    selector: #selector(RawEditorTextView.jumpToTop)
                ),
                NSAccessibilityCustomAction(
                    name: "Jump to Bottom",
                    target: textView,
                    selector: #selector(RawEditorTextView.jumpToBottom)
                ),
            ])
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let trackingScrollView = scrollView as? ScrollTrackingScrollView {
            trackingScrollView.onScroll = onScroll
        }
        guard let textView = scrollView.documentView as? RawEditorTextView else { return }

        // Update configuration
        textView.fontSize = fontSize
        textView.colorScheme = colorScheme

        if textView.string != text {
            logger.debug("updateNSView: text changed, length = \(text.count)")
            textView.string = text
            applyHighlighting(to: textView)

            // Update accessibility value for VoiceOver
            let accessibilityValue = text.isEmpty ? "Empty document" : "\(text.count) characters"
            textView.setAccessibilityValue(accessibilityValue)
        }

        // Update ruler if present
        if let ruler = scrollView.verticalRulerView as? RawLineNumberRulerView {
            ruler.fontSize = fontSize
            ruler.colorScheme = colorScheme
            ruler.needsDisplay = true
        }
    }

    // MARK: - Syntax Highlighting

    private func applyHighlighting(to textView: NSTextView) {
        guard let storage = textView.textStorage else {
            logger.error("No text storage available")
            return
        }

        let fullRange = NSRange(location: 0, length: storage.length)
        guard fullRange.length > 0 else {
            logger.debug("Empty text, skipping highlighting")
            return
        }

        logger.debug("Applying highlighting to \(fullRange.length) characters")

        let isDark = colorScheme == .dark

        // Colors - use semantic colors for better contrast
        let baseColor = isDark ? NSColor.labelColor : NSColor.textColor
        let headerColor = isDark ? NSColor.systemOrange : NSColor.systemRed
        let codeColor = isDark ? NSColor.systemTeal : NSColor.systemBlue
        let linkColor = isDark ? NSColor.systemIndigo : NSColor.systemIndigo
        let listColor = isDark ? NSColor.systemYellow : NSColor.systemOrange

        // Step 1: Apply base font and color to ENTIRE text first
        let baseFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        storage.addAttribute(.font, value: baseFont, range: fullRange)
        storage.addAttribute(.foregroundColor, value: baseColor, range: fullRange)

        logger.debug("Base attributes applied")

        // Step 2: Find and highlight code blocks FIRST (they have highest priority)
        highlightCodeBlocks(in: storage, fullRange: fullRange, codeColor: codeColor, baseFont: baseFont)

        // Step 3: Headers (full line matches)
        if let headerPattern = try? NSRegularExpression(pattern: #"^#{1,6}\s+.+$"#, options: .anchorsMatchLines) {
            let matches = headerPattern.matches(in: storage.string, options: [], range: fullRange)
            logger.debug("Found \(matches.count) headers")
            for match in matches {
                // Only apply if not already colored as code
                if !isRangeInCodeBlock(match.range, in: storage) {
                    storage.addAttribute(.foregroundColor, value: headerColor, range: match.range)
                    let boldFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                    storage.addAttribute(.font, value: boldFont, range: match.range)
                }
            }
        }

        // Step 4: Links
        if let linkPattern = try? NSRegularExpression(pattern: #"\[[^\]]+\]\([^)]+\)"#) {
            let matches = linkPattern.matches(in: storage.string, options: [], range: fullRange)
            logger.debug("Found \(matches.count) links")
            for match in matches {
                if !isRangeInCodeBlock(match.range, in: storage) {
                    storage.addAttribute(.foregroundColor, value: linkColor, range: match.range)
                }
            }
        }

        // Step 5: Bold
        if let boldPattern = try? NSRegularExpression(pattern: #"\*\*[^*]+\*\*|__[^_]+__"#) {
            let matches = boldPattern.matches(in: storage.string, options: [], range: fullRange)
            logger.debug("Found \(matches.count) bold sections")
            for match in matches {
                if !isRangeInCodeBlock(match.range, in: storage) {
                    let boldFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                    storage.addAttribute(.font, value: boldFont, range: match.range)
                }
            }
        }

        // Step 6: List markers
        if let listPattern = try? NSRegularExpression(pattern: #"^[\s]*[-*+]\s"#, options: .anchorsMatchLines) {
            let matches = listPattern.matches(in: storage.string, options: [], range: fullRange)
            logger.debug("Found \(matches.count) list markers")
            for match in matches {
                if !isRangeInCodeBlock(match.range, in: storage) {
                    storage.addAttribute(.foregroundColor, value: listColor, range: match.range)
                }
            }
        }

        logger.debug("Highlighting complete")
    }

    /// Highlights code blocks and tracks their ranges to prevent other highlighting.
    private func highlightCodeBlocks(
        in storage: NSTextStorage,
        fullRange: NSRange,
        codeColor: NSColor,
        baseFont: NSFont
    ) {
        let nsString = storage.string as NSString

        // Find code fence pairs (``` or ~~~)
        guard
            let fencePattern = try? NSRegularExpression(
                pattern: #"^```|~~~[a-zA-Z]*$"#,
                options: .anchorsMatchLines
            )
        else { return }

        let fenceMatches = fencePattern.matches(in: storage.string, options: [], range: fullRange)
        logger.debug("Found \(fenceMatches.count) code fences")

        // Process fence pairs
        var i = 0
        while i < fenceMatches.count - 1 {
            let openFence = fenceMatches[i]
            let closeFence = fenceMatches[i + 1]

            // Get the line ranges for both fences
            let openLine = nsString.lineRange(for: openFence.range)
            let closeLine = nsString.lineRange(for: closeFence.range)

            // Calculate the range between fences (including the fences themselves)
            let codeStart = openLine.location
            let codeEnd = closeLine.location + closeLine.length
            let codeLength = codeEnd - codeStart

            guard codeLength > 0 else {
                i += 1
                continue
            }

            let codeRange = NSRange(location: codeStart, length: codeLength)

            // Apply code highlighting
            storage.addAttribute(.foregroundColor, value: codeColor, range: codeRange)

            // Mark this range as code block for other highlighters to skip
            // Use higher alpha for better contrast in accessibility modes
            storage.addAttribute(
                .backgroundColor,
                value: codeColor.withAlphaComponent(0.15),
                range: codeRange
            )

            logger.debug("Highlighted code block: \(codeRange.location)-\(codeRange.location + codeRange.length)")

            i += 2 // Skip to next pair
        }
    }

    /// Checks if a range overlaps with an already-highlighted code block.
    private func isRangeInCodeBlock(_ range: NSRange, in storage: NSTextStorage) -> Bool {
        // Check if this range has the code block background color
        if range.location >= storage.length { return false }

        let effectiveRange = NSRange(
            location: range.location,
            length: min(range.length, storage.length - range.location)
        )
        guard effectiveRange.length > 0 else { return false }

        if
            let bgColor = storage.attribute(
                .backgroundColor,
                at: effectiveRange.location,
                effectiveRange: nil
            ) as? NSColor
        {
            // Check if it's the semi-transparent code color
            return bgColor.alphaComponent < 1.0 && bgColor.alphaComponent > 0
        }

        return false
    }
}

// MARK: - Raw Editor Text View

/// Custom NSTextView that stores configuration for highlighting updates.
private final class RawEditorTextView: NSTextView {
    var fontSize: CGFloat = 14
    var colorScheme: ColorScheme = .light

    // MARK: - Accessibility

    override func accessibilityCustomActions() -> [NSAccessibilityCustomAction]? {
        var actions = super.accessibilityCustomActions() ?? []

        // Add navigation actions
        actions.append(NSAccessibilityCustomAction(
            name: "Jump to Top",
            target: self,
            selector: #selector(jumpToTop)
        ))

        actions.append(NSAccessibilityCustomAction(
            name: "Jump to Bottom",
            target: self,
            selector: #selector(jumpToBottom)
        ))

        actions.append(NSAccessibilityCustomAction(
            name: "Select All",
            target: self,
            selector: #selector(selectAll)
        ))

        return actions
    }

    @objc
    func jumpToTop() -> Bool {
        scrollToBeginningOfDocument(nil)
        setSelectedRange(NSRange(location: 0, length: 0))
        return true
    }

    @objc
    func jumpToBottom() -> Bool {
        scrollToEndOfDocument(nil)
        guard let storage = textStorage else { return true }
        let endLocation = storage.length
        setSelectedRange(NSRange(location: endLocation, length: 0))
        return true
    }
}

// MARK: - Line Number Ruler View

/// Custom ruler view that draws line numbers synchronized with scroll.
/// Provides high-contrast line numbers that adapt to accessibility settings.
private final class RawLineNumberRulerView: NSRulerView {
    var fontSize: CGFloat = 14
    var colorScheme: ColorScheme = .light

    private var digitWidth: CGFloat { fontSize * 0.6 }
    private var padding: CGFloat { fontSize * 0.8 }

    /// Minimum contrast ratio for WCAG AA compliance (4.5:1 for normal text)
    private let minimumContrastRatio: CGFloat = 4.5

    init(scrollView: NSScrollView?) {
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        ruleThickness = 40
        needsDisplay = true

        // Set accessibility label for the ruler
        setAccessibilityLabel("Line Numbers")
        setAccessibilityRole(.staticText)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var requiredThickness: CGFloat {
        // Calculate based on number of digits needed
        guard let textView = scrollView?.documentView as? NSTextView else { return 40 }
        let lineCount = max(1, textView.string.components(separatedBy: .newlines).count)
        let digits = String(lineCount).count
        return max(32, (CGFloat(digits) * digitWidth) + padding)
    }

    override func draw(_ dirtyRect: NSRect) {
        // Fill background - higher contrast for accessibility
        let bgColor = colorScheme == .dark
            ? NSColor.black.withAlphaComponent(0.4)
            : NSColor.gray.withAlphaComponent(0.12)
        bgColor.setFill()
        dirtyRect.fill()

        // Draw separator - more visible
        let separatorColor = colorScheme == .dark
            ? NSColor.gray.withAlphaComponent(0.5)
            : NSColor.gray.withAlphaComponent(0.3)
        separatorColor.setStroke()
        let separatorPath = NSBezierPath()
        separatorPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: dirtyRect.minY))
        separatorPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: dirtyRect.maxY))
        separatorPath.lineWidth = 1
        separatorPath.stroke()

        // Draw line numbers
        drawLineNumbers(in: dirtyRect)
    }

    private func drawLineNumbers(in rect: NSRect) {
        guard
            let textView = scrollView?.documentView as? NSTextView,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer else { return }

        // Use secondary label color for better contrast than tertiary
        let textColor = colorScheme == .dark
            ? NSColor.secondaryLabelColor
            : NSColor.secondaryLabelColor
        let font = NSFont.monospacedSystemFont(ofSize: fontSize * 0.85, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
        ]

        // Get the visible glyph range
        let visibleRect = scrollView?.documentVisibleRect ?? rect
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)

        // Get the character range for visible glyphs
        let visibleCharRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)

        // Calculate starting line number
        let text = textView.string as NSString
        var lineNumber = 1
        if visibleCharRange.location > 0 {
            for i in 0 ..< visibleCharRange.location {
                if text.character(at: i) == 0x0A { lineNumber += 1 }
            }
        }

        // Enumerate line fragments and draw numbers
        layoutManager.enumerateLineFragments(forGlyphRange: visibleGlyphRange) { [weak self] lineRect, _, _, _, _ in
            guard let self else { return }

            // Convert to ruler coordinates
            let rulerY = lineRect.minY - visibleRect.minY

            // Draw line number
            let numberString = "\(lineNumber)" as NSString
            let stringSize = numberString.size(withAttributes: attributes)

            // Right-align the number
            let x = bounds.maxX - stringSize.width - (padding / 2)
            let y = rulerY + (lineRect.height - stringSize.height) / 2

            numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)

            lineNumber += 1
        }
    }

    /// Called when scroll view scrolls
    override func invalidateHashMarks() {
        super.invalidateHashMarks()
        needsDisplay = true
    }
}

// MARK: - Scroll Tracking Scroll View

/// NSScrollView subclass that reports scroll position changes for toolbar auto-hide.
/// Uses coalesced updates to prevent excessive notifications during smooth scrolling.
@MainActor
private final class ScrollTrackingScrollView: NSScrollView {
    var onScroll: ((CGFloat, CGFloat, CGFloat) -> Void)?

    private var lastReportedOffset: CGFloat = 0
    private var scrollUpdateTask: Task<Void, Never>?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupScrollTracking()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScrollTracking()
    }

    private func setupScrollTracking() {
        postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: contentView
        )
    }

    @objc
    private func boundsDidChange() {
        // Cancel any pending update and schedule a new one
        scrollUpdateTask?.cancel()
        scrollUpdateTask = Task { @MainActor [weak self] in
            // Small delay to coalesce rapid scroll events
            try? await Task.sleep(for: .milliseconds(4)) // ~240fps coalescing
            guard !Task.isCancelled else { return }
            self?.reportScrollPosition()
        }
    }

    private func reportScrollPosition() {
        guard
            let onScroll,
            let documentView else { return }

        let offset = contentView.bounds.origin.y
        let contentHeight = documentView.frame.height
        let visibleHeight = contentView.bounds.height

        // Only report if offset changed significantly (prevents micro-updates)
        guard abs(offset - lastReportedOffset) > 0.5 else { return }
        lastReportedOffset = offset

        onScroll(offset, contentHeight, visibleHeight)
    }

    deinit {
        scrollUpdateTask?.cancel()
    }
}
