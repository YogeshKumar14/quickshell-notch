#!/usr/bin/env bash
# Read wallust color4 (accent) from ~/.cache/wal/colors.sh safely without executing code
# Output: hex color string like #79849E

COLORS_FILE="$HOME/.cache/wal/colors.sh"

if [ -f "$COLORS_FILE" ]; then
    COLOR4=$(grep -E "^color4=['\"]?#[0-9a-fA-F]{6}['\"]?" "$COLORS_FILE" 2>/dev/null | head -n1 | sed -E "s/^color4=['\"]?([^'\"]+)['\"]?/\1/")
    echo "${COLOR4:-#0A84FF}"
else
    echo "#0A84FF"
fi
