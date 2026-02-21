//
//  TypographyApplier.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    @preconcurrency internal import AppKit
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
                    let fontSize = fontSizeForHeader(level: level, baseSize: request.readerFontSize)
                    let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
                    text.addAttribute(.font, value: font, range: range)
                    text.addAttribute(.foregroundColor, value: palette.heading, range: range)
                    // Apply paragraph style to headers with fixed 2pt line spacing
                    applyHeadingParagraphStyle(to: text, range: range, request: request)

                case .codeBlock:
                    let codeFont = NSFont.monospacedSystemFont(ofSize: request.codeFontSize, weight: .regular)
                    text.addAttribute(.font, value: codeFont, range: range)
                    text.addAttribute(.backgroundColor, value: palette.codeBackground, range: range)
                    // Apply paragraph style to code blocks for spacing
                    applyParagraphStyle(to: text, range: range, request: request)

                case .blockQuote:
                    text.addAttribute(.foregroundColor, value: palette.textSecondary, range: range)
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
                    // Calculate depth by counting blockQuote components in the intent
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

            if intent.contains(.code) {
                let codeFont = NSFont.monospacedSystemFont(ofSize: request.readerFontSize * 0.92, weight: .regular)
                text.addAttribute(.font, value: codeFont, range: range)
                text.addAttribute(.backgroundColor, value: palette.inlineCodeBackground, range: range)
            }

            if intent.contains(.stronglyEmphasized) {
                if let existingFont = text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
                    let boldFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .boldFontMask)
                    text.addAttribute(.font, value: boldFont, range: range)
                }
            }

            if intent.contains(.emphasized) {
                if let existingFont = text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
                    let italicFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .italicFontMask)
                    text.addAttribute(.font, value: italicFont, range: range)
                }
            }
        }

        // Apply kerning to full text
        let kern = request.textSpacing.kern(for: request.readerFontSize)
        text.addAttribute(.kern, value: kern, range: fullRange)
    }

    // MARK: - Private Methods

    private func applyParagraphStyle(to text: NSMutableAttributedString, range: NSRange, request: RenderRequest) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = request.textSpacing.lineSpacing(for: request.readerFontSize)
        style.paragraphSpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize)
        style.paragraphSpacingBefore = request.textSpacing.paragraphSpacing(for: request.readerFontSize) * 0.5
        style.hyphenationFactor = request.textSpacing.hyphenationFactor
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyListParagraphStyle(to text: NSMutableAttributedString, range: NSRange, request: RenderRequest) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = request.textSpacing.lineSpacing(for: request.readerFontSize)
        style.paragraphSpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize) * 0.35
        style.headIndent = 20
        style.firstLineHeadIndent = 0
        text.addAttribute(.paragraphStyle, value: style, range: range)
    }

    private func applyHeadingParagraphStyle(
        to text: NSMutableAttributedString,
        range: NSRange,
        request: RenderRequest
    ) {
        let style = NSMutableParagraphStyle()
        // Headings use fixed 2pt line spacing for tight multi-line layout
        style.lineSpacing = 2.0
        style.paragraphSpacing = request.textSpacing.paragraphSpacing(for: request.readerFontSize) * 0.5
        style.paragraphSpacingBefore = request.textSpacing.paragraphSpacing(for: request.readerFontSize) * 0.5
        style.hyphenationFactor = request.textSpacing.hyphenationFactor
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
}
