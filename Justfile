# Justfile for mdviewer
# https://github.com/casey/just

set shell := ["bash", "-euo", "pipefail"]
set positional-arguments

# Default recipe - list all available commands
default:
    @just --list

# ===== Build Commands =====

# Build the project in debug mode (also installs to /Applications)
build:
    #!/usr/bin/env bash
    set -euo pipefail
    cd mdviewer && swift build
    cd ..
    scripts/build.sh --no-tests

# Build the project in release mode (also installs to /Applications)
build-release:
    #!/usr/bin/env bash
    set -euo pipefail
    cd mdviewer && swift build -c release
    cd ..
    scripts/build.sh --no-tests

# Build the full macOS app bundle
build-app:
    scripts/build.sh

# Clean build artifacts
clean:
    cd mdviewer && swift package clean
    rm -rf release/md.app
    rm -rf mdviewer/.build/debug
    rm -rf mdviewer/.build/release
    @echo "Cleaned build artifacts"

# ===== Test Commands =====

# Run all tests
test:
    cd mdviewer && swift test

# Run tests with code coverage
test-coverage:
    cd mdviewer && swift test --enable-code-coverage
    @echo "Coverage report: mdviewer/.build/debug/codecov/"

# Run tests in parallel for faster execution
test-parallel:
    cd mdviewer && swift test --parallel

# Run only unit tests (excluding integration)
test-unit:
    cd mdviewer && swift test --filter mdviewerTests

# Run integration tests
test-integration:
    cd mdviewer && swift test --filter Integration

# Run visual regression tests
test-visual:
    cd mdviewer && swift test --filter Visual

# Run performance tests
test-performance:
    cd mdviewer && swift test --filter Performance

# Run E2E tests
test-e2e:
    scripts/build.sh --no-install
    scripts/e2e.sh

# Run E2E tests with visual comparison
test-e2e-visual:
    scripts/build.sh --no-install
    scripts/e2e.sh --visual

# ===== Code Quality Commands =====

# Run all quality checks (format, lint, build, test)
quality:
    scripts/quality.sh

# Run quick quality checks (format only)
quality-quick:
    scripts/quality.sh --quick

# Run SwiftFormat check (no changes)
format-check:
    scripts/format-check.sh

# Run SwiftFormat and apply fixes
format-fix:
    scripts/format.sh --fix

# Run SwiftLint check
lint:
    swiftlint lint --strict

# Run SwiftLint and apply auto-fixes
lint-fix:
    swiftlint --fix

# Analyze code with SwiftLint and generate report
lint-report:
    swiftlint analyze --reporter html > lint-report.html
    @echo "Lint report: lint-report.html"

# ===== Development Commands =====

# Install dependencies
install-deps:
    @echo "Installing SwiftFormat..."
    cd mdviewer && swift package resolve
    @echo "Installing Lefthook..."
    command -v lefthook >/dev/null 2>&1 || brew install lefthook
    @echo "Installing SwiftLint..."
    command -v swiftlint >/dev/null 2>&1 || brew install swiftlint

# Setup git hooks
setup-hooks:
    lefthook install

# Open project in Xcode
xcode:
    open mdviewer/Package.swift

# Run the app from source
run:
    cd mdviewer && swift run

# Run with debug output
debug:
    cd mdviewer && swift run 2>&1 | tee debug.log

# Install the built app to /Applications
install:
    scripts/install.sh

# Uninstall from /Applications
uninstall:
    rm -rf /Applications/md.app
    @echo "Uninstalled md.app"

# ===== Documentation Commands =====

# Generate documentation with DocC
docs-generate:
    cd mdviewer && swift package generate-documentation --target mdviewer

# Preview documentation locally
docs-preview:
    cd mdviewer && swift package preview-documentation --target mdviewer

# ===== CI/Automation Commands =====

# Run full CI pipeline locally
ci-local:
    just format-check
    just lint
    just build
    just test
    just build-app

# Generate test report
report:
    cd mdviewer && swift test --parallel --xunit-output test-report.xml
    @echo "Test report: mdviewer/test-report.xml"

# ===== Utility Commands =====

# Show Swift version
swift-version:
    swift --version

# Show project info
info:
    @echo "Project: mdviewer"
    @echo "Swift Version: $(swift --version | head -n 1)"
    @echo "Package: $(cd mdviewer && swift package describe --type json | grep -o '"name":"[^"]*"' | head -1)"
    @echo ""
    @echo "File counts:"
    @echo "  Swift files: $(find mdviewer/Sources -name '*.swift' | wc -l)"
    @echo "  Test files: $(find mdviewer/Tests -name '*.swift' | wc -l)"
    @echo "  Total lines: $(find mdviewer/Sources -name '*.swift' -exec wc -l {} + | tail -1 | awk '{print $1}')"

# Find TODOs and FIXMEs in the codebase
todos:
    @echo "TODOs and FIXMEs:"
    grep -r "TODO\|FIXME" --include="*.swift" mdviewer/Sources || echo "None found"

# Run security audit
audit:
    @echo "Checking for common security issues..."
    grep -r "NSLog\|print(" --include="*.swift" mdviewer/Sources && echo "⚠️  Found logging statements" || echo "✓ No print/NSLog found"
    grep -r "\.unsafe" --include="*.swift" mdviewer/Sources && echo "⚠️  Found unsafe code" || echo "✓ No unsafe code found"
    grep -r "disable.*security" --include="*.swift" mdviewer/Sources && echo "⚠️  Found security disabled" || echo "✓ No security disabled"
