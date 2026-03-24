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
struct TypographyApplier: TypographyApplying {
    // MARK: - Typography Application

    func applyTypography(to text: NSMutableAttributedString, request: RenderRequest) {
        let length = text.length
        guard length > 0 else { return }
        let fullRange = NSRange(location: 0, length: length)

        let palette = NativeThemePalette.cached(theme: request.appTheme, scheme: request.colorScheme)
        let bodyFont = request.readerFontFamily.nsFont(size: request.readerFontSize)

        // 1. Initial base styling (Fast)
        let enhancedFont = applyTypographicFeatures(to: bodyFont, preferences: request.typographyPreferences)
        text.addAttributes([
            .font: enhancedFont,
            .foregroundColor: palette.textPrimary,
            .paragraphStyle: createBaseParagraphStyle(
                lineSpacing: request.textSpacing.lineSpacing(for: request.readerFontSize),
                paragraphSpacing: request.textSpacing.paragraphSpacing(for: request.readerFontSize),
                hyphenationFactor: request.typographyPreferences.hyphenation ? request.textSpacing
                    .hyphenationFactor : 0,
                alignment: request.typographyPreferences.justification.nsAlignment
            ),
        ], range: fullRange)

        // 2. Table cell truncation (Mutates string length)
        truncateTableCells(in: text, bodyFont: enhancedFont, request: request)
        let newLength = text.length
        let newFullRange = NSRange(location: 0, length: newLength)

        // 3. Combined intent pass (Handles headers, code blocks, blockquotes, etc.)
        applyPresentationIntentAndKerning(to: text, fullRange: newFullRange, request: request, palette: palette)

        // 4. Structural pass (Links, markers, HRs, task lists)
        applyStructuralStyling(to: text, fullRange: newFullRange, palette: palette, request: request)
    }

    // MARK: - Typographic Features

    private func applyTypographicFeatures(to font: NSFont, preferences: TypographyPreferences) -> NSFont {
        guard preferences.ligatures else { return font }
        let descriptor = font.fontDescriptor.addingAttributes([
            .featureSettings: [[
                NSFontDescriptor.FeatureKey.typeIdentifier: kCommonLigaturesOnSelector,
                NSFontDescriptor.FeatureKey.selectorIdentifier: 1,
            ]],
        ])
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
    }

    // MARK: - Structural Styling Pass

    /// Combined pass for elements that require specialized scanning or string mutation.
    private func applyStructuralStyling(
        to text: NSMutableAttributedString,
        fullRange: NSRange,
        palette: NativeThemePalette,
        request: RenderRequest
    ) {
        let nsString = text.string as NSString
        let rhythm = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let hrSpacing = max(
            DesignTokens.TypographySpacing.horizontalRuleMinSpacing,
            rhythm * DesignTokens.TypographySpacing.horizontalRuleSpacingMultiplier
        )
        let hrStyle = NSMutableParagraphStyle()
        hrStyle.paragraphSpacingBefore = hrSpacing
        hrStyle.paragraphSpacing = hrSpacing
        let hrFont = NSFont.systemFont(ofSize: DesignTokens.Component.HorizontalRule.fontSize, weight: .regular)

        var listInsertions: [(location: Int, marker: String, style: NSParagraphStyle?)] = []
        var hrInsertions: [Int] = []

        // Single pass for links and intents
        text.enumerateAttribute(.link, in: fullRange, options: []) { value, range, _ in
            guard value != nil else { return }
            text.addAttributes([
                .foregroundColor: palette.link,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: palette.formattedLinkUnderlineColor(),
            ], range: range)
        }

        text
            .enumerateAttribute(
                MarkdownRenderAttribute.presentationIntent,
                in: fullRange,
                options: []
            ) { value, range, _ in
                guard let intent = value as? PresentationIntent else { return }

                // Discover List Markers
                var listItemOrdinal: Int?
                var isOrdered = false
                var isCodeBlock = false
                var isThematicBreak = false

                for component in intent.components {
                    switch component.kind {
                    case .listItem(let ordinal): listItemOrdinal = ordinal
                    case .orderedList: isOrdered = true
                    case .codeBlock: isCodeBlock = true
                    case .thematicBreak: isThematicBreak = true
                    default: break
                    }
                }

                if let ordinal = listItemOrdinal, !isCodeBlock {
                    let style = text.attribute(
                        .paragraphStyle,
                        at: range.location,
                        effectiveRange: nil
                    ) as? NSParagraphStyle
                    listInsertions.append((range.location, isOrdered ? "\(ordinal).\t" : "•\t", style))
                }

                // Discover HR positions
                if isThematicBreak {
                    text.addAttributes([
                        MarkdownRenderAttribute.horizontalRule: palette.horizontalRule,
                        .foregroundColor: NSColor.clear,
                        .paragraphStyle: hrStyle,
                        .font: hrFont,
                    ], range: range)

                    if NSMaxRange(range) < nsString.length, nsString.character(at: NSMaxRange(range)) != 0x0A {
                        hrInsertions.append(NSMaxRange(range))
                    }
                }
            }

        // Apply string mutations in reverse
        var mutations: [(location: Int, text: NSAttributedString)] = []
        let markerFont = request.readerFontFamily.nsFont(size: request.readerFontSize)

        for list in listInsertions {
            let prevChar = list.location > 0 ? nsString.character(at: list.location - 1) : 0
            if list.location == 0 || prevChar == 0x0A || prevChar == 0x09 {
                let markerAttr = NSMutableAttributedString(string: list.marker, attributes: [
                    .font: markerFont,
                    .foregroundColor: palette.listMarker,
                ])
                if let style = list.style?.mutableCopy() as? NSMutableParagraphStyle {
                    style.firstLineHeadIndent = 0
                    markerAttr.addAttribute(
                        .paragraphStyle,
                        value: style,
                        range: NSRange(location: 0, length: markerAttr.length)
                    )
                }
                mutations.append((list.location, markerAttr))
            }
        }

        let hrNewline = NSMutableAttributedString(string: "\n", attributes: [
            .paragraphStyle: hrStyle,
            .font: hrFont,
            .foregroundColor: NSColor.clear,
        ])
        for loc in hrInsertions {
            mutations.append((loc, hrNewline))
        }

        for mutation in mutations.sorted(by: { $0.location > $1.location }) {
            text.insert(mutation.text, at: mutation.location)
        }

        // Final task list pass (Regex-based, so separate)
        applyTaskListStyling(to: text, palette: palette, request: request)
    }

