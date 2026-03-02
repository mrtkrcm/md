#!/usr/bin/env bash
# visual-test.sh — two-phase visual regression tester for md.app.
#
# Phase 1: Capture — opens each fixture in the background, screenshots the
#           window with screencapture -l <windowID> (no focus steal), closes app.
#
# Phase 2: Analyse — sends ALL screenshots to Gemini 3 Flash in a SINGLE call
#           using @path references. Gemini returns a JSON array; Python parses it.
#           One model round-trip regardless of how many fixtures are run.
#
# Usage:
#   ./scripts/visual-test.sh           # all registered fixtures
#   ./scripts/visual-test.sh <name>    # single fixture by name (no .md extension)
#   GEMINI_MODEL=gemini-2.5-flash ./scripts/visual-test.sh  # override model
#
# Requirements:
#   - md.app installed at /Applications/md.app  (run: just install)
#   - gemini CLI on PATH and signed in
#
# Exit codes: 0 = all PASS, 1 = any FAIL or error

set -euo pipefail

GEMINI_MODEL="${GEMINI_MODEL:-gemini-3-flash-preview}"
GEMINI_TIMEOUT="${GEMINI_TIMEOUT:-120}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$PROJECT_ROOT/Tests/VisualFixtures"
SCREENSHOTS_DIR="$FIXTURES_DIR/screenshots"
RENDER_WAIT="${RENDER_WAIT:-3.0}"   # seconds for md.app to render a document

mkdir -p "$SCREENSHOTS_DIR"

