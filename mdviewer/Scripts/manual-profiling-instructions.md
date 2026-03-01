# Manual Profiling Instructions

## Option 1: Profile with Instruments (GUI Required)

Since Instruments is a macOS GUI app, it must be launched manually:

### Step 1: Build Release Version
```bash
cd /Users/murat/code/mdviewer/mdviewer
swift build -c release
```

### Step 2: Launch Instruments
```bash
# Open Instruments with the built app
open -a Instruments .build/release/mdviewer
```

### Step 3: Select Template
In Instruments, choose one of these templates:
- **Core Animation** - Best for UI frame rate analysis
- **os_signpost** - Best for viewing custom signpost intervals
- **Time Profiler** - Best for CPU usage analysis
- **Allocations** - Best for memory tracking

### Step 4: Configure Signposts (if using os_signpost template)
1. Select the app target
2. Click "Choose target options"
3. Under "Signpost Categories", ensure these are enabled:
   - `UIPerformance`
   - `Toolbar`
   - `DocumentRender`
   - `MarkdownRenderPipeline`

### Step 5: Record & Interact
1. Press **Cmd+R** to start recording
2. Interact with the app:
   - Click sidebar toggle button 10+ times
   - Switch between Rendered/Raw modes
   - Open different markdown documents
   - Resize the window
3. Press **Cmd+R** to stop recording

### Step 6: Analyze Results

#### Core Animation Template
- Look for **Frame drops** (yellow/red bars)
- Target: Consistent 60fps (16.67ms frames)
- Check if sidebar toggle causes dropped frames

#### os_signpost Template
Signpost intervals to measure:
| Interval | Expected | Action |
|----------|----------|--------|
| `InspectorSidebarRender` | <1ms | Sidebar body evaluation |
| `AsyncMarkdownRender` | <100ms | Markdown parsing pipeline |
| `TextViewUIUpdate` | <16ms | Attributed string application |
| `TextViewCreation` | <50ms | Initial text view setup |

Signpost events to verify:
- `InspectorToggleTapped` - Fires on button click
- `MarkdownRenderCompleted` - Fires when render done

#### Time Profiler Template
- Look for `ContentView.body` evaluation time
- Check `InspectorSidebar.body` evaluation
- Verify idle CPU drops to near zero

### Step 7: Save Trace
```bash
# Save to ProfileOutput directory
mkdir -p ProfileOutput
# In Instruments: File > Save (Cmd+S) > Navigate to ProfileOutput/
```

---

## Option 2: Set XCTest Baselines in Xcode

### Step 1: Open Project in Xcode
```bash
cd /Users/murat/code/mdviewer/mdviewer
open Package.swift
```

### Step 2: Navigate to Performance Tests
1. In Xcode navigator, expand `mdviewerTests`
2. Select `ViewBuilderPerformanceTests.swift`
3. Show Test Navigator (Cmd+6)

### Step 3: Run Performance Tests with Baseline Setting
1. Click the diamond icon next to a test to run it
2. After test completes, click the test result
3. Click **"Set Baseline"** button
4. Xcode will record the average measurement as the baseline

### Step 4: Set Baselines for All Tests
Run each test and set baselines:

```bash
# Run all performance tests
swift test --filter ViewBuilderPerformanceTests
```

Then in Xcode Test Navigator, set baselines for:
- ✅ `testInspectorSidebarBodyEvaluation` (~2μs)
- ✅ `testMetadataRowBodyEvaluation` (~8μs)
- ✅ `testEmptyMetadataStateBodyEvaluation` (~5μs)
- ✅ `testLazyVStackContainerPerformance` (~2μs)
- ✅ `testRegularVStackContainerPerformance` (~2μs)
- ✅ `testIsolatedSubviewsPerformance` (~2μs)
- ✅ `testComplexTypedFrontmatter` (~9μs)
- ✅ `testInspectorSidebarMemoryAllocations` (0KB physical)
- ✅ `testMetadataRowMemoryAllocations` (0KB physical)
- ✅ `testLazyVStackMemoryVsVStack` (0KB physical)
- ✅ `testRegularVStackMemoryVsLazy` (0KB physical)
- ✅ `testInspectorSidebarCPUTime` (~560k cycles)
- ✅ `testInspectorSidebarStorageImpact` (0KB writes)

### Step 5: Configure Regression Thresholds
In Xcode Test Navigator:
1. Select a test with baseline
2. Click **"Edit"** next to the baseline
3. Set:
   - **Max Regression**: 10%
   - **Max Standard Deviation**: 10%

---

## Option 3: Command-Line Baseline Capture

Since GUI isn't available, capture baselines from test output:

```bash
# Run performance tests and capture output
swift test --filter ViewBuilderPerformanceTests 2>&1 | tee ProfileOutput/baseline_capture_$(date +%Y%m%d_%H%M%S).txt
```

### Parse Results
The output shows measured values like:
```
measured [Clock Monotonic Time, s] average: 0.000002
measured [Memory Physical, kB] average: 0.000
measured [CPU Cycles, kC] average: 560.136
```

These values are documented in `Tests/PerformanceBaselines.md`.

---

## Expected Performance Characteristics

### After Optimizations Applied
- **Sidebar toggle**: No dropped frames (60fps maintained)
- **InspectorSidebar body**: ~2μs evaluation time
- **Memory during render**: 0KB physical growth (static formatters)
- **Idle CPU**: Near 0% (no 30fps TimelineView polling)
- **Markdown render**: <100ms for typical documents

### Key Improvements from This PR
1. Removed `TimelineView` 30fps polling from `LiquidBackground`
2. Replaced `List` with `LazyVStack` in sidebar
3. Removed hover state from `InspectorMetadataEntryView`
4. Static formatters instead of per-instance creation
5. Isolated view components prevent parent re-renders

---

## Troubleshooting

### Instruments Can't Find App
```bash
# Verify app exists
ls -la .build/release/mdviewer

# Rebuild if needed
swift build -c release
```

### Signposts Not Appearing
1. Ensure app is built with Release configuration
2. Check that `OSLog` import is present
3. Verify signpost calls aren't stripped in release

### Tests Fail with High Variance
```bash
# Run multiple times to establish stable baseline
for i in {1..5}; do
  swift test --filter ViewBuilderPerformanceTests
done
```

---

## CI Integration

For automated regression detection in CI:

```yaml
# .github/workflows/performance.yml (example)
name: Performance Tests
on: [push]
jobs:
  performance:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Performance Tests
        run: swift test --filter PerformanceTests
```

Note: CI runners may have variable performance. Consider:
- Running on dedicated hardware
- Using relative comparisons (main branch vs PR)
- Allowing larger variance thresholds (20-30%)
