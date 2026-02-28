#!/bin/bash
# build.sh — build, package, and install md.app (install is on by default)
#
# Usage:
#   scripts/build.sh [--no-install] [--open] [--no-tests] [--no-strip]
#                    [--skip-build] [--quiet]
#
# Environment overrides (all optional):
#   INSTALL_DIR   — install destination (default: /Applications)
#   BUNDLE_ID     — bundle identifier   (default: com.mrtkrcm.mdviewer)
#   APP_VERSION   — CFBundleShortVersionString (default: derived from git tag)
#   APP_BUILD     — CFBundleVersion            (default: git commit count)

set -euo pipefail

# ── Resolve paths ─────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/mdviewer"
SCRIPTS_DIR="$ROOT_DIR/scripts"
APP_NAME="md"
APP_BUNDLE="$ROOT_DIR/release/$APP_NAME.app"
INFO_PLIST_SRC="$PKG_DIR/Sources/mdviewer/Info.plist"
ICON_SRC="$PKG_DIR/Sources/mdviewer/Resources/AppIcon.icns"
[ -f "$ICON_SRC" ] || ICON_SRC="$ROOT_DIR/dist/MD.app/Contents/Resources/AppIcon.icns"

INSTALL_DIR="${INSTALL_DIR:-/Applications}"
BUNDLE_ID="${BUNDLE_ID:-com.mrtkrcm.mdviewer}"

# ── Parse flags ───────────────────────────────────────────────────────────────
INSTALL=true
OPEN_AFTER=false
RUN_TESTS=true
STRIP_BINARY=true
SKIP_BUILD=false
QUIET=false

for arg in "$@"; do
  case "$arg" in
    --no-install) INSTALL=false ;;
    --install)    INSTALL=true ;;   # kept for backwards compat
    --open)       OPEN_AFTER=true ;;
    --no-tests)   RUN_TESTS=false ;;
    --no-strip)   STRIP_BINARY=false ;;
    --skip-build) SKIP_BUILD=true ;;
    --quiet)      QUIET=true ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: scripts/build.sh [--no-install] [--open] [--no-tests] [--no-strip] [--skip-build] [--quiet]" >&2
      exit 1
      ;;
  esac
done

# ── Colored output helpers ────────────────────────────────────────────────────
if [ -t 1 ] && [ "$QUIET" = false ]; then
  BOLD='\033[1m'
  DIM='\033[2m'
  GREEN='\033[32m'
  BLUE='\033[34m'
  CYAN='\033[36m'
  YELLOW='\033[33m'
  RED='\033[31m'
  RESET='\033[0m'
else
  BOLD='' DIM='' GREEN='' BLUE='' CYAN='' YELLOW='' RED='' RESET=''
fi

TOTAL_START="$(date +%s)"

stage() {
  [ "$QUIET" = true ] && return
  local label="$1"
  STAGE_START="$(date +%s)"
  printf "\n${BOLD}${BLUE}▸ %s${RESET}\n" "$label"
}

stage_done() {
  [ "$QUIET" = true ] && return
  local elapsed=$(( $(date +%s) - STAGE_START ))
  printf "${GREEN}  ✓${RESET} ${DIM}(%ds)${RESET}\n" "$elapsed"
}

info() {
  [ "$QUIET" = true ] && return
  printf "  %s\n" "$1"
}

warn() {
  printf "${YELLOW}  ⚠ %s${RESET}\n" "$1" >&2
}

fail() {
  printf "${RED}  ✗ %s${RESET}\n" "$1" >&2
  exit 1
}

# ── Version derivation ────────────────────────────────────────────────────────
derive_version() {
  local tag
  tag="$(git -C "$ROOT_DIR" describe --tags --exact-match 2>/dev/null || true)"
  if [ -n "$tag" ]; then
    # Strip leading "v" if present (v1.2.3 → 1.2.3)
    echo "${tag#v}"
    return
  fi
  # No tag: use nearest ancestor tag + commit distance, or fall back to 1.0
  local base distance
  base="$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || true)"
  if [ -z "$base" ]; then
    echo "1.0"
    return
  fi
  distance="$(git -C "$ROOT_DIR" rev-list "${base}..HEAD" --count 2>/dev/null || echo "0")"
  local clean="${base#v}"
  if [ "$distance" -gt 0 ]; then
    echo "${clean}-dev.${distance}"
  else
    echo "$clean"
  fi
}

derive_build() {
  git -C "$ROOT_DIR" rev-list --count HEAD 2>/dev/null || echo "0"
}

APP_VERSION="${APP_VERSION:-$(derive_version)}"
APP_BUILD="${APP_BUILD:-$(derive_build)}"

# ── Tests ─────────────────────────────────────────────────────────────────────
if [ "$RUN_TESTS" = true ]; then
  stage "Test"
  (cd "$PKG_DIR" && swift test)
  info "Tests passed."
  stage_done
fi

# ── Build ─────────────────────────────────────────────────────────────────────
BIN_DIR="$(cd "$PKG_DIR" && swift build -c release --show-bin-path)"
BIN_SRC="$BIN_DIR/mdviewer"

if [ "$SKIP_BUILD" = true ]; then
  stage "Build (skipped — using existing binary)"
  if [ ! -x "$BIN_SRC" ]; then
    fail "No release binary found at $BIN_SRC — run 'just release' first"
  fi
  info "Using $BIN_SRC"
  stage_done
else
  stage "Build → $APP_NAME $APP_VERSION (build $APP_BUILD)"
  (cd "$PKG_DIR" && swift build -c release)
  if [ ! -x "$BIN_SRC" ]; then
    fail "Release binary not found: $BIN_SRC"
  fi
  stage_done
