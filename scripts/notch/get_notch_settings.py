#!/usr/bin/env python3
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
    "expanded_height": 420,
    "bottom_radius": 16,
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

def main():
    data = dict(DEFAULTS)
    if os.path.isfile(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as fp:
                loaded = json.load(fp)
            if isinstance(loaded, dict):
                # One-time migration: clock_12h folded into clock_format so the
                # custom format field is the single source of truth.
                if "clock_12h" in loaded:
                    loaded["clock_format"] = "h:mm A" if loaded["clock_12h"] else "HH:mm"
                data.update(loaded)
                # Drop keys no longer known (dead settings round-tripped before)
                for k in [k for k in data if k not in DEFAULTS]:
                    del data[k]
                print(json.dumps(data))
                if data != loaded:
                    os.makedirs(CONFIG_DIR, exist_ok=True)
                    atomic_write(CONFIG_FILE, json.dumps(data, indent=2))
                return
        except Exception as e:
            backup = CONFIG_FILE + ".corrupt." + time.strftime("%Y%m%d%H%M%S")
            try:
                os.rename(CONFIG_FILE, backup)
                print(f"WARNING: unreadable settings file backed up to {backup}", file=sys.stderr)
            except Exception:
                print(f"WARNING: unreadable settings file could not be backed up: {e}", file=sys.stderr)

    os.makedirs(CONFIG_DIR, exist_ok=True)
    atomic_write(CONFIG_FILE, json.dumps(DEFAULTS, indent=2))
    print(json.dumps(DEFAULTS))

if __name__ == "__main__":
    main()
