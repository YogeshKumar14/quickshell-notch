#!/usr/bin/env python3
import os
import sys
import json
import subprocess

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "core"))
from atomic_write import atomic_write

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
from persist_hypr_state import generate_lua, generate_conf, load_state, save_state, ensure_includes
from apply_hypr_option import apply as apply_hyprctl_keyword, normalize_color

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
NOTCH_CONFIG_FILE = os.path.join(CONFIG_DIR, "notch_settings.json")
HYPR_CONFIG_FILE = os.path.expanduser("~/.config/hypr/quickshell_hypr.lua")
CONF_PATH = os.path.expanduser("~/.config/hypr/quickshell_hypr.conf")

def to_bool(v):
    if isinstance(v, str):
        return v.strip().lower() == "true"
    return bool(v)

KEYWORD_MAP = {
    "gaps_in": ("general:gaps_in", int),
    "gaps_out": ("general:gaps_out", int),
    "rounding": ("decoration:rounding", int),
    "border_size": ("general:border_size", int),
    "blur": ("decoration:blur:enabled", to_bool),
    "layout": ("general:layout", str),
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

def main():
    if os.environ.get("QUICKSHELL_SANDBOX") == "1":
        print(json.dumps({"status": "sandbox_mode_skipped_apply"}))
        sys.exit(0)

    if len(sys.argv) < 2:
        print(json.dumps({"error": "No JSON payload provided"}))
        sys.exit(1)

    try:
        payload = json.loads(sys.argv[1])
    except Exception as e:
        print(json.dumps({"error": f"Invalid JSON: {e}"}))
        sys.exit(1)

    notch_data = payload.get("notch", {})
    hypr_data = payload.get("hypr", {})

    # 0. Validate and convert ALL hypr values BEFORE writing anything,
    #    so a bad value can never corrupt the persisted configs.
    #    Accept both nested {"hypr": {...}} and flat payloads.
    if not hypr_data:
        hypr_data = {k: payload[k] for k in KEYWORD_MAP if k in payload}

    converted = {}
    errors = []
    for key, (hyprctl_key, converter) in KEYWORD_MAP.items():
        if key in hypr_data:
            try:
                converted[key] = converter(hypr_data[key])
            except Exception as e:
                errors.append(f"{key}: {e}")

    if errors:
        print(json.dumps({"status": "error", "errors": errors}))
        sys.exit(1)

    # 1. ATOMIC WRITE FOR NOTCH SETTINGS
    os.makedirs(CONFIG_DIR, exist_ok=True)
    existing_notch = {}
    if os.path.isfile(NOTCH_CONFIG_FILE):
        try:
            with open(NOTCH_CONFIG_FILE, "r", encoding="utf-8") as fp:
                existing_notch = json.load(fp)
        except Exception:
            pass

    existing_notch.update(notch_data)
    atomic_write(NOTCH_CONFIG_FILE, json.dumps(existing_notch, indent=2))

    # 2. WRITE HYPRLAND LUA CONFIG & CONF (persistence) + sync state cache.
    #    Merge into existing state: a partial payload must never reset the
    #    settings it does not mention back to defaults.
    if converted:
        merged = load_state()
        merged.update(converted)
        os.makedirs(os.path.dirname(HYPR_CONFIG_FILE), exist_ok=True)
        atomic_write(HYPR_CONFIG_FILE, generate_lua(merged))
        atomic_write(CONF_PATH, generate_conf(merged))
        save_state(merged)
        ensure_includes(
            merged,
            'pcall(dofile, os.getenv("HOME") .. "/.config/hypr/quickshell_hypr.lua")',
            'source = $HOME/.config/hypr/quickshell_hypr.conf'
        )

        # 3. APPLY LIVE VIA TARGETED hyprctl keyword (no full reload)
        failures = []
        for key, value in converted.items():
            hyprctl_key = KEYWORD_MAP[key][0]
            if not apply_hyprctl_keyword(hyprctl_key, value):
                failures.append(key)

        if failures:
            print(json.dumps({"status": "partial", "errors": [f"hyprctl failed: {k}" for k in failures]}))
            return
        print(json.dumps({"status": "ok"}))
        return

    print(json.dumps({"status": "ok", "note": "no hypr settings in payload"}))

if __name__ == "__main__":
    main()
