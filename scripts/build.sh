#!/bin/bash
# build.sh — build, package, and optionally install md.app
#
# Usage:
#   scripts/build.sh [--install] [--open] [--no-tests] [--no-strip]
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
INSTALL=false
OPEN_AFTER=false
RUN_TESTS=true
STRIP_BINARY=true

for arg in "$@"; do
  case "$arg" in
    --install)    INSTALL=true ;;
    --open)       OPEN_AFTER=true ;;
    --no-tests)   RUN_TESTS=false ;;
    --no-strip)   STRIP_BINARY=false ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: scripts/build.sh [--install] [--open] [--no-tests] [--no-strip]" >&2
      exit 1
      ;;
  esac
done

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
  echo "Running tests..."
  (cd "$PKG_DIR" && swift test)
  echo "Tests passed."
fi

# ── Build ─────────────────────────────────────────────────────────────────────
echo "Building $APP_NAME $APP_VERSION (build $APP_BUILD)..."
(cd "$PKG_DIR" && swift build -c release)

BIN_DIR="$(cd "$PKG_DIR" && swift build -c release --show-bin-path)"
BIN_SRC="$BIN_DIR/mdviewer"
if [ ! -x "$BIN_SRC" ]; then
  echo "Release binary not found: $BIN_SRC" >&2
  exit 1
fi

# ── Strip ─────────────────────────────────────────────────────────────────────
if [ "$STRIP_BINARY" = true ]; then
  echo "Stripping binary..."
  BIN_STRIPPED="$(mktemp)"
  cp "$BIN_SRC" "$BIN_STRIPPED"
  xcrun strip -rSTx "$BIN_STRIPPED"
  BIN_SRC="$BIN_STRIPPED"
fi

# ── Package ───────────────────────────────────────────────────────────────────
echo "Packaging $APP_NAME.app..."
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
  echo "Warning: AppIcon.icns not found — bundle icon will be blank." >&2
fi

# Validate plist
if ! plutil -lint "$APP_BUNDLE/Contents/Info.plist" >/dev/null 2>&1; then
  echo "Error: Info.plist is invalid after patching." >&2
  plutil -lint "$APP_BUNDLE/Contents/Info.plist" >&2
  exit 1
fi

# ── Ad-hoc codesign ───────────────────────────────────────────────────────────
# Ad-hoc signing satisfies Gatekeeper for local use; replace "-" with a
# Developer ID certificate identity for distribution.
if command -v codesign >/dev/null 2>&1; then
  echo "Signing bundle (ad-hoc)..."
  if ! codesign --force --deep --sign - "$APP_BUNDLE" 2>&1; then
    echo "Warning: codesign failed — bundle may not launch on hardened systems." >&2
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
BUNDLE_SIZE="$(du -sh "$APP_BUNDLE" 2>/dev/null | cut -f1)"
echo ""
echo "  App:     $APP_BUNDLE"
echo "  Version: $APP_VERSION (build $APP_BUILD)"
echo "  Size:    $BUNDLE_SIZE"
echo "  ID:      $BUNDLE_ID"
echo ""

# ── Install ───────────────────────────────────────────────────────────────────
if [ "$INSTALL" = true ]; then
  TARGET="$INSTALL_DIR/$APP_NAME.app"
  TARGET_BIN="$TARGET/Contents/MacOS/$APP_NAME"

  echo "Stopping running instance (if any)..."
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

  echo "Installing to $TARGET..."
  STAGING="$INSTALL_DIR/.${APP_NAME}.new.$$"
  rm -rf "$STAGING"
  ditto "$APP_BUNDLE" "$STAGING"
  rm -rf "$TARGET"
  mv "$STAGING" "$TARGET"
  xattr -dr com.apple.quarantine "$TARGET" >/dev/null 2>&1 || true

  echo "Installed: $TARGET"

  if [ "$OPEN_AFTER" = true ]; then
    open "$TARGET"
  fi
fi
