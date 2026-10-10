#!/usr/bin/env python3
"""
stream_audio_visualizer.py — CAVA Raw Audio Visualizer Streamer.

Spawns cava as a child process with PR_SET_PDEATHSIG lifecycle management,
reads raw binary audio amplitudes, normalizes bars into 0-100 percentages,
detects audio activity thresholds, and streams JSON frames to stdout.

Stream Output:
    JSON line: { "bars": [int, ...], "active": bool }
"""

import os
import sys
import json
import time
import subprocess
import shutil
import atexit
import signal
import re

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "core"))
from process_utils import set_pdeathsig

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
NOTCH_CONFIG_FILE = os.path.join(CONFIG_DIR, "notch_settings.json")
CAVA_CONFIG_FILE = os.path.join(RUNTIME_DIR, f"quickshell_cava.{os.getpid()}")
DEFAULT_BAR_COUNT = 12
ACTIVITY_THRESHOLD = 5
MAX_BACKOFF = 30

proc = None
_active_procs = set()
_cleaning_up = False

def _child_preexec():
    set_pdeathsig()
    try:
        os.setpgrp()
    except Exception:
        pass

def _terminate_proc_group(p):
    if not p or not p.pid:
        return
    try:
        pgid = os.getpgid(p.pid)
        os.killpg(pgid, signal.SIGTERM)
    except (ProcessLookupError, OSError):
        pass
    try:
        p.wait(timeout=0.2)
    except (subprocess.TimeoutExpired, Exception):
        try:
            os.killpg(os.getpgid(p.pid), signal.SIGKILL)
            p.wait(timeout=0.2)
        except (ProcessLookupError, OSError, Exception):
            pass

def cleanup():
    global proc, _active_procs, _cleaning_up
    if _cleaning_up:
        return
    _cleaning_up = True
    try:
        procs = list(_active_procs)
        if proc and proc not in procs:
            procs.append(proc)
        for p in procs:
            _terminate_proc_group(p)
        _active_procs.clear()
        proc = None
    finally:
        _cleaning_up = False
    try:
        if os.path.exists(CAVA_CONFIG_FILE):
            os.unlink(CAVA_CONFIG_FILE)
    except OSError:
        pass

def sweep_stale_configs():
    # Sweep legacy config dir and runtime dir
    for scan_dir, prefix in [(CONFIG_DIR, "cava_config."), (RUNTIME_DIR, "quickshell_cava.")]:
        try:
            now = time.time()
            if not os.path.isdir(scan_dir):
                continue
            for name in os.listdir(scan_dir):
                if not name.startswith(prefix):
                    continue
                path = os.path.join(scan_dir, name)
                try:
                    pid = int(name.rsplit(".", 1)[1])
                except ValueError:
                    continue
                try:
                    if os.path.isdir(f"/proc/{pid}"):
                        continue
                except OSError:
                    pass
                if now - os.path.getmtime(path) > 30:
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

_cached_bar_count = DEFAULT_BAR_COUNT
_cached_config_mtime = 0.0

def reload_config_signal(signum, frame):
    global _cached_config_mtime
    _cached_config_mtime = 0.0

try:
    signal.signal(signal.SIGHUP, reload_config_signal)
except Exception:
    pass

def get_bar_count(force=False):
    global _cached_bar_count, _cached_config_mtime
    try:
        if os.path.isfile(NOTCH_CONFIG_FILE):
            st = os.stat(NOTCH_CONFIG_FILE)
            if force or st.st_mtime != _cached_config_mtime:
                with open(NOTCH_CONFIG_FILE, "r", encoding="utf-8") as fp:
                    data = json.load(fp)
                    _cached_bar_count = int(data.get("visualizer_bar_count", DEFAULT_BAR_COUNT))
                _cached_config_mtime = st.st_mtime
    except Exception:
        pass
    return _cached_bar_count

