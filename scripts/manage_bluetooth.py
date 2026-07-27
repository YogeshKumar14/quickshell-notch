#!/usr/bin/env python3
import subprocess
import json
import sys

def get_status():
    try:
        show_out = subprocess.check_output(["bluetoothctl", "show"], stderr=subprocess.DEVNULL).decode()
        is_on = "Powered: yes" in show_out
        
        devices = []
        if is_on:
            devices_out = subprocess.check_output(["bluetoothctl", "devices"], stderr=subprocess.DEVNULL).decode()
            for line in devices_out.splitlines():
                parts = line.split(" ", 2)
                if len(parts) >= 3:
                    mac, name = parts[1], parts[2]
                    info_out = subprocess.check_output(["bluetoothctl", "info", mac], stderr=subprocess.DEVNULL).decode()
                    is_connected = "Connected: yes" in info_out
                    devices.append({
                        "mac": mac,
                        "name": name,
                        "connected": is_connected
                    })
        return {"power": is_on, "devices": devices[:5]}
    except Exception:
        return {"power": False, "devices": []}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        if action == "on":
            subprocess.run(["bluetoothctl", "power", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "off":
            subprocess.run(["bluetoothctl", "power", "off"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "toggle_conn" and len(sys.argv) > 2:
            mac = sys.argv[2]
            try:
                info = subprocess.check_output(["bluetoothctl", "info", mac], stderr=subprocess.DEVNULL).decode()
                if "Connected: yes" in info:
                    subprocess.Popen(["bluetoothctl", "disconnect", mac], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                else:
                    subprocess.Popen(["bluetoothctl", "connect", mac], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass
    print(json.dumps(get_status()))
