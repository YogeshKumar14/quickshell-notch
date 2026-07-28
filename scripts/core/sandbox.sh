#!/bin/bash
# sandbox.sh - Launches a temporary quickshell instance for UI testing without altering the live desktop configuration

export QUICKSHELL_SANDBOX=1

echo "========================================="
echo "Quickshell Sandbox Environment Initialized"
echo "Live system settings will not be modified."
echo "========================================="

# Kill any existing sandbox instance
pkill -f "quickshell -n -p .*shell.qml" || true

# Launch the shell
quickshell -n -p ~/.config/quickshell/shell.qml
