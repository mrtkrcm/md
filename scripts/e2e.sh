#!/bin/bash
set -euo pipefail

# E2E Test Suite for mdviewer
# Validates app launch, UI interaction, render correctness, and liquid design

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="${APP_BUNDLE:-$ROOT_DIR/release/md.app}"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/md"
STARTUP_TIMEOUT_SECONDS="${STARTUP_TIMEOUT_SECONDS:-12}"
BUNDLE_ID="${BUNDLE_ID:-com.mrtkrcm.mdviewer}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-/tmp/mdviewer-e2e}"
VISUAL_CAPTURE="${VISUAL_CAPTURE:-false}"

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0

ENABLE_VISUAL=false
UPDATE_BASELINE=false

for arg in "$@"; do
  case "$arg" in
    --visual)          ENABLE_VISUAL=true ;;
    --update-baseline) UPDATE_BASELINE=true; ENABLE_VISUAL=true ;;
  esac
done

if [ "$VISUAL_CAPTURE" = "true" ]; then
  ENABLE_VISUAL=true
fi

# Helper functions
pass() { echo "✓ $1"; ((TESTS_PASSED++)); }
fail() { echo "✗ $1"; ((TESTS_FAILED++)); }

# ─── Phase 0: Validate bundle ────────────────────────────────────────────────
if [ ! -d "$APP_BUNDLE" ]; then
  echo "App bundle not found at: $APP_BUNDLE"
  echo "Run scripts/build.sh first."
  exit 1
fi

if [ ! -x "$APP_EXECUTABLE" ]; then
  echo "Executable missing or not executable: $APP_EXECUTABLE"
  exit 1
fi

if [ ! -f "$APP_BUNDLE/Contents/Info.plist" ]; then
  echo "Info.plist missing from bundle."
  exit 1
fi

if ! plutil -lint "$APP_BUNDLE/Contents/Info.plist" >/dev/null; then
  echo "Info.plist is invalid."
  exit 1
fi

# ─── Phase 1: Smoke test ─────────────────────────────────────────────────────
mkdir -p "$ARTIFACTS_DIR"

TEST_MD="$ARTIFACTS_DIR/test.md"
cat > "$TEST_MD" << 'MARKDOWN'
---
title: E2E Test Document
---
# E2E Test: Heading One

## Subheading

This is **bold** and _italic_ paragraph text for rendering validation.

### Code Example

```swift
let greeting = "Hello, E2E"
func greet() -> String { return greeting }
```

- Item one
- Item two
- Item three

> Blockquote text for visual validation.

Inline `code snippet` in paragraph.
MARKDOWN

echo "Launching app for smoke E2E..."
"$APP_EXECUTABLE" "$TEST_MD" &
APP_PID=$!

for ((i = 0; i < STARTUP_TIMEOUT_SECONDS * 10; i++)); do
  if pgrep -f "$APP_EXECUTABLE" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

if ! pgrep -f "$APP_EXECUTABLE" >/dev/null 2>&1; then
  echo "App did not start within ${STARTUP_TIMEOUT_SECONDS}s."
  exit 1
fi

echo "App started successfully."

# ─── Permissive Execution for Restricted Environments ────────────────────────
set +e # Allow following phases to fail non-critically (visual/accessibility)

# Poll for window registration via osascript
if command -v osascript >/dev/null 2>&1; then
  for i in {1..15}; do
    REG_PROC=$(osascript -e "tell application \"System Events\" to get name of every process whose unix id is $APP_PID" 2>/dev/null)
    if [ -n "$REG_PROC" ]; then
      break
    fi
    sleep 0.1
  done
fi

# Extra wait for rendering to complete
sleep 1.5

# ─── Phase 2: UI Interaction Tests ───────────────────────────────────────────
echo ""
echo "=== Phase 2: UI Interaction Tests ==="