    // MARK: - Combined Presentation Intent + Kerning

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

        text
            .enumerateAttribute(
                MarkdownRenderAttribute.presentationIntent,
                in: fullRange,
                options: []
            ) { value, range, _ in
                guard let intent = value as? PresentationIntent else { return }

                var isCodeBlock = false
                var isHeading = false
                var headingLevel = 0
                var isBlockQuote = false
                let hasListItem = intent.components.contains {
                    if case .listItem = $0.kind { return true }
                    return false
                }

                for component in intent.components {
                    switch component.kind {
                    case .header(let level):
                        guard !hasListItem else { continue }
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
                        applyTableHeaderStyle(
                            to: text,
                            range: range,
                            request: request,
                            palette: palette,
                            isTerminalInTable: isTerminalTableSegment(in: text, range: range, intent: intent)
                        )
                    case .tableRow(let rowIndex):
                        applyTableRowStyle(
                            to: text,
                            range: range,
                            rowIndex: rowIndex,
                            request: request,
                            palette: palette,
                            isTerminalInTable: isTerminalTableSegment(in: text, range: range, intent: intent)
                        )
                    default: break
                    }
                }

                if isHeading {
                    let headingFontSize = fontSizeForHeader(level: headingLevel, baseSize: request.readerFontSize)
                    let adjustedKern = (request.textSpacing
                        .kern(for: headingFontSize) +
                        (headingFontSize * request.textSpacing.opticalSizeAdjustment(for: headingFontSize))) * 0.8
                    text.addAttribute(.kern, value: adjustedKern, range: range)
                } else if isCodeBlock {
                    text.addAttribute(
                        .kern,
                        value: request.textSpacing.kern(for: request.codeFontSize) * 0.3,
                        range: range
                    )
                } else if isBlockQuote {
                    text.addAttribute(.kern, value: totalBaseKern + (request.readerFontSize * 0.003), range: range)
                }
            }

        // Inline intents
        text
            .enumerateAttribute(
                MarkdownRenderAttribute.inlinePresentationIntent,
                in: fullRange,
                options: []
            ) { value, range, _ in
                let rawValue = (value as? NSNumber)?.uintValue ?? 0
                guard rawValue != 0 else { return }
                let intent = InlinePresentationIntent(rawValue: rawValue)
                applyInlineStyles(to: text, range: range, intent: intent, palette: palette, request: request)

                if intent.contains(.code) {
                    text.addAttribute(
                        .kern,
                        value: request.textSpacing.kern(for: request.readerFontSize) * 0.3,
                        range: range
                    )
                }
            }

