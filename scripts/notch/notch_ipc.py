#!/usr/bin/env python3
import sys
import socket

SOCK_PATH = "/tmp/quickshell-notch.sock"

def send_command(cmd):
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