fi

# ── Strip ─────────────────────────────────────────────────────────────────────
if [ "$STRIP_BINARY" = true ]; then
  stage "Strip"
  BIN_STRIPPED="$(mktemp)"
  cp "$BIN_SRC" "$BIN_STRIPPED"
  xcrun strip -rSTx "$BIN_STRIPPED"
  BIN_SRC="$BIN_STRIPPED"
  stage_done
fi

# ── Package ───────────────────────────────────────────────────────────────────
stage "Package → $APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BIN_SRC" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# PkgInfo — required by some macOS launch paths
printf "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Info.plist — start from source, patch runtime values
cp "$INFO_PLIST_SRC" "$APP_BUNDLE/Contents/Info.plist"

plutil -replace CFBundleExecutable         -string "$APP_NAME"          "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleName               -string "$APP_NAME"          "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleDisplayName        -string "Markdown Viewer"    "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleIdentifier         -string "$BUNDLE_ID"         "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$APP_VERSION"       "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleVersion            -string "$APP_BUILD"         "$APP_BUNDLE/Contents/Info.plist"

# Ensure Retina support
plutil -replace NSHighResolutionCapable    -bool true                   "$APP_BUNDLE/Contents/Info.plist"

# App category (Productivity)
plutil -replace LSApplicationCategoryType  -string "public.app-category.productivity" \
  "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
  plutil -replace CFBundleIconFile -string "AppIcon.icns" "$APP_BUNDLE/Contents/Info.plist"
  plutil -replace CFBundleIconName -string "AppIcon"      "$APP_BUNDLE/Contents/Info.plist"
else
  warn "AppIcon.icns not found — bundle icon will be blank."
fi

# Validate plist
if ! plutil -lint "$APP_BUNDLE/Contents/Info.plist" >/dev/null 2>&1; then
  fail "Info.plist is invalid after patching."
fi

stage_done

# ── Ad-hoc codesign ───────────────────────────────────────────────────────────
if command -v codesign >/dev/null 2>&1; then
  stage "Sign (ad-hoc)"
  if ! codesign --force --deep --sign - "$APP_BUNDLE" 2>&1; then
    warn "codesign failed — bundle may not launch on hardened systems."
  fi
  stage_done
fi

# ── Summary ───────────────────────────────────────────────────────────────────
BUNDLE_SIZE="$(du -sh "$APP_BUNDLE" 2>/dev/null | cut -f1)"
if [ "$QUIET" = false ]; then
  printf "\n${BOLD}${CYAN}  App:     ${RESET}%s\n" "$APP_BUNDLE"
  printf "${BOLD}${CYAN}  Version: ${RESET}%s (build %s)\n" "$APP_VERSION" "$APP_BUILD"
  printf "${BOLD}${CYAN}  Size:    ${RESET}%s\n" "$BUNDLE_SIZE"
  printf "${BOLD}${CYAN}  ID:      ${RESET}%s\n\n" "$BUNDLE_ID"
fi

# ── Install ───────────────────────────────────────────────────────────────────
if [ "$INSTALL" = true ]; then
  stage "Install → $INSTALL_DIR/$APP_NAME.app"
  TARGET="$INSTALL_DIR/$APP_NAME.app"
  TARGET_BIN="$TARGET/Contents/MacOS/$APP_NAME"

  info "Stopping running instance (if any)..."
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
    osascript -e "tell application \"$APP_NAME\" to quit"     >/dev/null 2>&1 || true
  fi
  # Poll up to 3 s
  for _ in {1..30}; do
    pgrep -f "$TARGET_BIN" >/dev/null 2>&1 || break
    sleep 0.1
  done
  pgrep -f "$TARGET_BIN" >/dev/null 2>&1 && pkill -f "$TARGET_BIN" >/dev/null 2>&1 || true

  info "Copying bundle..."
  STAGING="$INSTALL_DIR/.${APP_NAME}.new.$$"
  rm -rf "$STAGING"
  ditto "$APP_BUNDLE" "$STAGING"
  rm -rf "$TARGET"
  mv "$STAGING" "$TARGET"
  xattr -dr com.apple.quarantine "$TARGET" >/dev/null 2>&1 || true

  stage_done

  # ── Post-install verification ─────────────────────────────────────────────
  stage "Verify"
  VERIFY_OK=true

  # Binary exists and is executable
  if [ -x "$TARGET/Contents/MacOS/$APP_NAME" ]; then
    info "Binary: OK"
  else
    warn "Binary missing or not executable"
    VERIFY_OK=false
  fi

  # Info.plist is valid
  if plutil -lint "$TARGET/Contents/Info.plist" >/dev/null 2>&1; then
    info "Info.plist: OK"
  else
    warn "Info.plist: invalid"
    VERIFY_OK=false
  fi

  # Codesign check
  if codesign --verify --deep --strict "$TARGET" 2>/dev/null; then
    info "Codesign: OK"
  else
    warn "Codesign: verification failed (may still work for local use)"
  fi

  if [ "$VERIFY_OK" = true ]; then
    stage_done
  else
    fail "Post-install verification failed"
  fi

  info "Installed: $TARGET"

  if [ "$OPEN_AFTER" = true ]; then
    open "$TARGET"
  fi
fi

# ── Total elapsed ─────────────────────────────────────────────────────────────
if [ "$QUIET" = false ]; then
  TOTAL_ELAPSED=$(( $(date +%s) - TOTAL_START ))
  printf "\n${BOLD}${GREEN}Done${RESET} ${DIM}(${TOTAL_ELAPSED}s total)${RESET}\n"
fi