        text.enumerateAttribute(
            MarkdownRenderAttribute.footnoteReference,
            in: fullRange,
            options: []
        ) { value, range, _ in
            guard value != nil else { return }
            applyFootnoteReferenceStyle(to: text, range: range, request: request)
        }
    }

    // MARK: - Component Stylers

    private func applyHeadingStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        level: Int,
        palette: NativeThemePalette
    ) {
        let weight: NSFont.Weight = (level == 1) ? .heavy : (level == 2 ? .bold : (level == 3 ? .semibold : .medium))
        let font = request.readerFontFamily.nsFont(
            size: fontSizeForHeader(level: level, baseSize: request.readerFontSize),
            weight: weight
        )
        text.addAttributes([
            .font: font,
            MarkdownRenderAttribute.headingLevel: level,
            .foregroundColor: palette.formattedHeadingColor(level: level),
        ], range: range)
        applyHeadingParagraphStyle(to: text, range: range, request: request, level: level)
    }

    private func applyCodeBlockStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        palette: NativeThemePalette
    ) {
        let codeFont = request.readerFontFamily.nsFont(size: request.codeFontSize, monospaced: true)
        text.addAttributes([
            .font: codeFont,
            .backgroundColor: palette.codeBackground,
            .foregroundColor: palette.codeText,
        ], range: range)
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
        var depth = 0
        for c in intent.components { if case .blockQuote = c.kind { depth += 1 } }
        text.addAttributes([
            .foregroundColor: palette.blockquoteText,
            MarkdownRenderAttribute.blockquoteAccent: palette.blockquoteAccent,
            MarkdownRenderAttribute.blockquoteBackground: palette.blockquoteBackground,
            MarkdownRenderAttribute.blockquoteDepth: max(1, depth),
        ], range: range)
        applyBlockquoteParagraphStyle(to: text, range: range, request: request, depth: max(1, depth))
    }

    private func applyTableHeaderStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        palette: NativeThemePalette,
        isTerminalInTable: Bool
    ) {
        let columnCount = tableColumnCount(in: text, range: range)
        text.addAttributes([
            .font: request.readerFontFamily.nsFont(size: request.readerFontSize, weight: .semibold),
            .foregroundColor: palette.formattedTableHeaderTextColor(),
            MarkdownRenderAttribute.tableHeaderBackground: palette.formattedTableHeaderBackground(),
            MarkdownRenderAttribute.tableBorder: palette.formattedTableBorder(),
            MarkdownRenderAttribute.tableColumnDividerOpacity: palette.tableColumnDividerOpacityMultiplier(),
            MarkdownRenderAttribute.tableColumnCount: columnCount,
            MarkdownRenderAttribute.tableTerminalRow: isTerminalInTable,
        ], range: range)
        applyTableRowParagraphStyle(
            to: text,
            range: range,
            request: request,
            isTerminalInTable: isTerminalInTable,
            columnCount: columnCount
        )
    }

    private func applyTableRowStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        rowIndex: Int,
        request: RenderRequest,
        palette: NativeThemePalette,
        isTerminalInTable: Bool
    ) {
        let columnCount = tableColumnCount(in: text, range: range)
        let isAlternating = rowIndex % 2 == 0
        if isAlternating {
            text.addAttribute(
                MarkdownRenderAttribute.tableRowBackground,
                value: palette.formattedTableRowBackground(),
                range: range
            )
        }
        text.addAttributes([
            .font: request.readerFontFamily.nsFont(size: request.readerFontSize),
            .foregroundColor: palette.textPrimary,
            MarkdownRenderAttribute.tableBodyBackground: palette.formattedTableBodyBackground(),
            MarkdownRenderAttribute.tableRowAlternating: isAlternating,
            MarkdownRenderAttribute.tableBorder: palette.formattedTableBorder(),
            MarkdownRenderAttribute.tableColumnDividerOpacity: palette.tableColumnDividerOpacityMultiplier(),
            MarkdownRenderAttribute.tableColumnCount: columnCount,
            MarkdownRenderAttribute.tableTerminalRow: isTerminalInTable,
        ], range: range)
        applyTableRowParagraphStyle(
            to: text,
            range: range,
            request: request,
            isTerminalInTable: isTerminalInTable,
            columnCount: columnCount
        )
    }

    private func applyFootnoteReferenceStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest
    ) {
        let pointSize = max(DesignTokens.Typography.caption, request.readerFontSize * 0.68)
        let footnoteFont = request.readerFontFamily.nsFont(size: pointSize)
        text.addAttributes(
            [
                .font: footnoteFont,
                .baselineOffset: round(request.readerFontSize * 0.24),
            ],
            range: range
        )
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
        style.usesDefaultHyphenation = hyphenationFactor > 0
        return style
    }

    private func applyBlockquoteParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        depth: Int
    ) {
        let lineHeight = request.readerFontSize * request.textSpacing.lineHeightMultiplier
        // Consistent 0.75× spacing for blockquotes (between compact and balanced)
        let spacing = lineHeight * 0.75
        let style = createBaseParagraphStyle(
            lineSpacing: request.textSpacing.lineSpacing(for: request.readerFontSize),
            paragraphSpacing: spacing,
            paragraphSpacingBefore: spacing * 0.75,
            hyphenationFactor: request.typographyPreferences.hyphenation ? max(
                0,
                request.textSpacing.hyphenationFactor - 0.05
            ) : 0,
            alignment: request.typographyPreferences.justification.nsAlignment
        )
        let indent: CGFloat = DesignTokens.TypographySpacing
            .blockquoteBaseIndent + CGFloat(max(0, depth - 1)) * DesignTokens.TypographySpacing.blockquoteDepthIncrement
        style.headIndent = indent
        style.firstLineHeadIndent = indent
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyParagraphStyle(to text: NSMutableAttributedString, range: NSRange, request: RenderRequest) {
        let style = createBaseParagraphStyle(
            lineSpacing: request.textSpacing.lineSpacing(for: request.readerFontSize),
            paragraphSpacing: request.textSpacing.paragraphSpacing(for: request.readerFontSize),
            hyphenationFactor: request.typographyPreferences.hyphenation ? max(
                0,
                request.textSpacing.hyphenationFactor - 0.05
            ) : 0,
            alignment: request.typographyPreferences.justification.nsAlignment
        )
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyListParagraphStyle(to text: NSMutableAttributedString, range: NSRange, request: RenderRequest) {
        let style = createBaseParagraphStyle(
            lineSpacing: request.textSpacing.lineSpacing(for: request.readerFontSize),
            paragraphSpacing: request.textSpacing.paragraphSpacing(for: request.readerFontSize) * 0.5,
            alignment: request.typographyPreferences.justification.nsAlignment
        )
        style.headIndent = 24
        style.firstLineHeadIndent = 0
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyTableRowParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        isTerminalInTable: Bool,
        columnCount: Int
    ) {
        let lineHeight = request.readerFontSize * request.textSpacing.lineHeightMultiplier
        let bodySpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let cellSpacing = max(
            DesignTokens.Component.Table.minCellSpacing,
            lineHeight * DesignTokens.TypographySpacing.tableCellSpacingMultiplier
        )
        let style = createBaseParagraphStyle(
            lineSpacing: max(2, request.textSpacing.lineSpacing(for: request.readerFontSize) * 0.9),
            paragraphSpacing: isTerminalInTable ? bodySpacing : cellSpacing,
            paragraphSpacingBefore: cellSpacing,
            alignment: request.typographyPreferences.justification.nsAlignment
        )
        style.tabStops = TableLayoutMetrics.tabStops(
            readableWidth: request.readableWidth,
            columnCount: columnCount
        )
        style.lineBreakMode = .byTruncatingTail
        style.headIndent = TableLayoutMetrics.contentInset
        style.firstLineHeadIndent = TableLayoutMetrics.contentInset
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func isTerminalTableSegment(
        in text: NSAttributedString,
        range: NSRange,
        intent: PresentationIntent
    ) -> Bool {
        guard let currentTable = tableInfo(from: intent) else { return false }

        var location = NSMaxRange(range)
        while location < text.length {
            var effectiveRange = NSRange(location: 0, length: 0)
            let nextValue = text.attribute(
                MarkdownRenderAttribute.presentationIntent,
                at: location,
                effectiveRange: &effectiveRange
            )

            if let nextIntent = nextValue as? PresentationIntent {
                guard let nextTable = tableInfo(from: nextIntent) else { return true }
                if nextTable.row == currentTable.row, nextTable.isHeader == currentTable.isHeader {
                    location = max(location + 1, NSMaxRange(effectiveRange))
                    continue
                }
                return false
            }

            location = effectiveRange.length > 0 ? max(location + 1, NSMaxRange(effectiveRange)) : location + 1
        }

        return true
    }

    private func tableInfo(from intent: PresentationIntent) -> (row: Int, isHeader: Bool)? {
        var row = -2
        var isHeader = false
        var isTable = false

        for component in intent.components {
            switch component.kind {
            case .tableCell:
                isTable = true
            case .tableRow(let rowIndex):
                row = rowIndex
            case .tableHeaderRow:
                isHeader = true
                row = -1
            default:
                break
            }
        }

        return isTable ? (row, isHeader) : nil
    }

    private func applyHeadingParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        level: Int
    ) {
        let headingSize = fontSizeForHeader(level: level, baseSize: request.readerFontSize)
        let baseSpacing = request.textSpacing.paragraphSpacing(for: headingSize)
        let mult: CGFloat = level == 1 ? 0.72 : (level == 2 ? 0.62 : (level == 3 ? 0.54 : 0.46))
        text.addAttribute(.paragraphStyle, value: createBaseParagraphStyle(
            lineSpacing: request.textSpacing.lineSpacing(for: headingSize),
            paragraphSpacing: baseSpacing * mult,
            paragraphSpacingBefore: baseSpacing * mult,
            alignment: request.typographyPreferences.justification.nsAlignment
        ), range: range)
    }

    private func fontSizeForHeader(level: Int, baseSize: CGFloat) -> CGFloat {
        let mult: CGFloat = level == 1 ? 1.75 :
            (level == 2 ? 1.5 : (level == 3 ? 1.3 : (level == 4 ? 1.15 : (level == 5 ? 1.1 : 1.05))))
        return baseSize * mult
    }

    private func applyCodeBlockParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        hasLineNumbers: Bool
    ) {
        let style = createBaseParagraphStyle(
            lineSpacing: request.codeFontSize * DesignTokens.TypographySpacing.codeBlockLineMultiplier,
            paragraphSpacing: 0,
            paragraphSpacingBefore: 0
        )
        // Enable soft word wrapping for code blocks (matching reference image)
        style.lineBreakMode = .byWordWrapping
        if hasLineNumbers {
            let gutter = (request.codeFontSize * DesignTokens.TypographySpacing
                .codeBlockCharWidthMultiplier * DesignTokens.TypographySpacing.codeBlockGutterChars) +
                (request.codeFontSize * DesignTokens.TypographySpacing.codeBlockGutterPaddingMultiplier)
            style.headIndent = gutter
            style.firstLineHeadIndent = gutter
        }
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyInlineStyles(
        to text: NSMutableAttributedString,
        range: NSRange,
        intent: InlinePresentationIntent,
        palette: NativeThemePalette,
        request: RenderRequest
    ) {
        var font = text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
        if intent.contains(.code) {
            font = request.readerFontFamily.nsFont(size: request.readerFontSize * 0.92, monospaced: true)
            text.addAttributes(
                [
                    .font: font!,
                    .backgroundColor: palette.inlineCodeBackground,
                    .foregroundColor: palette.codeText,
                    .baselineOffset: 0, // Set to 0 to fix alignment with background highlight
                ],
                range: range
            )
        }
        if intent.contains(.stronglyEmphasized) || intent.contains(.emphasized) {
            if let f = font { text.addAttribute(
                .font,
                value: cachedFontByApplyingTraits(
                    f,
                    bold: intent.contains(.stronglyEmphasized),
                    italic: intent.contains(.emphasized)
                ),
                range: range
            ) }
        }
        if intent.contains(.strikethrough) {
            text.addAttributes(
                [.strikethroughStyle: NSUnderlineStyle.single.rawValue, .strikethroughColor: palette.textTertiary],
                range: range
            )
        }
    }

    private func truncateTableCells(in text: NSMutableAttributedString, bodyFont: NSFont, request: RenderRequest) {
        let nsString = text.string as NSString
        var mutations: [(range: NSRange, text: String)] = []
        let ellipsisWidth = ("…" as NSString).size(withAttributes: [.font: bodyFont]).width

        nsString
            .enumerateSubstrings(
                in: NSRange(location: 0, length: text.length),
                options: .byParagraphs
            ) { sub, subR, _, _ in
                guard let row = sub, row.contains("\t") else { return }
                let segs = row.components(separatedBy: "\t")
                let colWidth = TableLayoutMetrics.nonTerminalCellContentWidth(
                    readableWidth: request.readableWidth,
                    columnCount: segs.count
                ) - DesignTokens.Component.Table.truncationPadding
                var newSegs: [String] = []
                var changed = false
                for (i, seg) in segs.enumerated() {
                    if i == segs.count - 1 { newSegs.append(seg); continue }
                    let w = (seg as NSString).size(withAttributes: [.font: bodyFont]).width
                    if w <= colWidth { newSegs.append(seg) } else {
                        let chars = Array(seg)
                        var len = Int((colWidth - ellipsisWidth) / (w / CGFloat(chars.count)))
                        while
                            len > 0,
                            (String(chars.prefix(len)) as NSString).size(withAttributes: [.font: bodyFont])
                                .width > (colWidth - ellipsisWidth) { len -= 1 }
                        newSegs.append(String(chars.prefix(len)) + "…"); changed = true
                    }
                }
                if changed { mutations.append((subR, newSegs.joined(separator: "\t"))) }
            }
        for m in mutations.sorted(by: { $0.range.location > $1.range.location }) { text.replaceCharacters(
            in: m.range,
            with: m.text
        ) }
    }

    private func tableColumnCount(in text: NSAttributedString, range: NSRange) -> Int {
        let nsString = text.string as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: range.location, length: 0))
        let lineText = nsString.substring(with: lineRange)
        let tabCount = lineText.reduce(into: 0) { result, character in
            if character == "\t" {
                result += 1
            }
        }
        return max(1, tabCount + 1)
    }

    private nonisolated(unsafe) static let fontCache = NSCache<NSString, NSFont>()
    private func cachedFontByApplyingTraits(_ base: NSFont, bold: Bool, italic: Bool) -> NSFont {
        let key = "\(base.fontName)-\(base.pointSize)-\(bold)-\(italic)" as NSString
        if let c = Self.fontCache.object(forKey: key) { return c }
        var traits = base.fontDescriptor.symbolicTraits
        if bold { traits.insert(.bold) }
        if italic { traits.insert(.italic) }
        let f = NSFont(descriptor: base.fontDescriptor.withSymbolicTraits(traits), size: base.pointSize) ?? base
        Self.fontCache.setObject(f, forKey: key); return f
    }

    /// Pre-compiled regex for task list checkbox detection.
    /// Uses lazy initialization with fatalError fallback since pattern is compile-time constant.
    private static let taskListRegex: NSRegularExpression = {
        // Pattern is compile-time constant - safe to force unwrap after validation
        guard let regex = try? NSRegularExpression(pattern: #"\[( |x|X)\]"#, options: []) else {
            fatalError("Invalid task list regex pattern - this should never happen")
        }
        return regex
    }()

    /// Applies task list checkbox styling and strikethrough for completed items.
    func applyTaskListStyling(to text: NSMutableAttributedString, palette: NativeThemePalette, request: RenderRequest) {
        let nsString = text.string as NSString
        let matches = Self.taskListRegex.matches(
            in: text.string,
            options: [],
            range: NSRange(location: 0, length: text.length)
        )
        for m in matches {
            guard
                let intent = text.attribute(
                    MarkdownRenderAttribute.presentationIntent,
                    at: m.range.location,
                    effectiveRange: nil
                ) as? PresentationIntent,
                intent.components.contains(where: { if case .unorderedList = $0.kind { return true }; return false })
            else { continue }
            let checked = nsString.substring(with: m.range).lowercased() == "[x]"
            text.addAttributes(
                [
                    .font: NSFont.monospacedSystemFont(
                        ofSize: max(11, request.readerFontSize * 0.9),
                        weight: .semibold
                    ),
                    .foregroundColor: checked ? palette.taskListChecked : palette.taskListUnchecked,
                    MarkdownRenderAttribute.taskListChecked: checked,
                ],
                range: m.range
            )
            if checked {
                let line = nsString.lineRange(for: m.range)
                let end = nsString.character(at: NSMaxRange(line) - 1) == 0x0A ? NSMaxRange(line) - 1 : NSMaxRange(line)
                text.addAttributes(
                    [
                        .foregroundColor: palette.textSecondary,
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                        .strikethroughColor: palette.textTertiary,
                    ],
                    range: NSRange(
                        location: m.range.location + m.range.length,
                        length: end - (m.range.location + m.range.length)
                    )
                )
            }
        }
    }
}
