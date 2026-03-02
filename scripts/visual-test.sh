#!/usr/bin/env bash
# visual-test.sh — open md.app with a fixture, screenshot the window, analyse with Gemini.
#
# Usage:
#   ./scripts/visual-test.sh [fixture.md]   # run single fixture (default: hr_heading.md)
#   ./scripts/visual-test.sh --all          # run all fixtures
#
# Requires:
#   - md.app installed at /Applications/md.app  (run: just install)
#   - GEMINI_API_KEY set in environment
#   - python3, curl, screencapture on PATH
#
# Exit codes: 0 = all checks passed, 1 = one or more Gemini concerns found

set -euo pipefail

GEMINI_MODEL="${GEMINI_MODEL:-gemini-3-flash-preview}"
GEMINI_API_KEY="${GEMINI_API_KEY:?GEMINI_API_KEY must be set}"
API_URL="https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}"

FIXTURES_DIR="$(cd "$(dirname "$0")/../Tests/VisualFixtures" && pwd)"
SCREENSHOTS_DIR="/tmp/mdviewer-visual-tests"
PASS=0
FAIL=0
RESULTS=()

mkdir -p "$SCREENSHOTS_DIR"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

log()  { printf '\033[0;34m▶ %s\033[0m\n' "$*"; }
ok()   { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
fail() { printf '\033[0;31m✗ %s\033[0m\n' "$*"; }
warn() { printf '\033[0;33m⚠ %s\033[0m\n' "$*"; }

# The running process name for md.app as seen by the window server.
MD_PROCESS_NAME="Markdown Viewer"

# Open a file in md.app and wait for it to render.
# Kills any existing instance first so the fixture is guaranteed to be the active document.
open_fixture() {
    local fixture="$1"

    # Quit cleanly if already running so we control exactly which file is shown.
    osascript -e 'tell application "md" to quit' 2>/dev/null || true
    sleep 0.5

    open -a /Applications/md.app "$fixture"
    sleep 3.0  # allow layout + render pass to complete
}

# Capture the frontmost md.app window to a PNG via CGWindowListCopyWindowInfo.
# Uses a small Swift one-liner — no Python/Quartz dependency.
capture_window() {
    local out="$1"

    local wid
    wid=$(/usr/bin/swift - 2>/dev/null << SWIFT
import Cocoa
let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
if let wl = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] {
    for w in wl {
        let name = w[kCGWindowOwnerName as String] as? String ?? ""
        if name == "Markdown Viewer" {
            if let num = w[kCGWindowNumber as String] as? Int {
                Swift.print(num)
                exit(0)
            }
        }
    }
}
exit(1)
SWIFT
    ) || true

    if [[ -n "$wid" && "$wid" =~ ^[0-9]+$ ]]; then
        screencapture -l "$wid" -x "$out"
    else
        warn "Window ID not found — falling back to full-screen capture"
        screencapture -x "$out"
    fi
}

# Send screenshot + prompt to Gemini REST API; print and return the response text.
analyse_screenshot() {
    local img="$1"
    local prompt="$2"
    local payload_file="$SCREENSHOTS_DIR/payload_$$.json"

    # Build JSON payload via Python reading image file directly (avoids shell arg-length limits)
    python3 - "$img" "$prompt" "$payload_file" <<'PY'
import base64, json, sys

img_path   = sys.argv[1]
prompt     = sys.argv[2]
out_path   = sys.argv[3]

with open(img_path, "rb") as f:
    b64 = base64.b64encode(f.read()).decode("ascii")

body = {
    "contents": [{
        "parts": [
            {"inline_data": {"mime_type": "image/png", "data": b64}},
            {"text": prompt}
        ]
    }]
}

with open(out_path, "w") as f:
    json.dump(body, f)
PY

    curl -s "$API_URL" \
        -H "Content-Type: application/json" \
        -d "@$payload_file" \
    | python3 -c "
import json, sys
r = json.load(sys.stdin)
if 'error' in r:
    print('API ERROR:', r['error'].get('message','unknown'), file=sys.stderr)
    sys.exit(1)
print(r['candidates'][0]['content']['parts'][0]['text'])
"

    rm -f "$payload_file"
}

