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
/// based on the requested theme, font family, and user typography preferences.
/// Implements modern typesetting best practices for optimal readability.
struct TypographyApplier: TypographyApplying {
    // MARK: - Typography Application

    func applyTypography(to text: NSMutableAttributedString, request: RenderRequest) {
        var fullRange = NSRange(location: 0, length: text.length)
        guard fullRange.length > 0 else { return }

        let palette = NativeThemePalette.cached(theme: request.appTheme, scheme: request.colorScheme)
        let bodyFont = request.readerFontFamily.nsFont(size: request.readerFontSize)

        // Apply base font with user's typographic preferences.
        let enhancedFont = applyTypographicFeatures(to: bodyFont, preferences: request.typographyPreferences)
        text.addAttribute(.font, value: enhancedFont, range: fullRange)
        text.addAttribute(.foregroundColor, value: palette.textPrimary, range: fullRange)

        // Apply base paragraph style with user preferences.
        let baseStyle = createBaseParagraphStyle(
            lineSpacing: request.textSpacing.lineSpacing(for: request.readerFontSize),
            paragraphSpacing: request.textSpacing.paragraphSpacing(for: request.readerFontSize),
            hyphenationFactor: request.typographyPreferences.hyphenation ? request.textSpacing.hyphenationFactor : 0,
            alignment: request.typographyPreferences.justification.nsAlignment
        )
        text.addAttribute(.paragraphStyle, value: baseStyle, range: fullRange)

        // Truncate wide table cells before attribute pass.
        truncateTableCells(in: text, bodyFont: enhancedFont, request: request)
        fullRange = NSRange(location: 0, length: text.length)

        // Apply presentation-intent–aware styling and kerning in combined pass
        applyPresentationIntentAndKerning(to: text, fullRange: fullRange, request: request, palette: palette)

        // Apply consistent link styling.
        applyLinkStyling(to: text, fullRange: fullRange, palette: palette)

        // Apply horizontal rule styles.
        applyHorizontalRuleStyles(to: text, fullRange: fullRange, palette: palette, request: request)

        // Insert list markers.
        insertListMarkers(in: text, palette: palette, request: request)

        // Apply task list checkbox styling.
        applyTaskListStyling(to: text, palette: palette, request: request)
    }

    // MARK: - Typographic Features

    /// Applies advanced typographic features based on user preferences.
    private func applyTypographicFeatures(to font: NSFont, preferences: TypographyPreferences) -> NSFont {
        guard preferences.ligatures else { return font }

        let descriptor = font.fontDescriptor.addingAttributes([
            .featureSettings: [
                [
                    NSFontDescriptor.FeatureKey.typeIdentifier: kCommonLigaturesOnSelector,
                    NSFontDescriptor.FeatureKey.selectorIdentifier: 1,
                ],
            ],
        ])

        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
    }

    // MARK: - Combined Presentation Intent + Kerning

    /// Combined pass for presentation intent styling and kerning to reduce attribute enumeration.
    private func applyPresentationIntentAndKerning(
        to text: NSMutableAttributedString,
        fullRange: NSRange,
        request: RenderRequest,
        palette: NativeThemePalette
    ) {
        let baseKern = request.textSpacing.kern(for: request.readerFontSize)
        let opticalAdjustment = request.textSpacing.opticalSizeAdjustment(for: request.readerFontSize)
        let totalBaseKern = baseKern + (request.readerFontSize * opticalAdjustment)

        text.addAttribute(.kern, value: totalBaseKern, range: fullRange)

        // Single enumeration for both presentation intent styling and kerning adjustments
        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            var isCodeBlock = false
            var isHeading = false
            var headingLevel = 0
            var isBlockQuote = false

            for component in intent.components {
                switch component.kind {
                case .header(let level):
                    isHeading = true
                    headingLevel = level
                    applyHeadingStyle(to: text, range: range, request: request, level: level, palette: palette)

                case .codeBlock:
                    isCodeBlock = true
                    applyCodeBlockStyle(to: text, range: range, request: request, palette: palette)

                case .blockQuote:
                    isBlockQuote = true
                    applyBlockquoteStyle(to: text, range: range, request: request, palette: palette, intent: intent)

                case .paragraph:
                    applyParagraphStyle(to: text, range: range, request: request)

                case .unorderedList, .orderedList:
                    applyListParagraphStyle(to: text, range: range, request: request)

                case .tableHeaderRow:
                    applyTableHeaderStyle(to: text, range: range, request: request, palette: palette)

                case .tableRow(let rowIndex):
                    applyTableRowStyle(to: text, range: range, rowIndex: rowIndex, request: request, palette: palette)

                default:
                    break
                }
            }

            // Apply kerning adjustments based on detected types
            if isHeading {
                let headingFontSize = fontSizeForHeader(level: headingLevel, baseSize: request.readerFontSize)
                let headingKern = request.textSpacing.kern(for: headingFontSize)
                let headingAdjustment = request.textSpacing.opticalSizeAdjustment(for: headingFontSize)
                let adjustedKern = (headingKern + (headingFontSize * headingAdjustment)) * 0.8
                text.addAttribute(.kern, value: adjustedKern, range: range)
            } else if isCodeBlock {
                let codeKern = request.textSpacing.kern(for: request.codeFontSize) * 0.3
                text.addAttribute(.kern, value: codeKern, range: range)
            } else if isBlockQuote {
                let quoteKern = totalBaseKern + (request.readerFontSize * 0.003)
                text.addAttribute(.kern, value: quoteKern, range: range)
            }
        }

