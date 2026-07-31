#!/bin/bash
# sandbox.sh - Launches a temporary quickshell instance for UI testing without altering the live desktop configuration

export QUICKSHELL_SANDBOX=1

SANDBOX_PIDFILE="/tmp/quickshell-sandbox.pid"

echo "========================================="
echo "Quickshell Sandbox Environment Initialized"
echo "Live system settings will not be modified."
echo "========================================="

# Kill only a previously launched sandbox instance (PID-targeted — never the live bar)
if [ -f "$SANDBOX_PIDFILE" ]; then
    kill "$(cat "$SANDBOX_PIDFILE")" 2>/dev/null || true
    rm -f "$SANDBOX_PIDFILE"
fi

# Launch the shell
quickshell -n -p "$HOME/.config/quickshell/shell.qml" &
echo $! > "$SANDBOX_PIDFILE"
wait
rm -f "$SANDBOX_PIDFILE"
