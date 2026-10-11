#!/usr/bin/env bash
# set_hypr_option.sh — CLI Helper to Persist & Apply Individual Hyprland Options.
#
# Usage:
#   bash set_hypr_option.sh <setting_name> <value>
#   bash set_hypr_option.sh reset_defaults ""

if [ "$QUICKSHELL_SANDBOX" = "1" ]; then
    echo "sandbox_skipped"
    exit 0
fi

TYPE="$1"
VAL="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSIST_SCRIPT="${SCRIPT_DIR}/persist_hypr_state.py"
APPLY_SCRIPT="${SCRIPT_DIR}/apply_hypr_option.py"

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
        PYTHONPATH="$HOME/.config/quickshell/scripts/notch:$HOME/.config/quickshell/scripts/core:$HOME/.config/quickshell/scripts/hyprland" \
        python3 - <<'PY'
import json, os, subprocess, sys
from get_notch_settings import DEFAULTS as NOTCH_DEFAULTS
from persist_hypr_state import DEFAULTS as HYPR_DEFAULTS

payload = json.dumps({"hyprland": HYPR_DEFAULTS, "notch": NOTCH_DEFAULTS})
apply_script = os.path.expanduser('~/.config/quickshell/scripts/hyprland/apply_all_settings.py')
res = subprocess.run([sys.executable, apply_script, payload], capture_output=True, text=True)
if res.returncode != 0:
    print(f"Error resetting defaults: {res.stderr or res.stdout}", file=sys.stderr)
    sys.exit(1)
PY
        exit $?
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

# Persist to lua file for reboot durability only if the live apply succeeded
python3 "$PERSIST_SCRIPT" "$TYPE" "$VAL" || exit 1
echo "ok"
