#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/mdviewer"
RUN_FORMAT_CHECK=true
RUN_E2E=false

for arg in "$@"; do
  case "$arg" in
    --skip-format)
      RUN_FORMAT_CHECK=false
      ;;
    --e2e)
      RUN_E2E=true
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: scripts/quality.sh [--skip-format] [--e2e]"
      exit 1
      ;;
  esac
done

if $RUN_FORMAT_CHECK; then
  "$ROOT_DIR/scripts/format.sh" --check
fi

cd "$PKG_DIR"

echo "Running build..."
swift build -c release -Xswiftc -warnings-as-errors

echo "Running tests..."
swift test -Xswiftc -warnings-as-errors

if $RUN_E2E; then
  echo "Running E2E smoke test..."
  "$ROOT_DIR/scripts/build.sh"
  "$ROOT_DIR/scripts/e2e.sh"
fi