def write_cava_config(bar_count, monitor_source):
    bar_count = max(2, min(64, int(bar_count)))
    clean_source = re.sub(r"[^a-zA-Z0-9._-]", "", monitor_source) or "auto"
    config_content = f"""[general]
bars = {bar_count}
framerate = 30
autosens = 1
sleep_timer = 2

[input]
method = pulse
source = {clean_source}

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
channels = mono
mono_option = average

[smoothing]
monstercat = 0
noise_reduction = 35
"""
    with open(CAVA_CONFIG_FILE, "w", encoding="utf-8") as fp:
        fp.write(config_content)

def main():
    global proc
    set_pdeathsig()
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
        silent_frames = 0
        last_was_active = True
        bar_count = get_bar_count()
        monitor = get_monitor()
        write_cava_config(bar_count, monitor)
        produced_output = False
        zero_bars = [0] * bar_count
        silent_frame_payload = json.dumps({"bars": zero_bars, "active": False})

        try:
            proc = subprocess.Popen(
                [cava_bin, "-p", CAVA_CONFIG_FILE],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
                preexec_fn=_child_preexec
            )
            _active_procs.add(proc)

            # Pre-compute logarithmic EQ weights and per-bar decay rates
            eq_weights = [
                0.82 + 0.45 * (i / max(1, bar_count - 1)) ** 0.8
                for i in range(bar_count)
            ]
            decay_rates = [
                0.76 - 0.14 * (i / max(1, bar_count - 1))
                for i in range(bar_count)
            ]
            phys_bars = [0.0] * bar_count
            frame_count = 0

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
                        raw_vals = [int(p) for p in parts[:bar_count]]
                        # Apply noise floor deadband (< 6% amplitude filtered to 0)
                        cleaned_vals = [0 if v < 6 else v for v in raw_vals]

                        # Fast path: zero input and zero existing physics -> silent frame without math allocations
                        all_silent_input = not any(cleaned_vals)
                        all_phys_zero = not any(phys_bars)

                        if all_silent_input and all_phys_zero:
                            silent_frames += 1
                            if last_was_active or silent_frames == 1:
                                print(silent_frame_payload, flush=True)
                                last_was_active = False
                        else:
                            # Apply independent per-bar physics: fast attack + organic frequency-dependent decay
                            for i in range(bar_count):
                                target = min(100.0, cleaned_vals[i] * eq_weights[i]) if cleaned_vals[i] > 0 else 0.0
                                prev = phys_bars[i]
                                if target >= prev:
                                    phys_bars[i] = 0.85 * target + 0.15 * prev
                                else:
                                    decayed = prev * decay_rates[i]
                                    phys_bars[i] = 0.0 if decayed < 2.0 else decayed

                            vals = [int(round(v)) for v in phys_bars]
                            is_act = any(v > ACTIVITY_THRESHOLD for v in vals)

                            if is_act:
                                silent_frames = 0
                                last_was_active = True
                                print(json.dumps({"bars": vals, "active": True}), flush=True)
                            else:
                                silent_frames += 1
                                if last_was_active or silent_frames == 1:
                                    print(silent_frame_payload, flush=True)
                                    last_was_active = False

                        produced_output = True

                        if consecutive_failures > 0:
                            consecutive_failures = 0
                            backoff = 1.0

                        frame_count += 1
                        if frame_count % 10 == 0:
                            if get_bar_count() != bar_count:
                                break
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
            last_rc = None
            if proc:
                last_rc = proc.poll()
                _active_procs.discard(proc)
                _terminate_proc_group(proc)
                proc = None

        # A clean exit — we streamed frames, or cava terminated on its own with
        # code 0 (e.g. monitor source vanished) — is not a failure. Only real
        # spawn failures or crashes should grow the backoff.
        if produced_output or last_rc == 0:
            consecutive_failures = 0
            backoff = 1.0
            time.sleep(0.5)
        else:
            consecutive_failures += 1
            delay = min(backoff, MAX_BACKOFF)
            backoff = min(backoff * 2, MAX_BACKOFF)
            time.sleep(delay)

if __name__ == "__main__":
    main()
