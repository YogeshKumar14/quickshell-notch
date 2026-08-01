#!/usr/bin/env python3
import glob
import json
import os
import re
import subprocess


def get_volume():
    try:
        out = subprocess.check_output(
            ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
            text=True, stderr=subprocess.DEVNULL, timeout=5
        )
        m = re.search(r"(\d+(?:\.\d+)?)", out)
        if m:
            return int(round(float(m.group(1)) * 100))
    except Exception:
        pass
    return None


def get_mic():
    try:
        out = subprocess.check_output(
            ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"],
            text=True, stderr=subprocess.DEVNULL, timeout=5
        )
        m = re.search(r"(\d+(?:\.\d+)?)", out)
        if m:
            return int(round(float(m.group(1)) * 100))
    except Exception:
        pass
    return None


def get_brightness():
    try:
        out = subprocess.check_output(["brightnessctl", "-m"], text=True, stderr=subprocess.DEVNULL, timeout=5)
        parts = out.split(",")
        if len(parts) >= 4:
            return int(parts[3].rstrip("%"))
    except Exception:
        pass
    return None


def get_battery():
    for dev in sorted(glob.glob("/sys/class/power_supply/BAT*")):
        try:
            with open(os.path.join(dev, "capacity"), "r") as fp:
                capacity = int(fp.read().strip())
            with open(os.path.join(dev, "status"), "r") as fp:
                status = fp.read().strip()
            return capacity, status
        except Exception:
            continue
    return None, "Unknown"


def main():
    capacity, status = get_battery()
    print(json.dumps({
        "volume": get_volume(),
        "mic": get_mic(),
        "brightness": get_brightness(),
        "battery": capacity,
        "battery_status": status
    }), flush=True)


if __name__ == "__main__":
    main()
