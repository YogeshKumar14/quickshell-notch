#!/usr/bin/env bash
if [ "$QUICKSHELL_SANDBOX" = "1" ]; then
    echo "sandbox_skipped"
    exit 0
fi

TYPE="$1"
VAL="$2"

PERSIST_SCRIPT="$HOME/.config/quickshell/scripts/hyprland/persist_hypr_state.py"
APPLY_SCRIPT="$HOME/.config/quickshell/scripts/hyprland/apply_hypr_option.py"

# Map setting name to the hyprctl key (dotted path).
case "$TYPE" in
    gaps_in)            KEY="general:gaps_in" ;;
    gaps_out)           KEY="general:gaps_out" ;;
    rounding)           KEY="decoration:rounding" ;;
    border_size)        KEY="general:border_size" ;;
    blur)               KEY="decoration:blur:enabled" ;;
    active_border)      KEY="general:col.active_border" ;;
    inactive_border)    KEY="general:col.inactive_border" ;;
    layout)             KEY="general:layout" ;;
    animations)         KEY="animations:enabled" ;;
    active_opacity)     KEY="decoration:active_opacity" ;;
    inactive_opacity)   KEY="decoration:inactive_opacity" ;;
    shadow)             KEY="decoration:shadow:enabled" ;;
    dim_inactive)       KEY="decoration:dim_inactive" ;;
    master_ratio)       KEY="master:mfact" ;;
    input_sensitivity)  KEY="input:sensitivity" ;;
    input_tap_to_click) KEY="input:touchpad:tap_to_click" ;;
    input_natural_scroll) KEY="input:touchpad:natural_scroll" ;;
    shadow_range)       KEY="decoration:shadow:range" ;;
    blur_passes)        KEY="decoration:blur:passes" ;;
    blur_size)          KEY="decoration:blur:size" ;;
    reset_defaults)
        rm -f "$HOME/.config/hypr/quickshell_hypr.lua"
        rm -f "$HOME/.config/hypr/quickshell_hypr.conf"
        PYTHONPATH="$HOME/.config/quickshell/scripts/notch:$HOME/.config/quickshell/scripts/core" \
        python3 - <<'PY'
import json, os

from get_notch_settings import DEFAULTS
from atomic_write import atomic_write

cfg = os.path.expanduser('~/.config/quickshell/notch_settings.json')
atomic_write(cfg, json.dumps(DEFAULTS, indent=4))
PY
        rm -f "$HOME/.cache/quickshell/hypr_state.json"
        hyprctl reload
        exit 0
        ;;
    *)
        echo "Unknown option type: $TYPE"
        exit 1
        ;;
esac

# Apply live (keyword with eval fallback for non-legacy parsers).
if ! python3 "$APPLY_SCRIPT" "$KEY" "$VAL"; then
    echo "live apply failed for $TYPE; not persisting" >&2
    exit 1
fi

# Persist to lua + conf files for reboot durability only if the live apply succeeded
python3 "$PERSIST_SCRIPT" "$TYPE" "$VAL" || exit 1
echo "ok"
