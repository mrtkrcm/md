#!/bin/bash
# precommit-quality.sh - Fast staged-file quality gate for git pre-commit.
# Usage: precommit-quality.sh [staged files...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MDVIEWER_DIR="${PROJECT_DIR}/mdviewer"

if [ $# -eq 0 ]; then
    echo "No staged files detected; skipping pre-commit quality checks."
    exit 0
fi

SWIFT_FILES=()
SOURCE_SWIFT_FILES=()

for file in "$@"; do
    if [[ "$file" != *.swift ]]; then
        continue
    fi

    # Normalize paths for tools executed from /mdviewer.
    normalized="$file"
    if [[ "$normalized" == mdviewer/* ]]; then
        normalized="${normalized#mdviewer/}"
    fi

    SWIFT_FILES+=("$normalized")

    if [[ "$normalized" == Sources/* ]]; then
        SOURCE_SWIFT_FILES+=("$normalized")
    fi
done

if [ ${#SWIFT_FILES[@]} -eq 0 ]; then
    echo "No staged Swift files; skipping Swift checks."
    exit 0
fi

echo "Running staged Swift quality checks on ${#SWIFT_FILES[@]} file(s)..."

# 1) Formatting gate (staged files only)
"${SCRIPT_DIR}/format-check.sh" "${SWIFT_FILES[@]}"

# 2) Lint gate (staged files only)
(
    cd "${MDVIEWER_DIR}"
    swiftlint lint --quiet --config "${PROJECT_DIR}/.swiftlint.yml" "${SWIFT_FILES[@]}"
)

# 3) Compile gate only when source files changed
if [ ${#SOURCE_SWIFT_FILES[@]} -gt 0 ]; then
    echo "Source Swift files changed; running compile check..."
    (
        cd "${MDVIEWER_DIR}"
        swift build >/dev/null
    )
fi

echo "Pre-commit quality checks passed."