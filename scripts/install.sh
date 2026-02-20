#!/bin/bash
# install.sh — build, package, and install md.app to /Applications
#
# Usage:
#   scripts/install.sh [--open] [--no-tests]
#
# Delegates to build.sh with --install. All build.sh flags and environment
# variables (INSTALL_DIR, BUNDLE_ID, APP_VERSION) are supported.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$ROOT_DIR/scripts/build.sh" --install "$@"
