"""
hypr_keymap.py — Canonical configuration keymap for Hyprland settings.

Provides the single source of truth for all Hyprland options managed by
QuickShell Notch, their types, validation/converter functions, and
corresponding hyprctl keys.
"""

from typing import Any, Callable, Dict, List, Tuple
from apply_hypr_option import normalize_color
from persist_hypr_state import validate_layout


def to_bool(v: Any) -> bool:
    """Convert string or boolean value to boolean."""
    if isinstance(v, str):
        return v.strip().lower() == "true"
    return bool(v)


# Canonical mapping: short_key -> (hyprctl_key, converter_callable)
KEYWORD_MAP: Dict[str, Tuple[str, Callable[[Any], Any]]] = {
    "gaps_in": ("general:gaps_in", int),
    "gaps_out": ("general:gaps_out", int),
    "rounding": ("decoration:rounding", int),
    "border_size": ("general:border_size", int),
    "blur": ("decoration:blur:enabled", to_bool),
    "layout": ("general:layout", validate_layout),
    "animations": ("animations:enabled", to_bool),
    "active_opacity": ("decoration:active_opacity", float),
    "inactive_opacity": ("decoration:inactive_opacity", float),
    "shadow": ("decoration:shadow:enabled", to_bool),
    "shadow_range": ("decoration:shadow:range", int),
    "dim_inactive": ("decoration:dim_inactive", to_bool),
    "master_ratio": ("master:mfact", float),
    "blur_passes": ("decoration:blur:passes", int),
    "blur_size": ("decoration:blur:size", int),
    "input_sensitivity": ("input:sensitivity", float),
    "input_tap_to_click": ("input:touchpad:tap_to_click", to_bool),
    "input_natural_scroll": ("input:touchpad:natural_scroll", to_bool),
    "active_border": ("general:col.active_border", normalize_color),
    "inactive_border": ("general:col.inactive_border", normalize_color),
}

# Reverse lookup: hyprctl_key -> short_key
HYPRCTL_TO_SHORT: Dict[str, str] = {v[0]: k for k, v in KEYWORD_MAP.items()}

# Ordered list of all hyprctl keys for batch queries
ALL_HYPR_OPTIONS: List[str] = [v[0] for v in KEYWORD_MAP.values()]
