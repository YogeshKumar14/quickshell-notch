#!/usr/bin/env python3
"""
get_notch_settings.py — Settings Manager & Schema Migrator for QuickShell Notch.

Maintains default settings schema, loads user preferences from
~/.config/quickshell/notch_settings.json, performs automatic schema migration
for newly introduced keys, and prunes deprecated keys.

CLI Output:
    JSON object containing all active notch configuration options.
"""

import os
import sys
import json
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "core"))
from atomic_write import atomic_write

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "notch_settings.json")

DEFAULTS = {
    "auto_close": 5000,
    "compact_width": 130,
    "expand_tension": 4.5,
    "expand_damping": 0.28,
    "tab_tension": 5.5,
    "tab_damping": 0.22,
    "dripping_ears": True,
    "wall_duration": 0.5,
    "wall_type": "outer",
    "expanded_height": 106,
    "bottom_radius": 22,
    "app_columns": 4,
    "workspace_overlay": True,
    "workspace_timeout": 2500,
    "ws_anim_type": "stretch",
    "button_anims": True,
    "button_speed": 180,
    "visualizer_enabled": True,
    "visualizer_style": "bars",
    "visualizer_height": 16,
    "visualizer_timeout": 0,
    "visualizer_bar_count": 12,
    "visualizer_wave_width": 2,
    "visualizer_pulsar_scale": 1.2,
    "visualizer_pause_delay": 1000,
    "stats_interval": 2000,
    "osd_timeout": 2000,
    "clock_format": "h:mm A",
    "clock_font_size": 14,
    "battery_warning_threshold": 20,
    "wallpaper_dir": "",
    "highlight_anim_type": "spring",
    "highlight_spring_tension": 5.5,
    "highlight_spring_damping": 0.25,
    "grid_anim_duration": 120
}

def coerce_value(key, val):
    if key not in DEFAULTS:
        return None
    default = DEFAULTS[key]
    try:
        if isinstance(default, bool):
            return str(val).lower() == "true"
        if isinstance(default, int):
            return int(float(val))
        if isinstance(default, float):
            return float(val)
    except (ValueError, TypeError):
        return default
    return val

def load_settings(config_file: str = CONFIG_FILE) -> dict:
    """Load settings from config_file, applying defaults and schema migration."""
    data = dict(DEFAULTS)
    if os.path.isfile(config_file):
        try:
            with open(config_file, "r", encoding="utf-8") as fp:
                loaded = json.load(fp)
            if isinstance(loaded, dict):
                # One-time migration: clock_12h folded into clock_format
                if "clock_12h" in loaded:
                    loaded["clock_format"] = "h:mm A" if loaded["clock_12h"] else "HH:mm"
                for k, v in loaded.items():
                    if k in DEFAULTS:
                        coerced = coerce_value(k, v)
                        data[k] = coerced if coerced is not None else DEFAULTS[k]
                return data
        except Exception:
            pass
    return data


def main():
    data = load_settings(CONFIG_FILE)
    if not os.path.isfile(CONFIG_FILE):
        os.makedirs(CONFIG_DIR, exist_ok=True)
        atomic_write(CONFIG_FILE, json.dumps(DEFAULTS, indent=2))
    print(json.dumps(data))


if __name__ == "__main__":
    main()
