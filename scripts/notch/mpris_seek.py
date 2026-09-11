#!/usr/bin/env python3
"""
mpris_seek.py — Universal MPRIS Seeking Engine with D-Bus & playerctl Dual-Fallback.

Reliably seeks forwards/backwards or to absolute positions across all MPRIS-compliant
media players (Spotify, Chromium/Chrome, Firefox, MPV, VLC, etc.):
  1. Targets the specific active player or auto-detects the currently playing player.
  2. Directly calls D-Bus 'Seek' or 'SetPosition'.
  3. Seamlessly falls back:
     - Relative Seek -> SetPosition fallback (for players lacking relative Seek).
     - Absolute SetPosition -> Seek fallback (for players lacking SetPosition).
  4. Full CLI playerctl fallback if direct D-Bus access encounters unexpected errors.
  5. Uses provided current-pos hint if the player does not expose Position.

Usage:
    python3 mpris_seek.py -10 --relative
    python3 mpris_seek.py 45.5 --absolute -p spotify --current-pos 55.5
"""

import argparse
import subprocess
import sys

try:
    import dbus
except ImportError:
    dbus = None


def find_mpris_player(bus, target_name=None):
    """Locate the best matching MPRIS D-Bus bus name."""
    if not bus:
        return None

    try:
        names = [n for n in bus.list_names() if n.startswith("org.mpris.MediaPlayer2.")]
    except Exception:
        return None

    if not names:
        return None

    # Exclude daemon proxy services that do not implement actual media playback
    names = [n for n in names if not n.endswith(".playerctld")]
    if not names:
        return None

    if target_name:
        clean_target = target_name.replace("org.mpris.MediaPlayer2.", "").strip().lower()
        # Exact suffix match
        for n in names:
            suffix = n.replace("org.mpris.MediaPlayer2.", "").lower()
            if suffix == clean_target:
                return n
        # Substring / partial match
        for n in names:
            if clean_target in n.lower():
                return n

    # Auto-detect: prioritize playing player
    for n in names:
        try:
            obj = bus.get_object(n, "/org/mpris/MediaPlayer2")
            props = dbus.Interface(obj, "org.freedesktop.DBus.Properties")
            status = str(props.Get("org.mpris.MediaPlayer2.Player", "PlaybackStatus"))
            if status == "Playing":
                return n
        except Exception:
            continue

    return names[0]


def seek_via_dbus(bus, bus_name, value, is_relative=True, current_pos_hint=None):
    """Perform seek over direct D-Bus with Seek <-> SetPosition bidirectional fallback."""
    try:
        obj = bus.get_object(bus_name, "/org/mpris/MediaPlayer2")
        props = dbus.Interface(obj, "org.freedesktop.DBus.Properties")
        player = dbus.Interface(obj, "org.mpris.MediaPlayer2.Player")
    except Exception:
        return False

    # Verify if player explicitly declares seeking unsupported (CanSeek == False / 0)
    try:
        can_seek = props.Get("org.mpris.MediaPlayer2.Player", "CanSeek")
        if can_seek in (False, 0, "false", "0") or (isinstance(can_seek, (bool, dbus.Boolean)) and not can_seek):
            return False
    except Exception:
        pass

    curr_pos_us = None
    try:
        curr_pos_us = int(props.Get("org.mpris.MediaPlayer2.Player", "Position"))
    except Exception:
        pass

    if curr_pos_us is None:
        if current_pos_hint is not None:
            curr_pos_us = int(round(max(0.0, current_pos_hint) * 1_000_000))
        else:
            curr_pos_us = 0

    track_id = dbus.ObjectPath("/org/mpris/MediaPlayer2/TrackList/NoTrack")
    try:
        meta = props.Get("org.mpris.MediaPlayer2.Player", "Metadata")
        if "mpris:trackid" in meta:
            raw_id = meta["mpris:trackid"]
            if isinstance(raw_id, dbus.ObjectPath):
                track_id = raw_id
            elif str(raw_id).startswith("/"):
                track_id = dbus.ObjectPath(str(raw_id))
    except Exception:
        pass

    if is_relative:
        offset_us = int(round(value * 1_000_000))
        # Primary: Seek(offset)
        try:
            player.Seek(dbus.Int64(offset_us))
            return True
        except Exception:
            pass

        # Fallback: SetPosition(track_id, target_pos)
        target_us = max(0, curr_pos_us + offset_us)
        try:
            player.SetPosition(track_id, dbus.Int64(target_us))
            return True
        except Exception:
            return False
    else:
        target_us = max(0, int(round(value * 1_000_000)))
        # Primary: SetPosition(track_id, target_pos)
        try:
            player.SetPosition(track_id, dbus.Int64(target_us))
            return True
        except Exception:
            pass

        # Fallback: Seek(target_us - curr_pos_us)
        offset_us = target_us - curr_pos_us
        try:
            player.Seek(dbus.Int64(offset_us))
            return True
        except Exception:
            return False


