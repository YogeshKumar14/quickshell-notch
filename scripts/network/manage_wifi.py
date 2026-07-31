#!/usr/bin/env python3
import subprocess
import json
import sys
import signal
import ctypes

TIMEOUT = 5

def set_pdeathsig():
    try:
        libc = ctypes.CDLL("libc.so.6")
        libc.prctl(1, signal.SIGTERM)
    except Exception:
        pass

def get_status():
    try:
        power_out = subprocess.check_output(["nmcli", "radio", "wifi"], stderr=subprocess.DEVNULL, timeout=TIMEOUT).decode().strip()
        is_on = (power_out == "enabled")
        
        active_ssid = ""
        saved_ssids = set()
        if is_on:
            try:
                conn_out = subprocess.check_output(["nmcli", "-t", "-f", "name,type,active", "connection", "show"], stderr=subprocess.DEVNULL, timeout=TIMEOUT).decode()
                for line in conn_out.splitlines():
                    parts = line.split(":")
                    if len(parts) >= 3 and "wireless" in parts[1]:
                        saved_ssids.add(parts[0])
                        if parts[2] == "yes":
                            active_ssid = parts[0]
            except Exception:
                pass
        
        networks = []
        if is_on:
            list_out = subprocess.check_output(["nmcli", "-t", "-f", "ssid,signal,security,active", "dev", "wifi", "list"], stderr=subprocess.DEVNULL, timeout=TIMEOUT).decode()
            seen_ssids = set()
            for line in list_out.splitlines():
                parts = line.split(":")
                if len(parts) >= 4:
                    ssid, signal_strength, security, active = parts[0], parts[1], parts[2], parts[3]
                    if ssid and ssid not in seen_ssids:
                        seen_ssids.add(ssid)
                        is_active = (active == "yes" or (active_ssid and ssid == active_ssid))
                        networks.append({
                            "ssid": ssid,
                            "signal": int(signal_strength) if signal_strength.isdigit() else 0,
                            "security": security,
                            "active": is_active,
                            "saved": (ssid in saved_ssids)
                        })
            # Sort networks so the active one floats to the top
            networks.sort(key=lambda x: not x["active"])
            
        return {"power": is_on, "active": active_ssid, "networks": networks[:12]}
    except Exception:
        return {"power": False, "active": "", "networks": []}

def spawn(args):
    return subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, preexec_fn=set_pdeathsig)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        if action == "on":
            subprocess.run(["nmcli", "radio", "wifi", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=TIMEOUT)
        elif action == "off":
            subprocess.run(["nmcli", "radio", "wifi", "off"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=TIMEOUT)
        elif action == "connect" and len(sys.argv) > 2:
            ssid = sys.argv[2]
            password = sys.argv[3] if len(sys.argv) > 3 else None
            if password:
                spawn(["nmcli", "dev", "wifi", "connect", ssid, "password", password])
            else:
                spawn(["nmcli", "dev", "wifi", "connect", ssid])
    print(json.dumps(get_status()))
