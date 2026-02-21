# Architecture

Overview of mdviewer's architecture and design patterns.

## Overview

mdviewer follows a clean architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                         Views                               │
│  (ContentView, ReaderTextView, FloatingMetadataView)       │
└──────────────────────┬──────────────────────────────────────┘
                       │ @AppStorage, @State
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                        Models                               │
│  (MarkdownDocument, Preferences, Frontmatter)              │
└──────────────────────┬──────────────────────────────────────┘
                       │ Async calls
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                       Services                              │
│                 (MarkdownRenderService)                    │
│                      Actor-isolated                         │
└──────────────────────┬──────────────────────────────────────┘
                       │ Pipeline stages
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      Pipeline                               │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │
│  │   Parser    │→│   Syntax    │→│      Typography     │   │
│  │             │ │ Highlighter │ │       Applier       │   │
│  └─────────────┘ └─────────────┘ └─────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Design Patterns

### MVVM with SwiftUI

Views observe models through property wrappers:

```swift
struct ContentView: View {
    @Binding var document: MarkdownDocument
    @AppStorage("theme") private var theme = AppTheme.basic.rawValue

    var body: some View {
        // View observes model changes automatically
    }
}
```

### Actor-Based Services

The render service uses Swift 6 actors for thread safety:

```swift
actor MarkdownRenderService: MarkdownRendering {
    private let parser: MarkdownParser
    private let syntaxHighlighter: SyntaxHighlighter

    func render(_ request: RenderRequest) async -> RenderedMarkdown {
        // Thread-safe rendering
    }
}
```

### Pipeline Pattern

Markdown rendering uses composable pipeline stages:

```swift
protocol PipelineStage {
    associatedtype Input
    associatedtype Output
    func process(_ input: Input) -> Output
}
```

Stages:
1. **MarkdownParser**: Converts Markdown to AST
2. **SyntaxHighlighter**: Applies code highlighting
3. **TypographyApplier**: Adds typographic attributes
4. **BlockSeparatorInjector**: Adds visual separators

### Protocol-Oriented Design

Core abstractions defined as protocols:

- ``MarkdownRendering``: Main render service interface
- ``SyntaxHighlighting``: Code highlighting
- ``TypographyApplying``: Typography styling
- ``BlockSeparatorInjecting``: Block separators

### Design Tokens

Centralized theming through ``DesignTokens``:

```swift
enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let standard: CGFloat = 8
        static let lg: CGFloat = 16
    }

    enum Typography {
        static let body = Font.system(.body)
        static let code = Font.system(.body, design: .monospaced)
    }
}
```

## Module Organization

### Sources/mdviewer/

| Directory | Purpose |
|-----------|---------|
| `Models/` | Data models and business logic |
| `Views/` | SwiftUI view layer |
| `Services/` | Business logic and external communication |
| `Theme/` | Design tokens and theming |
| `Syntax/` | Syntax highlighting |
| `Resources/` | Assets and bundled files |

### Concurrency Model

- **MainActor**: UI updates and `@AppStorage` access
- **Background Actors**: Heavy processing (rendering, parsing)
- **Unstructured Tasks**: Fire-and-forget operations

```swift
// View layer (MainActor implied)
func loadDocument() {
    Task {
        // Background processing
        let rendered = await renderService.render(request)

        // Back to MainActor for UI update
        self.content = rendered.attributedString
    }
}
```

## Testing Strategy

| Test Type | Location | Purpose |
|-----------|----------|---------|
| Unit Tests | `mdviewerTests/` | Individual component testing |
| Integration Tests | `*IntegrationTests.swift` | Pipeline end-to-end |
| Visual Tests | `*VisualTests.swift` | Rendering output validation |
| E2E Tests | `scripts/e2e.sh` | Full app UI automation |

## Performance Considerations

1. **Lazy Loading**: Render pipeline stages are lazy
2. **Caching**: Parsed AST cached per document
3. **Debouncing**: User input debounced before render
4. **Incremental Updates**: Only changed regions re-rendered
