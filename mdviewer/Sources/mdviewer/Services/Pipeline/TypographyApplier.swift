//
//  TypographyApplier.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Typography Applier

/// Applies professional typography styling including fonts, colors, and spacing.
///
/// This component configures the visual appearance of rendered Markdown
/// based on the requested theme, font family, and spacing preferences.
/// Implements modern typesetting best practices for optimal readability.
struct TypographyApplier: TypographyApplying {
    // MARK: - Typography Application

    func applyTypography(to text: NSMutableAttributedString, request: RenderRequest) {
        let fullRange = NSRange(location: 0, length: text.length)
        guard fullRange.length > 0 else { return }

        let palette = NativeThemePalette(theme: request.appTheme, scheme: request.colorScheme)
        let bodyFont = request.readerFontFamily.nsFont(size: request.readerFontSize)

        // Apply base font, color, and paragraph style to the full range.
        // The base paragraph style ensures that inter-block newlines (which carry no
        // PresentationIntent and therefore receive no block-specific paragraph style)
        // get sensible defaults instead of a nil/system default style.
        text.addAttribute(.font, value: bodyFont, range: fullRange)
        text.addAttribute(.foregroundColor, value: palette.textPrimary, range: fullRange)
        let baseStyle = createBaseParagraphStyle(
            lineSpacing: request.textSpacing.lineSpacing(for: request.readerFontSize),
            paragraphSpacing: request.textSpacing.paragraphSpacing(for: request.readerFontSize),
            hyphenationFactor: 0
        )
        text.addAttribute(.paragraphStyle, value: baseStyle, range: fullRange)

        // Apply presentation-intent–aware styling
        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            for component in intent.components {
                switch component.kind {
                case .header(let level):
                    applyHeadingStyle(to: text, range: range, request: request, level: level, palette: palette)

                case .codeBlock:
                    let codeFont = request.readerFontFamily.nsFont(size: request.codeFontSize, monospaced: true)
                    text.addAttribute(.font, value: codeFont, range: range)
                    text.addAttribute(.backgroundColor, value: palette.codeBackground, range: range)
                    // Only add codeBlock attribute when line numbers are enabled (used by layout manager)
                    if request.showLineNumbers {
                        text.addAttribute(MarkdownRenderAttribute.codeBlock, value: true, range: range)
                    }
                    // Apply paragraph style to code blocks for spacing
                    applyCodeBlockParagraphStyle(
                        to: text,
                        range: range,
                        request: request,
                        hasLineNumbers: request.showLineNumbers
                    )

                case .blockQuote:
                    // Style blockquote text
                    text.addAttribute(.foregroundColor, value: palette.textSecondary, range: range)

                    // Visual styling for blockquote borders and background
                    text.addAttribute(
                        MarkdownRenderAttribute.blockquoteAccent,
                        value: palette.blockquoteAccent,
                        range: range
                    )
                    text.addAttribute(
                        MarkdownRenderAttribute.blockquoteBackground,
                        value: palette.blockquoteBackground,
                        range: range
                    )

                    // Calculate nesting depth for progressive indentation
                    let blockquoteCount = intent.components.filter {
                        if case .blockQuote = $0.kind { return true }
                        return false
                    }.count
                    text.addAttribute(
                        MarkdownRenderAttribute.blockquoteDepth,
                        value: max(1, blockquoteCount),
                        range: range
                    )

                    // Apply dedicated blockquote paragraph style with enhanced spacing
                    applyBlockquoteParagraphStyle(
                        to: text,
                        range: range,
                        request: request,
                        depth: max(1, blockquoteCount)
                    )

                case .paragraph:
                    // Apply paragraph style to paragraphs for proper spacing
                    applyParagraphStyle(to: text, range: range, request: request)

                case .unorderedList, .orderedList:
                    // Apply paragraph style to lists for proper indentation and spacing
                    applyListParagraphStyle(to: text, range: range, request: request)

                case .tableHeaderRow:
                    // Bold header cells using the reader's font family
                    let headerFont = request.readerFontFamily.nsFont(size: request.readerFontSize, weight: .semibold)
                    text.addAttribute(.font, value: headerFont, range: range)
                    text.addAttribute(.foregroundColor, value: palette.heading, range: range)
                    let headerBackground = palette.formattedTableHeaderBackground()
                    let tableBorder = palette.formattedTableBorder()
                    text.addAttribute(
                        MarkdownRenderAttribute.tableHeaderBackground,
                        value: headerBackground,
                        range: range
                    )
                    text.addAttribute(
                        MarkdownRenderAttribute.tableBorder,
                        value: tableBorder,
                        range: range
                    )
                    text.addAttribute(
                        MarkdownRenderAttribute.tableColumnDividerOpacity,
                        value: palette.tableColumnDividerOpacityMultiplier(),
                        range: range
                    )
                    applyTableRowParagraphStyle(to: text, range: range, request: request)

                case .tableRow(let rowIndex):
                    // Body font for table rows — tab stops handle column alignment
                    let rowFont = request.readerFontFamily.nsFont(size: request.readerFontSize)
                    text.addAttribute(.font, value: rowFont, range: range)
                    let rowBackground = palette.formattedTableRowBackground()
                    let tableBorder = palette.formattedTableBorder()
                    let isAlternating = rowIndex % 2 == 0
                    if isAlternating {
                        text.addAttribute(
                            MarkdownRenderAttribute.tableRowBackground,
                            value: rowBackground,
                            range: range
                        )
                    }
                    text.addAttribute(
                        MarkdownRenderAttribute.tableRowAlternating,
                        value: isAlternating,
                        range: range
                    )
                    text.addAttribute(
                        MarkdownRenderAttribute.tableBorder,
                        value: tableBorder,
                        range: range
                    )
                    text.addAttribute(
                        MarkdownRenderAttribute.tableColumnDividerOpacity,
                        value: palette.tableColumnDividerOpacityMultiplier(),
                        range: range
                    )
                    applyTableRowParagraphStyle(to: text, range: range, request: request)

                default:
                    break
                }
            }
        }

