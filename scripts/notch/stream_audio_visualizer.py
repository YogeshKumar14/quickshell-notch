#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
import shutil
import atexit
import signal

import ctypes

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
NOTCH_CONFIG_FILE = os.path.join(CONFIG_DIR, "notch_settings.json")
CAVA_CONFIG_FILE = os.path.join(CONFIG_DIR, f"cava_config.{os.getpid()}")
DEFAULT_BAR_COUNT = 12
ACTIVITY_THRESHOLD = 5
MAX_BACKOFF = 30

proc = None

def set_pdeathsig():
    try:
        libc = ctypes.CDLL("libc.so.6")
        PR_SET_PDEATHSIG = 1
        libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
    except Exception:
        pass

def cleanup():
    global proc
    if proc:
        try:
            proc.kill()
            proc.wait(timeout=0.5)
        except Exception:
            pass
    try:
        os.unlink(CAVA_CONFIG_FILE)
    except OSError:
        pass

def sweep_stale_configs():
    try:
        now = time.time()
        for name in os.listdir(CONFIG_DIR):
            if not name.startswith("cava_config."):
                continue
            path = os.path.join(CONFIG_DIR, name)
            try:
                pid = int(name.rsplit(".", 1)[1])
            except ValueError:
                continue
            try:
                if os.path.isdir(f"/proc/{pid}"):
                    continue
            except OSError:
                pass
            if now - os.path.getmtime(path) > 60:
                try:
                    os.unlink(path)
                except OSError:
                    pass
    except OSError:
        pass

atexit.register(cleanup)

def sig_handler(signum, frame):
    cleanup()
    sys.exit(0)

signal.signal(signal.SIGTERM, sig_handler)
signal.signal(signal.SIGINT, sig_handler)

def get_monitor():
    try:
        sink = subprocess.check_output(["pactl", "get-default-sink"], text=True, stderr=subprocess.DEVNULL, timeout=5).strip()
        if sink:
            monitor = f"{sink}.monitor"
            try:
                sources = subprocess.check_output(["pactl", "list", "sources", "short"], text=True, stderr=subprocess.DEVNULL, timeout=5)
                if monitor in sources:
                    return monitor
            except Exception:
                pass
            return "auto"
    except Exception:
        pass
    return "auto"

def get_bar_count():
    if os.path.isfile(NOTCH_CONFIG_FILE):
        try:
            with open(NOTCH_CONFIG_FILE, "r", encoding="utf-8") as fp:
                data = json.load(fp)
                return int(data.get("visualizer_bar_count", DEFAULT_BAR_COUNT))
        except Exception:
            pass
    return DEFAULT_BAR_COUNT

def write_cava_config(bar_count, monitor_source):
    config_content = f"""[general]
bars = {bar_count}
framerate = 15
autosens = 1
sleep_timer = 2

[input]
method = pulse
source = {monitor_source}

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
"""
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CAVA_CONFIG_FILE, "w", encoding="utf-8") as fp:
        fp.write(config_content)

def main():
    global proc
    sweep_stale_configs()
    cava_bin = shutil.which("cava")
    if not cava_bin:
        print(json.dumps({"bars": [0] * DEFAULT_BAR_COUNT, "active": False}), flush=True)
        sys.exit(0)

    silent_frames = 0
    last_was_active = True
    backoff = 1.0
    consecutive_failures = 0

    while True:
        bar_count = get_bar_count()
        monitor = get_monitor()
        write_cava_config(bar_count, monitor)

        try:
            proc = subprocess.Popen(
                [cava_bin, "-p", CAVA_CONFIG_FILE],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
                preexec_fn=set_pdeathsig
            )

            while proc.poll() is None:
                line = proc.stdout.readline()
                if not line:
                    break
                line = line.strip()
                if not line:
                    continue

                parts = [p for p in line.split(";") if p != ""]
                if len(parts) >= bar_count:
                    try:
                        vals = [int(p) for p in parts[:bar_count]]
                        is_act = any(v > ACTIVITY_THRESHOLD for v in vals)

                        if is_act:
                            silent_frames = 0
                            last_was_active = True
                            print(json.dumps({"bars": vals, "active": True}), flush=True)
                        else:
                            silent_frames += 1
                            if last_was_active or silent_frames == 1:
                                print(json.dumps({"bars": [0] * bar_count, "active": False}), flush=True)
                                last_was_active = False

                        if consecutive_failures > 0:
                            consecutive_failures = 0
                            backoff = 1.0
                    except ValueError:
                        pass
        except Exception as e:
            print(f"cava spawn failed: {e}", file=sys.stderr)
            consecutive_failures += 1
            delay = min(backoff, MAX_BACKOFF)
            backoff = min(backoff * 2, MAX_BACKOFF)
            time.sleep(delay)
            continue
        finally:
            if proc:
                try:
                    proc.kill()
                    proc.wait(timeout=0.5)
                except Exception:
                    pass

        consecutive_failures += 1
        delay = min(backoff, MAX_BACKOFF)
        backoff = min(backoff * 2, MAX_BACKOFF)
        time.sleep(delay)

if __name__ == "__main__":
    main()
