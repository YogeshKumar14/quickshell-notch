"""
hypr_keymap.py — Canonical configuration keymap for Hyprland settings.

Provides the single source of truth for all Hyprland options managed by
QuickShell Notch, their types, validation/converter functions, and
corresponding hyprctl keys.
"""

from typing import Any, Callable, Dict, List, Tuple
from apply_hypr_option import normalize_color
from persist_hypr_state import (
    validate_layout,
    clamp_int,
    clamp_float,
    LIMITS_INT,
    LIMITS_FLOAT,
)


def to_bool(v: Any) -> bool:
    """Convert string or boolean value to boolean."""
    if isinstance(v, bool):
        return v
    if isinstance(v, str):
        s = v.strip().lower()
        if s in ("true", "1", "yes", "on"):
            return True
        if s in ("false", "0", "no", "off"):
            return False
        raise ValueError(f"Invalid boolean string: {v!r}")
    if isinstance(v, int):
        return bool(v)
    raise TypeError(f"Invalid boolean value: {v!r}")


# Canonical mapping: short_key -> (hyprctl_key, converter_callable)
KEYWORD_MAP: Dict[str, Tuple[str, Callable[[Any], Any]]] = {
    "gaps_in": ("general:gaps_in", lambda v: clamp_int(v, *LIMITS_INT["gaps_in"])),
    "gaps_out": ("general:gaps_out", lambda v: clamp_int(v, *LIMITS_INT["gaps_out"])),
    "rounding": ("decoration:rounding", lambda v: clamp_int(v, *LIMITS_INT["rounding"])),
    "border_size": ("general:border_size", lambda v: clamp_int(v, *LIMITS_INT["border_size"])),
    "blur": ("decoration:blur:enabled", to_bool),
    "layout": ("general:layout", validate_layout),
    "animations": ("animations:enabled", to_bool),
    "active_opacity": ("decoration:active_opacity", lambda v: clamp_float(v, *LIMITS_FLOAT["active_opacity"])),
    "inactive_opacity": ("decoration:inactive_opacity", lambda v: clamp_float(v, *LIMITS_FLOAT["inactive_opacity"])),
    "shadow": ("decoration:shadow:enabled", to_bool),
    "shadow_range": ("decoration:shadow:range", lambda v: clamp_int(v, *LIMITS_INT["shadow_range"])),
    "dim_inactive": ("decoration:dim_inactive", to_bool),
    "master_ratio": ("master:mfact", lambda v: clamp_float(v, *LIMITS_FLOAT["master_ratio"])),
    "blur_passes": ("decoration:blur:passes", lambda v: clamp_int(v, *LIMITS_INT["blur_passes"])),
    "blur_size": ("decoration:blur:size", lambda v: clamp_int(v, *LIMITS_INT["blur_size"])),
    "input_sensitivity": ("input:sensitivity", lambda v: clamp_float(v, *LIMITS_FLOAT["input_sensitivity"])),
    "input_tap_to_click": ("input:touchpad:tap_to_click", to_bool),
    "input_natural_scroll": ("input:touchpad:natural_scroll", to_bool),
    "active_border": ("general:col.active_border", normalize_color),
    "inactive_border": ("general:col.inactive_border", normalize_color),
}

# Reverse lookup: hyprctl_key -> short_key
HYPRCTL_TO_SHORT: Dict[str, str] = {v[0]: k for k, v in KEYWORD_MAP.items()}

# Ordered list of all hyprctl keys for batch queries
ALL_HYPR_OPTIONS: List[str] = [v[0] for v in KEYWORD_MAP.values()]