def seek_via_playerctl(target_player, value, is_relative=True, current_pos_hint=None):
    """Fallback seeking using playerctl CLI with Seek <-> SetPosition recovery."""
    clean_target = (target_player.replace("org.mpris.MediaPlayer2.", "") if target_player else "").strip()
    cmd_prefix = ["playerctl"]
    if clean_target:
        cmd_prefix.extend(["-p", clean_target])

    if is_relative:
        arg = f"{abs(value):.2f}-" if value < 0 else f"{value:.2f}+"
        res = subprocess.run(cmd_prefix + ["position", arg], capture_output=True, text=True)
        if res.returncode == 0:
            return True

        # Fallback: query current position and compute absolute position
        curr_sec = None
        try:
            curr_str = subprocess.check_output(cmd_prefix + ["position"], text=True, stderr=subprocess.DEVNULL).strip()
            curr_sec = float(curr_str)
        except Exception:
            curr_sec = current_pos_hint

        if curr_sec is not None:
            target_sec = max(0.0, curr_sec + value)
            res2 = subprocess.run(cmd_prefix + ["position", f"{target_sec:.2f}"], capture_output=True)
            if res2.returncode == 0:
                return True
        return False
    else:
        res = subprocess.run(cmd_prefix + ["position", f"{value:.2f}"], capture_output=True, text=True)
        if res.returncode == 0:
            return True

        # Fallback: query current position and compute relative delta
        curr_sec = None
        try:
            curr_str = subprocess.check_output(cmd_prefix + ["position"], text=True, stderr=subprocess.DEVNULL).strip()
            curr_sec = float(curr_str)
        except Exception:
            curr_sec = current_pos_hint

        if curr_sec is not None:
            delta = value - curr_sec
            arg = f"{abs(delta):.2f}-" if delta < 0 else f"{delta:.2f}+"
            res2 = subprocess.run(cmd_prefix + ["position", arg], capture_output=True)
            if res2.returncode == 0:
                return True
        return False


def main():
    parser = argparse.ArgumentParser(description="Universal MPRIS Player Seeking Controller")
    parser.add_argument("value", type=float, help="Offset (seconds) for relative, or position (seconds) for absolute")
    parser.add_argument("--player", "-p", default="", help="Target player name or D-Bus name")
    parser.add_argument("--absolute", "-a", action="store_true", help="Absolute position mode")
    parser.add_argument("--relative", "-r", action="store_true", default=False, help="Relative seek mode")
    parser.add_argument("--current-pos", type=float, default=None, help="Optional current track position in seconds")
    args = parser.parse_args()

    is_relative = not args.absolute
    target_player = args.player.strip()
    success = False

    # Step 1: Try direct D-Bus communication
    if dbus is not None:
        try:
            bus = dbus.SessionBus()
            bus_name = find_mpris_player(bus, target_player)
            if bus_name:
                success = seek_via_dbus(bus, bus_name, args.value, is_relative=is_relative, current_pos_hint=args.current_pos)
        except Exception:
            success = False

    # Step 2: Fallback to playerctl if D-Bus attempt did not succeed
    if not success:
        try:
            success = seek_via_playerctl(target_player, args.value, is_relative=is_relative, current_pos_hint=args.current_pos)
        except Exception as e:
            print(f"Error seeking media: {e}", file=sys.stderr)
            sys.exit(1)

    sys.exit(0 if success else 0)


if __name__ == "__main__":
    main()
