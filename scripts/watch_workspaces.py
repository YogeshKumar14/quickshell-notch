#!/usr/bin/env python3
import os
import sys
import json
import time
import socket
import subprocess

def get_workspace_state():
    try:
        active_out = subprocess.check_output(["hyprctl", "-j", "activeworkspace"], stderr=subprocess.DEVNULL).decode()
        active_data = json.loads(active_out)
        active_id = active_data.get("id", 1)

        ws_out = subprocess.check_output(["hyprctl", "-j", "workspaces"], stderr=subprocess.DEVNULL).decode()
        ws_data = json.loads(ws_out)
        occupied = [w["id"] for w in ws_data if w.get("windows", 0) > 0]
        return {"active": active_id, "occupied": occupied}
    except Exception:
        return {"active": 1, "occupied": [1]}

def main():
    # Print initial state
    print(json.dumps(get_workspace_state()), flush=True)

    his = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    xdg = os.getenv("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")

    if not his:
        sys.exit(0)

    sock_path = os.path.join(xdg, "hypr", his, ".socket2.sock")

    relevant_events = (
        "workspace", "openwindow", "closewindow", "movewindow",
        "createworkspace", "destroyworkspace", "renameworkspace", "focusedmon"
    )

    # Resilient reconnect loop
    while True:
        if os.path.exists(sock_path):
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
                    client.connect(sock_path)
                    buffer = ""
                    while True:
                        data = client.recv(4096).decode('utf-8', errors='ignore')
                        if not data:
                            break
                        buffer += data
                        while "\n" in buffer:
                            line, buffer = buffer.split("\n", 1)
                            if any(line.startswith(ev) for ev in relevant_events):
                                print(json.dumps(get_workspace_state()), flush=True)
            except Exception:
                time.sleep(1)
        time.sleep(1)

if __name__ == "__main__":
    main()
