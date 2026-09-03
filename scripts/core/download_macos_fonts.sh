#!/bin/bash
# download_macos_fonts.sh — Utility script to download Apple macOS SF Pro & SF Mono fonts.
#
# Usage:
#   bash scripts/core/download_macos_fonts.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FONTS_DIR="${BASE_DIR}/assets/fonts"
USER_FONTS_DIR="${HOME}/.local/share/fonts"

export BASE_DIR
export FONTS_DIR

mkdir -p "${FONTS_DIR}"

python3 - <<'EOF'
import os
import urllib.request
import sys

base_dir = os.environ.get("BASE_DIR", os.path.expanduser("~/.config/quickshell"))
fonts_dir = os.path.join(base_dir, "assets", "fonts")
os.makedirs(fonts_dir, exist_ok=True)

sf_pro_base = "https://raw.githubusercontent.com/sahibjotsaggu/San-Francisco-Pro-Fonts/master/"
sf_mono_base = "https://raw.githubusercontent.com/supercomputra/SF-Mono-Font/master/"

files = {
    # SF Pro Variable Font
    "SF-Pro.ttf": sf_pro_base + "SF-Pro.ttf",
    # SF Pro Text
    "SF-Pro-Text-Regular.otf": sf_pro_base + "SF-Pro-Text-Regular.otf",
    "SF-Pro-Text-Medium.otf": sf_pro_base + "SF-Pro-Text-Medium.otf",
    "SF-Pro-Text-Semibold.otf": sf_pro_base + "SF-Pro-Text-Semibold.otf",
    "SF-Pro-Text-Bold.otf": sf_pro_base + "SF-Pro-Text-Bold.otf",
    # SF Pro Display
    "SF-Pro-Display-Regular.otf": sf_pro_base + "SF-Pro-Display-Regular.otf",
    "SF-Pro-Display-Medium.otf": sf_pro_base + "SF-Pro-Display-Medium.otf",
    "SF-Pro-Display-Semibold.otf": sf_pro_base + "SF-Pro-Display-Semibold.otf",
    "SF-Pro-Display-Bold.otf": sf_pro_base + "SF-Pro-Display-Bold.otf",
    # SF Mono
    "SFMono-Regular.otf": sf_mono_base + "SFMono-Regular.otf",
    "SFMono-Medium.otf": sf_mono_base + "SFMono-Medium.otf",
    "SFMono-Semibold.otf": sf_mono_base + "SFMono-Semibold.otf",
    "SFMono-Bold.otf": sf_mono_base + "SFMono-Bold.otf",
}

for fname, url in files.items():
    dst = os.path.join(fonts_dir, fname)
    if not os.path.exists(dst) or os.path.getsize(dst) == 0:
        print(f"Downloading {fname}...")
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req) as resp, open(dst, "wb") as f:
            f.write(resp.read())
        print(f"Downloaded {fname} ({os.path.getsize(dst)} bytes)")
    else:
        print(f"Already exists: {fname}")

print("Font download complete.")
EOF

# Install to user font cache for system-wide and fontconfig access
mkdir -p "${USER_FONTS_DIR}/SF-Pro" "${USER_FONTS_DIR}/SF-Mono"
cp -f "${FONTS_DIR}"/SF-Pro* "${USER_FONTS_DIR}/SF-Pro/" 2>/dev/null || true
cp -f "${FONTS_DIR}"/SFMono* "${USER_FONTS_DIR}/SF-Mono/" 2>/dev/null || true

if command -v fc-cache >/dev/null 2>&1; then
    echo "Updating fontconfig cache..."
    fc-cache -f "${USER_FONTS_DIR}" >/dev/null 2>&1 || true
fi

echo "macOS SF Pro and SF Mono fonts installed successfully."
