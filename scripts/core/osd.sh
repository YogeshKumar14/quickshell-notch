#!/usr/bin/env bash
# ~/.config/quickshell/scripts/core/osd.sh

send_osd() {
    KIND="$1"
    VALUE="$2"
    [ -z "$VALUE" ] && return 0
    KIND="$KIND" VALUE="$VALUE" python3 - <<'PY'
import os, socket
try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(1.0)
    s.connect('/tmp/quickshell-notch.sock')
    s.sendall(f"osd:{os.environ['KIND']}:{os.environ['VALUE']}\n".encode())
    s.close()
except Exception:
    pass
PY
}

if [ "$1" == "volume" ]; then
    if [ "$2" == "up" ]; then
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    elif [ "$2" == "down" ]; then
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-
    fi
    # Wait 50ms for Pipewire to propagate the audio event
    sleep 0.05
    # Get current volume (rounded to nearest percent)
    VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2 * 100}')
    send_osd vol "$VOL"
elif [ "$1" == "brightness" ]; then
    if [ "$2" == "up" ]; then
        brightnessctl s +5%
    elif [ "$2" == "down" ]; then
        brightnessctl s 5%-
    fi
    # Wait 50ms for sysfs to propagate the backlight event
    sleep 0.05
    # Get current brightness percentage
    BRI=$(brightnessctl -m | head -n1 | awk -F',' '{print $4}' | tr -d '%')
    send_osd bri "$BRI"
fi
