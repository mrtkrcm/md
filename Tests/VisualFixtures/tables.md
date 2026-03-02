# Tables

## Simple Table

| Name | Type | Default |
|------|------|---------|
| fontSize | CGFloat | 17.0 |
| lineSpacing | CGFloat | 1.4 |
| hyphenation | Bool | true |

## Wide Table With Long Content

| Component | Description | Status | Notes |
|-----------|-------------|--------|-------|
| `TypographyApplier` | Applies paragraph styles and fonts | Active | Runs after parser |
| `BlockSeparatorInjector` | Inserts newlines between block elements | Active | Order-dependent |
| `SyntaxHighlighter` | Highlights code block tokens | Active | Skips mermaid |
| `MermaidDiagramRenderer` | Renders Mermaid diagrams as images | Active | Final pass |

## Table With Inline Code

| Method | Return Type | Throws |
|--------|-------------|--------|
| `render(_:)` | `RenderResult` | No |
| `parse(_:options:)` | `NSAttributedString` | Yes |
| `applyTypography(to:request:)` | `Void` | No |

## Narrow Table

| Key | Value |
|-----|-------|
| A | 1 |
| B | 2 |
| C | 3 |
