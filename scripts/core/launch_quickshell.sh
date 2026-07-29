#!/usr/bin/env bash

# Launcher script to enforce single-instance quickshell and prevent duplicate processes

# Kill existing quickshell and background helpers
pkill -9 -f cava >/dev/null 2>&1
pkill -9 -f stream_audio_visualizer.py >/dev/null 2>&1
pkill -9 -f watch_workspaces.py >/dev/null 2>&1
# Kill SwayNC so QuickShell can claim the notification D-Bus interface
pkill -9 -x swaync >/dev/null 2>&1
pkill -9 -x swaync-client >/dev/null 2>&1
pkill -9 -x quickshell >/dev/null 2>&1
sleep 0.3

# Launch quickshell with explicit configuration path
exec quickshell -n -p "$HOME/.config/quickshell/shell.qml"
