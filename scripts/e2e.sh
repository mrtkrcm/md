#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="${APP_BUNDLE:-$ROOT_DIR/release/md.app}"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/md"
STARTUP_TIMEOUT_SECONDS="${STARTUP_TIMEOUT_SECONDS:-12}"
BUNDLE_ID="${BUNDLE_ID:-com.example.md}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-/tmp/mdviewer-e2e}"
VISUAL_CAPTURE="${VISUAL_CAPTURE:-false}"

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

# Poll for window registration via osascript (graceful fallback if Accessibility not granted)
if command -v osascript >/dev/null 2>&1; then
  for i in {1..15}; do
    if osascript -e "tell application \"System Events\" to get name of every process whose unix id is $APP_PID" >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
fi

# Extra wait for rendering to complete
sleep 1.5

# ─── Phase 2: Visual capture (opt-in) ────────────────────────────────────────
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
end tell
OSASCRIPT
    ) || true

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

# ─── Quit app ─────────────────────────────────────────────────────────────────
if command -v osascript >/dev/null 2>&1; then
  osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
  osascript -e "tell application \"md\" to quit" >/dev/null 2>&1 || true
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

if pgrep -f "$APP_EXECUTABLE" >/dev/null 2>&1; then
  echo "App process is still running after forced stop."
  exit 1
fi

echo "E2E smoke test passed."

if [ "$ENABLE_VISUAL" = "true" ]; then
  if [ "$VISUAL_EXIT_CODE" -ne 0 ]; then
    echo "WARNING: Visual checks completed with warnings (see above)."
  else
    echo "Visual checks passed."
  fi
fi
