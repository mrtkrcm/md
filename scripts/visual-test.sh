#!/usr/bin/env bash
# visual-test.sh — single-launch, single-query visual regression suite for md.app.
#
# Phase 1: Capture — launches the app ONCE in the background, switches between
#           fixture files without relaunching (no focus stealing per fixture),
#           screenshots each window with screencapture -l <wid> -x (no shutter sound).
#
# Phase 2: Analyse — builds ONE Gemini prompt that references ALL screenshots via
#           @path, attaching per-fixture criteria inline. Gemini returns a JSON array;
#           Python extracts it from the noisy CLI output. One model round-trip total.
#
# Usage:
#   ./scripts/visual-test.sh               # all registered fixtures
#   ./scripts/visual-test.sh hr_heading    # single fixture by name
#   GEMINI_MODEL=gemini-2.5-pro ./scripts/visual-test.sh
#
# Requirements:
#   - md.app installed at /Applications/md.app  (just install)
#   - gemini CLI on PATH and authenticated
#
# Exit codes: 0 = all PASS, 1 = any FAIL

set -euo pipefail

GEMINI_MODEL="${GEMINI_MODEL:-gemini-3-flash-preview}"
GEMINI_TIMEOUT="${GEMINI_TIMEOUT:-180}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$PROJECT_ROOT/Tests/VisualFixtures"
SCREENSHOTS_DIR="$FIXTURES_DIR/screenshots"
INITIAL_WAIT="${INITIAL_WAIT:-4}"    # seconds for first render after app launch
SWITCH_WAIT="${SWITCH_WAIT:-3}"      # seconds after switching to a new file
WINDOW_POLL_SECS="${WINDOW_POLL_SECS:-6}"   # max seconds to poll for window ID

mkdir -p "$SCREENSHOTS_DIR"

