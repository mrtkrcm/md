# Performance Profiling Guide

## Running the Profile

```bash
# Option 1: Use the profile script
./mdviewer/profile.sh

# Option 2: Manual profiling
just build
open -a Instruments .build/debug/mdviewer
```

## Instruments Setup

1. **Select Template**: Choose "Points of Interest" (recommended) or "Time Profiler"
2. **Target Process**: Select `mdviewer` 
3. **Record**: Press Cmd+R to start recording

## Test Documents

After running `profile.sh`, test documents are created in `/tmp/mdviewer-profile/`:

| File | Size | Purpose |
|------|------|---------|
| `small.md` | ~500 bytes | Baseline overhead |
| `medium.md` | ~2KB | Typical document |
| `large.md` | ~50KB | Stress test |

## Signpost Categories

The app emits these signpost intervals:

### `MarkdownRender` (Overall)
- **Begin**: When render request starts
- **End**: When render completes
- **Metadata**: Character count

### Pipeline Phases
1. **`InjectSeparators`** - BlockSeparatorInjector
2. **`ApplyTypography`** - TypographyApplier  
3. **`ApplyCodeStyling`** - SyntaxHighlighter
4. **`RenderMermaid`** - MermaidDiagramRenderer

## Interpreting Results

### Points of Interest Instrument

Look for the signpost intervals in the timeline:

```
┌─────────────────────────────────────────────────────────┐
│  MarkdownRender (50ms)                                  │
│  ├─ InjectSeparators (5ms)                              │
│  ├─ ApplyTypography (30ms)                              │
│  ├─ ApplyCodeStyling (10ms)                             │
│  └─ RenderMermaid (5ms)                                 │
└─────────────────────────────────────────────────────────┘
```

### Expected Improvements

Comparing before/after the optimizations:

| Phase | Before | After | Improvement |
|-------|--------|-------|-------------|
| `InjectSeparators` | ~10ms | ~7ms | 30% faster |
| `ApplyTypography` | ~40ms | ~30ms | 25% faster |
| **Total** | ~60ms | ~45ms | **25% faster** |

*(Times approximate for large document)*

### Time Profiler Analysis

1. **Filter by Library**: `mdviewer`
2. **Sort by**: Self Time (descending)
3. **Key Functions to Watch**:
   - `BlockSeparatorInjector.injectSeparators`
   - `TypographyApplier.applyTypography`
   - `NSString bridging` (should be reduced)
   - `enumerateAttribute` (fewer calls now)

### Red Flags

If you see these, further optimization is needed:

- `InjectSeparators` taking >20ms for medium document
- `NSString` bridging in hot loops
- Multiple `enumerateAttribute` calls per render
- High allocation counts in `BlockRun` or `ListRun`

## Comparison Method

To compare before/after:

1. **Checkout original code**:
   ```bash
   git stash
   just build
   # Profile and save trace
   ```

2. **Apply optimizations**:
   ```bash
   git stash pop
   just build
   # Profile and compare
   ```

3. **Export Results**:
   - File > Export > CSV
   - Compare times for each signpost

## Console Logging

For quick checks without Instruments, check Console.app:

```
Subsystem: mdviewer
Category: render-signpost
```

Or use log command:
```bash
log stream --predicate 'subsystem == "mdviewer"' --info
```

## Memory Profiling

Add Allocations instrument to track:

- `BlockRun` allocations (should be minimal)
- `NSAttributedString` temporary objects
- `NSString` conversions (should be reduced)

## CPU Profiling

Use Time Profiler with these settings:
- **Sampling rate**: 1ms
- **Show system libraries**: Off
- **Invert call tree**: Off
- **Top functions**: On

Look for:
- Swift string bridging overhead
- Attribute enumeration loops
- Array reallocations

## Document Size Guidelines

| Size | Render Time Target |
|------|-------------------|
| < 10KB | < 16ms (60fps) |
| < 100KB | < 50ms |
| < 1MB | < 200ms |

If times exceed these, profile to find bottlenecks.
