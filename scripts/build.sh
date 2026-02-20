#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/mdviewer"
APP_NAME="md"
APP_BUNDLE="$ROOT_DIR/release/$APP_NAME.app"
INFO_PLIST_SOURCE="$PKG_DIR/Sources/mdviewer/Info.plist"
BUNDLE_ID="com.example.$APP_NAME"

INSTALL_APP="${INSTALL_APP:-false}"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
QUIT_RUNNING_APP="${QUIT_RUNNING_APP:-true}"
OPEN_APP_AFTER_INSTALL="${OPEN_APP_AFTER_INSTALL:-false}"

normalize_bool() {
  case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on) echo "true" ;;
    0|false|no|off) echo "false" ;;
    *)
      echo "Invalid boolean value: $1" >&2
      exit 1
      ;;
  esac
}

INSTALL_APP="$(normalize_bool "$INSTALL_APP")"
QUIT_RUNNING_APP="$(normalize_bool "$QUIT_RUNNING_APP")"
OPEN_APP_AFTER_INSTALL="$(normalize_bool "$OPEN_APP_AFTER_INSTALL")"

cd "$PKG_DIR"

echo "Building mdviewer (release)..."
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="$BIN_DIR/mdviewer"
if [ ! -x "$BIN_PATH" ]; then
  echo "Release binary not found at: $BIN_PATH"
  exit 1
fi

echo "Packaging $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$INFO_PLIST_SOURCE" "$APP_BUNDLE/Contents/Info.plist"

plutil -replace CFBundleExecutable -string "$APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleName -string "$APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string "$APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP_BUNDLE/Contents/Info.plist"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

echo "Release app ready: $APP_BUNDLE"

RUN_TESTS=${RUN_TESTS:-auto}
SHOULD_RUN_TESTS=false

if [ "$RUN_TESTS" = "0" ] || [ "$RUN_TESTS" = "false" ] || [ "$RUN_TESTS" = "no" ]; then
  echo "Skipping tests (RUN_TESTS=$RUN_TESTS)."
elif [ "$RUN_TESTS" = "1" ] || [ "$RUN_TESTS" = "true" ] || [ "$RUN_TESTS" = "yes" ]; then
  SHOULD_RUN_TESTS=true
elif xcodebuild -version >/dev/null 2>&1; then
  SHOULD_RUN_TESTS=true
else
  echo "Skipping tests: full Xcode is not configured (Command Line Tools only)."
  echo "Set RUN_TESTS=true to force tests, or configure Xcode:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi

if [ "$SHOULD_RUN_TESTS" = true ]; then
  echo "Running tests..."
  swift test
fi

if [ "$INSTALL_APP" = true ]; then
  TARGET_APP_BUNDLE="$INSTALL_DIR/$APP_NAME.app"
  TARGET_EXECUTABLE="$TARGET_APP_BUNDLE/Contents/MacOS/$APP_NAME"

  if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating install directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
  fi

  if [ "$QUIT_RUNNING_APP" = true ]; then
    echo "Stopping running app (if open)..."
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
      osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
    fi

    for _ in {1..30}; do
      if ! pgrep -f "$TARGET_EXECUTABLE" >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done

    if pgrep -f "$TARGET_EXECUTABLE" >/dev/null 2>&1; then
      pkill -f "$TARGET_EXECUTABLE" >/dev/null 2>&1 || true
      sleep 0.2
    fi
  fi

  echo "Installing app to: $TARGET_APP_BUNDLE"
  TMP_TARGET="$INSTALL_DIR/.${APP_NAME}.app.new.$$"
  rm -rf "$TMP_TARGET"

  if ! ditto "$APP_BUNDLE" "$TMP_TARGET"; then
    echo "Failed to copy app bundle to staging path: $TMP_TARGET"
    exit 1
  fi

  if [ -d "$TARGET_APP_BUNDLE" ]; then
    rm -rf "$TARGET_APP_BUNDLE"
  fi
  mv "$TMP_TARGET" "$TARGET_APP_BUNDLE"

  xattr -dr com.apple.quarantine "$TARGET_APP_BUNDLE" >/dev/null 2>&1 || true

  echo "Installed: $TARGET_APP_BUNDLE"
  if [ "$OPEN_APP_AFTER_INSTALL" = true ]; then
    open "$TARGET_APP_BUNDLE"
  fi
fi
