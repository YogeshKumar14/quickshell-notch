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
CAVA_CONFIG_FILE = os.path.join(CONFIG_DIR, "cava_config")

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

atexit.register(cleanup)

def sig_handler(signum, frame):
    cleanup()
    sys.exit(0)

signal.signal(signal.SIGTERM, sig_handler)
signal.signal(signal.SIGINT, sig_handler)

def get_default_monitor():
    try:
        sink = subprocess.check_output(["pactl", "get-default-sink"], text=True, stderr=subprocess.DEVNULL).strip()
        if sink:
            return f"{sink}.monitor"
    except Exception:
        pass
    return "auto"

def get_bar_count():
    if os.path.isfile(NOTCH_CONFIG_FILE):
        try:
            with open(NOTCH_CONFIG_FILE, "r", encoding="utf-8") as fp:
                data = json.load(fp)
                return int(data.get("visualizer_bar_count", 12))
        except Exception:
            pass
    return 12

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
    cava_bin = shutil.which("cava")
    if not cava_bin:
        print(json.dumps({"bars": [0]*12, "active": False}), flush=True)
        sys.exit(0)

    current_bar_count = get_bar_count()
    current_monitor = get_default_monitor()
    write_cava_config(current_bar_count, current_monitor)

    last_mtime = 0
    if os.path.exists(NOTCH_CONFIG_FILE):
        last_mtime = os.path.getmtime(NOTCH_CONFIG_FILE)

    while True:
        try:
            current_bar_count = get_bar_count()
            current_monitor = get_default_monitor()
            write_cava_config(current_bar_count, current_monitor)

            proc = subprocess.Popen(
                [cava_bin, "-p", CAVA_CONFIG_FILE],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
                preexec_fn=set_pdeathsig
            )

            last_config_check = time.monotonic()
            silent_frames = 0
            last_was_active = True

            while proc.poll() is None:
                line = proc.stdout.readline()
                if not line:
                    break
                line = line.strip()
                if not line:
                    continue

                # Periodic config check (every 5 seconds)
                now = time.monotonic()
                if now - last_config_check >= 5.0:
                    last_config_check = now
                    if os.path.exists(NOTCH_CONFIG_FILE):
                        mtime = os.path.getmtime(NOTCH_CONFIG_FILE)
                        if mtime != last_mtime:
                            last_mtime = mtime
                            new_bar_count = get_bar_count()
                            if new_bar_count != current_bar_count:
                                proc.kill()
                                proc.wait()
                                break

                parts = [p for p in line.split(";") if p != ""]
                if len(parts) >= current_bar_count:
                    try:
                        vals = [int(p) for p in parts[:current_bar_count]]
                        is_act = any(v > 1 for v in vals)

                        if is_act:
                            silent_frames = 0
                            last_was_active = True
                            print(json.dumps({"bars": vals, "active": True}), flush=True)
                        else:
                            silent_frames += 1
                            if last_was_active or silent_frames == 1:
                                print(json.dumps({"bars": [0] * current_bar_count, "active": False}), flush=True)
                                last_was_active = False
                    except ValueError:
                        pass
        except Exception:
            pass
        finally:
            if proc:
                try:
                    proc.kill()
                    proc.wait()
                except Exception:
                    pass
        time.sleep(0.5)

if __name__ == "__main__":
    main()
