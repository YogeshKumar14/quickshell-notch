#!/usr/bin/env python3
import subprocess
import json
import sys
import signal
import ctypes

import re

TIMEOUT = 5
CONNECT_TIMEOUT = 15
MAC_REGEX = re.compile(r"^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$")

def is_valid_mac(mac_str):
    return bool(MAC_REGEX.match(mac_str.strip()))

def set_pdeathsig():
    try:
        libc = ctypes.CDLL("libc.so.6")
        libc.prctl(1, signal.SIGTERM)
    except Exception:
        pass

def get_status():
    try:
        show_out = subprocess.check_output(["bluetoothctl", "show"], stderr=subprocess.DEVNULL, timeout=TIMEOUT).decode()
        is_on = "Powered: yes" in show_out
        
        devices = []
        if is_on:
            connected_macs = set()
            try:
                conn_out = subprocess.check_output(["bluetoothctl", "devices", "Connected"], stderr=subprocess.DEVNULL, timeout=TIMEOUT).decode()
                for line in conn_out.splitlines():
                    parts = line.split(" ")
                    if len(parts) >= 3 and parts[0] == "Device":
                        connected_macs.add(parts[1])
            except Exception:
                pass

            try:
                devices_out = subprocess.check_output(["bluetoothctl", "devices"], stderr=subprocess.DEVNULL, timeout=TIMEOUT).decode()
                for line in devices_out.splitlines():
                    parts = line.split(" ", 2)
                    if len(parts) >= 3 and parts[0] == "Device":
                        mac, name = parts[1], parts[2]
                        is_connected = mac in connected_macs
                        devices.append({
                            "mac": mac,
                            "name": name,
                            "connected": is_connected
                        })
            except Exception:
                pass
        return {"power": is_on, "devices": devices[:10]}
    except Exception:
        return {"power": False, "devices": []}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        if action == "on":
            subprocess.run(["bluetoothctl", "power", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=TIMEOUT)
        elif action == "off":
            subprocess.run(["bluetoothctl", "power", "off"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=TIMEOUT)
        elif action == "toggle_conn" and len(sys.argv) > 2:
            mac = sys.argv[2].strip()
            if is_valid_mac(mac):
                try:
                    info = subprocess.check_output(["bluetoothctl", "info", mac], stderr=subprocess.DEVNULL, timeout=TIMEOUT).decode()
                    if "Connected: yes" in info:
                        subprocess.run(["bluetoothctl", "disconnect", mac], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=CONNECT_TIMEOUT, preexec_fn=set_pdeathsig)
                    else:
                        subprocess.run(["bluetoothctl", "connect", mac], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=CONNECT_TIMEOUT, preexec_fn=set_pdeathsig)
                except Exception:
                    pass
    print(json.dumps(get_status()))
