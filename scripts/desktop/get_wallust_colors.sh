#!/usr/bin/env bash
# Read wallust color4 (accent) from ~/.cache/wal/colors.sh
# Output: hex color string like #79849E

COLORS_FILE="$HOME/.cache/wal/colors.sh"

if [ -f "$COLORS_FILE" ]; then
    source "$COLORS_FILE"
    echo "${color4:-#0A84FF}"
else
    echo "#0A84FF"
fi
