# Markdown Parser Comparison

## Current Implementation

### Architecture
```
Markdown → EnhancedMarkdownParser → NSAttributedString → BlockSeparatorInjector → TypographyApplier → SyntaxHighlighter → Rendered Output
```

**Parser**: `NSAttributedString(markdown:)` - Native Foundation parser

**Pros:**
- Zero dependencies for parsing
- Native `PresentationIntent` attributes for semantic structure
- Optimized by Apple, integrated with TextKit
- Automatic handling of GFM (GitHub Flavored Markdown)
- Supports tables, task lists, strikethrough

**Cons:**
- Limited customization of parsing
- Hard line breaks require pre-processing workaround
- Table rendering requires post-processing
- No access to AST/syntax tree

---

## Option 1: swift-markdown (Apple)

**Repository**: https://github.com/swiftlang/swift-markdown

### Architecture
```
Markdown → swift-markdown AST → Custom NSAttributedString Generator → BlockSeparatorInjector → TypographyApplier → SyntaxHighlighter → Rendered Output
```

**Pros:**
- Official Apple package (well-maintained)
- Full access to AST/syntax tree
- More control over parsing
- Extensible document model
- Better for complex transformations

**Cons:**
- **MAJOR**: Requires rebuilding entire rendering pipeline
- No native `PresentationIntent` attributes (would need custom generation)
- Would lose current `TypographyApplier` optimizations
- Additional dependency (~2MB)
- Significant refactoring effort (2-3 weeks)
- No built-in NSAttributedString output

### Migration Impact
- Rewrite `EnhancedMarkdownParser` completely
- Rebuild `BlockSeparatorInjector` to work with AST
- Rewrite `TypographyApplier` to traverse AST instead of attributes
- Lose all current attribute-based optimizations
- Risk of introducing regressions

**Estimated Effort**: 40-60 hours

---

## Option 2: Parsley

**Repository**: https://github.com/loopwerk/Parsley

### Architecture
```
Markdown → Parsley → NSAttributedString → TypographyApplier → SyntaxHighlighter → Rendered Output
```

**Pros:**
- Purpose-built for NSAttributedString
- MIT license
- Could replace `EnhancedMarkdownParser` only
- Maintains similar output format

**Cons:**
- Third-party dependency (maintenance risk)
- Unknown performance characteristics
- May not support all GFM features
- Would still need custom styling pipeline
- Unknown if it provides `PresentationIntent` attributes

### Migration Impact
- Replace `EnhancedMarkdownParser`
- May need to keep `BlockSeparatorInjector`
- Uncertainty about attribute compatibility

**Estimated Effort**: 10-20 hours (plus testing)

---

## Recommendation: STAY WITH CURRENT APPROACH

### Rationale

1. **Performance**: Current native parser is highly optimized by Apple
2. **Stability**: Zero parsing-related bugs in 486 tests
3. **Maintenance**: No parser dependency to manage
4. **Effort**: Migration would be high-risk with minimal gain

### When to Consider Migration

Consider swift-markdown only if:
- Need real-time collaborative editing (operational transforms)
- Need to support non-standard markdown extensions
- Need to export to multiple formats (PDF, DOCX, etc.)
- Current parser has unresolvable performance issues

### Current Optimization Path

Better to optimize the current pipeline:

1. ✓ Already done: NSString caching in `BlockSeparatorInjector`
2. ✓ Already done: Combined passes in `TypographyApplier`
3. ✓ Already done: Signpost profiling instrumentation

Additional possible optimizations:
- Cache parsed AST for large documents
- Lazy syntax highlighting (only visible code blocks)
- Background thread parsing for files > 100KB

---

## Performance Comparison (Estimated)

| Parser | Small Doc | Medium Doc | Large Doc | Memory |
|--------|-----------|------------|-----------|--------|
| NSAttributedString (Current) | 2ms | 10ms | 90ms | Low |
| swift-markdown + Custom | 5ms | 15ms | 80ms | Medium |
| Parsley | 3ms | 12ms | Unknown | Unknown |

*Note: swift-markdown could be faster for large docs due to AST caching, but would require significant implementation effort.*

---

## Conclusion

**DO NOT MIGRATE** at this time.

The current approach using `NSAttributedString(markdown:)` is:
- Well-optimized
- Battle-tested (486 tests passing)
- Zero-dependency for parsing
- Performant enough for the use case

**Revisit decision if**:
- Performance profiling shows parser as bottleneck (currently not)
- Need features impossible with native parser
- Apple deprecates NSAttributedString markdown parsing

---

## Alternative: Hybrid Approach (Future)

If needed later, could use swift-markdown only for specific features:

```swift
// Keep current parser for rendering
let attributedString = try parser.parse(markdown)

// Use swift-markdown only for outline/navigation
let document = Document(parsing: markdown)
let headings = document.headings // For outline view
```

This would add swift-markdown as a dependency only for navigation features without disrupting the rendering pipeline.
