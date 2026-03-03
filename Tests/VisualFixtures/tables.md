# Tables

## Simple Table

| Name | Type | Default |
| --- | --- | --- |
| fontSize | CGFloat | 17.0 |
| lineSpacing | CGFloat | 1.4 |
| hyphenation | Bool | true |

## Multi-Column Table

| Component | Status | Notes |
| --- | --- | --- |
| `TypographyApplier` | Active | Runs after parser |
| `BlockSeparatorInjector` | Active | Order-dependent |
| `SyntaxHighlighter` | Active | Skips mermaid |
| `MermaidDiagramRenderer` | Active | Final pass |

## Table With Inline Code

| Method | Signature | Returns |
| --- | --- | --- |
| `render` | `render(_ md: String)` | `NSAttributedString` |
| `parse` | `parse(_ input: String)` | `[Block]` |
