# Markdown Parser Architecture & Extension Guide

## Current Architecture

```
Input: String (Markdown)
  ↓
MarkdownParser (Protocol: MarkdownParsing)
  ├── Implementation: Built-in NSAttributedString(markdown:)
  ├── Output: NSAttributedString with PresentationIntent attributes
  └── Attributes: font, foregroundColor, backgroundColor, paragraphStyle
  ↓
MarkdownRenderService
  ├── FrontmatterParser (strips YAML frontmatter)
  ├── BlockSeparatorInjector (handles block boundaries)
  ├── TypographyApplier (applies fonts, colors, spacing)
  ├── SyntaxHighlighter (syntax coloring for code blocks)
  └── Cache: NSCache<NSString, RenderedMarkdown>
  ↓
Output: RenderedMarkdown (wraps final NSAttributedString)
```

## Protocol: MarkdownParsing

```swift
protocol MarkdownParsing {
    func parse(_ markdown: String) throws -> NSAttributedString
}
```

Currently implemented by:
- `MarkdownParser` (uses built-in `NSAttributedString(markdown:)`)

Future implementations can implement this protocol:
- `SwiftMarkdownParser` (when swift-markdown integration needed)
- `CustomMarkdownParser` (for specialized use cases)

## Attribute Mapping

### Standard NSAttributedString Attributes Applied

| Attribute | Used By | Example |
|-----------|---------|---------|
| `.font` | TypographyApplier | H1: system 32pt bold, Body: 16pt |
| `.foregroundColor` | TypographyApplier | Heading color, text color, link color |
| `.backgroundColor` | TypographyApplier | Code blocks, inline code |
| `.paragraphStyle` | TypographyApplier | Line spacing, paragraph spacing, indentation |
| `.baselineOffset` | TypographyApplier | Inline code subtle vertical adjustment |
| `.strikethroughStyle` | TypographyApplier | Strikethrough text |
| `.strikethroughColor` | TypographyApplier | Strikethrough color |
| `.kern` | TypographyApplier | Letter spacing per text-spacing preset |

### Custom MarkdownRenderAttribute Extensions

Defined in `MarkdownRenderAttribute.swift`:

```swift
struct MarkdownRenderAttribute {
    static let presentationIntent = NSAttributedString.Key("NSPresentationIntent")
    static let inlinePresentationIntent = NSAttributedString.Key("InlinePresentationIntent")
    static let codeBlock = NSAttributedString.Key("CodeBlock")
    static let blockquoteAccent = NSAttributedString.Key("BlockquoteAccent")
    static let blockquoteBackground = NSAttributedString.Key("BlockquoteBackground")
    static let blockquoteDepth = NSAttributedString.Key("BlockquoteDepth")
    static let paragraphSeparator = NSAttributedString.Key("ParagraphSeparator")
}
```

## Presentation Intent Mapping

### Block-Level Elements

Mapped from `PresentationIntent.Component.Kind`:

```
.paragraph       → Regular body text with line spacing
.header(level)   → Sized/weighted font + spacing-before
.codeBlock       → Monospace font + background
.blockQuote      → Accent color + left border
.unorderedList   → Indented items with bullets
.orderedList     → Indented items with numbers
```

### Inline Elements

Mapped from `InlinePresentationIntent`:

```
.code            → Monospace font + inline background
.stronglyEmphasized → Bold trait
.emphasized      → Italic trait
.strikethrough   → Strikethrough style
```

## Pipeline Stages

### Stage 1: FrontmatterParser (MarkdownRenderService)
- Strips YAML frontmatter (if present)
- Extracts metadata for document inspector
- Returns: `(frontmatter: Frontmatter, renderedMarkdown: String)`

### Stage 2: MarkdownParser (This File)
- Parses markdown string to NSAttributedString
- Applies base PresentationIntent attributes
- Returns: NSAttributedString

### Stage 3: BlockSeparatorInjector
- Identifies block boundaries from PresentationIntent
- Marks block separators with custom attributes
- Returns: Modified NSMutableAttributedString

### Stage 4: TypographyApplier
- Applies fonts (system, monospace per preference)
- Applies colors (theme-aware)
- Applies paragraph styles (spacing, alignment, indentation)
- Applies inline formatting (bold, italic, code styles)
- Returns: Styled NSMutableAttributedString

### Stage 5: SyntaxHighlighter
- Finds code block ranges
- Applies syntax coloring
- Returns: Final NSMutableAttributedString

## Future: swift-markdown Integration

### Why Consider it?

