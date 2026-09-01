#!/usr/bin/env python3
"""
get_hypr_options.py — Fast Batch Reader for Active Hyprland Options.

Executes a single batch `hyprctl --batch getoption ...` query for all
managed Hyprland configuration keys, parses JSON/text outputs tolerantly,
and normalizes values into standard representation for SettingsWindow.qml.

CLI Output:
    JSON object containing all active Hyprland options.
"""

import os
import sys
import subprocess
import json

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_keymap import ALL_HYPR_OPTIONS


def extract_color(grad, default):
    """Tolerant gradient parser: accepts a string ("aarrggbb deg") or a list
    of color strings (multi-color gradients) and returns the first color."""
    if isinstance(grad, list):
        grad = " ".join(str(c) for c in grad)
    if not isinstance(grad, str):
        return default
    parts = grad.split()
    return parts[0] if parts else default

def main():
    options = ALL_HYPR_OPTIONS

    res = {}
    
    results = {}
    try:
        batch_cmd = ";".join(f"getoption {opt}" for opt in options)
        out = subprocess.check_output(["hyprctl", "-j", "--batch", batch_cmd], stderr=subprocess.DEVNULL, timeout=5).decode()
        
        # Parse the batch output tolerantly: blank-line separated blocks, with
        # line-by-line fallback so format changes degrade gracefully
        parts = [p.strip() for p in out.split("\n\n") if p.strip()]
        for p in parts:
            try:
                data = json.loads(p)
                if isinstance(data, list):
                    for item in data:
                        if isinstance(item, dict) and item.get("option"):
                            results[item["option"]] = item
                    continue
                elif isinstance(data, dict) and data.get("option"):
                    results[data["option"]] = data
                    continue
            except Exception:
                pass
            for line in p.splitlines():
                try:
                    data = json.loads(line)
                    if isinstance(data, dict) and data.get("option"):
                        results[data["option"]] = data
                except Exception:
                    pass
    except Exception:
        results = {}

    # gaps_in
    gi = results.get("general:gaps_in", {})
    if "int" in gi:
        res["gaps_in"] = gi["int"]
    elif "css" in gi:
        p_list = gi["css"].split()
        res["gaps_in"] = int(p_list[0]) if p_list else 5
    else:
        res["gaps_in"] = 5

    # gaps_out
    go = results.get("general:gaps_out", {})
    if "int" in go:
        res["gaps_out"] = go["int"]
    elif "css" in go:
        p_list = go["css"].split()
        res["gaps_out"] = int(p_list[0]) if p_list else 10
    else:
        res["gaps_out"] = 10

    # rounding
    res["rounding"] = results.get("decoration:rounding", {}).get("int", 10)

    # border_size
    res["border_size"] = results.get("general:border_size", {}).get("int", 2)

    # blur_enabled
    res["blur_enabled"] = results.get("decoration:blur:enabled", {}).get("bool", True)

    # active_border
    ab = results.get("general:col.active_border", {})
    res["active_border"] = extract_color(ab.get("gradient"), "ff89b4fa")

    # inactive_border
    ib = results.get("general:col.inactive_border", {})
    res["inactive_border"] = extract_color(ib.get("gradient"), "ff585b70")

    # layout
    res["layout"] = results.get("general:layout", {}).get("str", "dwindle")

    # animations enabled
    res["animations_enabled"] = results.get("animations:enabled", {}).get("bool", True)

    # active_opacity
    res["active_opacity"] = results.get("decoration:active_opacity", {}).get("float", 1.0)

    # inactive_opacity
    res["inactive_opacity"] = results.get("decoration:inactive_opacity", {}).get("float", 1.0)

    # shadow_enabled
    res["shadow_enabled"] = results.get("decoration:shadow:enabled", {}).get("bool", True)

    # dim_inactive
    res["dim_inactive"] = results.get("decoration:dim_inactive", {}).get("bool", False)

    # master mfact (split ratio)
    res["master_ratio"] = results.get("master:mfact", {}).get("float", 0.55)

    # animation speed multiplier (placeholder)
    res["anim_speed"] = 1.0

    # blur size & passes
    res["blur_size"] = results.get("decoration:blur:size", {}).get("int", 8)
    res["blur_passes"] = results.get("decoration:blur:passes", {}).get("int", 3)

    # shadow range
    res["shadow_range"] = results.get("decoration:shadow:range", {}).get("int", 4)

    # input
    res["input_sensitivity"] = results.get("input:sensitivity", {}).get("float", 0.0)
    res["input_tap_to_click"] = results.get("input:touchpad:tap_to_click", {}).get("bool", False)
    res["input_natural_scroll"] = results.get("input:touchpad:natural_scroll", {}).get("bool", False)

    print(json.dumps(res))

if __name__ == "__main__":
    main()
