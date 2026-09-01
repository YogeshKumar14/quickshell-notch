#!/usr/bin/env python3
"""
get_device_levels.py — Hardware Audio, Brightness, and Battery State Poller.

Queries system hardware states in a single batch process:
  - Master Volume level and mute state (via wpctl)
  - Microphone Input level and mute state (via wpctl)
  - Screen Brightness percentage (via brightnessctl / sysfs backlight)
  - Battery capacity percentage and charging status (via sysfs power_supply)

CLI Output:
    JSON object: {
        "volume": int, "volume_muted": bool,
        "mic": int, "mic_muted": bool,
        "brightness": int,
        "battery": int, "battery_status": str
    }
"""

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
        muted = "[MUTED]" in out
        m = re.search(r"(\d+(?:\.\d+)?)", out)
        if m:
            return int(round(float(m.group(1)) * 100)), muted
    except Exception:
        pass
    return None, False


def get_mic():
    try:
        out = subprocess.check_output(
            ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"],
            text=True, stderr=subprocess.DEVNULL, timeout=5
        )
        muted = "[MUTED]" in out
        m = re.search(r"(\d+(?:\.\d+)?)", out)
        if m:
            return int(round(float(m.group(1)) * 100)), muted
    except Exception:
        pass
    return None, False


def get_brightness():
    # Try fast direct sysfs read first (no subprocess overhead)
    for dev in glob.glob("/sys/class/backlight/*"):
        try:
            with open(os.path.join(dev, "brightness"), "r") as fp:
                cur = float(fp.read().strip())
            with open(os.path.join(dev, "max_brightness"), "r") as fp:
                mx = float(fp.read().strip())
            if mx > 0:
                return int(round((cur / mx) * 100))
        except Exception:
            pass
    try:
        out = subprocess.check_output(["brightnessctl", "-m"], text=True, stderr=subprocess.DEVNULL, timeout=5)
        for line in out.splitlines():
            parts = line.split(",")
            if len(parts) >= 4:
                return int(parts[3].rstrip("%"))
    except Exception:
        pass
    return None


def get_battery():
    candidates = sorted(glob.glob("/sys/class/power_supply/BAT*"))
    if not candidates:
        for p in glob.glob("/sys/class/power_supply/*"):
            try:
                with open(os.path.join(p, "type"), "r") as fp:
                    if fp.read().strip().lower() == "battery":
                        candidates.append(p)
            except Exception:
                pass
    for dev in candidates:
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
    vol_level, vol_muted = get_volume()
    mic_level, mic_muted = get_mic()
    print(json.dumps({
        "volume": vol_level,
        "volume_muted": vol_muted,
        "mic": mic_level,
        "mic_muted": mic_muted,
        "brightness": get_brightness(),
        "battery": capacity,
        "battery_status": status
    }), flush=True)


if __name__ == "__main__":
    main()
