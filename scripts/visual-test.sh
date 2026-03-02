#!/usr/bin/env bash
# visual-test.sh — screenshot md.app in the background and analyse with Gemini CLI.
#
# Usage:
#   ./scripts/visual-test.sh           # default fixture: hr_heading
#   ./scripts/visual-test.sh --all     # all fixtures
#   ./scripts/visual-test.sh path/to/fixture.md
#
# Requirements:
#   - md.app installed at /Applications/md.app  (run: just install)
#   - gemini CLI on PATH, signed in
#
# Screenshots are saved to Tests/VisualFixtures/screenshots/ inside the project
# so gemini CLI can read them (it restricts file access to the workspace).
#
# Exit codes: 0 = all PASS, 1 = one or more FAIL

set -euo pipefail

GEMINI_MODEL="${GEMINI_MODEL:-gemini-3-flash-preview}"
GEMINI_TIMEOUT="${GEMINI_TIMEOUT:-45}"   # seconds before giving up on gemini
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$PROJECT_ROOT/Tests/VisualFixtures"
SCREENSHOTS_DIR="$FIXTURES_DIR/screenshots"

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

# Open a file in md.app in the background (-g = no focus steal).
# Quits any existing instance first for a deterministic document state.
open_fixture() {
    local fixture="$1"
    osascript -e 'tell application "md" to quit' 2>/dev/null || true
    sleep 0.6
    open -g -a /Applications/md.app "$fixture"
    sleep 3.0   # allow full layout + render pass
}

# Get the CGWindowID of the frontmost Markdown Viewer window via Swift snippet.
get_window_id() {
    /usr/bin/swift - 2>/dev/null << 'SWIFT'
import Cocoa
let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
if let wl = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] {
    for w in wl {
        if (w[kCGWindowOwnerName as String] as? String) == "Markdown Viewer",
           let num = w[kCGWindowNumber as String] as? Int {
            Swift.print(num)
            exit(0)
        }
    }
}
exit(1)
SWIFT
}

# Capture the md.app window by ID into $out without stealing focus.
capture_window() {
    local out="$1"
    local wid
    wid=$(get_window_id) || true

    if [[ -n "$wid" && "$wid" =~ ^[0-9]+$ ]]; then
        screencapture -l "$wid" -x "$out"
    else
        warn "Window ID not found — falling back to full-screen capture"
        screencapture -x "$out"
    fi
}

# Ask Gemini CLI to analyse the screenshot at a workspace-relative path.
# Gemini's file access is sandboxed to the project root, so we pass a
# relative @path which the CLI resolves via its read_file tool.
analyse_screenshot() {
    local rel_path="$1"   # relative to project root, e.g. Tests/VisualFixtures/screenshots/foo.png
    local prompt="$2"

    # Run from project root so relative @paths resolve correctly.
    cd "$PROJECT_ROOT"

    timeout "$GEMINI_TIMEOUT" gemini \
        -m "$GEMINI_MODEL" \
        --approval-mode yolo \
        -e "" \
        -p "Look at @${rel_path}

${prompt}" 2>&1 \
    | grep -v "^Loaded\|^Loading\|YOLO mode\|Error during discovery\|MCP error\|supports tool\|supports resource\|supports prompt\|Hook registry\|Received\|updated for\|changed, updating\|Prompts updated\|Tools updated\|Tools changed\|Attempt [0-9]* failed\|Retrying\|GaxiosError\|rateLimitExceeded\|RESOURCE_EXHAUSTED\|capacity available\|quota will reset\|git-ignored\|Git-ignored\|Ignored [0-9]" \
    || true
}

# Run one visual test.
run_test() {
    local fixture="$1"
    local prompt="$2"
    local name
    name="$(basename "$fixture" .md)"
    local out_abs="$SCREENSHOTS_DIR/${name}.png"
    local out_rel="Tests/VisualFixtures/screenshots/${name}.png"

    log "Fixture: $(basename "$fixture")"

    log "Opening in background..."
    open_fixture "$fixture"

    log "Capturing window (no focus steal)..."
    capture_window "$out_abs"

    if [[ ! -s "$out_abs" ]]; then
        fail "$name — screenshot empty or missing"
        FAIL=$((FAIL + 1))
        RESULTS+=("FAIL:$name:no screenshot")
        return
    fi

    log "Analysing with Gemini ($GEMINI_MODEL, timeout ${GEMINI_TIMEOUT}s)..."
    local analysis
    if ! analysis=$(analyse_screenshot "$out_rel" "$prompt"); then
        fail "$name — Gemini timed out or errored"
        FAIL=$((FAIL + 1))
        RESULTS+=("FAIL:$name:gemini error")
        return
    fi

    echo ""
    echo "$analysis"
    echo ""

    # Detect structured FAIL ratings from the numbered-criterion prompt format.
    # Matches:  "1. FAIL ...", "1. **FAIL ...", "1) FAIL ..."
    if echo "$analysis" | grep -qE "^[[:space:]]*[0-9]+[.)][[:space:]]+(\*\*)?FAIL"; then
        fail "$name — Gemini found issues (see above)"
        FAIL=$((FAIL + 1))
        RESULTS+=("FAIL:$name:visual issues detected")
    else
        ok "$name"
        PASS=$((PASS + 1))
        RESULTS+=("PASS:$name")
    fi

    log "Screenshot: $out_abs"
    echo ""
}

# ---------------------------------------------------------------------------
# test prompts
# ---------------------------------------------------------------------------

read -r -d '' HR_HEADING_PROMPT <<'PROMPT' || true
You are a visual QA reviewer for a macOS Markdown reader app.
Answer each criterion with exactly "PASS" or "FAIL" followed by a brief reason.

1. Heading alignment: Is "Security Considerations" (and every other heading that follows a horizontal rule) LEFT-aligned — not centered?
2. HR spacing above: Is there clear whitespace above each thin horizontal hairline, separating it from preceding content?
3. HR spacing below: Is there clear whitespace below each thin horizontal hairline, separating it from the following heading or paragraph?
4. No overlap: Does every hairline avoid overwriting or visually overlapping heading or paragraph text?
5. Heading legibility: Is every heading after a horizontal rule fully legible and unobscured?

End with one sentence overall verdict.
PROMPT

read -r -d '' TYPOGRAPHY_PROMPT <<'PROMPT' || true
You are a visual QA reviewer for a macOS Markdown reader app.
Answer each criterion with exactly "PASS" or "FAIL" followed by a brief reason.

1. Heading alignment: Are all headings (H1, H2, H3) LEFT-aligned?
2. HR rendering: Do horizontal rules appear as thin hairlines with clear whitespace above and below, with no overlap onto adjacent text?
3. List indentation: Do list items indent properly? When a list item wraps, does the continuation align under the text (not under the bullet)?
4. Inline code: Are inline code spans visually distinct from body text?
5. Spacing consistency: Is paragraph and block spacing consistent and readable throughout the document?

End with one sentence overall verdict.
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
        CUSTOM_PROMPT="Describe any visual rendering issues in this macOS Markdown reader screenshot. Check heading alignment, spacing around horizontal rules, list indentation, and overall typography. Answer PASS or FAIL per issue found."
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
