//
//  EnhancedMarkdownParser.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - Enhanced Markdown Parser

    /// Enhanced Markdown parser that extends the built-in NSAttributedString parser
    /// with support for hard line breaks while preserving native semantic intents.
    ///
    /// This parser:
    /// 1. Pre-processes markdown for hard line breaks only
    /// 2. Uses the built-in parser for standard markdown
    /// 3. Post-processes to fix formatting and add custom rendering
    struct EnhancedMarkdownParser: MarkdownParsing {
        func parse(_ markdown: String) throws -> NSAttributedString {
            guard !markdown.isEmpty else {
                return NSAttributedString()
            }

            // Pre-process hard line breaks while preserving markdown semantics.
            let processedMarkdown = preprocessMarkdown(markdown)

            do {
                let attributedString = try NSAttributedString(
                    markdown: processedMarkdown,
                    baseURL: nil
                )

                // Post-process to fix formatting issues
                return postprocessAttributedString(attributedString)
            } catch {
                throw MarkdownParsingError.parsingFailed(underlying: error)
            }
        }

        // MARK: - Pre-processing

        private func preprocessMarkdown(_ markdown: String) -> String {
            let lines = markdown.components(separatedBy: .newlines)
            var result: [String] = []
            var i = 0

            while i < lines.count {
                let line = lines[i]
                // Handle hard line breaks (convert two spaces or backslash to HTML br)
                if line.hasSuffix("  ") {
                    // Remove trailing spaces and add explicit line break
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    result.append(trimmed + "<br>")
                } else if line.hasSuffix("\\") {
                    // Remove backslash and add explicit line break
                    let withoutBackslash = String(line.dropLast())
                    result.append(withoutBackslash + "<br>")
                } else {
                    result.append(line)
                }

                i += 1
            }

            return result.joined(separator: "\n")
        }

        // MARK: - Post-processing

        private func postprocessAttributedString(_ string: NSAttributedString) -> NSAttributedString {
            let mutableString = NSMutableAttributedString(attributedString: string)
            let fullRange = NSRange(location: 0, length: mutableString.length)

            // Fix tab stops for table alignment
            mutableString.enumerateAttribute(
                .paragraphStyle,
                in: fullRange,
                options: []
            ) { value, range, _ in
                guard let style = value as? NSParagraphStyle else { return }

                // Check if this paragraph contains tabs (likely a table row)
                let substring = mutableString.string as NSString
                let lineRange = substring.lineRange(for: range)
                let lineText = substring.substring(with: lineRange)

                if lineText.contains("\t") {
                    let mutableStyle = style.mutableCopy() as! NSMutableParagraphStyle

                    // Set up tab stops for table columns
                    let tabStops: [NSTextTab] = (0 ..< 8).map { i in
                        NSTextTab(
                            textAlignment: .left,
                            location: CGFloat(i + 1) * 100,
                            options: [:]
                        )
                    }
                    mutableStyle.tabStops = tabStops

                    mutableString.addAttribute(.paragraphStyle, value: mutableStyle, range: range)
                }
            }

            return mutableString
        }
    }

#endif
