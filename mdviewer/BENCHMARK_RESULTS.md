# Performance Benchmark Results

## Test Environment
- **Platform**: macOS 14.0 (arm64e)
- **Swift**: 6.0
- **Build**: Debug (profiling uses debug for symbol visibility)

## Current Performance Metrics

### Renderer Performance
```
Test: testRenderBudgetsForLargeDocument
Result: PASSED (0.090s)
```

### Syntax Highlighter Performance
| Lines | Average Time | Relative Std Dev |
|-------|-------------|------------------|
| 200   | 3ms         | 1.1%            |
| 400   | 8ms         | 11.4%           |
| 50    | 1ms         | 13.0%           |

### View Builder Performance
| Component | Average Time |
|-----------|-------------|
| InspectorSidebar | 0.012ms |
| MetadataRow | 0.004ms |
| LazyVStack | 0.002ms |
| RegularVStack | 0.002ms |

### Memory Usage
- **Inspector Sidebar**: ~21MB peak physical
- **Zero disk writes** during rendering
- **Zero physical memory growth** during repeated operations

## Optimizations Applied

### 1. BlockSeparatorInjector
- **NSString caching**: Single conversion vs repeated
- **Pre-allocated arrays**: `reserveCapacity()` for known sizes
- **Reused attributed strings**: Single instances for common insertions
- **Set-based duplicate detection**: O(1) vs O(n) linear scan
- **Tab string caching**: Avoids repeated `String(repeating:)`

**Expected improvement**: 20-30% faster

### 2. TypographyApplier
- **Combined passes**: Merged presentation intent + kerning (3→2 passes)
- **NSString caching**: Multiple locations
- **Array pre-allocation**: `reserveCapacity()` throughout
- **Simplified ligature logic**: Early exit when disabled
- **Removed filter().last pattern**: Manual loop for efficiency

**Expected improvement**: 15-25% faster

### 3. Signpost Instrumentation
Added detailed OSLog signposts for:
- `MarkdownRender` (overall)
- `InjectSeparators`
- `ApplyTypography`
- `ApplyCodeStyling`
- `RenderMermaid`

## Comparison Method

To compare before/after:

```bash
# 1. Save current optimizations
git add .
git commit -m "perf: optimizations applied"

# 2. Checkout original code
git stash
just build
swift test --filter RendererPerformanceTests

# 3. Restore optimizations
git stash pop
just build
swift test --filter RendererPerformanceTests
```

## Profiling with Instruments

Run the profile script:
```bash
./mdviewer/profile.sh
```

Then in Instruments:
1. Select "Points of Interest" template
2. Target: `mdviewer` process
3. Open test files from `/tmp/mdviewer-profile/`
4. Record and analyze signpost intervals

## Target Metrics

| Document Size | Target Render Time | Status |
|--------------|-------------------|--------|
| < 10KB | < 16ms (60fps) | ✓ Under |
| < 100KB | < 50ms | ✓ Under |
| < 1MB | < 200ms | ✓ Under |

Current large document render: **90ms** (includes full pipeline)

## Red Flags to Watch

If profiling shows these, further optimization needed:
- `InjectSeparators` > 20ms for medium document
- `NSString` bridging > 10% of total time
- > 3 `enumerateAttribute` calls per render phase
- Array reallocations in hot loops

## Next Steps

1. Run Instruments profiling locally
2. Export trace as `.trace` or CSV
3. Share results for analysis
4. Further optimize based on findings
