#!/bin/bash
# install.sh — build, package, and install md.app to /Applications
#
# Usage:
#   scripts/install.sh [--open] [--with-tests]
#
# Tests are skipped by default; use --with-tests to run them before install.
# If a fresh release binary already exists, the build step is skipped.
#
# Delegates to build.sh. All build.sh flags and environment variables
# (INSTALL_DIR, BUNDLE_ID, APP_VERSION) are supported.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/mdviewer"

# ── Defaults ──────────────────────────────────────────────────────────────────
RUN_TESTS=false
EXTRA_ARGS=()
SKIP_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --with-tests) RUN_TESTS=true ;;
    *)            EXTRA_ARGS+=("$arg") ;;
  esac
done

# ── Freshness check ──────────────────────────────────────────────────────────
# If a release binary exists and is newer than all Swift source files, skip build.
BIN_DIR="$(cd "$PKG_DIR" && swift build -c release --show-bin-path 2>/dev/null || true)"
BIN="$BIN_DIR/mdviewer"

if [ -x "$BIN" ]; then
  BIN_MTIME="$(stat -f %m "$BIN" 2>/dev/null || echo 0)"
  NEWEST_SRC="$(find "$PKG_DIR/Sources" -name '*.swift' -exec stat -f %m {} + 2>/dev/null | sort -n | tail -1 || echo 0)"
  if [ "$BIN_MTIME" -gt "$NEWEST_SRC" ] 2>/dev/null; then
    SKIP_BUILD=true
  fi
fi

# ── Assemble flags ────────────────────────────────────────────────────────────
FLAGS=(--install)

if [ "$RUN_TESTS" = false ]; then
  FLAGS+=(--no-tests)
fi

if [ "$SKIP_BUILD" = true ]; then
  FLAGS+=(--skip-build)
fi

exec bash "$ROOT_DIR/scripts/build.sh" "${FLAGS[@]}" "${EXTRA_ARGS[@]}"