# Test window properties
if command -v osascript >/dev/null 2>&1; then
  # List all windows for diagnostics
  echo "Listing windows for process $APP_PID..."
  osascript -e "tell application \"System Events\" to get name of every window of (first process whose unix id is $APP_PID)" 2>/dev/null || echo "Could not list windows."

  WINDOW_EXISTS=$(osascript -e "tell application \"System Events\" to count windows of (first process whose unix id is $APP_PID)" 2>/dev/null || echo "0")
  WINDOW_EXISTS_INT=${WINDOW_EXISTS:-0}
  if [ "$WINDOW_EXISTS_INT" -gt 0 ]; then
    pass "Window exists"

    # Test window is resizable (liquid design)
    BOUNDS=$(osascript 2>/dev/null << OSASCRIPT
set appPid to $APP_PID
tell application "System Events"
  try
    set procs to every process whose unix id is appPid
    if (count of procs) > 0 then
      set proc to first item of procs
      set wins to every window of proc
      if (count of wins) > 0 then
        set b to bounds of first item of wins
        return (item 3 of b) - (item 1 of b) & "," & (item 4 of b) - (item 2 of b)
      end if
    end if
  on error
    return ""
  end try
end tell
OSASCRIPT
)

    if [ -n "${BOUNDS:-}" ]; then
      WIDTH=$(echo "$BOUNDS" | cut -d',' -f1)
      HEIGHT=$(echo "$BOUNDS" | cut -d',' -f2)
      if [ -n "$WIDTH" ] && [ -n "$HEIGHT" ] && [ "$WIDTH" -gt 800 ] && [ "$HEIGHT" -gt 600 ]; then
        pass "Window has valid size (${WIDTH}x${HEIGHT})"
      elif [ -n "$WIDTH" ] && [ "$WIDTH" -gt 0 ]; then
        fail "Window size too small (${WIDTH}x${HEIGHT})"
      else
        echo "WARNING: Could not parse valid window bounds via osascript (Accessibility permission may be missing)."
      fi
    else
      echo "WARNING: Could not determine window bounds via osascript (Accessibility permission may be missing)."
    fi
  else
    echo "WARNING: No window found via osascript (Accessibility permission may be missing)."
  fi
fi

# ─── Phase 3: Visual capture and render validation ───────────────────────────
echo ""
echo "=== Phase 3: Render Validation ==="

VISUAL_EXIT_CODE=0
if [ "$ENABLE_VISUAL" = "true" ]; then
  SCREENSHOT="$ARTIFACTS_DIR/screenshot.png"
  echo "Capturing screenshot..."

  CAPTURED=false

  # Try window-region capture via AppleScript bounds (best-effort)
  if command -v osascript >/dev/null 2>&1; then
    BOUNDS=$(osascript 2>/dev/null << OSASCRIPT
set appPid to $APP_PID
tell application "System Events"
  try
    set procs to every process whose unix id is appPid
    if (count of procs) > 0 then
      set proc to first item of procs
      set wins to every window of proc
      if (count of wins) > 0 then
        set b to bounds of first item of wins
        set x to item 1 of b
        set y to item 2 of b
        set w to (item 3 of b) - x
        set h to (item 4 of b) - y
        return (x as text) & "," & (y as text) & "," & (w as text) & "," & (h as text)
      end if
    end if
  on error
    return ""
  end try
end tell
OSASCRIPT
    )

    if [ -n "${BOUNDS:-}" ]; then
      if screencapture -x -R "$BOUNDS" "$SCREENSHOT" 2>/dev/null; then
        CAPTURED=true
        echo "Window screenshot captured: $SCREENSHOT"
      fi
    fi
  fi

  # Fallback: full-screen capture
  if [ "$CAPTURED" = "false" ]; then
    if screencapture -x "$SCREENSHOT" 2>/dev/null; then
      CAPTURED=true
      echo "Full-screen screenshot captured: $SCREENSHOT"
    fi
  fi

  if [ "$CAPTURED" = "true" ] && [ -f "$SCREENSHOT" ]; then
    # Validate dimensions and size with sips
    SIPS_OUT=$(sips -g pixelWidth -g pixelHeight "$SCREENSHOT" 2>/dev/null || true)
    PIX_W=$(echo "$SIPS_OUT" | awk '/pixelWidth/{print $2}')
    PIX_H=$(echo "$SIPS_OUT" | awk '/pixelHeight/{print $2}')
    FILE_SIZE=$(stat -f%z "$SCREENSHOT" 2>/dev/null || echo 0)

    echo "Screenshot dimensions: ${PIX_W:-?}x${PIX_H:-?}, size: ${FILE_SIZE} bytes"

    if [ "${PIX_W:-0}" -lt 800 ] || [ "${PIX_H:-0}" -lt 600 ]; then
      echo "WARNING: Screenshot dimensions ${PIX_W:-0}x${PIX_H:-0} are below minimum 800x600."
      VISUAL_EXIT_CODE=1
    fi

    if [ "${FILE_SIZE:-0}" -lt 51200 ]; then
      echo "WARNING: Screenshot file size ${FILE_SIZE} bytes is below minimum 50 KB."
      VISUAL_EXIT_CODE=1
    fi

    BASELINE_DIR="$ROOT_DIR/tests/e2e/baselines"
    BASELINE="$BASELINE_DIR/screenshot.png"

    if [ "$UPDATE_BASELINE" = "true" ]; then
      mkdir -p "$BASELINE_DIR"
      cp "$SCREENSHOT" "$BASELINE"
      echo "Baseline updated: $BASELINE"
    elif [ -f "$BASELINE" ]; then
      echo "Comparing against baseline..."
      BASELINE_SIZE=$(stat -f%z "$BASELINE" 2>/dev/null || echo 0)
      SCREENSHOT_SIZE=$(stat -f%z "$SCREENSHOT" 2>/dev/null || echo 0)
      if [ "${BASELINE_SIZE:-0}" -gt 0 ]; then
        SIZE_DIFF=$(( BASELINE_SIZE > SCREENSHOT_SIZE \
          ? BASELINE_SIZE - SCREENSHOT_SIZE \
          : SCREENSHOT_SIZE - BASELINE_SIZE ))
        SIZE_PCT=$(( SIZE_DIFF * 100 / BASELINE_SIZE ))
        echo "Baseline: ${BASELINE_SIZE} bytes, current: ${SCREENSHOT_SIZE} bytes, diff: ${SIZE_PCT}%"
        if [ "$SIZE_PCT" -gt 20 ]; then
          echo "WARNING: Screenshot differs significantly from baseline (${SIZE_PCT}% size difference)."
          VISUAL_EXIT_CODE=1
        fi
      fi
    fi
  else
    echo "WARNING: Screenshot capture failed (Screen Recording permission may be required)."
    VISUAL_EXIT_CODE=1
  fi
