#!/usr/bin/env python3
import subprocess
import json
import sys

def get_status():
    try:
        power_out = subprocess.check_output(["nmcli", "radio", "wifi"], stderr=subprocess.DEVNULL).decode().strip()
        is_on = (power_out == "enabled")
        
        active_ssid = ""
        if is_on:
            ssid_out = subprocess.check_output(["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"], stderr=subprocess.DEVNULL).decode()
            for line in ssid_out.splitlines():
                if line.startswith("yes:"):
                    active_ssid = line.split(":", 1)[1]
                    break
        
        networks = []
        if is_on:
            list_out = subprocess.check_output(["nmcli", "-t", "-f", "ssid,signal,security,active", "dev", "wifi", "list"], stderr=subprocess.DEVNULL).decode()
            seen_ssids = set()
            for line in list_out.splitlines():
                parts = line.split(":")
                if len(parts) >= 4:
                    ssid, signal, security, active = parts[0], parts[1], parts[2], parts[3]
                    if ssid and ssid not in seen_ssids:
                        seen_ssids.add(ssid)
                        networks.append({
                            "ssid": ssid,
                            "signal": int(signal) if signal.isdigit() else 0,
                            "security": security,
                            "active": (active == "yes")
                        })
        return {"power": is_on, "active": active_ssid, "networks": networks[:6]}
    except Exception:
        return {"power": False, "active": "", "networks": []}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        if action == "on":
            subprocess.run(["nmcli", "radio", "wifi", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "off":
            subprocess.run(["nmcli", "radio", "wifi", "off"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif action == "connect" and len(sys.argv) > 2:
            ssid = sys.argv[2]
            subprocess.run(["nmcli", "dev", "wifi", "connect", ssid], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(json.dumps(get_status()))
