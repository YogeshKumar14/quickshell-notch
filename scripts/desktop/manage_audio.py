#!/usr/bin/env python3
"""
manage_audio.py — PipeWire Audio Sink/Source & Volume Management Backend
"""

import sys
import os
import re
import json
import subprocess

def get_audio_status():
    data = {
        "volume": 50,
        "volume_muted": False,
        "mic": 50,
        "mic_muted": False,
        "sinks": [],
        "sources": []
    }

    # 1. Query master sink volume
    try:
        res = subprocess.run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            out = res.stdout.strip()
            # e.g. "Volume: 0.50 [MUTED]" or "Volume: 0.50"
            m = re.search(r"Volume:\s*([0-9.]+)", out)
            if m:
                data["volume"] = max(0, min(100, int(round(float(m.group(1)) * 100))))
            data["volume_muted"] = "[MUTED]" in out
    except Exception:
        pass

    # 2. Query master source volume
    try:
        res = subprocess.run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            out = res.stdout.strip()
            m = re.search(r"Volume:\s*([0-9.]+)", out)
            if m:
                data["mic"] = max(0, min(100, int(round(float(m.group(1)) * 100))))
            data["mic_muted"] = "[MUTED]" in out
    except Exception:
        pass

    # 3. Parse wpctl status for Sinks and Sources
    try:
        res = subprocess.run(["wpctl", "status"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            lines = res.stdout.splitlines()
            current_section = None
            for line in lines:
                clean_line = line.strip()
                if "Sinks:" in clean_line:
                    current_section = "sinks"
                    continue
                elif "Sources:" in clean_line:
                    current_section = "sources"
                    continue
                elif "Filters:" in clean_line or "Streams:" in clean_line or "Video" in clean_line or "Settings" in clean_line:
                    current_section = None
                    continue

                if current_section in ("sinks", "sources"):
                    # Format: "│  *   96. ZEB-THUNDER NEO                     [vol: 0.13]"
                    # Or:     "│      53. Built-in Audio Analog Stereo        [vol: 0.57 MUTED]"
                    match = re.search(r"([*]?)\s*(\d+)\.\s+([^\[]+)(?:\[(.*)\])?", line)
                    if match:
                        is_active = match.group(1) == "*"
                        node_id = int(match.group(2))
                        name = match.group(3).strip()
                        details = match.group(4) or ""
                        vol_match = re.search(r"vol:\s*([0-9.]+)", details)
                        vol = int(round(float(vol_match.group(1)) * 100)) if vol_match else 0
                        muted = "MUTED" in details

                        item = {
                            "id": node_id,
                            "name": name,
                            "active": is_active,
                            "volume": vol,
                            "muted": muted
                        }
                        if current_section == "sinks":
                            data["sinks"].append(item)
                        else:
                            data["sources"].append(item)
    except Exception:
        pass

    return data

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "status":
        print(json.dumps(get_audio_status()))
        return

    cmd = sys.argv[1]
    if cmd == "set-volume" and len(sys.argv) > 2:
        try:
            val = max(0, min(100, int(sys.argv[2])))
            subprocess.run(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", f"{val / 100.0:.2f}"], check=False)
        except Exception:
            pass
    elif cmd == "set-mic" and len(sys.argv) > 2:
        try:
            val = max(0, min(100, int(sys.argv[2])))
            subprocess.run(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SOURCE@", f"{val / 100.0:.2f}"], check=False)
        except Exception:
            pass
    elif cmd == "toggle-volume-mute":
        subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"], check=False)
    elif cmd == "toggle-mic-mute":
        subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"], check=False)
    elif cmd == "set-sink" and len(sys.argv) > 2:
        try:
            sink_id = int(sys.argv[2])
            subprocess.run(["wpctl", "set-default", str(sink_id)], check=False)
        except Exception:
            pass
    elif cmd == "set-source" and len(sys.argv) > 2:
        try:
            source_id = int(sys.argv[2])
            subprocess.run(["wpctl", "set-default", str(source_id)], check=False)
        except Exception:
            pass

    print(json.dumps(get_audio_status()))

if __name__ == "__main__":
    main()
