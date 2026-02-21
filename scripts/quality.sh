#!/bin/bash
# quality.sh - Comprehensive code quality checks
# Usage: quality.sh [--quick] [--skip-format] [--e2e]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MDVIEWER_DIR="${PROJECT_DIR}/mdviewer"

# Flags
QUICK_MODE=false
SKIP_FORMAT=false
RUN_E2E=false
RUN_COVERAGE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --quick)
            QUICK_MODE=true
            ;;
        --skip-format)
            SKIP_FORMAT=true
            ;;
        --e2e)
            RUN_E2E=true
            ;;
        --coverage)
            RUN_COVERAGE=true
            ;;
        --help|-h)
            echo "Usage: quality.sh [options]"
            echo ""
            echo "Options:"
            echo "  --quick        Run only fast checks (format, lint)"
            echo "  --skip-format  Skip SwiftFormat check"
            echo "  --e2e          Include E2E tests"
            echo "  --coverage     Generate code coverage report"
            echo "  --help         Show this help"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Run 'quality.sh --help' for usage"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           mdviewer Code Quality Check                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

FAILED=0

# Function to print section headers
section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo "──────────────────────────────────────────────────────────"
}

# Function to print success
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print error
error() {
    echo -e "${RED}✗ $1${NC}"
}

# 1. SwiftFormat Check
if ! $SKIP_FORMAT; then
    section "SwiftFormat Check"
    if "${SCRIPT_DIR}/format-check.sh"; then
        success "SwiftFormat check passed"
    else
        error "SwiftFormat check failed"
        echo "Run 'just format-fix' to fix formatting issues"
        FAILED=$((FAILED + 1))
    fi
else
    warning "Skipping SwiftFormat check"
fi

# 2. SwiftLint Check
section "SwiftLint Check"
if command -v swiftlint >/dev/null 2>&1; then
    if swiftlint lint --quiet --strict; then
        success "SwiftLint check passed"
    else
        error "SwiftLint check failed"
        echo "Run 'just lint-fix' to fix auto-fixable issues"
        FAILED=$((FAILED + 1))
    fi
else
    warning "SwiftLint not installed, skipping"
    echo "Install with: brew install swiftlint"
fi

# If quick mode, stop here
if $QUICK_MODE; then
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}║  Quick quality check passed!                             ║${NC}"
    else
        echo -e "${RED}║  Quick quality check failed ($FAILED issue(s))           ║${NC}"
    fi
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    exit $FAILED
fi

# 3. Build
section "Build"
cd "${MDVIEWER_DIR}"
echo "Building in release mode..."
if swift build -c release -Xswiftc -warnings-as-errors 2>&1 | tee /tmp/build.log; then
    success "Build successful"
else
    error "Build failed"
    FAILED=$((FAILED + 1))
fi

# 4. Tests
section "Tests"
TEST_FLAGS="-Xswiftc -warnings-as-errors"
if $RUN_COVERAGE; then
    TEST_FLAGS="$TEST_FLAGS --enable-code-coverage"
fi

echo "Running tests..."
if swift test $TEST_FLAGS 2>&1 | tee /tmp/test.log; then
    success "All tests passed"

    # Show test summary
    if command -v grep >/dev/null 2>&1; then
        TEST_COUNT=$(grep -o "Executed.*tests" /tmp/test.log | tail -1 || echo "")
        if [ -n "$TEST_COUNT" ]; then
            echo "   $TEST_COUNT"
        fi
    fi
else
    error "Tests failed"
    FAILED=$((FAILED + 1))
fi

# 5. Code Coverage (if enabled)
if $RUN_COVERAGE; then
    section "Code Coverage"
    PROFDATA=$(find .build -name "*.profdata" 2>/dev/null | head -1)
    if [ -n "$PROFDATA" ]; then
        echo "Generating coverage report..."
        xcrun llvm-cov export \
            -format=lcov \
            -instr-profile="$PROFDATA" \
            .build/debug/mdviewerPackageTests.xctest/Contents/MacOS/mdviewerPackageTests \
            > coverage.lcov 2>/dev/null || true

        if [ -f coverage.lcov ]; then
            success "Coverage report generated: coverage.lcov"
        else
            warning "Could not generate coverage report"
        fi
    else
        warning "No coverage data found"
    fi
fi

# 6. E2E Tests
if $RUN_E2E; then
    section "E2E Tests"
    echo "Building app for E2E tests..."
    if "${SCRIPT_DIR}/build.sh" --no-tests; then
        echo "Running E2E tests..."
        if "${SCRIPT_DIR}/e2e.sh"; then
            success "E2E tests passed"
        else
            error "E2E tests failed"
            FAILED=$((FAILED + 1))
        fi
    else
        error "App build failed"
        FAILED=$((FAILED + 1))
    fi
fi

# 7. Security Check
section "Security Check"
SECURITY_ISSUES=0

# Check for print statements
if grep -r "print(" --include="*.swift" "${MDVIEWER_DIR}/Sources" >/dev/null 2>&1; then
    warning "Found print() statements (consider using Logger)"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
else
    success "No print() statements found"
fi

# Check for NSLog
if grep -r "NSLog(" --include="*.swift" "${MDVIEWER_DIR}/Sources" >/dev/null 2>&1; then
    error "Found NSLog() statements (use Logger instead)"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
else
    success "No NSLog() statements found"
fi

# 8. File Headers Check
section "File Headers Check"
MISSING_HEADERS=$(find "${MDVIEWER_DIR}/Sources" "${MDVIEWER_DIR}/Tests" -name "*.swift" ! -path "*/.build/*" -exec grep -L "//  .*\.swift" {} \; 2>/dev/null || true)
if [ -z "$MISSING_HEADERS" ]; then
    success "All files have proper headers"
else
    warning "Some files missing headers:"
    echo "$MISSING_HEADERS" | head -5
    if [ $(echo "$MISSING_HEADERS" | wc -l) -gt 5 ]; then
        echo "... and more"
    fi
fi

# Summary
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}║  ✓ All quality checks passed!                            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}║  ✗ Quality check failed ($FAILED issue(s))               ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
