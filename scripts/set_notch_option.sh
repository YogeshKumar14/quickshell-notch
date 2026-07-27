#!/usr/bin/env bash
KEY="$1"
VAL="$2"

CONFIG_FILE="$HOME/.config/quickshell/notch_settings.json"
mkdir -p "$HOME/.config/quickshell"

python3 -c "
import os, json
file_path = os.path.expanduser('$CONFIG_FILE')
data = {}
if os.path.isfile(file_path):
    try:
        with open(file_path, 'r') as fp:
            data = json.load(fp)
    except Exception: pass

key = '$KEY'
val = '$VAL'

if key in ['auto_close', 'compact_width', 'expanded_height', 'bottom_radius', 'app_columns', 'workspace_timeout', 'button_speed', 'visualizer_height', 'visualizer_timeout', 'network_refresh']:
    data[key] = int(val)
elif key in ['expand_tension', 'expand_damping', 'tab_tension', 'tab_damping', 'wall_duration']:
    data[key] = float(val)
elif key in ['dripping_ears', 'clock_12h', 'bar_shadow', 'workspace_overlay', 'button_anims', 'visualizer_enabled']:
    data[key] = val.lower() == 'true'
else:
    data[key] = val

with open(file_path, 'w') as fp:
    json.dump(data, fp)
"
