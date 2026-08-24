#!/usr/bin/env bash
if [ "$QUICKSHELL_SANDBOX" = "1" ]; then
    echo "sandbox_skipped"
    exit 0
fi

KEY="$1"
VAL="$2"
if [ -z "$KEY" ]; then
    echo "Usage: set_notch_option.sh KEY VAL" >&2
    exit 1
fi

CONFIG_FILE="$HOME/.config/quickshell/notch_settings.json"
mkdir -p "$HOME/.config/quickshell"

QUICK_OPT_KEY="$KEY" QUICK_OPT_VAL="$VAL" QUICK_OPT_FILE="$CONFIG_FILE" \
PYTHONPATH="$HOME/.config/quickshell/scripts/notch:$HOME/.config/quickshell/scripts/core" \
python3 - <<'PY'
import os, sys, json, time

from get_notch_settings import DEFAULTS, coerce_value
from atomic_write import atomic_write

file_path = os.environ["QUICK_OPT_FILE"]
key = os.environ["QUICK_OPT_KEY"]
val = os.environ["QUICK_OPT_VAL"]

data = dict(DEFAULTS)
if os.path.isfile(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as fp:
            loaded = json.load(fp)
        if isinstance(loaded, dict):
            data.update(loaded)
    except Exception as e:
        backup = file_path + ".corrupt." + time.strftime("%Y%m%d%H%M%S")
        try:
            os.rename(file_path, backup)
            print(f"WARNING: unreadable settings file backed up to {backup}", file=sys.stderr)
        except Exception:
            print(f"WARNING: unreadable settings file could not be backed up: {e}", file=sys.stderr)

coerced = coerce_value(key, val)
if coerced is not None:
    data[key] = coerced
    atomic_write(file_path, json.dumps(data, indent=2))
else:
    print(f"Unknown or invalid notch setting key: {key}", file=sys.stderr)
PY
