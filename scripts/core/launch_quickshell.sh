#!/usr/bin/env bash

# Kill specific known helper processes (path-prefixed to avoid system-wide matches)
pkill -9 -f "/stream_audio_visualizer\.py" >/dev/null 2>&1
pkill -9 -f "/watch_workspaces\.py" >/dev/null 2>&1
# Kill SwayNC so QuickShell can claim the notification D-Bus interface
pkill -9 -x swaync >/dev/null 2>&1
pkill -9 -x swaync-client >/dev/null 2>&1
pkill -9 -x quickshell >/dev/null 2>&1

# Wait for quickshell to fully exit (releases the IPC socket and Hyprland layer)
for ((i = 0; i < 30; i++)); do
    if ! pgrep -x quickshell >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# Launch quickshell with explicit configuration path
exec quickshell -n -p "$HOME/.config/quickshell/shell.qml"
