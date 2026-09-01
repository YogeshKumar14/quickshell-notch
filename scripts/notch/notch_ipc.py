#!/usr/bin/env python3
"""
notch_ipc.py — CLI Client for QuickShell Notch Unix Socket IPC.

Transmits control commands to the running QuickShell notch daemon via
/tmp/quickshell-notch.sock.

Supported Commands:
    toggle          - Toggle expanded/collapsed state
    close           - Collapse expanded notch
    walls           - Toggle Wallpaper selector tab (PAGE 1)
    apps            - Toggle Application launcher tab (PAGE 2)
    osd:vol:<0-100> - Display Volume OSD with percentage
    osd:bri:<0-100> - Display Brightness OSD with percentage

Usage:
    python3 notch_ipc.py toggle
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
        send_command(sys.argv[1])
    else:
        send_command("toggle")
