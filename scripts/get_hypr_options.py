#!/usr/bin/env python3
import subprocess
import json

def main():
    options = [
        "general:gaps_in",
        "general:gaps_out",
        "decoration:rounding",
        "general:border_size",
        "decoration:blur:enabled",
        "general:col.active_border",
        "general:col.inactive_border",
        "general:layout",
        "animations:enabled",
        "decoration:active_opacity",
        "decoration:inactive_opacity",
        "decoration:shadow:enabled",
        "decoration:dim_inactive",
        "master:mfact"
    ]

    res = {}
    
    try:
        batch_cmd = ";".join(f"getoption {opt}" for opt in options)
        out = subprocess.check_output(["hyprctl", "-j", "--batch", batch_cmd], stderr=subprocess.DEVNULL).decode()
        
        # Parse the batch output: each option result is separated by newlines
        parts = [p.strip() for p in out.split("\n\n") if p.strip()]
        results = {}
        for p in parts:
            try:
                data = json.loads(p)
                opt_name = data.get("option")
                if opt_name:
                    results[opt_name] = data
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
    grad = ab.get("gradient", "ff89b4fa")
    color_part = grad.split()[0] if grad else "ff89b4fa"
    res["active_border"] = color_part

    # inactive_border
    ib = results.get("general:col.inactive_border", {})
    igrad = ib.get("gradient", "ff585b70")
    icolor_part = igrad.split()[0] if igrad else "ff585b70"
    res["inactive_border"] = icolor_part

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

    print(json.dumps(res))

if __name__ == "__main__":
    main()
