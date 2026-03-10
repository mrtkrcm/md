#!/bin/bash
# format-check.sh - Check SwiftFormat compliance without making changes
# Usage: format-check.sh [files...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MDVIEWER_DIR="${PROJECT_DIR}/mdviewer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Checking SwiftFormat compliance..."

# Check if we're in CI
if [ -n "${CI:-}" ]; then
    STRICT_MODE=true
else
    STRICT_MODE=false
fi

# Change to mdviewer directory
cd "${MDVIEWER_DIR}"

if [ $# -gt 0 ]; then
    echo "Checking ${#} files..."

    FILES_TO_CHECK=()
    for file in "$@"; do
        if [[ "$file" == *.swift ]]; then
            FILES_TO_CHECK+=("$file")
        fi
    done

    if [ ${#FILES_TO_CHECK[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ No Swift files to check${NC}"
        exit 0
    fi

    if swift run swiftformat --lint "${FILES_TO_CHECK[@]}" 2>/dev/null; then
        echo -e "${GREEN}✓ All files properly formatted${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some files need formatting${NC}"
        echo "Run 'just format-fix' to fix formatting issues"
        exit 1
    fi
fi

# Match the format-fix scope so build artifacts and vendored packages
# inside DerivedData do not fail the project formatting gate.
if swift package plugin --allow-writing-to-package-directory swiftformat \
    --target mdviewer \
    --target mdviewerTests \
    --lint
then
    echo -e "${GREEN}✓ All files properly formatted${NC}"
    exit 0
else
    echo -e "${RED}✗ Some files need formatting${NC}"
    echo "Run 'just format-fix' to fix formatting issues"
    exit 1
fi