# Run one visual test case.
run_test() {
    local fixture="$1"
    local prompt="$2"
    local name
    name="$(basename "$fixture" .md)"
    local out="$SCREENSHOTS_DIR/${name}.png"

    log "Opening fixture: $(basename "$fixture")"
    open_fixture "$fixture"

    log "Capturing window..."
    capture_window "$out"

    if [[ ! -s "$out" ]]; then
        fail "$name — screenshot not captured or empty"
        FAIL=$((FAIL + 1))
        RESULTS+=("FAIL:$name:screenshot not captured")
        return
    fi

    log "Analysing with Gemini ($GEMINI_MODEL)..."
    local analysis
    if ! analysis=$(analyse_screenshot "$out" "$prompt"); then
        fail "$name — Gemini API error"
        FAIL=$((FAIL + 1))
        RESULTS+=("FAIL:$name:API error")
        return
    fi

    echo ""
    echo "$analysis"
    echo ""

    # Heuristic: flag if Gemini's structured response contains a FAIL rating.
    # The prompts request "PASS or FAIL" per numbered criterion; we match those lines.
    # We also catch unambiguous single-word failure descriptors as a safety net.
    if echo "$analysis" | grep -qiE \
        "^\s*[0-9]+[.)]\s+(\*\*)?FAIL|^\s*[0-9]+\.\s+FAIL[^A-Z]"; then
        fail "$name — Gemini flagged visual concerns (see above)"
        FAIL=$((FAIL + 1))
        RESULTS+=("FAIL:$name:visual concern detected")
    else
        ok "$name — no visual concerns"
        PASS=$((PASS + 1))
        RESULTS+=("PASS:$name")
    fi

    echo "  Screenshot saved: $out"
    echo ""
}

# ---------------------------------------------------------------------------
# test prompts
# ---------------------------------------------------------------------------

read -r -d '' HR_HEADING_PROMPT <<'PROMPT' || true
You are a visual QA reviewer for a macOS Markdown reader app.
Examine this screenshot carefully and answer each question with PASS or FAIL followed by a brief reason.

1. Heading alignment: Is the heading "Security Considerations" (and any other heading that follows a horizontal rule) LEFT-aligned? It must NOT be centered or offset.
2. HR spacing above: Is there visible whitespace/padding ABOVE the thin horizontal hairline, separating it from the content above?
3. HR spacing below: Is there visible whitespace/padding BELOW the thin horizontal hairline, separating it from the heading below?
4. No overlap: Does the horizontal hairline avoid overwriting or overlapping any heading or paragraph text?
5. Heading visible: Is the full heading text legible and not obscured by the hairline?

End with a one-sentence overall verdict.
PROMPT

read -r -d '' TYPOGRAPHY_PROMPT <<'PROMPT' || true
You are a visual QA reviewer for a macOS Markdown reader app.
Examine this screenshot carefully and answer each question with PASS or FAIL followed by a brief reason.

1. Heading alignment: Are all headings (H1, H2, H3) LEFT-aligned?
2. HR rendering: Do horizontal rules appear as thin hairlines with clear whitespace above and below — no overlap with adjacent text?
3. List indentation: Do list items have proper indentation? When a list item wraps to the next line, does the continuation text align under the item text (not under the bullet)?
4. Inline code: Are inline code spans visually distinct from body text (different background or font)?
5. Overall layout: Does the document have consistent, readable spacing throughout?

End with a one-sentence overall verdict.
PROMPT

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

case "${1:-}" in
    --all)
        run_test "$FIXTURES_DIR/hr_heading.md"          "$HR_HEADING_PROMPT"
        run_test "$FIXTURES_DIR/typography_baseline.md" "$TYPOGRAPHY_PROMPT"
        ;;
    "")
        run_test "$FIXTURES_DIR/hr_heading.md" "$HR_HEADING_PROMPT"
        ;;
    *.md)
        CUSTOM_PROMPT="Describe any visual rendering issues in this macOS Markdown reader screenshot. Check: alignment of headings, spacing around horizontal rules, list indentation, and overall typography. Be specific."
        run_test "$1" "$CUSTOM_PROMPT"
        ;;
    *)
        echo "Usage: $0 [fixture.md | --all]"
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# summary
# ---------------------------------------------------------------------------

printf '═%.0s' {1..60}; echo ""
printf "Visual Test Results: \033[0;32m%d passed\033[0m, \033[0;31m%d failed\033[0m\n" "$PASS" "$FAIL"
for r in "${RESULTS[@]}"; do
    status="${r%%:*}"
    rest="${r#*:}"
    name="${rest%%:*}"
    detail="${rest#*:}"
    if [[ "$status" == "PASS" ]]; then
        ok "$name"
    else
        fail "$name — $detail"
    fi
done
printf '═%.0s' {1..60}; echo ""

[[ "$FAIL" -eq 0 ]]
