#!/usr/bin/env bash

# Non-blocking, single-instance wallpaper application with PID lockfile
TARGET_PIC="$1"

if [ -z "$TARGET_PIC" ] || [ ! -f "$TARGET_PIC" ]; then
    echo "Usage: apply_wallpaper.sh /path/to/image" >&2
    exit 1
fi

# Non-blocking lock: if another apply_wallpaper instance is running, exit cleanly
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_wallpaper_${UID:-0}.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

# Read transition duration and type from permanent config
SETTINGS_FILE="$HOME/.config/quickshell/notch_settings.json"
DURATION=0.5
TYPE="outer"

if [ -f "$SETTINGS_FILE" ]; then
    PARSED=$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(f\"{d.get('wall_duration', 0.5)} {d.get('wall_type', 'outer') or 'outer'}\")
" "$SETTINGS_FILE" 2>/dev/null)
    if [ -n "$PARSED" ]; then
        read -r DURATION TYPE <<< "$PARSED"
    fi
fi
DURATION="${DURATION:-0.5}"
TYPE="${TYPE:-outer}"

# 1. Ensure awww-daemon is running (wait for it to be ready)
if ! awww query >/dev/null 2>&1; then
    awww-daemon --format xrgb &
    for _ in $(seq 1 50); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

# 2. Get focused monitor
FOCUSED_MONITOR=$(hyprctl monitors 2>/dev/null | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

# 3. Apply wallpaper (only persist the path on success)
if [ "$TYPE" = "none" ]; then
    if [ -n "$FOCUSED_MONITOR" ]; then
        awww img -o "$FOCUSED_MONITOR" "$TARGET_PIC" --transition-type none
    else
        awww img "$TARGET_PIC" --transition-type none
    fi
else
    if [ -n "$FOCUSED_MONITOR" ]; then
        awww img -o "$FOCUSED_MONITOR" "$TARGET_PIC" --transition-fps 60 --transition-type "$TYPE" --transition-step 90 --transition-duration "$DURATION"
    else
        awww img "$TARGET_PIC" --transition-fps 60 --transition-type "$TYPE" --transition-step 90 --transition-duration "$DURATION"
    fi
fi
APPLY_STATUS=$?

if [ "$APPLY_STATUS" -ne 0 ]; then
    echo "awww img failed (exit $APPLY_STATUS); wallpaper not applied" >&2
    exit 1
fi

# 4. Save current wallpaper path (atomically)
mkdir -p "$HOME/.config/quickshell"
CURRENT_FILE="$HOME/.config/quickshell/current_wallpaper"
TMP_FILE="$CURRENT_FILE.tmp"
echo "$TARGET_PIC" > "$TMP_FILE"
mv "$TMP_FILE" "$CURRENT_FILE"

# 5. Run wallust quietly without hyprctl reload to ensure layer-shell stability
if command -v wallust >/dev/null 2>&1; then
    wallust run "$TARGET_PIC" >/dev/null 2>&1
fi
