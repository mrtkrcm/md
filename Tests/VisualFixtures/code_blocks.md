# Code Blocks

## Swift

```swift
final class MarkdownRenderService {
    static let shared = MarkdownRenderService()

    func render(_ request: RenderRequest) async -> RenderResult {
        let parser = EnhancedMarkdownParser()
        var text = parser.parse(request.markdown, options: request.parserOptions)
        let applier = TypographyApplier()
        applier.applyTypography(to: &text, request: request)
        return RenderResult(attributedString: text)
    }
}
```

## Bash

```bash
#!/usr/bin/env bash
set -euo pipefail

just build
just test
just install
echo "Done"
```

## Plain / Unknown Language

```
plain text block
no syntax highlighting
just monospace font
```

## Inline Code

Use `NSMutableAttributedString` to build the document. Call `text.addAttribute(.font, value: font, range: range)` for each run. The `paragraphStyle` attribute controls spacing — never use literal `\n` for spacing.

## Long Line Code Block

```swift
text.addAttribute(.paragraphStyle, value: hrStyle, range: NSRange(location: effectiveRange.location, length: rangeEnd - effectiveRange.location))
```