log()  { printf '\033[0;34m▶ %s\033[0m\n' "$*" >&2; }
ok()   { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
fail() { printf '\033[0;31m✗ %s\033[0m\n' "$*"; }
warn() { printf '\033[0;33m⚠ %s\033[0m\n' "$*" >&2; }
die()  { fail "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Fixture registry — "name|file|criteria" entries
# ---------------------------------------------------------------------------
declare -a FIXTURES=(
"hr_heading|hr_heading.md|
  Horizontal rules (thin hairlines) must have clear whitespace above and below.
  Every heading that follows a horizontal rule must be LEFT-aligned, not centered.
  Hairlines must not overlap or overdraw any heading or paragraph text."

"typography_baseline|typography_baseline.md|
  All headings (H1–H3) must be left-aligned with a clear size hierarchy.
  List items must show bullet or number markers at the left edge, with text indented.
  Inline code spans must be visually distinct (different background or monospace font).
  Paragraph spacing must be consistent and readable throughout."

"tables|tables.md|
  All table borders (outer frame + internal cell dividers) must be fully visible.
  IMPORTANT: text truncated with '...' in cells is CORRECT and INTENTIONAL — do NOT penalise it.
  Header row must be visually distinct from data rows (bold colored text, lighter background).
  Cells that contain backtick inline code show a subtle pill/background highlight — this is CORRECT styling.
  Content below the scroll fold is out of scope — only judge what is visible."

"code_blocks|code_blocks.md|
  Fenced code blocks must have a distinct background separating them from body text.
  Swift block must show syntax highlighting (keywords, types, strings in distinct colors).
  Line numbers must be neutral grey, not inherit keyword pink/red from the code.
  Inline code spans must have a visible background pill/highlight."

"mermaid|mermaid.md|
  The mermaid fenced block must be replaced by a rendered diagram image, not raw text.
  Flowchart nodes (Parser, TypographyApplier, SyntaxHighlighter, Output) must be fully
  visible and connected by arrows left-to-right.
  No nodes may be clipped at any edge of the diagram container."
)

# ---------------------------------------------------------------------------
# Phase 1: Capture — single app launch, switch files without relaunching
# ---------------------------------------------------------------------------

# Return the CGWindowID of the frontmost (or background) "Markdown Viewer" window.
get_window_id() {
    /usr/bin/swift - 2>/dev/null <<'SWIFT'
import Cocoa
let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
if let wl = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] {
    for w in wl {
        if (w[kCGWindowOwnerName as String] as? String) == "Markdown Viewer",
           let num = w[kCGWindowNumber as String] as? Int {
            Swift.print(num); exit(0)
        }
    }
}
exit(1)
SWIFT
}

# Poll for a valid window ID for up to WINDOW_POLL_SECS seconds.
poll_window_id() {
    local deadline=$(( SECONDS + WINDOW_POLL_SECS ))
    local wid=""
    while [[ $SECONDS -lt $deadline ]]; do
        wid=$(get_window_id 2>/dev/null) || true
        if [[ -n "$wid" && "$wid" =~ ^[0-9]+$ ]]; then
            echo "$wid"; return 0
        fi
        sleep 0.5
    done
    return 1
}

capture_all() {
    # Kill any running instance first, then launch the first fixture in background.
    osascript -e 'tell application "md" to quit' 2>/dev/null || true
    sleep 0.8

    log "Launching md.app in background with first fixture…"
    open -g -a /Applications/md.app "${RUN_FILES[0]}"
    # Ensure it stays in background even if the app calls makeKeyAndOrderFront.
    sleep 0.5
    osascript -e 'tell application "System Events" to set frontmost of process "Markdown Viewer" to false' 2>/dev/null || true
    sleep "$INITIAL_WAIT"

    for i in "${!RUN_NAMES[@]}"; do
        local name="${RUN_NAMES[$i]}"
        local fixture_file="${RUN_FILES[$i]}"
        local out="$SCREENSHOTS_DIR/${name}.png"

        if [[ $i -gt 0 ]]; then
            # Switch to the next fixture file without relaunching the app.
            open -g -a /Applications/md.app "$fixture_file"
            osascript -e 'tell application "System Events" to set frontmost of process "Markdown Viewer" to false' 2>/dev/null || true
            sleep "$SWITCH_WAIT"
        fi

        local wid
        if wid=$(poll_window_id); then
            screencapture -l "$wid" -x "$out"
            log "[$name] captured (window $wid)"
        else
            warn "[$name] window not found — skipping screenshot"
            # Write a 1×1 placeholder so downstream does not crash.
            python3 -c "
import struct, zlib
def png1x1():
    sig=b'\\x89PNG\\r\\n\\x1a\\n'
    def chunk(t,d):
        return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xFFFFFFFF)
    ihdr=chunk(b'IHDR',struct.pack('>IIBBBBB',1,1,8,2,0,0,0))
    idat=chunk(b'IDAT',zlib.compress(b'\\x00\\xff\\xff\\xff'))
    iend=chunk(b'IEND',b'')
    return sig+ihdr+idat+iend
import sys; open(sys.argv[1],'wb').write(png1x1())
" "$out"
        fi
    done

    # Close the app silently after all captures.
    osascript -e 'tell application "md" to quit' 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Phase 2: Analyse — single Gemini call, all screenshots in one prompt
# ---------------------------------------------------------------------------

analyse_all() {
    log "Sending ${#RUN_NAMES[@]} screenshot(s) to Gemini in a single call…"

    # Prompt structure:
    #   1. All @image references first (gemini CLI resolves them at the start)
    #   2. Per-screenshot criteria labeled by number and fixture name
    #   3. Explicit example JSON with actual fixture names so Gemini returns the
    #      right structure without guessing field names or values.
    local prompt=""

    # Line 1: all image attachments
    for i in "${!RUN_NAMES[@]}"; do
        prompt+="@${RUN_RELPATHS[$i]} "
    done
    prompt+=$'\n\n'

    prompt+="You are a visual QA engineer for md.app (macOS Markdown reader).
Evaluate the ${#RUN_NAMES[@]} screenshots attached above. Each screenshot is numbered
in the order listed. Inspect carefully for: alignment issues, clipping, missing
elements, rendering artefacts, colour/contrast problems, and overflow.

"
    for i in "${!RUN_NAMES[@]}"; do
        prompt+="Screenshot $((i+1)) — fixture \"${RUN_NAMES[$i]}\":
${RUN_CRITERIA[$i]}
"
    done

    # Build the skeleton JSON example with actual fixture names so there is
    # zero ambiguity about the expected field names and fixture identifiers.
    local skeleton="["
    for i in "${!RUN_NAMES[@]}"; do
        [[ $i -gt 0 ]] && skeleton+=","
        skeleton+="{\"fixture\":\"${RUN_NAMES[$i]}\",\"pass\":true_or_false,\"score\":0.0_to_1.0,\"issues\":[\"...\"],\"summary\":\"one sentence\"}"
    done
    skeleton+="]"

    prompt+="
Return ONLY this JSON array — no prose, no markdown fences, nothing else:
${skeleton}"

    local tmp
    tmp=$(mktemp /tmp/mdviewer-vt-XXXXXX)
    cd "$PROJECT_ROOT"
    timeout "$GEMINI_TIMEOUT" gemini \
        -m "$GEMINI_MODEL" \
        --approval-mode yolo \
        -p "$prompt" > "$tmp" 2>&1 \
    || echo '[]' >> "$tmp"

    cat "$tmp"
    rm -f "$tmp"
}

# ---------------------------------------------------------------------------
# Parse and report
# ---------------------------------------------------------------------------

parse_and_report() {
    local raw="$1"
    shift
    python3 - "$raw" "$@" <<'PY'
import json, re, sys

raw   = sys.argv[1]
names = sys.argv[2:]

# Extract the JSON array; it may be buried in CLI noise.
# Strategy: find the outermost '[' ... ']' block that parses as valid JSON.
results = None
for m in re.finditer(r'\[', raw):
    end = raw.rfind(']')
    if end != -1:
        candidate = raw[m.start():end+1]
        try:
            results = json.loads(candidate)
            break
        except json.JSONDecodeError:
            continue

if results is None:
    print("\033[0;31m✗ Could not parse Gemini JSON array response\033[0m")
    print("Raw output (first 1000 chars):")
    print(raw[:1000])
    sys.exit(1)

by_name = {r.get("fixture", ""): r for r in results}
passed = failed = 0

print()
for name in names:
    r = by_name.get(name)
    if not r:
        print(f"\033[0;31m✗ {name}  no result\033[0m")
        failed += 1
        continue
    score   = r.get("score", 0.0)
    summary = r.get("summary", "")
    issues  = r.get("issues", [])
    if r.get("pass", False):
        print(f"\033[0;32m✓ {name}\033[0m  (score={score:.2f})  {summary}")
        passed += 1
    else:
        print(f"\033[0;31m✗ {name}\033[0m  (score={score:.2f})  {summary}")
        for issue in issues:
            print(f"    • {issue}")
        failed += 1

print()
print("═" * 60)
print(f"Visual Test Results: \033[0;32m{passed} passed\033[0m, \033[0;31m{failed} failed\033[0m")
print("═" * 60)
sys.exit(0 if failed == 0 else 1)
PY
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

declare -a RUN_NAMES=()
declare -a RUN_FILES=()
declare -a RUN_CRITERIA=()
declare -a RUN_RELPATHS=()

# Accept multiple fixture name args or run all.
declare -a REQUESTED=("${@}")

for entry in "${FIXTURES[@]}"; do
    IFS='|' read -r name file criteria <<< "$entry"
    full_file="$FIXTURES_DIR/$file"

    # If specific names requested, skip others.
    if [[ ${#REQUESTED[@]} -gt 0 ]]; then
        match=0
        for req in "${REQUESTED[@]}"; do
            [[ "$req" == "$name" ]] && match=1 && break
        done
        [[ $match -eq 0 ]] && continue
    fi

    if [[ ! -f "$full_file" ]]; then
        warn "Fixture not found, skipping: $full_file"; continue
    fi
    RUN_NAMES+=("$name")
    RUN_FILES+=("$full_file")
    RUN_CRITERIA+=("$criteria")
    RUN_RELPATHS+=("Tests/VisualFixtures/screenshots/${name}.png")
done

[[ ${#RUN_NAMES[@]} -eq 0 ]] && die "No matching fixtures found"

log "Running ${#RUN_NAMES[@]} fixture(s): ${RUN_NAMES[*]}"
echo ""

log "=== Phase 1: Capture ==="
capture_all
echo ""

log "=== Phase 2: Analyse ==="
gemini_output=$(analyse_all)
echo ""

parse_and_report "$gemini_output" "${RUN_NAMES[@]}"
