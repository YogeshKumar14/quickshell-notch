#!/usr/bin/env bash

# Non-blocking, single-instance wallpaper application with PID lockfile
TARGET_PIC="$1"

if [ -z "$TARGET_PIC" ] || [ ! -f "$TARGET_PIC" ]; then
    echo "Usage: apply_wallpaper.sh /path/to/image"
    exit 1
fi

# Non-blocking lock: if another apply_wallpaper instance is running, exit cleanly
exec 200>"/tmp/quickshell_wallpaper.lock"
flock -n 200 || exit 0

# Read transition duration and type from permanent config
SETTINGS_FILE="$HOME/.config/quickshell/notch_settings.json"
DURATION=0.5
TYPE="outer"

if [ -f "$SETTINGS_FILE" ]; then
    read -r DURATION TYPE <<< "$(python3 -c "import json; d=json.load(open('$SETTINGS_FILE')); print(f\"{d.get('wall_duration', 0.5)} {d.get('wall_type', 'outer')}\")" 2>/dev/null)"
fi

# 1. Ensure awww-daemon is running
awww query >/dev/null 2>&1 || awww-daemon --format xrgb &

# 2. Get focused monitor
FOCUSED_MONITOR=$(hyprctl monitors 2>/dev/null | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

# 3. Save current wallpaper path
mkdir -p "$HOME/.config/quickshell"
echo "$TARGET_PIC" > "$HOME/.config/quickshell/current_wallpaper"

# 4. Run awww img with custom duration and transition type
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

# 5. Run wallust quietly without hyprctl reload to ensure layer-shell stability
if command -v wallust >/dev/null 2>&1; then
    wallust run "$TARGET_PIC" >/dev/null 2>&1
fi