1. **Advanced Features Needed**
   - Table rendering with cell formatting
   - Strikethrough variants
   - Task lists with checkboxes
   - Footnotes and references

2. **Custom Processing Required**
   - Link transformations (rewriting URLs)
   - Asset embedding (images in documents)
   - Validation rules (document linting)
   - Metadata extraction

3. **Performance Scaling**
   - Documents > 1MB need streaming
   - Real-time collaborative editing requires incremental parsing

### Architecture Changes Required

```swift
// New abstraction layer
protocol MarkdownParser {
    func parse(_ markdown: String) throws -> Document
}

protocol MarkdownVisitor {
    func visit(_ document: Document) -> NSAttributedString
}

// Built-in implementation (current)
struct BuiltinMarkdownParser: MarkdownParser {
    func parse(_ markdown: String) throws -> Document {
        let attributed = try NSAttributedString(markdown: markdown, baseURL: nil)
        return Document(attributed: attributed)
    }
}

// swift-markdown implementation (future)
struct SwiftMarkdownParser: MarkdownParser {
    func parse(_ markdown: String) throws -> Document {
        import Markdown // would need to add to Package.swift
        let parser = Document.Parser()
        let doc = try parser.parse(markdown)
        return Document(swiftMarkdownDocument: doc)
    }
}

// Renderer
struct NSAttributedStringRenderer: MarkdownVisitor {
    let config: RenderConfig
    
    func visit(_ document: Document) -> NSAttributedString {
        let visitor = NSAttributedStringBuildingVisitor(config: config)
        document.accept(visitor)
        return visitor.result
    }
}
```

### Implementation Strategy

1. **Phase 1**: Parallel implementation
   - Keep built-in parser as default
   - Add feature flag for swift-markdown
   - Run both through same typography pipeline
   - Compare outputs in tests

2. **Phase 2**: Feature parity testing
   - All 181 existing tests must pass with new parser
   - Regression test suite for edge cases
   - Performance benchmarking (should be < 2x slower)

3. **Phase 3**: Gradual migration
   - New documents use swift-markdown by default
   - Old documents still work with built-in
   - Config option to force either parser

4. **Phase 4**: Cleanup
   - Remove built-in parser (if stable)
   - Simplify to single implementation

## Extension Points

### Adding a New Parser

1. Implement `MarkdownParsing` protocol:
```swift
struct MyCustomParser: MarkdownParsing {
    func parse(_ markdown: String) throws -> NSAttributedString {
        // Custom parsing logic
        return NSMutableAttributedString(string: "")
    }
}
```

2. Register in `MarkdownRenderService.init()`:
```swift
init(
    parser: MarkdownParsing = MyCustomParser(),
    // ... other params
) { ... }
```

3. Test with existing test suite (should pass unchanged)

### Adding a New Typography Feature

1. Add custom attribute to `MarkdownRenderAttribute`:
```swift
static let myNewFeature = NSAttributedString.Key("MyNewFeature")
```

2. Update `TypographyApplier` to detect and apply it:
```swift
// In applyTypography()
text.enumerateAttribute(
    MarkdownRenderAttribute.myNewFeature,
    in: fullRange,
    options: []
) { value, range, _ in
    // Apply styling
}
```

3. Update tests to verify the feature

## Testing Strategy

### Unit Tests
- Parser output correctness
- Attribute presence and values
- Edge cases (empty string, special characters, nesting)

### Integration Tests
- Full pipeline output
- Visual regression tests
- Performance benchmarks
- All themes and spacing presets

### Running Tests
```bash
swift test                          # All tests
swift test --filter MarkdownParser  # Parser tests only
swift test --parallel               # Faster execution
swift test --enable-code-coverage   # Coverage report
```

## Performance Targets

| Operation | Target | Current |
|-----------|--------|---------|
| Parse 10KB | < 10ms | ~5-8ms ✓ |
| Parse 100KB | < 50ms | ~40-45ms ✓ |
| Parse 1MB | < 500ms | ~400-450ms ✓ |
| Cache hit | < 1ms | ~0.5ms ✓ |
| Full pipeline | < 100ms | ~50-80ms ✓ |

## See Also

- `MarkdownRenderService.swift` - Orchestrates the full pipeline
- `TypographyApplier.swift` - Applies styling
- `BlockSeparatorInjector.swift` - Handles block boundaries
- `SyntaxHighlighter.swift` - Code syntax coloring
- `PARSER_EVALUATION.md` - Library comparison

---

*Last Updated: 2026-02-26*