        // Handle inline presentation intents
        text.enumerateAttribute(
            MarkdownRenderAttribute.inlinePresentationIntent,
            in: fullRange,
            options: []
        ) { value, range, _ in
            let rawValue = (value as? NSNumber)?.uintValue ?? 0
            guard rawValue != 0 else { return }
            let intent = InlinePresentationIntent(rawValue: rawValue)
            applyInlineStyles(to: text, range: range, intent: intent, palette: palette, request: request)

            // Apply inline code kerning adjustment
            if intent.contains(.code) {
                let inlineCodeKern = request.textSpacing.kern(for: request.readerFontSize) * 0.3
                text.addAttribute(.kern, value: inlineCodeKern, range: range)
            }
        }
    }

    private func applyCodeBlockStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        palette: NativeThemePalette
    ) {
        let codeFont = request.readerFontFamily.nsFont(size: request.codeFontSize, monospaced: true)
        text.addAttribute(.font, value: codeFont, range: range)
        text.addAttribute(.backgroundColor, value: palette.codeBackground, range: range)

        if request.showLineNumbers {
            text.addAttribute(MarkdownRenderAttribute.codeBlock, value: true, range: range)
        }

        applyCodeBlockParagraphStyle(to: text, range: range, request: request, hasLineNumbers: request.showLineNumbers)
    }

    private func applyBlockquoteStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        palette: NativeThemePalette,
        intent: PresentationIntent
    ) {
        text.addAttribute(.foregroundColor, value: palette.textSecondary, range: range)
        text.addAttribute(MarkdownRenderAttribute.blockquoteAccent, value: palette.blockquoteAccent, range: range)
        text.addAttribute(
            MarkdownRenderAttribute.blockquoteBackground,
            value: palette.blockquoteBackground,
            range: range
        )

        var blockquoteCount = 0
        for component in intent.components {
            if case .blockQuote = component.kind {
                blockquoteCount += 1
            }
        }

        text.addAttribute(MarkdownRenderAttribute.blockquoteDepth, value: max(1, blockquoteCount), range: range)
        applyBlockquoteParagraphStyle(to: text, range: range, request: request, depth: max(1, blockquoteCount))
    }

    private func applyTableHeaderStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        palette: NativeThemePalette
    ) {
        let headerFont = request.readerFontFamily.nsFont(size: request.readerFontSize, weight: .semibold)
        text.addAttribute(.font, value: headerFont, range: range)
        text.addAttribute(.foregroundColor, value: palette.heading, range: range)

        let headerBackground = palette.formattedTableHeaderBackground()
        let tableBorder = palette.formattedTableBorder()

        text.addAttribute(MarkdownRenderAttribute.tableHeaderBackground, value: headerBackground, range: range)
        text.addAttribute(MarkdownRenderAttribute.tableBorder, value: tableBorder, range: range)
        text.addAttribute(
            MarkdownRenderAttribute.tableColumnDividerOpacity,
            value: palette.tableColumnDividerOpacityMultiplier(),
            range: range
        )
        applyTableRowParagraphStyle(to: text, range: range, request: request)
    }

    private func applyTableRowStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        rowIndex: Int,
        request: RenderRequest,
        palette: NativeThemePalette
    ) {
        let rowFont = request.readerFontFamily.nsFont(size: request.readerFontSize)
        text.addAttribute(.font, value: rowFont, range: range)

        let rowBackground = palette.formattedTableRowBackground()
        let tableBorder = palette.formattedTableBorder()
        let isAlternating = rowIndex % 2 == 0

        if isAlternating {
            text.addAttribute(MarkdownRenderAttribute.tableRowBackground, value: rowBackground, range: range)
        }

        text.addAttribute(MarkdownRenderAttribute.tableRowAlternating, value: isAlternating, range: range)
        text.addAttribute(MarkdownRenderAttribute.tableBorder, value: tableBorder, range: range)
        text.addAttribute(
            MarkdownRenderAttribute.tableColumnDividerOpacity,
            value: palette.tableColumnDividerOpacityMultiplier(),
            range: range
        )
        applyTableRowParagraphStyle(to: text, range: range, request: request)
    }

    // MARK: - Paragraph Styles

    private func createBaseParagraphStyle(
        lineSpacing: CGFloat,
        paragraphSpacing: CGFloat = 0,
        paragraphSpacingBefore: CGFloat = 0,
        hyphenationFactor: Float = 0,
        alignment: NSTextAlignment = .left
    ) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.paragraphSpacingBefore = paragraphSpacingBefore
        style.hyphenationFactor = hyphenationFactor
        style.alignment = alignment
        style.allowsDefaultTighteningForTruncation = false
        style.usesDefaultHyphenation = hyphenationFactor > 0
        return style
    }

    private func applyBlockquoteParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        depth: Int
    ) {
        let lineSpacing = request.textSpacing.lineSpacing(for: request.readerFontSize)
        let baseSpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let nestingFactor = min(1.6, 1.0 + CGFloat(max(0, depth - 1)) * 0.2)
        let spacing = baseSpacing * 0.62 * nestingFactor
        let spacingBefore = baseSpacing * 0.42
        let hyphenationFactor = request.typographyPreferences.hyphenation
            ? max(0, request.textSpacing.hyphenationFactor - 0.05)
            : 0

        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            paragraphSpacingBefore: spacingBefore,
            hyphenationFactor: hyphenationFactor,
            alignment: request.typographyPreferences.justification.nsAlignment
        )

        let blockquoteIndent: CGFloat = 12 + CGFloat(max(0, depth - 1)) * 10
        style.headIndent = blockquoteIndent
        style.firstLineHeadIndent = blockquoteIndent
        style.tabStops = [NSTextTab(textAlignment: .left, location: blockquoteIndent, options: [:])]

        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyParagraphStyle(to text: NSMutableAttributedString, range: NSRange, request: RenderRequest) {
        let lineSpacing = request.textSpacing.lineSpacing(for: request.readerFontSize)
        let spacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let hyphenationFactor = request.typographyPreferences.hyphenation
            ? max(0, request.textSpacing.hyphenationFactor - 0.05)
            : 0
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            hyphenationFactor: hyphenationFactor,
            alignment: request.typographyPreferences.justification.nsAlignment
        )
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyListParagraphStyle(to text: NSMutableAttributedString, range: NSRange, request: RenderRequest) {
        let lineSpacing = request.textSpacing.lineSpacing(for: request.readerFontSize)
        let fullSpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let spacing = fullSpacing * 0.5
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            hyphenationFactor: 0,
            alignment: request.typographyPreferences.justification.nsAlignment
        )

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
        let bodySpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let cellSpacing = max(5, bodySpacing * 0.28)
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: cellSpacing,
            paragraphSpacingBefore: cellSpacing * 0.5,
            hyphenationFactor: 0,
            alignment: request.typographyPreferences.justification.nsAlignment
        )

        let tableInset: CGFloat = 16
        style.firstLineHeadIndent = tableInset
        style.headIndent = tableInset

        let usableWidth = request.readableWidth - tableInset * 2
        let colWidth = max(90, usableWidth * 0.20)
        style.tabStops = (0 ..< 8).map { i in
            NSTextTab(textAlignment: .left, location: tableInset + (colWidth * CGFloat(i + 1)), options: [:])
        }
        style.lineBreakMode = .byTruncatingTail
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    // MARK: - Heading Styles

    private func applyHeadingStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        level: Int,
        palette: NativeThemePalette
    ) {
        let fontSize = fontSizeForHeader(level: level, baseSize: request.readerFontSize)

        let weight: NSFont.Weight
        switch level {
        case 1: weight = .heavy
        case 2: weight = .bold
        case 3: weight = .semibold
        default: weight = .medium
        }

        let font = request.readerFontFamily.nsFont(size: fontSize, weight: weight)
        text.addAttribute(.font, value: font, range: range)
        text.addAttribute(MarkdownRenderAttribute.headingLevel, value: level, range: range)
        text.addAttribute(.foregroundColor, value: palette.formattedHeadingColor(level: level), range: range)
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

        let spacingMultiplier: CGFloat
        let spacingBeforeMultiplier: CGFloat
        switch level {
        case 1:
            spacingMultiplier = 0.72
            spacingBeforeMultiplier = 0.7
        case 2:
            spacingMultiplier = 0.62
            spacingBeforeMultiplier = 0.62
        case 3:
            spacingMultiplier = 0.54
            spacingBeforeMultiplier = 0.54
        default:
            spacingMultiplier = 0.46
            spacingBeforeMultiplier = 0.46
        }

        let baseSpacing = request.textSpacing.paragraphSpacing(for: headingSize)
        let spacing = baseSpacing * spacingMultiplier
        let spacingBefore = baseSpacing * spacingBeforeMultiplier

        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            paragraphSpacingBefore: spacingBefore,
            hyphenationFactor: 0,
            alignment: request.typographyPreferences.justification.nsAlignment
        )
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func fontSizeForHeader(level: Int, baseSize: CGFloat) -> CGFloat {
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
        let lineSpacing = max(2, request.codeFontSize * 0.15)
        let spacing = request.textSpacing.paragraphSpacing(for: request.codeFontSize) * 0.75
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            hyphenationFactor: 0,
            alignment: .left
        )

        if hasLineNumbers {
            let digitWidth = request.codeFontSize * 0.6
            let gutterWidth = (digitWidth * 4) + (request.codeFontSize * 0.8)
            style.headIndent = gutterWidth
            style.firstLineHeadIndent = gutterWidth
        }

        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    // MARK: - Inline Styles

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

        if intent.contains(.code) {
            let codeFont = request.readerFontFamily.nsFont(size: request.readerFontSize * 0.92, monospaced: true)
            workingFont = codeFont
            text.addAttribute(.font, value: codeFont, range: range)
            text.addAttribute(.backgroundColor, value: palette.inlineCodeBackground, range: range)
            let baselineOffset = round(request.readerFontSize * 0.06)
            text.addAttribute(.baselineOffset, value: baselineOffset, range: range)
        }

        if wantsBold || wantsItalic, let baseFont = workingFont {
            let emphasized = cachedFontByApplyingTraits(baseFont, bold: wantsBold, italic: wantsItalic)
            text.addAttribute(.font, value: emphasized, range: range)
        }

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

            text.addAttribute(.foregroundColor, value: palette.link, range: range)
            text.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            text.addAttribute(.underlineColor, value: palette.formattedLinkUnderlineColor(), range: range)
        }
    }

    // MARK: - Horizontal Rule

    private func applyHorizontalRuleStyles(
        to text: NSMutableAttributedString,
        fullRange: NSRange,
        palette: NativeThemePalette,
        request: RenderRequest
    ) {
        let rhythm = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let spacing = max(12, rhythm * 0.6)
        let hrStyle = NSMutableParagraphStyle()
        hrStyle.paragraphSpacingBefore = spacing
        hrStyle.paragraphSpacing = spacing

        let hrFont = NSFont.systemFont(ofSize: 6, weight: .regular)
        var insertAfter: [Int] = []
        insertAfter.reserveCapacity(8)

        // Cache NSString to avoid repeated conversions
        let nsText = text.string as NSString
        var i = fullRange.location
        let end = NSMaxRange(fullRange)

        // Pre-allocate buffer for intent checks
        var effectiveRange = NSRange(location: 0, length: 0)

        while i < end {
            effectiveRange.location = i
            effectiveRange.length = 1
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
                text.addAttribute(.foregroundColor, value: NSColor.clear, range: range)
                text.addAttribute(.paragraphStyle, value: hrStyle, range: range)
                text.addAttribute(.font, value: hrFont, range: range)

                if rangeEnd < end, nsText.character(at: rangeEnd) != unichar(0x000A) {
                    insertAfter.append(rangeEnd)
                }
            }

            i = max(i + 1, rangeEnd)
        }

        let hrNewline = NSMutableAttributedString(string: "\n")
        hrNewline.addAttribute(.paragraphStyle, value: hrStyle, range: NSRange(location: 0, length: 1))
        hrNewline.addAttribute(.font, value: hrFont, range: NSRange(location: 0, length: 1))
        hrNewline.addAttribute(.foregroundColor, value: NSColor.clear, range: NSRange(location: 0, length: 1))

        for pos in insertAfter.sorted(by: >) {
            text.insert(hrNewline, at: pos)
        }
    }

    // MARK: - List Markers

    private func insertListMarkers(
        in text: NSMutableAttributedString,
        palette: NativeThemePalette,
        request: RenderRequest
    ) {
        let font = request.readerFontFamily.nsFont(size: request.readerFontSize)
        var insertions: [(location: Int, marker: String)] = []
        insertions.reserveCapacity(32)

        text.enumerateAttribute(
            MarkdownRenderAttribute.presentationIntent,
            in: NSRange(location: 0, length: text.length)
        ) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            var listItemOrdinal: Int?
            var isOrdered = false
            var isCodeBlock = false
            for component in intent.components {
                switch component.kind {
                case .listItem(let ordinal): listItemOrdinal = ordinal
                case .orderedList: isOrdered = true
                case .codeBlock: isCodeBlock = true
                default: break
                }
            }
            // Code blocks nested inside list items inherit the listItem intent but must
            // not receive a bullet or ordinal marker — the marker belongs on the list item
            // paragraph, not on every line of the fenced code block.
            guard let ordinal = listItemOrdinal, !isCodeBlock else { return }
            insertions.append((location: range.location, marker: isOrdered ? "\(ordinal).\t" : "•\t"))
        }

        let nsText = text.string as NSString
        for insertion in insertions.sorted(by: { $0.location > $1.location }) {
            // Validate: only insert markers at valid positions:
            // - position 0 (start of document)
            // - after newline (0x0A) - normal line start
            // - after tab (0x09) - for nested list items where BlockSeparatorInjector inserted indentation
            // This prevents markers from being inserted mid-line if the presentation intent
            // range doesn't align with visual line boundaries.
            let prevChar: unichar = insertion.location > 0 ? nsText.character(at: insertion.location - 1) : 0
            let isValidPosition = insertion.location == 0 || prevChar == 0x0A || prevChar == 0x09
            guard isValidPosition else { continue }

            // Create the marker with font and color attributes.
            let markerAttr = NSMutableAttributedString(
                string: insertion.marker,
                attributes: [
                    .font: font,
                    .foregroundColor: palette.listMarker,
                ]
            )

            // Apply paragraph style from the list item, but ensure firstLineHeadIndent is 0
            // so the marker stays at the left margin while content respects headIndent.
            if
                insertion.location < text.length,
                let existingStyle = text.attribute(.paragraphStyle, at: insertion.location, effectiveRange: nil)
                as? NSParagraphStyle,
                let mutableStyle = existingStyle.mutableCopy() as? NSMutableParagraphStyle
            {
                mutableStyle.firstLineHeadIndent = 0
                markerAttr.addAttribute(
                    .paragraphStyle,
                    value: mutableStyle,
                    range: NSRange(location: 0, length: markerAttr.length)
                )
            }

            text.insert(markerAttr, at: insertion.location)
        }
    }

    // MARK: - Table Cell Truncation

    private func truncateTableCells(
        in text: NSMutableAttributedString,
        bodyFont: NSFont,
        request: RenderRequest
    ) {
        let tableInset: CGFloat = 16
        let usableWidth = request.readableWidth - tableInset * 2
        let colWidth = max(90, usableWidth * 0.20) - 4
        let attrs: [NSAttributedString.Key: Any] = [.font: bodyFont]

        // Cache NSString to avoid repeated conversions
        let nsString = text.string as NSString
        var mutations: [(substringRange: NSRange, replacement: String)] = []
        mutations.reserveCapacity(16)

        // Pre-calculate ellipsis width to avoid repeated calculations
        let ellipsisWidth = ("…" as NSString).size(withAttributes: attrs).width

        nsString.enumerateSubstrings(
            in: NSRange(location: 0, length: text.length),
            options: [.byParagraphs]
        ) { substring, substringRange, _, _ in
            guard let row = substring, row.contains("\t") else { return }

            let segments = row.components(separatedBy: "\t")
            guard segments.count > 1 else { return }

            var newSegments: [String] = []
            newSegments.reserveCapacity(segments.count)
            var changed = false

            for (idx, segment) in segments.enumerated() {
                if idx == segments.count - 1 {
                    newSegments.append(segment)
                    continue
                }

                let segmentNSString = segment as NSString
                let width = segmentNSString.size(withAttributes: attrs).width
                if width <= colWidth {
                    newSegments.append(segment)
                } else {
                    // Use a more efficient truncation approach
                    let availableWidth = colWidth - ellipsisWidth
                    let chars = Array(segment)
                    var truncatedLength = 0

                    // Estimate character count based on average character width
                    let avgCharWidth = width / CGFloat(chars.count)
                    let estimatedLength = Int(availableWidth / avgCharWidth)
                    truncatedLength = min(estimatedLength, chars.count)

                    // Fine-tune with binary search if needed
                    while truncatedLength > 0 {
                        let candidate = String(chars.prefix(truncatedLength))
                        if (candidate as NSString).size(withAttributes: attrs).width <= availableWidth {
                            break
                        }
                        truncatedLength -= 1
                    }

                    let truncated = String(chars.prefix(truncatedLength)) + "…"
                    newSegments.append(truncated)
                    changed = true
                }
            }

            guard changed else { return }
            mutations.append((substringRange: substringRange, replacement: newSegments.joined(separator: "\t")))
        }

        for mutation in mutations.sorted(by: { $0.substringRange.location > $1.substringRange.location }) {
            text.replaceCharacters(in: mutation.substringRange, with: mutation.replacement)
        }
    }

    // MARK: - Task List Styling

    private static let taskListRegex: NSRegularExpression = // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: #"\[( |x|X)\]"#, options: [])

    /// Font cache for commonly used variants
    private nonisolated(unsafe) static let fontCache: NSCache<NSString, NSFont> = {
        let cache = NSCache<NSString, NSFont>()
        cache.countLimit = 50 // Limit to prevent unbounded growth
        return cache
    }()

    private func cachedFontByApplyingTraits(_ base: NSFont, bold: Bool, italic: Bool) -> NSFont {
        let cacheKey = "\(base.fontName)-\(base.pointSize)-\(bold ? "B" : "")-\(italic ? "I" : "")" as NSString

        if let cached = Self.fontCache.object(forKey: cacheKey) {
            return cached
        }

        var traits = base.fontDescriptor.symbolicTraits
        if bold { traits.insert(.bold) }
        if italic { traits.insert(.italic) }

        let descriptor = base.fontDescriptor.withSymbolicTraits(traits)
        let font = NSFont(descriptor: descriptor, size: base.pointSize) ?? {
            var fallback = base
            if bold {
                fallback = NSFontManager.shared.convert(fallback, toHaveTrait: .boldFontMask)
            }
            if italic {
                fallback = NSFontManager.shared.convert(fallback, toHaveTrait: .italicFontMask)
            }
            return fallback
        }()

        Self.fontCache.setObject(font, forKey: cacheKey)
        return font
    }

    func applyTaskListStyling(
        to text: NSMutableAttributedString,
        palette: NativeThemePalette,
        request: RenderRequest
    ) {
        // Cache NSString conversion
        let nsString = text.string as NSString
        let fullRange = NSRange(location: 0, length: text.length)
        let markerMatches = Self.taskListRegex.matches(in: text.string, options: [], range: fullRange)
        guard !markerMatches.isEmpty else { return }

        let markerFont = NSFont.monospacedSystemFont(ofSize: max(11, request.readerFontSize * 0.9), weight: .semibold)
        let markerKern = max(0, request.textSpacing.kern(for: request.readerFontSize) * 0.7)

        for match in markerMatches {
            let markerRange = match.range
            guard markerRange.location != NSNotFound, markerRange.length > 0 else { continue }

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
            if textEnd > lineRange.location, nsString.character(at: textEnd - 1) == 0x0A {
                textEnd -= 1
            }
            guard textStart < textEnd else { continue }

            let contentRange = NSRange(location: textStart, length: textEnd - textStart)
            text.addAttribute(.foregroundColor, value: palette.textSecondary, range: contentRange)
            text.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: contentRange)
            text.addAttribute(.strikethroughColor, value: palette.textTertiary, range: contentRange)
            text.addAttribute(.kern, value: markerKern * 0.8, range: contentRange)
        }
    }
}
