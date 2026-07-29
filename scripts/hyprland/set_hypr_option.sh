#!/usr/bin/env bash
if [ "$QUICKSHELL_SANDBOX" = "1" ]; then
    echo "sandbox_skipped"
    exit 0
fi

TYPE="$1"
VAL="$2"

PERSIST_SCRIPT="$HOME/.config/quickshell/scripts/hyprland/persist_hypr_state.py"

# Apply live keyword to memory instantly
case "$TYPE" in
    gaps_in)          hyprctl keyword general:gaps_in "$VAL" ;;
    gaps_out)         hyprctl keyword general:gaps_out "$VAL" ;;
    rounding)         hyprctl keyword decoration:rounding "$VAL" ;;
    border_size)      hyprctl keyword general:border_size "$VAL" ;;
    blur)             hyprctl keyword decoration:blur:enabled "$VAL" ;;
    active_border)    hyprctl keyword general:col.active_border "$VAL" ;;
    inactive_border)  hyprctl keyword general:col.inactive_border "$VAL" ;;
    layout)           hyprctl keyword general:layout "$VAL" ;;
    animations)       hyprctl keyword animations:enabled "$VAL" ;;
    active_opacity)   hyprctl keyword decoration:active_opacity "$VAL" ;;
    inactive_opacity) hyprctl keyword decoration:inactive_opacity "$VAL" ;;
    shadow)           hyprctl keyword decoration:shadow:enabled "$VAL" ;;
    dim_inactive)     hyprctl keyword decoration:dim_inactive "$VAL" ;;
    master_ratio)     hyprctl keyword master:mfact "$VAL" ;;
    input_sensitivity) hyprctl keyword input:sensitivity "$VAL" ;;
    input_tap_to_click) hyprctl keyword input:touchpad:tap_to_click "$VAL" ;;
    input_natural_scroll) hyprctl keyword input:touchpad:natural_scroll "$VAL" ;;
    shadow_range)     hyprctl keyword decoration:shadow:range "$VAL" ;;
    blur_passes)      hyprctl keyword decoration:blur:passes "$VAL" ;;
    blur_size)        hyprctl keyword decoration:blur:size "$VAL" ;;
    reset_defaults)
        rm -f "$HOME/.config/hypr/quickshell_hypr.lua"
        rm -f "$HOME/.config/hypr/quickshell/quickshell_hypr.lua"
        python3 -c "
import json, os
cfg = os.path.expanduser('~/.config/quickshell/notch_settings.json')
defaults = {
    'always_ontop': True, 'notch_radius': 12, 'show_battery': True,
    'show_network': True, 'show_bluetooth': True, 'show_media': True,
    'expanded_height': 420, 'workspace_mode': 'dots', 'workspace_count': 10,
    'workspace_sort': 'name', 'wallpaper_dir': '~/Pictures/Wallpapers',
    'wallpaper_cols': 3, 'wallpaper_use_swww': True, 'wallpaper_fill_mode': 'fit',
    'visualizer_enabled': True, 'visualizer_style': 'bars',
    'visualizer_height': 16, 'visualizer_timeout': 0,
    'visualizer_bar_count': 12, 'visualizer_wave_width': 2,
    'visualizer_pulsar_scale': 1.2, 'visualizer_pause_delay': 1000,
    'stats_interval': 2000, 'network_refresh': 5000, 'osd_timeout': 2000,
    'clock_format': 'h:mm A', 'clock_font_size': 14,
    'battery_warning_threshold': 20
}
with open(cfg, 'w') as f:
    json.dump(defaults, f, indent=4)
"
        rm -f "$HOME/.cache/quickshell/hypr_state.json"
        hyprctl reload
        exit 0
        ;;
    *)
        echo "Unknown option type: $TYPE"
        exit 1
        ;;
esac

# Persist to lua + conf files for reboot durability
python3 "$PERSIST_SCRIPT" "$TYPE" "$VAL"
