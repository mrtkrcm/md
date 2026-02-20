#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INSTALL_APP=true \
QUIT_RUNNING_APP="${QUIT_RUNNING_APP:-true}" \
OPEN_APP_AFTER_INSTALL="${OPEN_APP_AFTER_INSTALL:-false}" \
INSTALL_DIR="${INSTALL_DIR:-/Applications}" \
RUN_TESTS="${RUN_TESTS:-auto}" \
bash "$ROOT_DIR/scripts/build.sh"

