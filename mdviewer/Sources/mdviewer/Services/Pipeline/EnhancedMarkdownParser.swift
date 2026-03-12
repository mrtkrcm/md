//
//  EnhancedMarkdownParser.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - Enhanced Markdown Parser

    /// Enhanced Markdown parser that extends the built-in NSAttributedString parser
    /// with lightweight footnote support while preserving native semantic intents.
    ///
    /// This parser:
    /// 1. Extracts footnote definitions before native parsing
    /// 2. Uses the built-in parser for standard markdown
    /// 3. Post-processes to fix formatting and add custom rendering
    struct EnhancedMarkdownParser: MarkdownParsing {
        private struct FootnoteDefinition {
            let label: String
            let body: String
        }

        private struct PreprocessingResult {
            let markdown: String
            let footnotes: [FootnoteDefinition]
        }

        func parse(_ markdown: String) throws -> NSAttributedString {
            guard !markdown.isEmpty else {
                return NSAttributedString()
            }

            let preprocessed = preprocessMarkdown(markdown)

            do {
                let attributedString = try NSAttributedString(
                    markdown: preprocessed.markdown,
                    baseURL: nil
                )

                // Post-process to fix formatting issues
                return postprocessAttributedString(attributedString, footnotes: preprocessed.footnotes)
            } catch {
                throw MarkdownParsingError.parsingFailed(underlying: error)
            }
        }

        // MARK: - Pre-processing

        private func preprocessMarkdown(_ markdown: String) -> PreprocessingResult {
            let lines = markdown.components(separatedBy: .newlines)
            var result: [String] = []
            var footnotes: [FootnoteDefinition] = []
            var i = 0
            var activeFence: Character?
            var activeFenceLength = 0

            while i < lines.count {
                let line = lines[i]

                if let fence = fenceDelimiter(in: line) {
                    if activeFence == nil {
                        activeFence = fence.character
                        activeFenceLength = fence.length
                    } else if activeFence == fence.character, fence.length >= activeFenceLength {
                        activeFence = nil
                        activeFenceLength = 0
                    }
                    result.append(line)
                    i += 1
                    continue
                }

                if activeFence == nil, let footnote = footnoteDefinition(in: line) {
                    var bodyLines = [footnote.body]
                    i += 1

                    while i < lines.count {
                        let continuation = lines[i]
                        if continuation.hasPrefix("    ") {
                            bodyLines.append(String(continuation.dropFirst(4)))
                            i += 1
                            continue
                        }
                        if continuation.hasPrefix("\t") {
                            bodyLines.append(String(continuation.dropFirst()))
                            i += 1
                            continue
                        }
                        if continuation.isEmpty, i + 1 < lines.count {
                            let next = lines[i + 1]
                            if next.hasPrefix("    ") || next.hasPrefix("\t") {
                                bodyLines.append("")
                                i += 1
                                continue
                            }
                        }
                        break
                    }

                    footnotes.append(
                        FootnoteDefinition(
                            label: footnote.label,
                            body: bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                    continue
                }

                result.append(line)
                i += 1
            }

            return PreprocessingResult(
                markdown: result.joined(separator: "\n"),
                footnotes: footnotes
            )
        }

        // MARK: - Post-processing

        private func postprocessAttributedString(
            _ string: NSAttributedString,
            footnotes: [FootnoteDefinition]
        ) -> NSAttributedString {
            let mutableString = NSMutableAttributedString(attributedString: string)

            replaceFootnoteReferences(in: mutableString)
            appendFootnotes(footnotes, to: mutableString)
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
                    guard let mutableStyle = style.mutableCopy() as? NSMutableParagraphStyle else { return }

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

        private func fenceDelimiter(in line: String) -> (character: Character, length: Int)? {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let first = trimmed.first, first == "`" || first == "~" else { return nil }
            let length = trimmed.prefix { $0 == first }.count
            return length >= 3 ? (first, length) : nil
        }

        private func footnoteDefinition(in line: String) -> (label: String, body: String)? {
            guard line.hasPrefix("[^"), let closing = line.firstIndex(of: "]") else { return nil }
            let afterClosing = line.index(after: closing)
            guard afterClosing < line.endIndex, line[afterClosing] == ":" else { return nil }

            let labelStart = line.index(line.startIndex, offsetBy: 2)
            let label = String(line[labelStart ..< closing])
            guard !label.isEmpty else { return nil }

            let bodyStart = line.index(after: afterClosing)
            let body = String(line[bodyStart...]).trimmingCharacters(in: .whitespaces)
            return (label, body)
        }

        private func replaceFootnoteReferences(in text: NSMutableAttributedString) {
            let pattern = #"\[\^([^\]]+)\]"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

            let fullRange = NSRange(location: 0, length: text.length)
            let matches = regex.matches(in: text.string, options: [], range: fullRange)

            for match in matches.reversed() {
                guard match.numberOfRanges == 2 else { continue }
                let range = match.range(at: 0)
                let labelRange = match.range(at: 1)
                let nsString = text.string as NSString
                let label = nsString.substring(with: labelRange)
                let originalAttributes = text.attributes(
                    at: min(range.location, max(0, text.length - 1)),
                    effectiveRange: nil
                )
                var replacementAttributes = originalAttributes
                replacementAttributes[MarkdownRenderAttribute.footnoteReference] = label
                let replacement = NSAttributedString(string: label, attributes: replacementAttributes)
                text.replaceCharacters(in: range, with: replacement)
            }
        }

        private func appendFootnotes(_ footnotes: [FootnoteDefinition], to text: NSMutableAttributedString) {
            guard !footnotes.isEmpty else { return }

            let separator = text.length > 0 ? "\n\n" : ""
            text.append(NSAttributedString(string: separator))

            for (index, footnote) in footnotes.enumerated() {
                let body: NSAttributedString
                do {
                    body = try NSAttributedString(markdown: footnote.body, baseURL: nil)
                } catch {
                    body = NSAttributedString(string: footnote.body)
                }

                let entry = NSMutableAttributedString()
                let prefixAttributes = body.length > 0 ? body.attributes(at: 0, effectiveRange: nil) : [:]
                var markerAttributes = prefixAttributes
                markerAttributes[MarkdownRenderAttribute.footnoteReference] = footnote.label

                entry.append(NSAttributedString(string: footnote.label, attributes: markerAttributes))
                entry.append(NSAttributedString(string: " ", attributes: prefixAttributes))
                entry.append(body)

                if index < footnotes.count - 1 {
                    entry.append(NSAttributedString(string: "\n"))
                }

                text.append(entry)
            }
        }
    }

#endif
