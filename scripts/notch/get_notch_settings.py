#!/usr/bin/env python3
import os
import json

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "notch_settings.json")

DEFAULTS = {
    "auto_close": 5000,
    "compact_width": 130,
    "expand_anim_type": "outback",
    "expand_tension": 4.5,
    "expand_damping": 0.28,
    "tab_anim_type": "spring",
    "tab_tension": 5.5,
    "tab_damping": 0.22,
    "dripping_ears": True,
    "clock_12h": False,
    "wall_duration": 0.5,
    "wall_type": "outer",
    "expanded_height": 420,
    "bottom_radius": 16,
    "app_columns": 4,
    "bar_shadow": True,
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
    "visualizer_dot_size": 4,
    "visualizer_pulsar_scale": 1.2,
    "visualizer_pause_delay": 1000,
    "stats_interval": 2000,
    "network_refresh": 5000,
    "osd_timeout": 2000,
    "clock_format": "h:mm A",
    "clock_font_size": 14,
    "battery_warning_threshold": 20
}

def main():
    if os.path.isfile(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as fp:
                data = json.load(fp)
                for k, v in DEFAULTS.items():
                    if k not in data:
                        data[k] = v
                print(json.dumps(data))
                return
        except Exception:
            pass
    
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_FILE, "w", encoding="utf-8") as fp:
        json.dump(DEFAULTS, fp)
    print(json.dumps(DEFAULTS))

if __name__ == "__main__":
    main()
