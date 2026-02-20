#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/mdviewer"
RUN_FORMAT_CHECK=true

for arg in "$@"; do
  case "$arg" in
    --skip-format)
      RUN_FORMAT_CHECK=false
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: scripts/quality.sh [--skip-format]"
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
