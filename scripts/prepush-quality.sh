#!/bin/bash
# prepush-quality.sh - Strong quality gate for git pre-push.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MDVIEWER_DIR="${PROJECT_DIR}/mdviewer"

echo "Running pre-push quality checks..."

# Fast static checks.
"${SCRIPT_DIR}/format-check.sh"
(
    cd "${PROJECT_DIR}"
    swiftlint lint --quiet --config "${PROJECT_DIR}/.swiftlint.yml"
)

# Full compile + test gate before push.
(
    cd "${MDVIEWER_DIR}"
    swift build -Xswiftc -warnings-as-errors
    swift test --parallel
)

echo "Pre-push quality checks passed."