log()  { printf '\033[0;34m▶ %s\033[0m\n' "$*" >&2; }
ok()   { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
fail() { printf '\033[0;31m✗ %s\033[0m\n' "$*"; }
warn() { printf '\033[0;33m⚠ %s\033[0m\n' "$*" >&2; }
die()  { fail "$*"; exit 1; }

# ---------------------------------------------------------------------------
# fixture registry
# Each entry: "name|fixture_file|NLP criteria prompt for Gemini"
# The criteria text is plain English — Gemini uses it as a lens for the image.
# ---------------------------------------------------------------------------

declare -a FIXTURES=(
"hr_heading|hr_heading.md|
  Horizontal rules (thin hairlines) must have clear whitespace above and below them.
  Every heading that follows a horizontal rule must be LEFT-aligned, never centered.
  Hairlines must not overlap or overdraw any heading or paragraph text.
  All heading text must be fully legible and unobscured."

"typography_baseline|typography_baseline.md|
  All headings (H1, H2, H3) must be left-aligned.
  Horizontal rules must appear as thin hairlines with clear spacing above and below; no text overlap.
  List items must be indented; when a list item wraps, continuation lines align under the text not the bullet.
  Inline code spans must look visually distinct from body text (different background or monospace font).
  Paragraph and block spacing must be consistent and readable throughout."

"tables|tables.md|
  All table borders (left, right, top, bottom, internal) must be fully visible — no missing edges.
  Cell content must not overflow or clip outside cell boundaries.
  Table header row must be visually distinct from data rows (different background or weight).
  Column widths must be proportional; the rightmost column must not be cut off.
  Inline code inside table cells must be styled correctly."

"code_blocks|code_blocks.md|
  Fenced code blocks must have a distinct background visually separating them from body text.
  Swift code block must show syntax highlighting (keywords, types, strings in distinct colors).
  Bash code block must show at least some syntax coloring or be clearly monospace.
  Plain unlabelled code block must render in monospace without errors.
  Inline code spans in the paragraph must have a visible background pill/highlight.
  Long lines in code blocks should not cause layout overflow or clipping."

"mermaid|mermaid.md|
  Each mermaid code block must be replaced by a rendered diagram image, not raw text.
  The flowchart diagram must show labelled nodes connected by arrows.
  The sequence diagram must show participants as boxes with labelled arrows between them.
  The state diagram must show states with transitions.
  Diagrams must not overlap with surrounding text or headings.
  There must be clear whitespace between each diagram and the surrounding content."
)

# ---------------------------------------------------------------------------
# Phase 1: Capture
# ---------------------------------------------------------------------------

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

capture_one() {
    local fixture_file="$1"
    local out="$2"
    local name="$3"

    log "[$name] opening in background..."
    osascript -e 'tell application "md" to quit' 2>/dev/null || true
    sleep 0.5
    open -g -a /Applications/md.app "$fixture_file"
    sleep "$RENDER_WAIT"

    local wid
    wid=$(get_window_id 2>/dev/null) || true

    if [[ -n "$wid" && "$wid" =~ ^[0-9]+$ ]]; then
        screencapture -l "$wid" -x "$out"
        log "[$name] captured (window $wid) → $(basename "$out")"
    else
        warn "[$name] window ID not found — full-screen fallback"
        screencapture -x "$out"
    fi
}

capture_all() {
    for i in "${!RUN_NAMES[@]}"; do
        local name="${RUN_NAMES[$i]}"
        local fixture_file="${RUN_FILES[$i]}"
        local out="$SCREENSHOTS_DIR/${name}.png"
        capture_one "$fixture_file" "$out" "$name"
    done
    osascript -e 'tell application "md" to quit' 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Phase 2: Analyse — parallel gemini calls, one per fixture
# Each runs in the background; results are collected after all complete.
# multimodal-looker extension is left enabled so gemini can read PNG images.
# ---------------------------------------------------------------------------

filter_gemini() {
    grep -v \
        -e "^Loaded" \
        -e "^Loading" \
        -e "YOLO mode" \
        -e "Error during discovery" \
        -e "MCP error" \
        -e "supports tool" \
        -e "supports resource" \
        -e "supports prompt" \
        -e "Hook registry" \
        -e "Received" \
        -e "updated for" \
        -e "changed, updating" \
        -e "Prompts updated" \
        -e "Tools updated" \
        -e "Tools changed" \
        -e "Attempt [0-9]* failed" \
        -e "Retrying" \
        -e "GaxiosError" \
        -e "rateLimitExceeded" \
        -e "RESOURCE_EXHAUSTED" \
        -e "capacity available" \
        -e "quota will reset" \
        -e "Git-ignored" \
        -e "git-ignored" \
        -e "Ignored [0-9]" \
        -e "^$" \
        || true
}

# Analyse one fixture in a subprocess; write JSON result to $outfile.
analyse_one() {
    local name="$1"
    local rel_path="$2"
    local criteria="$3"
    local outfile="$4"

    local prompt
    prompt="You are a visual QA engineer for a macOS Markdown reader app.
Examine the screenshot at @${rel_path} using natural language understanding.

Quality criteria for this fixture (${name}):
${criteria}

Look carefully for layout issues, alignment problems, missing elements, rendering
artefacts, overlapping content, clipping, or colour/contrast problems.

Return ONLY a single JSON object — no prose, no markdown fences:
{\"pass\": <true|false>, \"score\": <0.0-1.0>, \"issues\": [\"...\"], \"summary\": \"one sentence\"}"

    cd "$PROJECT_ROOT"
    # Capture raw output unfiltered — the JSON parser extracts the object regardless of noise.
    # Do NOT pipe through filter_gemini here: noise lines can share a line with JSON content.
    timeout "$GEMINI_TIMEOUT" gemini \
        -m "$GEMINI_MODEL" \
        --approval-mode yolo \
        -p "$prompt" > "$outfile" 2>&1 \
    || echo '{"pass":false,"score":0,"issues":["gemini timeout or error"],"summary":"analysis failed"}' > "$outfile"
}

analyse_all() {
    log "Analysing ${#RUN_NAMES[@]} fixture(s) sequentially (model: $GEMINI_MODEL)..."

    local combined="["
    for i in "${!RUN_NAMES[@]}"; do
        local name="${RUN_NAMES[$i]}"
        local tmp
        tmp=$(mktemp /tmp/mdviewer-vt-XXXXXX)

        log "[$name] analysing..."
        analyse_one "$name" "${RUN_RELPATHS[$i]}" "${RUN_CRITERIA[$i]}" "$tmp"

        local raw
        raw=$(cat "$tmp")
        rm -f "$tmp"

        # Extract the first JSON object; handle markdown fences and leading prose
        local obj
        obj=$(python3 -c "
import re, sys, json

raw = sys.argv[1]

def try_parse(s):
    try:
        json.loads(s)
        return s
    except Exception:
        return None

# Strategy 1: find the last occurrence of a JSON object (model output is at the end)
# Use a greedy search from the last '{' to handle noise prefixes on the same line.
for m in reversed(list(re.finditer(r'\{', raw))):
    candidate = raw[m.start():]
    # trim at the last '}' 
    end = candidate.rfind('}')
    if end != -1:
        candidate = candidate[:end+1]
        result = try_parse(candidate)
        if result:
            print(result)
            sys.exit(0)

# Strategy 2: markdown fence
fm = re.search(r'\`\`\`(?:json)?\s*(\{.*?\})\s*\`\`\`', raw, re.DOTALL)
if fm:
    result = try_parse(fm.group(1))
    if result:
        print(result)
        sys.exit(0)

print('{\"pass\":false,\"score\":0,\"issues\":[\"no valid JSON in response\"],\"summary\":\"parse failed\"}')
" "$raw") || obj='{"pass":false,"score":0,"issues":["python parse error"],"summary":"parse failed"}'

        # Inject fixture name
        obj=$(python3 -c "
import json, sys
try:
    obj = json.loads(sys.argv[1])
    obj.setdefault('fixture', sys.argv[2])
    print(json.dumps(obj))
except Exception as e:
    print(json.dumps({'fixture': sys.argv[2], 'pass': False, 'score': 0, 'issues': [str(e)], 'summary': 'json error'}))
" "$obj" "$name")

        [[ $i -gt 0 ]] && combined+=","
        combined+="$obj"
        log "[$name] done"
    done
    combined+="]"

    echo "$combined"
}

# ---------------------------------------------------------------------------
# Parse JSON and report results
# ---------------------------------------------------------------------------

parse_and_report() {
    local json="$1"
    shift
    python3 - "$json" "$@" <<'PY'
import json, sys, re

raw   = sys.argv[1]
names = sys.argv[2:]

# Extract JSON array from response — strip any stray prose/fences
match = re.search(r'\[.*\]', raw, re.DOTALL)
if not match:
    print("\033[0;31m✗ Could not parse Gemini JSON response\033[0m")
    print("Raw output:")
    print(raw[:2000])
    sys.exit(1)

try:
    results = json.loads(match.group())
except json.JSONDecodeError as e:
    print(f"\033[0;31m✗ JSON parse error: {e}\033[0m")
    print("Raw snippet:", raw[:500])
    sys.exit(1)

by_name = {r["fixture"]: r for r in results}
passed = 0
failed = 0

print()
for name in names:
    r = by_name.get(name)
    if not r:
        print(f"\033[0;31m✗ {name} — no result returned by Gemini\033[0m")
        failed += 1
        continue

    score = r.get("score", 0.0)
    summary = r.get("summary", "")
    issues = r.get("issues", [])

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

# Filter fixture registry to requested set
declare -a RUN_NAMES=()
declare -a RUN_FILES=()
declare -a RUN_CRITERIA=()
declare -a RUN_RELPATHS=()

filter="${1:-}"   # optional: fixture name to run solo

for entry in "${FIXTURES[@]}"; do
    IFS='|' read -r name file criteria <<< "$entry"
    full_file="$FIXTURES_DIR/$file"
    rel_path="Tests/VisualFixtures/screenshots/${name}.png"

    if [[ -z "$filter" || "$filter" == "$name" ]]; then
        if [[ ! -f "$full_file" ]]; then
            warn "Fixture not found, skipping: $full_file"
            continue
        fi
        RUN_NAMES+=("$name")
        RUN_FILES+=("$full_file")
        RUN_CRITERIA+=("$criteria")
        RUN_RELPATHS+=("$rel_path")
    fi
done

if [[ ${#RUN_NAMES[@]} -eq 0 ]]; then
    die "No matching fixtures found for: '${filter:-all}'"
fi

log "Running ${#RUN_NAMES[@]} fixture(s): ${RUN_NAMES[*]}"
echo ""

# Phase 1
log "=== Phase 1: Capture ==="
capture_all
echo ""

# Phase 2
log "=== Phase 2: Analyse (single Gemini call) ==="
gemini_output=$(analyse_all)
echo ""

# Report
parse_and_report "$gemini_output" "${RUN_NAMES[@]}"
