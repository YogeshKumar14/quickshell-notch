#!/usr/bin/env python3
"""Apply a single Hyprland option live.

`hyprctl keyword` silently no-ops (exit 0, no effect) on Hyprland builds with
the non-legacy (lua) config parser, so we fall back to `hyprctl eval` with a
`hl.config(...)` merge, which works on both parser types.

Canonical color format: bare 8-hex AARRGGBB (matches `hyprctl getoption`
"gradient data:"). The lua parser wants RGBA byte order, so colors are
swapped to RRGGBBAA before being emitted as `rgba(...)` strings.
"""
import json
import re
import subprocess
import sys

COLOR_KEYS = ("active_border", "inactive_border")


def normalize_color(v):
    s = str(v).strip().lower()
    s = re.sub(r"^rgba\(|\)$", "", s).strip()
    if s.startswith("0x"):
        s = s[2:]
    if len(s) >= 10:  # tolerate legacy 10-digit form (AARRGGBB + trailing ff)
        s = s[:8]
    if not re.fullmatch(r"[0-9a-f]{8}", s):
        raise ValueError("invalid color: %r" % v)
    return s


def swap_color(v):
    """aarrggbb -> rrggbbaa"""
    return v[2:] + v[:2]


def is_color_key(key):
    return "col." in key or key in COLOR_KEYS


def _lua_value(key, v):
    if is_color_key(key):
        return '"rgba(%s)"' % swap_color(normalize_color(v))
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        low = v.strip().lower()
        if low == "true":
            return "true"
        if low == "false":
            return "false"
        return json.dumps(v)
    return str(v)


def lua_assign(key, val):
    parts = [p for seg in key.split(":") for p in seg.split(".")]
    expr = _lua_value(key, val)
    for p in reversed(parts):
        expr = "{ %s = %s }" % (p, expr)
    return expr


def apply(key, val):
    try:
        result = subprocess.run(
            ["hyprctl", "keyword", key, str(val)],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            timeout=2
        )
        out = (result.stdout or b"").decode("utf-8", errors="replace").lower()
        if result.returncode == 0 and "non-legacy" not in out:
            return True
        result = subprocess.run(
            ["hyprctl", "eval", "hl.config(%s)" % lua_assign(key, val)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            timeout=2
        )
        return result.returncode == 0
    except Exception:
        return False


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: apply_hypr_option.py <hyprctl-key> <value>")
        sys.exit(1)
    sys.exit(0 if apply(sys.argv[1], sys.argv[2]) else 1)
