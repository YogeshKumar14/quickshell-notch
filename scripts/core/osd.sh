#!/usr/bin/env bash
# ~/.config/quickshell/scripts/core/osd.sh

if [ "$1" == "volume" ]; then
    if [ "$2" == "up" ]; then
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    elif [ "$2" == "down" ]; then
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-
    fi
    # Wait 50ms for Pipewire to propagate the audio event
    sleep 0.05
    # Get current volume
    VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')
    python3 -c "import socket; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect('/tmp/quickshell-notch.sock'); s.sendall(b'osd:vol:${VOL%.*}\n'); s.close()"
elif [ "$1" == "brightness" ]; then
    if [ "$2" == "up" ]; then
        brightnessctl s +5%
    elif [ "$2" == "down" ]; then
        brightnessctl s 5%-
    fi
    # Wait 50ms for sysfs to propagate the backlight event
    sleep 0.05
    # Get current brightness percentage
    BRI=$(brightnessctl i | grep -oP '\(\K[0-9]+(?=%\))')
    python3 -c "import socket; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect('/tmp/quickshell-notch.sock'); s.sendall(b'osd:bri:${BRI}\n'); s.close()"
fi
