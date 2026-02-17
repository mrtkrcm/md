#!/bin/bash
set -e

# Navigate to the package directory
cd mdviewer

# Build the project
echo "Building mdviewer..."
swift build -c release

RUN_TESTS=${RUN_TESTS:-auto}

if [ "$RUN_TESTS" = "0" ] || [ "$RUN_TESTS" = "false" ] || [ "$RUN_TESTS" = "no" ]; then
  echo "Skipping tests (RUN_TESTS=$RUN_TESTS)."
  exit 0
fi

if [ "$RUN_TESTS" = "1" ] || [ "$RUN_TESTS" = "true" ] || [ "$RUN_TESTS" = "yes" ]; then
  echo "Running tests..."
  swift test
  exit 0
fi

# auto mode: run tests when Xcode is available, otherwise skip with guidance.
if xcodebuild -version >/dev/null 2>&1; then
  echo "Running tests..."
  swift test
else
  echo "Skipping tests: full Xcode is not configured (Command Line Tools only)."
  echo "Set RUN_TESTS=true to force tests, or configure Xcode:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi
