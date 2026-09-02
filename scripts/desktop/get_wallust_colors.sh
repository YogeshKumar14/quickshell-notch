#!/usr/bin/env bash
# Read wallust color4 (accent) from ~/.cache/wal/colors.sh safely without executing code
# Output: hex color string like #79849E

COLORS_FILE="$HOME/.cache/wal/colors.sh"
LUA_FILE="$HOME/.config/hypr/wallust/wallust-hyprland.lua"

# 1. Primary source: ~/.cache/wal/colors.sh
if [ -f "$COLORS_FILE" ]; then
    COLOR4=$(grep -E "^color4=['\"]?#[0-9a-fA-F]{6}['\"]?" "$COLORS_FILE" 2>/dev/null | head -n1 | sed -E "s/^color4=['\"]?([^'\"]+)['\"]?/\1/")
    if [[ "$COLOR4" =~ ^#[0-9a-fA-F]{6}$ ]]; then
        echo "$COLOR4"
        exit 0
    fi
fi

# 2. Secondary fallback: ~/.config/hypr/wallust/wallust-hyprland.lua
if [ -f "$LUA_FILE" ]; then
    COLOR4_HEX=$(grep -E 'colors\.color4\s*=\s*"rgb\([0-9a-fA-F]{6}\)"' "$LUA_FILE" 2>/dev/null | head -n1 | sed -E 's/.*"rgb\(([0-9a-fA-F]{6})\)".*/#\1/')
    if [[ "$COLOR4_HEX" =~ ^#[0-9a-fA-F]{6}$ ]]; then
        echo "$COLOR4_HEX"
        exit 0
    fi
fi

# 3. Default fallback
echo "#0A84FF"
