#!/bin/bash
# download_m3_icons.sh — Legacy redirect to download_macos_icons.sh
#
# Usage:
#   bash scripts/core/download_m3_icons.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${SCRIPT_DIR}/download_macos_icons.sh"
