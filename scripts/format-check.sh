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

# If specific files provided, check only those
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

    # Run SwiftFormat in lint mode on specific files
    if swift run swiftformat --lint "${FILES_TO_CHECK[@]}" 2>/dev/null; then
        echo -e "${GREEN}✓ All files properly formatted${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some files need formatting${NC}"
        echo "Run 'just format-fix' to fix formatting issues"
        exit 1
    fi
else
    # Run SwiftFormat in lint mode on entire project
    if swift run swiftformat --lint . 2>/dev/null; then
        echo -e "${GREEN}✓ All files properly formatted${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some files need formatting${NC}"
        echo ""
        echo "Files needing formatting:"
        swift run swiftformat --lint . 2>&1 | grep "would have been formatted" || true
        echo ""
        echo "Run 'just format-fix' to fix formatting issues"
        exit 1
    fi
fi
