#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/mdviewer"
MODE="${1:-fix}"

cd "$PKG_DIR"

case "$MODE" in
  --check|check)
    echo "Checking Swift formatting..."
    swift package plugin --allow-writing-to-package-directory swiftformat \
      --target mdviewer \
      --target mdviewerTests \
      --lint
    ;;
  --fix|fix|"")
    echo "Applying Swift formatting..."
    swift package plugin --allow-writing-to-package-directory swiftformat \
      --target mdviewer \
      --target mdviewerTests
    ;;
  *)
    echo "Unknown mode: $MODE"
    echo "Usage: scripts/format.sh [--check|--fix]"
    exit 1
    ;;
esac