        // Apply inline code styling
        text.enumerateAttribute(
            MarkdownRenderAttribute.inlinePresentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            // Convert NSNumber to InlinePresentationIntent
            let rawValue = (value as? NSNumber)?.uintValue ?? 0
            guard rawValue != 0 else { return }
            let intent = InlinePresentationIntent(rawValue: rawValue)

            applyInlineStyles(to: text, range: range, intent: intent, palette: palette, request: request)
        }

        // Apply consistent link styling across all themes.
        applyLinkStyling(to: text, fullRange: fullRange, palette: palette)

        // Apply kerning to full text with optical sizing and element-specific adjustments
        applyKerning(to: text, request: request, fullRange: fullRange)

        // Detect and style horizontal rules (thematic breaks: ---, ***, ___)
        // Must run after the presentation-intent pass so paragraph style is already set.
        applyHorizontalRuleStyles(to: text, fullRange: fullRange, palette: palette)

        // Style list marker characters (•, ◦, numbers) with the theme marker color.
        applyListMarkerStyles(to: text, fullRange: fullRange, palette: palette)

        // Apply task list checkbox styling (reuses palette from above)
        applyTaskListStyling(to: text, palette: palette, request: request)
    }

    /// Applies element-specific kerning for optimal readability.
    /// Different text elements benefit from different tracking:
    /// - Body text: Uses the spacing preference's kern value
    /// - Headings: Slightly tighter tracking (headings look better compact)
    /// - Code: Minimal tracking (monospace fonts have fixed spacing)
    /// - Blockquotes: Slightly more open for quoted text distinction
    private func applyKerning(to text: NSMutableAttributedString, request: RenderRequest, fullRange: NSRange) {
        let baseKern = request.textSpacing.kern(for: request.readerFontSize)
        let opticalAdjustment = request.textSpacing.opticalSizeAdjustment(for: request.readerFontSize)
        let totalBaseKern = baseKern + (request.readerFontSize * opticalAdjustment)

        // Apply base kerning to all text first
        text.addAttribute(.kern, value: totalBaseKern, range: fullRange)

        // Apply element-specific adjustments
        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            for component in intent.components {
                switch component.kind {
                case .header(let level):
                    // Headings: tighter tracking for visual impact
                    let headingFontSize = fontSizeForHeader(level: level, baseSize: request.readerFontSize)
                    let headingKern = request.textSpacing.kern(for: headingFontSize)
                    let headingAdjustment = request.textSpacing.opticalSizeAdjustment(for: headingFontSize)
                    // Reduce kerning by 20% for headings (tighter look)
                    let adjustedKern = (headingKern + (headingFontSize * headingAdjustment)) * 0.8
                    text.addAttribute(.kern, value: adjustedKern, range: range)

                case .codeBlock:
                    // Code blocks: minimal tracking (monospace has fixed spacing)
                    let codeKern = request.textSpacing.kern(for: request.codeFontSize) * 0.3
                    text.addAttribute(.kern, value: codeKern, range: range)

                case .blockQuote:
                    // Blockquotes: slightly more open for distinction
                    let quoteKern = totalBaseKern + (request.readerFontSize * 0.003)
                    text.addAttribute(.kern, value: quoteKern, range: range)

                default:
                    break
                }
            }
        }

        // Adjust inline code kerning
        text.enumerateAttribute(
            MarkdownRenderAttribute.inlinePresentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            let rawValue = (value as? NSNumber)?.uintValue ?? 0
            guard rawValue != 0 else { return }
            let intent = InlinePresentationIntent(rawValue: rawValue)

            if intent.contains(.code) {
                // Inline code: minimal tracking
                let inlineCodeKern = request.textSpacing.kern(for: request.readerFontSize) * 0.3
                text.addAttribute(.kern, value: inlineCodeKern, range: range)
            }
        }
    }

    // MARK: - Private Methods

    /// Creates a base paragraph style with consistent settings across all block types.
    /// Applies proper paragraph spacing to separate blocks visually.
    /// Uses macOS native typography best practices for optimal text rendering.
    ///
    /// Returns `NSMutableParagraphStyle` so callers that need additional mutations
    /// (list indentation, code gutter) can do so without a force-cast.
    private func createBaseParagraphStyle(
        lineSpacing: CGFloat,
        paragraphSpacing: CGFloat = 0,
        paragraphSpacingBefore: CGFloat = 0,
        hyphenationFactor: Float = 0,
        alignment: NSTextAlignment = .left
    ) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        // lineSpacing adds fixed points after each line (controlled by ReaderTextSpacing).
        // lineHeightMultiple is left at the default (1.0) — the two models should not be
        // combined, as lineSpacing is added *after* the multiplied line height.
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.paragraphSpacingBefore = paragraphSpacingBefore
        style.hyphenationFactor = hyphenationFactor
        style.alignment = alignment
        // Enable optimal character spacing for body text
        style.allowsDefaultTighteningForTruncation = false
        return style
    }

    private func applyBlockquoteParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        depth: Int
    ) {
        let lineSpacing = request.textSpacing.lineSpacing(for: request.readerFontSize)
        // Blockquotes get slightly more generous spacing for visual distinction
        let baseSpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let nestingFactor = min(1.6, 1.0 + CGFloat(max(0, depth - 1)) * 0.2)
        let spacing = baseSpacing * 0.72 * nestingFactor
        let spacingBefore = baseSpacing * 0.55
        let hyphenationFactor = max(0, request.textSpacing.hyphenationFactor - 0.05)

        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            paragraphSpacingBefore: spacingBefore,
            hyphenationFactor: hyphenationFactor
        )

        // Add progressive indentation for nested blockquote hierarchy.
        let blockquoteIndent: CGFloat = 12 + CGFloat(max(0, depth - 1)) * 10
        style.headIndent = blockquoteIndent
        style.firstLineHeadIndent = blockquoteIndent
        style.tabStops = [NSTextTab(textAlignment: .left, location: blockquoteIndent, options: [:])]

        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyParagraphStyle(to text: NSMutableAttributedString, range: NSRange, request: RenderRequest) {
        let lineSpacing = request.textSpacing.lineSpacing(for: request.readerFontSize)
        let spacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let hyphenationFactor = max(0, request.textSpacing.hyphenationFactor - 0.05)
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            hyphenationFactor: hyphenationFactor
        )
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyListParagraphStyle(to text: NSMutableAttributedString, range: NSRange, request: RenderRequest) {
        let lineSpacing = request.textSpacing.lineSpacing(for: request.readerFontSize)
        // List items have moderate spacing
        let fullSpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let spacing = fullSpacing * 0.5
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            hyphenationFactor: 0
        )

        // Configure list-specific indentation for visual hierarchy
        let listIndent: CGFloat = 24
        style.headIndent = listIndent
        style.firstLineHeadIndent = 0
        style.tabStops = [NSTextTab(textAlignment: .left, location: listIndent, options: [:])]

        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyTableRowParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest
    ) {
        let lineSpacing = max(2, request.textSpacing.lineSpacing(for: request.readerFontSize) * 0.9)
        // paragraphSpacing + paragraphSpacingBefore together determine how much vertical
        // space surrounds each row's text. tableVPadding in the layout manager then adds
        // an additional drawn margin around the measured rect.
        let cellSpacing = max(6, request.readerFontSize * 0.36)
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: cellSpacing,
            paragraphSpacingBefore: cellSpacing * 0.5,
            hyphenationFactor: 0
        )
        // Tables use an inset track so row surfaces and borders can align visually.
        let tableInset: CGFloat = 16
        style.firstLineHeadIndent = tableInset
        style.headIndent = tableInset

        // Tab stops for column alignment.
        //
        // `colWidth` is the fixed pitch between consecutive column left edges.
        // Smaller values push columns closer together, leaving more room for the
        // last column (which has no tab stop and spans to the row rect's right edge).
        //
        // At 20% of usable width per column:
        //   • 2-col  (720pt): col2 starts at 160pt, col3 gets 544pt  → plenty
        //   • 3-col  (720pt): col2 starts at 160pt, col3 at 304pt   → 400pt for col3
        //   • 3-col  (480pt): col2 starts at 107pt, col3 at 202pt   → 262pt for col3
        //   • 4-col  (720pt): col4 starts at 448pt                  → 256pt for col4
        //
        // A hard floor of 90pt prevents columns collapsing to nothing on tiny windows.
        let usableWidth = request.readableWidth - tableInset * 2
        let colWidth = max(90, usableWidth * 0.20)
        style.tabStops = (0 ..< 8).map { i in
            NSTextTab(textAlignment: .left, location: tableInset + (colWidth * CGFloat(i + 1)), options: [:])
        }
        // Allow character-level wrapping so long code identifiers (e.g. DesignTokens.Animation.fast)
        // break within the column rather than clipping at the text container edge.
        style.lineBreakMode = .byCharWrapping
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    /// Applies comprehensive heading styling including font, color, and paragraph style.
    private func applyHeadingStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        level: Int,
        palette: NativeThemePalette
    ) {
        let fontSize = fontSizeForHeader(level: level, baseSize: request.readerFontSize)

        // Progressive font weight for clear visual hierarchy
        let weight: NSFont.Weight
        switch level {
        case 1: weight = .heavy
        case 2: weight = .bold
        case 3: weight = .semibold
        default: weight = .medium
        }
        let font = request.readerFontFamily.nsFont(size: fontSize, weight: weight)
        text.addAttribute(.font, value: font, range: range)
        text.addAttribute(
            .foregroundColor,
            value: palette.formattedHeadingColor(level: level),
            range: range
        )

        // Apply paragraph style with appropriate spacing
        applyHeadingParagraphStyle(to: text, range: range, request: request, level: level)
    }

    private func applyHeadingParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        level: Int
    ) {
        let headingSize = fontSizeForHeader(level: level, baseSize: request.readerFontSize)
        let lineSpacing = request.textSpacing.lineSpacing(for: headingSize)

        // Balanced spacing for visual hierarchy without excessive gaps
        let spacingMultiplier: CGFloat
        let spacingBeforeMultiplier: CGFloat
        switch level {
        case 1:
            spacingMultiplier = 1.0
            spacingBeforeMultiplier = 1.2

        case 2:
            spacingMultiplier = 0.9
            spacingBeforeMultiplier = 1.0

        case 3:
            spacingMultiplier = 0.8
            spacingBeforeMultiplier = 0.85

        default:
            spacingMultiplier = 0.7
            spacingBeforeMultiplier = 0.7
        }

        let baseSpacing = request.textSpacing.paragraphSpacing(for: headingSize)
        let spacing = baseSpacing * spacingMultiplier
        let spacingBefore = baseSpacing * spacingBeforeMultiplier

        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            paragraphSpacingBefore: spacingBefore,
            hyphenationFactor: 0
        )
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func fontSizeForHeader(level: Int, baseSize: CGFloat) -> CGFloat {
        // Clear heading hierarchy with significant size differences
        switch level {
        case 1: return baseSize * 1.75
        case 2: return baseSize * 1.5
        case 3: return baseSize * 1.3
        case 4: return baseSize * 1.15
        case 5: return baseSize * 1.1
        case 6: return baseSize * 1.05
        default: return baseSize
        }
    }

    private func applyCodeBlockParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        hasLineNumbers: Bool
    ) {
        // Code blocks use tighter line spacing for compact display
        let lineSpacing = max(2, request.codeFontSize * 0.15)
        let spacing = request.textSpacing.paragraphSpacing(for: request.codeFontSize)
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            hyphenationFactor: 0
        )

        // Configure gutter indentation for line numbers
        if hasLineNumbers {
            let digitWidth = request.codeFontSize * 0.6
            let gutterWidth = (digitWidth * 4) + (request.codeFontSize * 0.8)
            style.headIndent = gutterWidth
            style.firstLineHeadIndent = gutterWidth
        }

        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    /// Applies comprehensive inline formatting to text based on presentation intent.
    /// Handles bold, italic, code, strikethrough, and combinations thereof.
    private func applyInlineStyles(
        to text: NSMutableAttributedString,
        range: NSRange,
        intent: InlinePresentationIntent,
        palette: NativeThemePalette,
        request: RenderRequest
    ) {
        let wantsBold = intent.contains(.stronglyEmphasized)
        let wantsItalic = intent.contains(.emphasized)
        var workingFont = text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont

        // Apply inline code styling
        if intent.contains(.code) {
            let codeFont = request.readerFontFamily.nsFont(
                size: request.readerFontSize * 0.92,
                monospaced: true
            )
            workingFont = codeFont
            text.addAttribute(.font, value: codeFont, range: range)
            text.addAttribute(.backgroundColor, value: palette.inlineCodeBackground, range: range)
            // Subtle baseline adjustment scaled to font size for optical alignment
            let baselineOffset = round(request.readerFontSize * 0.06)
            text.addAttribute(.baselineOffset, value: baselineOffset, range: range)
        }

        // Apply bold/italic together so mixed emphasis (`***text***`) stays stable.
        if wantsBold || wantsItalic, let baseFont = workingFont {
            let emphasized = fontByApplyingTraits(baseFont, bold: wantsBold, italic: wantsItalic)
            text.addAttribute(.font, value: emphasized, range: range)
        }

        // Apply strikethrough (if supported)
        if intent.contains(.strikethrough) {
            text.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            text.addAttribute(.strikethroughColor, value: palette.textTertiary, range: range)
        }
    }

    private func applyLinkStyling(
        to text: NSMutableAttributedString,
        fullRange: NSRange,
        palette: NativeThemePalette
    ) {
        text.enumerateAttribute(.link, in: fullRange, options: []) { value, range, _ in
            guard value != nil else { return }

            // Preserve existing links and apply a consistent themed style.
            text.addAttribute(.foregroundColor, value: palette.link, range: range)
            text.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            text.addAttribute(.underlineColor, value: palette.formattedLinkUnderlineColor(), range: range)
        }
    }

    // MARK: - Horizontal Rule Styling

    /// Scans the rendered attributed string for runs carrying `PresentationIntent.thematicBreak`
    /// and tags them with `mdv.horizontalRule`. The character foreground is set to `.clear` so
    /// only the drawn hairline from `ReaderLayoutManager` is visible.
    ///
    /// The Swift Markdown parser converts `---`, `***`, and `___` into a single U+2E3B
    /// THREE-EM DASH glyph with a `thematicBreak` presentation intent. Scanning the raw text
    /// for the original ASCII characters would therefore never find a match.
    private func applyHorizontalRuleStyles(
        to text: NSMutableAttributedString,
        fullRange: NSRange,
        palette: NativeThemePalette
    ) {
        // Build the paragraph style once — all HR runs share the same metrics.
        // paragraphSpacingBefore / paragraphSpacing give the rule generous vertical
        // breathing room so it reads as a section divider rather than a stray line.
        // The large font size inflates the line-fragment height, which determines
        // where rect.midY falls in the layout manager; the glyph itself is hidden.
        let hrStyle = NSMutableParagraphStyle()
        hrStyle.paragraphSpacingBefore = 20
        hrStyle.paragraphSpacing = 20
        // Do NOT set alignment — the HR glyph shares a paragraph with whatever
        // element follows it (e.g. the heading), so any alignment override here
        // would also affect that element. The hairline is drawn by ReaderLayoutManager
        // using rect.midY and does not depend on text alignment.

        let hrFont = NSFont.systemFont(ofSize: 6, weight: .regular)

        // Two-pass approach:
        // Pass 1 – tag all HR glyph ranges and collect positions that need a paragraph
        //           boundary injected immediately after the glyph.
        // Pass 2 – insert the missing newlines in reverse order (preserves earlier indices).
        //
        // The Swift Markdown parser sometimes places the U+2E3B THREE-EM DASH glyph in
        // the same NSTextView paragraph as the element that follows it (e.g. a heading),
        // because no '\n' separates them in the attributed string.  When that happens the
        // HR glyph and the heading share a single line fragment, causing the hairline to
        // overdraw the heading text.  Inserting '\n' after the glyph forces each into its
        // own paragraph so ReaderLayoutManager can draw the hairline in isolation.

        var insertAfter: [Int] = [] // character positions where a '\n' must be injected

        var i = fullRange.location
        let end = NSMaxRange(fullRange)
        while i < end {
            var effectiveRange = NSRange(location: i, length: 1)
            let intent = text.attribute(
                MarkdownRenderAttribute.presentationIntent,
                at: i,
                effectiveRange: &effectiveRange
            ) as? PresentationIntent
            let rangeEnd = min(effectiveRange.location + effectiveRange.length, end)

            let isThematicBreak = intent?.components.contains {
                if case .thematicBreak = $0.kind { return true }; return false
            } ?? false

            if isThematicBreak {
                let range = NSRange(location: effectiveRange.location, length: rangeEnd - effectiveRange.location)
                text.addAttribute(MarkdownRenderAttribute.horizontalRule, value: palette.horizontalRule, range: range)
                // Hide the glyph — only the drawn hairline should be visible.
                text.addAttribute(.foregroundColor, value: NSColor.clear, range: range)
                // Apply paragraph metrics so the rule has vertical breathing room.
                text.addAttribute(.paragraphStyle, value: hrStyle, range: range)
                // Small font keeps the line-fragment compact while still providing a
                // centred midY for the hairline to draw against.
                text.addAttribute(.font, value: hrFont, range: range)

                // Check whether the character immediately after the HR glyph is a newline.
                // If not, we need to inject one so the HR lives in its own paragraph.
                if rangeEnd < end {
                    let nextChar = (text.string as NSString).character(at: rangeEnd)
                    if nextChar != unichar(0x000A) {
                        insertAfter.append(rangeEnd)
                    }
                }
            }

            i = max(i + 1, rangeEnd)
        }

        // Pass 2: insert '\n' separators in reverse order so earlier positions stay valid.
        // The injected newline carries the hrStyle so it belongs to the HR paragraph and
        // the following element starts a fresh paragraph with its own block-level style.
        let hrNewline = NSMutableAttributedString(string: "\n")
        hrNewline.addAttribute(.paragraphStyle, value: hrStyle, range: NSRange(location: 0, length: 1))
        hrNewline.addAttribute(.font, value: hrFont, range: NSRange(location: 0, length: 1))
        hrNewline.addAttribute(.foregroundColor, value: NSColor.clear, range: NSRange(location: 0, length: 1))

        for pos in insertAfter.sorted(by: >) {
            text.insert(hrNewline, at: pos)
        }
    }

    // MARK: - List Marker Styling

    /// Regex matching list markers: bullet (•, ◦, ▪, ‣) or ordered number (1., 2., …).
    /// The system parser emits these characters at the start of each list item.
    private static let listMarkerRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"^([\u2022\u25E6\u25AA\u2023]|[0-9]+\.)(?=[\t ])"#,
        options: .anchorsMatchLines
    )

    /// Applies the theme's `listMarker` color to bullet and number marker characters.
    private func applyListMarkerStyles(
        to text: NSMutableAttributedString,
        fullRange: NSRange,
        palette: NativeThemePalette
    ) {
        guard let regex = Self.listMarkerRegex else { return }
        let matches = regex.matches(in: text.string, options: [], range: fullRange)
        guard !matches.isEmpty else { return }

        for match in matches {
            let range = match.range(at: 1)
            guard range.location != NSNotFound, range.length > 0 else { continue }
            // Verify this character is inside a list item intent, not an accidental match.
            guard
                let intent = text.attribute(
                    MarkdownRenderAttribute.presentationIntent,
                    at: range.location,
                    effectiveRange: nil
                ) as? PresentationIntent,
                intent.components.contains(where: {
                    if case .listItem = $0.kind { return true }
                    return false
                })
            else { continue }

            text.addAttribute(.foregroundColor, value: palette.listMarker, range: range)
            text.addAttribute(MarkdownRenderAttribute.listMarker, value: true, range: range)
        }
    }

    // MARK: - Task List Styling

    /// Regex for task-list checkbox patterns — compiled once, reused on every render.
    private static let taskListRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"\[( |x|X)\]"#
    )

    private func fontByApplyingTraits(_ base: NSFont, bold: Bool, italic: Bool) -> NSFont {
        var traits = base.fontDescriptor.symbolicTraits
        if bold { traits.insert(.bold) }
        if italic { traits.insert(.italic) }

        let descriptor = base.fontDescriptor.withSymbolicTraits(traits)
        if let converted = NSFont(descriptor: descriptor, size: base.pointSize) {
            return converted
        }

        // Fallback path for fonts that do not support descriptor trait conversion.
        var fallback = base
        if bold {
            fallback = NSFontManager.shared.convert(fallback, toHaveTrait: .boldFontMask)
        }
        if italic {
            fallback = NSFontManager.shared.convert(fallback, toHaveTrait: .italicFontMask)
        }
        return fallback
    }

    /// Applies special styling to task list checkbox characters.
    /// Call this after all other styling is applied.
    func applyTaskListStyling(
        to text: NSMutableAttributedString,
        palette: NativeThemePalette,
        request: RenderRequest
    ) {
        let nsString = text.string as NSString
        let fullRange = NSRange(location: 0, length: text.length)
        guard let regex = Self.taskListRegex else { return }
        let markerMatches = regex.matches(in: text.string, options: [], range: fullRange)
        guard !markerMatches.isEmpty else { return }

        let markerFont = NSFont.monospacedSystemFont(
            ofSize: max(11, request.readerFontSize * 0.9),
            weight: .semibold
        )
        let markerKern = max(0, request.textSpacing.kern(for: request.readerFontSize) * 0.7)

        for match in markerMatches {
            let markerRange = match.range
            guard markerRange.location != NSNotFound, markerRange.length > 0 else { continue }

            // Restrict checkbox styling to list items so plain paragraph text like [x]
            // is not interpreted as a task marker.
            guard
                let intent = text.attribute(
                    MarkdownRenderAttribute.presentationIntent,
                    at: markerRange.location,
                    effectiveRange: nil
                ) as? PresentationIntent
            else { continue }
            let isListItem = intent.components.contains {
                if case .unorderedList = $0.kind { return true }
                return false
            }
            guard isListItem else { continue }

            let markerText = nsString.substring(with: markerRange)
            let checked = markerText == "[x]" || markerText == "[X]"
            let markerColor = checked ? palette.taskListChecked : palette.taskListUnchecked

            text.addAttribute(.font, value: markerFont, range: markerRange)
            text.addAttribute(.foregroundColor, value: markerColor, range: markerRange)
            text.addAttribute(.kern, value: markerKern, range: markerRange)
            text.addAttribute(MarkdownRenderAttribute.taskListChecked, value: checked, range: markerRange)

            guard checked else { continue }
            let lineRange = nsString.lineRange(for: markerRange)
            let textStart = markerRange.location + markerRange.length
            var textEnd = lineRange.location + lineRange.length
            if
                textEnd > lineRange.location,
                nsString.character(at: textEnd - 1) == 0x0A
            {
                textEnd -= 1
            }
            guard textStart < textEnd else { continue }

            let contentRange = NSRange(
                location: textStart,
                length: textEnd - textStart
            )
            text.addAttribute(.foregroundColor, value: palette.textSecondary, range: contentRange)
            text.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: contentRange)
            text.addAttribute(.strikethroughColor, value: palette.textTertiary, range: contentRange)
            // Keep checked item spacing slightly tighter for cleaner rhythm.
            text.addAttribute(.kern, value: markerKern * 0.8, range: contentRange)
        }
    }
}
