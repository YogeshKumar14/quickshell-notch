#!/usr/bin/env python3
"""
mpris_duration.py — Universal MPRIS Track Duration Resolver with D-Bus & playerctl Dual-Fallback.

Queries the active or targeted media player for track duration (mpris:length),
normalizes microseconds to seconds (float), and outputs the duration.

Usage:
    python3 mpris_duration.py [-p player_name]
Output:
    Duration in seconds as float (e.g. 188.173) or 0.0 if unknown/unavailable.
"""

import argparse
import subprocess
import sys

try:
    import dbus
except ImportError:
    dbus = None


def normalize_length(raw_val):
    """Normalize raw MPRIS length value (microseconds or seconds) to seconds float."""
    if raw_val is None:
        return 0.0
    try:
        if isinstance(raw_val, str):
            lines = raw_val.strip().splitlines()
            if not lines:
                return 0.0
            val = float(lines[0].strip())
        else:
            val = float(raw_val)
        if val <= 0:
            return 0.0
        # MPRIS v2 specifies mpris:length in microseconds (Time_In_Us).
        # A value > 100,000 indicates microseconds (>0.1s in us; >27.7 hrs in seconds).
        if val > 100_000:
            return val / 1_000_000.0
        return val
    except (ValueError, TypeError):
        return 0.0


def get_duration_via_dbus(bus, target_name=None):
    """Query player metadata via direct D-Bus connection."""
    if not bus:
        return None

    try:
        names = [n for n in bus.list_names() if n.startswith("org.mpris.MediaPlayer2.")]
    except Exception:
        return None

    if not names:
        return None

    matched = None
    if target_name:
        clean_target = target_name.replace("org.mpris.MediaPlayer2.", "").strip().lower()
        target_last = clean_target.split(".")[-1] if "." in clean_target else clean_target
        for n in names:
            suffix = n.replace("org.mpris.MediaPlayer2.", "").lower()
            suffix_last = suffix.split(".")[-1] if "." in suffix else suffix
            if suffix == clean_target or suffix_last == target_last:
                matched = n
                break
        if not matched:
            for n in names:
                if clean_target in n.lower() or target_last in n.lower():
                    matched = n
                    break
        # If target was specified but not found, do not hijack another player
        if not matched:
            return None
    else:
        # Prioritize playing player
        for n in names:
            try:
                obj = bus.get_object(n, "/org/mpris/MediaPlayer2")
                props = dbus.Interface(obj, "org.freedesktop.DBus.Properties")
                status = str(props.Get("org.mpris.MediaPlayer2.Player", "PlaybackStatus"))
                if status == "Playing":
                    matched = n
                    break
            except Exception:
                continue

        if not matched and names:
            matched = names[0]

    if matched:
        try:
            obj = bus.get_object(matched, "/org/mpris/MediaPlayer2")
            props = dbus.Interface(obj, "org.freedesktop.DBus.Properties")
            meta = props.Get("org.mpris.MediaPlayer2.Player", "Metadata")
            for k in ("mpris:length", "length", "duration", "xesam:duration"):
                if k in meta:
                    val = normalize_length(meta[k])
                    if val > 0:
                        return val
        except Exception:
            pass

    return None


def get_duration_via_playerctl(target_name=None):
    """Query track duration via playerctl CLI fallback."""
    cmd = ["playerctl"]
    if target_name:
        cmd.extend(["-p", target_name])
    cmd.extend(["metadata", "mpris:length"])
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=2)
        if res.returncode == 0 and res.stdout.strip():
            for line in res.stdout.strip().splitlines():
                val = normalize_length(line.strip())
                if val > 0:
                    return val
    except Exception:
        pass
    return None


def main():
    parser = argparse.ArgumentParser(description="Query MPRIS track duration in seconds.")
    parser.add_argument("-p", "--player", help="Target MPRIS player name/pattern")
    args = parser.parse_args()

    dur = None
    if dbus is not None:
        try:
            bus = dbus.SessionBus()
            dur = get_duration_via_dbus(bus, args.player)
        except Exception:
            pass

    if dur is None or dur <= 0:
        dur = get_duration_via_playerctl(args.player)

    if dur is None or dur <= 0:
        print("0.0")
        sys.exit(0)

    print(f"{dur:.3f}")
    sys.exit(0)


if __name__ == "__main__":
    main()