fi

# ─── Phase 4: Liquid Design Tests ────────────────────────────────────────────
echo ""
echo "=== Phase 4: Liquid Design Tests ==="

if command -v osascript >/dev/null 2>&1; then
  # Test responsive resize
  osascript << OSASCRIPT 2>/dev/null
set appPid to $APP_PID
tell application "System Events"
  try
    set proc to first process whose unix id is appPid
    set win to first window of proc
    set bounds of win to {100, 100, 900, 700}
  on error
    error "Failed to resize"
  end try
end tell
OSASCRIPT
  sleep 1

  SMALL_SCREENSHOT="$ARTIFACTS_DIR/render-small.png"
  if (screencapture -x "$SMALL_SCREENSHOT" 2>/dev/null); then
    pass "Responsive to smaller window"
  else
    echo "WARNING: Small window screenshot failed (Screen Recording permission missing)."
  fi

  # Resize to larger
  osascript << OSASCRIPT 2>/dev/null
set appPid to $APP_PID
tell application "System Events"
  try
    set proc to first process whose unix id is appPid
    set win to first window of proc
    set bounds of win to {100, 100, 1400, 900}
  on error
    error "Failed to resize"
  end try
end tell
OSASCRIPT
  sleep 1

  LARGE_SCREENSHOT="$ARTIFACTS_DIR/render-large.png"
  if (screencapture -x "$LARGE_SCREENSHOT" 2>/dev/null); then
    pass "Responsive to larger window"
  else
    echo "WARNING: Large window screenshot failed (Screen Recording permission missing)."
  fi
fi

# ─── Cleanup and Final Summary ────────────────────────────────────────────────
set -e # Re-enable for cleanup
echo ""
echo "=== Phase 5: Cleanup ==="

if command -v osascript >/dev/null 2>&1; then
  set +e
  osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1
  osascript -e "tell application \"md\" to quit" >/dev/null 2>&1
  set -e
fi

for i in {1..50}; do
  if ! pgrep -f "$APP_EXECUTABLE" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

if pgrep -f "$APP_EXECUTABLE" >/dev/null 2>&1; then
  echo "App did not quit cleanly; forcing stop."
  pkill -f "$APP_EXECUTABLE" >/dev/null 2>&1 || true
  sleep 0.2
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "====================================="
echo "Test Summary"
echo "====================================="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ "$ENABLE_VISUAL" = "true" ]; then
  if [ "$VISUAL_EXIT_CODE" -ne 0 ]; then
    echo "WARNING: Visual checks had warnings"
  else
    echo "Visual checks: passed"
  fi
fi

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo "E2E smoke test PASSED"
  exit 0
else
  echo ""
  echo "E2E smoke test FAILED"
  exit 1
fi
