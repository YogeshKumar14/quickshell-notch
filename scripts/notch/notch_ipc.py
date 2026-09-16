#!/usr/bin/env python3
"""
notch_ipc.py — CLI Client for QuickShell Notch Unix Socket IPC.

Transmits control commands to the running QuickShell notch daemon via
/tmp/quickshell-notch.sock.

Supported Commands:
    toggle          - Toggle expanded/collapsed state
    close           - Collapse expanded notch
    nook            - Toggle Media Controller / NotchNook tab (PAGE 0)
    apps            - Toggle Application launcher tab (PAGE 1)
    tray            - Alias for apps (PAGE 1)
    walls           - Toggle Wallpaper selector tab (PAGE 2)
    stats           - Toggle Hardware Stats tab (PAGE 3)
    tab:<0-3>       - Direct switch to specific tab index (0..3)
    audio           - Toggle Audio routing drawer
    notifs          - Toggle Notification history drawer
    notifs:clear    - Clear all active notifications with staggered animation
    wifi            - Toggle Wi-Fi network selector drawer
    bluetooth       - Toggle Bluetooth device drawer
    bt              - Alias for bluetooth
    settings        - Toggle Settings window
    settings:tab:<0-3> - Open Settings window directly to tab index (0..3)
    reload_settings - Reload notch preferences from disk
    osd:vol:<0-150> - Display Volume OSD with percentage
    osd:bri:<0-100> - Display Brightness OSD with percentage

Usage:
    python3 notch_ipc.py toggle
    python3 notch_ipc.py nook
    python3 notch_ipc.py apps
    python3 notch_ipc.py walls
    python3 notch_ipc.py stats
    python3 notch_ipc.py tab:3
    python3 notch_ipc.py notifs
    python3 notch_ipc.py notifs:clear
    python3 notch_ipc.py settings
    python3 notch_ipc.py settings:tab:1
    python3 notch_ipc.py osd:vol:75
"""

import sys
import socket

SOCK_PATH = "/tmp/quickshell-notch.sock"


def send_command(cmd: str) -> None:
    """Send an IPC command string to the QuickShell notch socket.

    Args:
        cmd: Command string (e.g. "toggle", "close", "osd:vol:50").
    """
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(1.0)
            s.connect(SOCK_PATH)
            s.sendall(f"{cmd}\n".encode('utf-8'))
    except Exception as e:
        print(f"Error sending command '{cmd}' to quickshell notch socket: {e}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] in ("-h", "--help", "help"):
            print(__doc__.strip())
            sys.exit(0)
        send_command(sys.argv[1])
    else:
        send_command("toggle")
