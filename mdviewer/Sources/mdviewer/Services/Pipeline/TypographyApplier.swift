//
//  TypographyApplier.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Typography Applier

/// Applies typography styling including fonts, colors, and spacing.
///
/// This component configures the visual appearance of rendered Markdown
/// based on the requested theme, font family, and spacing preferences.
struct TypographyApplier: TypographyApplying {
    // MARK: - Typography Application

    func applyTypography(to text: NSMutableAttributedString, request: RenderRequest) {
        let fullRange = NSRange(location: 0, length: text.length)
        guard fullRange.length > 0 else { return }

        let palette = NativeThemePalette(theme: request.appTheme, scheme: request.colorScheme)
        let bodyFont = request.readerFontFamily.nsFont(size: request.readerFontSize)

        // Apply base font and color
        text.addAttribute(.font, value: bodyFont, range: fullRange)
        text.addAttribute(.foregroundColor, value: palette.textPrimary, range: fullRange)

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
                    let codeFont = NSFont.monospacedSystemFont(ofSize: request.codeFontSize, weight: .regular)
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

                    // Apply paragraph style to blockquotes for spacing
                    applyParagraphStyle(to: text, range: range, request: request)

                case .paragraph:
                    // Apply paragraph style to paragraphs for proper spacing
                    applyParagraphStyle(to: text, range: range, request: request)

                case .unorderedList, .orderedList:
                    // Apply paragraph style to lists for proper indentation and spacing
                    applyListParagraphStyle(to: text, range: range, request: request)

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

        // Apply kerning to full text
        let kern = request.textSpacing.kern(for: request.readerFontSize)
        text.addAttribute(.kern, value: kern, range: fullRange)
    }

    // MARK: - Private Methods

    /// Creates a base paragraph style with consistent settings across all block types.
    /// Applies proper paragraph spacing to separate blocks visually.
    private func createBaseParagraphStyle(
        lineSpacing: CGFloat,
        paragraphSpacing: CGFloat = 0,
        paragraphSpacingBefore: CGFloat = 0,
        hyphenationFactor: Float = 0,
        alignment: NSTextAlignment = .left
    ) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.paragraphSpacingBefore = paragraphSpacingBefore
        style.hyphenationFactor = hyphenationFactor
        style.alignment = alignment
        return style
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
        // List items have tighter spacing: 40% of standard paragraph spacing
        let fullSpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        let spacing = fullSpacing * 0.4
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            hyphenationFactor: 0
        ) as! NSMutableParagraphStyle

        // Configure list-specific indentation for visual hierarchy
        let listIndent: CGFloat = 24
        style.headIndent = listIndent
        style.firstLineHeadIndent = 0
        style.tabStops = [NSTextTab(textAlignment: .left, location: listIndent, options: [:])]

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

        // Progressive font weight for visual hierarchy
        let weight: NSFont.Weight = level <= 2 ? .bold : .semibold
        let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        text.addAttribute(.font, value: font, range: range)
        text.addAttribute(.foregroundColor, value: palette.heading, range: range)

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
        let spacing = request.textSpacing.paragraphSpacing(for: headingSize)
        let spacingBefore = request.textSpacing.paragraphSpacingBefore(for: headingSize)
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            paragraphSpacingBefore: spacingBefore,
            hyphenationFactor: 0
        )
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func fontSizeForHeader(level: Int, baseSize: CGFloat) -> CGFloat {
        switch level {
        case 1: return baseSize * 2.0
        case 2: return baseSize * 1.5
        case 3: return baseSize * 1.25
        case 4: return baseSize * 1.1
        case 5: return baseSize * 1.05
        case 6: return baseSize
        default: return baseSize
        }
    }

    private func applyCodeBlockParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest,
        hasLineNumbers: Bool
    ) {
        let lineSpacing = request.textSpacing.lineSpacing(for: request.codeFontSize)
        let spacing = request.textSpacing.paragraphSpacing(for: request.codeFontSize)
        let style = createBaseParagraphStyle(
            lineSpacing: lineSpacing,
            paragraphSpacing: spacing,
            hyphenationFactor: 0
        ) as! NSMutableParagraphStyle

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
        // Apply inline code styling
        if intent.contains(.code) {
            let codeFont = NSFont.monospacedSystemFont(
                ofSize: request.readerFontSize * 0.92,
                weight: .regular
            )
            text.addAttribute(.font, value: codeFont, range: range)
            text.addAttribute(.backgroundColor, value: palette.inlineCodeBackground, range: range)
            // Add subtle padding for inline code
            text.addAttribute(.baselineOffset, value: 1, range: range)
        }

        // Apply bold (strong emphasis)
        if intent.contains(.stronglyEmphasized) {
            if let existingFont = text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
                let boldFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .boldFontMask)
                text.addAttribute(.font, value: boldFont, range: range)
            }
        }

        // Apply italic (emphasis)
        if intent.contains(.emphasized) {
            if let existingFont = text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
                let italicFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .italicFontMask)
                text.addAttribute(.font, value: italicFont, range: range)
            }
        }

        // Apply strikethrough (if supported)
        if intent.contains(.strikethrough) {
            text.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            text.addAttribute(.strikethroughColor, value: palette.textSecondary, range: range)
        }
    }
}
