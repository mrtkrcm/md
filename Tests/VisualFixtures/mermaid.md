# Mermaid Diagrams

## Render Pipeline

```mermaid
flowchart LR
    A[Parser] --> B[TypographyApplier]
    B --> C[SyntaxHighlighter]
    C --> D[Output]
```
