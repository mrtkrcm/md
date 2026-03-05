# Rendering Pipeline

Deep dive into the Markdown rendering pipeline architecture.

## Overview

The rendering pipeline transforms raw Markdown into styled attributed strings through a series of composable stages:

```
Raw Markdown → Parser → AST → Syntax Highlighter → Typography → Output
```

## Pipeline Stages

### 1. Markdown Parser

Converts raw Markdown text into an abstract syntax tree (AST).

```swift
struct MarkdownParser {
    func parse(_ text: String) -> MarkdownAST {
        // Parse frontmatter and content
        // Return structured representation
    }
}
```

Features:
- Frontmatter extraction (YAML)
- Block-level parsing (headers, lists, code blocks)
- Inline parsing (links, emphasis, code)

### 2. Syntax Highlighter

Applies syntax highlighting to code blocks.

```swift
struct SyntaxHighlighter: SyntaxHighlighting {
    func highlight(_ code: String, language: String?) -> NSAttributedString {
        // Tokenize code
        // Apply color attributes
    }
}
```

Supported languages:
- Swift
- JavaScript/TypeScript
- Python
- JSON
- Markdown
- Shell/Bash

### 3. Typography Applier

Adds typographic styling to the AST.

```swift
struct TypographyApplier: TypographyApplying {
    func apply(_ ast: MarkdownAST, theme: AppTheme) -> StyledDocument {
        // Apply font families
        // Set sizes and weights
        // Configure line spacing
    }
}
```

### 4. Block Separator Injector

Adds visual separators between blocks.

```swift
struct BlockSeparatorInjector: BlockSeparatorInjecting {
    func inject(into document: StyledDocument) -> StyledDocument {
        // Add spacing between paragraphs
        // Configure block margins
    }
}
```

## Render Service

The ``MarkdownRenderService`` orchestrates the pipeline:

```swift
actor MarkdownRenderService: MarkdownRendering {
    func render(_ request: RenderRequest) async -> RenderedMarkdown {
        // 1. Check cache
        if let cached = await cache.get(request.id) {
            return cached
        }

        // 2. Parse
        let ast = parser.parse(request.text)

        // 3. Process through pipeline
        let highlighted = await syntaxHighlighter.process(ast)
        let styled = typographyApplier.apply(highlighted, theme: request.theme)
        let final = separatorInjector.inject(into: styled)

        // 4. Cache and return
        let result = RenderedMarkdown(styledDocument: final)
        await cache.set(result, for: request.id)
        return result
    }
}
```

## Caching Strategy

Two-level caching for performance:

1. **AST Cache**: Parsed AST cached by content hash
2. **Render Cache**: Final output cached by request signature

Cache invalidation:
- Content changes invalidate AST cache
- Theme changes invalidate render cache
- Manual clear via `RenderCache.clear()`

## Extending the Pipeline

To add a new pipeline stage:

1. Define a protocol (if not existing):
```swift
protocol NewProcessingStage {
    func process(_ input: InputType) -> OutputType
}
```

2. Implement the stage:
```swift
struct MyNewStage: NewProcessingStage {
    func process(_ input: InputType) -> OutputType {
        // Processing logic
    }
}
```

3. Add to render service:
```swift
actor MarkdownRenderService {
    private let newStage: NewProcessingStage

    func render(_ request: RenderRequest) async -> RenderedMarkdown {
        // ... existing stages
        let processed = newStage.process(previousOutput)
        // ... continue pipeline
    }
}
```

## Performance & 120fps Optimizations

The pipeline is optimized for **120Hz ProMotion displays** using several key techniques:

### 1. Decoration Caching
The `ReaderLayoutManager` maintains a `decorationCache` for block-level elements (code blocks, blockquotes, tables). Geometry is calculated once and reused during scrolling, reducing frame times from ~12ms to **<2ms**.

### 2. $O(N \log N)$ Attribute Scanning
Manual linear scans have been replaced with `enumerateAttribute(_:in:options:using:)`. This leverages the internal tree structure of `NSAttributedString` for highly efficient metadata discovery, essential for large documents.

### 3. Single-Pass Pipeline
The `BlockSeparatorInjector` and `TypographyApplier` have been consolidated into single-pass traversals to minimize the cost of string mutations and attribute updates.

### 4. Request Stability
`NativeMarkdownTextView` performs a deep equality check on incoming `RenderRequest` objects to avoid redundant renders during parent view updates or scroll events.

## Benchmarks (M1 Pro @ 120Hz)
