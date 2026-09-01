#!/usr/bin/env bash
# ~/.config/quickshell/scripts/core/osd.sh — Fast Zero-Delay OSD Dispatcher

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTCH_IPC="${SCRIPT_DIR}/../notch/notch_ipc.py"

send_osd() {
    local kind="$1"
    local val="$2"
    [ -z "$val" ] && return 0
    python3 "$NOTCH_IPC" "osd:${kind}:${val}" >/dev/null 2>&1 &
}

if [ "$1" == "volume" ]; then
    if [ "$2" == "up" ]; then
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    elif [ "$2" == "down" ]; then
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-
    fi
    VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%.0f", $2 * 100}')
    send_osd vol "$VOL"
elif [ "$1" == "brightness" ]; then
    if [ "$2" == "up" ]; then
        BRI=$(brightnessctl -m set +5% 2>/dev/null | head -n1 | awk -F',' '{print $4}' | tr -d '%')
    elif [ "$2" == "down" ]; then
        BRI=$(brightnessctl -m set 5%- 2>/dev/null | head -n1 | awk -F',' '{print $4}' | tr -d '%')
    fi
    send_osd bri "$BRI"
fi
