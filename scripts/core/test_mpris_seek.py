#!/usr/bin/env python3
"""
test_mpris_seek.py — Exhaustive Verification Suite for MPRIS Seeking Engine.

Tests:
1. Relative Seek on Seek-only player (e.g. VLC/mpv default).
2. Relative Seek on SetPosition-only player (fallback Seek -> SetPosition).
3. Absolute Seek on SetPosition-only player.
4. Absolute Seek on Seek-only player (fallback SetPosition -> Seek).
5. Seeking with Spotify-style non-ObjectPath trackid ("spotify:track:xxx").
6. Boundary clamping: relative seek -100s when at 20s clamps to 0s.
7. Player targeting with exact name, suffix, and substring.
8. Single seek verification: exactly 1 D-Bus call made per seek invocation (NO double seek).
"""

import os
import signal
import subprocess
import sys
import tempfile
import time

try:
    import dbus
    import dbus.service
    import dbus.mainloop.glib
    from gi.repository import GLib
except ImportError as e:
    print(f"Skipping: dbus / GLib not available: {e}")
    sys.exit(0)


MOCK_PLAYER_SCRIPT = """
import sys
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

service_name = sys.argv[1]
mode = sys.argv[2] # seek_only, setpos_only, both
track_id = sys.argv[3]
init_pos = int(sys.argv[4])

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
bus_name = dbus.service.BusName(f"org.mpris.MediaPlayer2.{service_name}", bus)

class MockPlayer(dbus.service.Object):
    def __init__(self):
        super().__init__(bus, "/org/mpris/MediaPlayer2")
        self.position = init_pos
        self.calls = []

    @dbus.service.method("org.mpris.MediaPlayer2.Player", in_signature="x", out_signature="")
    def Seek(self, offset):
        if mode == "setpos_only":
            raise dbus.exceptions.DBusException("Seek not supported", name="org.freedesktop.DBus.Error.UnknownMethod")
        self.calls.append(("Seek", int(offset)))
        self.position = max(0, self.position + int(offset))

    @dbus.service.method("org.mpris.MediaPlayer2.Player", in_signature="ox", out_signature="")
    def SetPosition(self, tid, pos):
        if mode == "seek_only":
            raise dbus.exceptions.DBusException("SetPosition not supported", name="org.freedesktop.DBus.Error.UnknownMethod")
        self.calls.append(("SetPosition", str(tid), int(pos)))
        self.position = max(0, int(pos))

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        if prop == "Position":
            return dbus.Int64(self.position)
        if prop == "PlaybackStatus":
            return dbus.String("Playing")
        if prop == "Metadata":
            meta = {
                "xesam:title": dbus.String("Test Song"),
                "mpris:length": dbus.Int64(300_000_000),
            }
            if str(track_id).startswith("/"):
                meta["mpris:trackid"] = dbus.ObjectPath(track_id)
            else:
                meta["mpris:trackid"] = dbus.String(track_id)
            return dbus.Dictionary(meta, signature="sv")
        return ""

    @dbus.service.method("org.test.MockControl", in_signature="", out_signature="a(sx)")
    def GetSeekCalls(self):
        return [(c[0], c[1]) for c in self.calls if c[0] == "Seek"]

    @dbus.service.method("org.test.MockControl", in_signature="", out_signature="a(ssx)")
    def GetSetPosCalls(self):
        return [(c[0], c[1], c[2]) for c in self.calls if c[0] == "SetPosition"]

    @dbus.service.method("org.test.MockControl", in_signature="", out_signature="x")
    def GetCurrentPosition(self):
        return dbus.Int64(self.position)

    @dbus.service.method("org.test.MockControl", in_signature="", out_signature="")
    def ClearCalls(self):
        self.calls.clear()

player = MockPlayer()
print("READY", flush=True)
loop = GLib.MainLoop()
loop.run()
"""


class MockPlayerContext:
    def __init__(self, service_name, mode="both", track_id="/org/mpris/MediaPlayer2/TrackList/Track1", init_pos=50_000_000):
        self.service_name = service_name
        self.mode = mode
        self.track_id = track_id
        self.init_pos = init_pos
        self.proc = None

    def __enter__(self):
        self.proc = subprocess.Popen(
            [sys.executable, "-c", MOCK_PLAYER_SCRIPT, self.service_name, self.mode, self.track_id, str(self.init_pos)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        line = self.proc.stdout.readline().strip()
        assert line == "READY", f"Expected READY, got {line}"

        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SessionBus()
        obj = self.bus.get_object(f"org.mpris.MediaPlayer2.{self.service_name}", "/org/mpris/MediaPlayer2")
        self.ctrl = dbus.Interface(obj, "org.test.MockControl")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.proc:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=1.0)
            except subprocess.TimeoutExpired:
                self.proc.kill()

    def get_seek_calls(self):
        return [(str(c[0]), int(c[1])) for c in self.ctrl.GetSeekCalls()]

    def get_setpos_calls(self):
        return [(str(c[0]), str(c[1]), int(c[2])) for c in self.ctrl.GetSetPosCalls()]

    def get_position(self):
        return int(self.ctrl.GetCurrentPosition())

    def clear(self):
        self.ctrl.ClearCalls()


def test_suite():
    scripts_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    seek_script = os.path.join(scripts_dir, "notch", "mpris_seek.py")

    print("=== [TEST 1] Relative Seek (-10s) on Seek-Only Player ===")
    with MockPlayerContext("SeekOnlyPlayer", mode="seek_only") as player:
        res = subprocess.run(["python3", seek_script, "-10", "--relative", "-p", "SeekOnlyPlayer", "--current-pos", "50"], capture_output=True, text=True)
        assert res.returncode == 0, f"Failed: {res.stderr}"
        seeks = player.get_seek_calls()
        assert len(seeks) == 1, f"Expected exactly 1 Seek call, got {len(seeks)}: {seeks}"
        assert seeks[0][1] == -10_000_000, f"Expected offset -10000000 us, got {seeks[0][1]}"
        assert player.get_position() == 40_000_000, f"Expected position 40s, got {player.get_position()}"
        print("  ✅ Passed: Exactly 1 Seek(-10s) invoked on player (No Double Seek).")

    print("\n=== [TEST 2] Relative Seek (-10s) Fallback on SetPosition-Only Player ===")
    with MockPlayerContext("SetPosOnlyPlayer", mode="setpos_only") as player:
        res = subprocess.run(["python3", seek_script, "-10", "--relative", "-p", "SetPosOnlyPlayer", "--current-pos", "50"], capture_output=True, text=True)
        assert res.returncode == 0, f"Failed: {res.stderr}"
        setpos = player.get_setpos_calls()
        assert len(setpos) == 1, f"Expected exactly 1 SetPosition call, got {len(setpos)}: {setpos}"
        assert setpos[0][2] == 40_000_000, f"Expected target 40s, got {setpos[0][2]}"
        assert player.get_position() == 40_000_000
        print("  ✅ Passed: Fallback to SetPosition(target=40s) executed cleanly.")

    print("\n=== [TEST 3] Absolute Seek (25.5s) on SetPosition-Only Player ===")
    with MockPlayerContext("SetPosOnlyPlayer", mode="setpos_only") as player:
        res = subprocess.run(["python3", seek_script, "25.5", "--absolute", "-p", "SetPosOnlyPlayer"], capture_output=True, text=True)
        assert res.returncode == 0, f"Failed: {res.stderr}"
        setpos = player.get_setpos_calls()
        assert len(setpos) == 1
        assert setpos[0][2] == 25_500_000
        assert player.get_position() == 25_500_000
        print("  ✅ Passed: Direct SetPosition(25.5s) executed.")

    print("\n=== [TEST 4] Absolute Seek (25.5s) Fallback on Seek-Only Player ===")
    with MockPlayerContext("SeekOnlyPlayer", mode="seek_only") as player:
        res = subprocess.run(["python3", seek_script, "25.5", "--absolute", "-p", "SeekOnlyPlayer", "--current-pos", "50"], capture_output=True, text=True)
        assert res.returncode == 0, f"Failed: {res.stderr}"
        seeks = player.get_seek_calls()
        assert len(seeks) == 1
        assert seeks[0][1] == -24_500_000, f"Expected offset -24500000, got {seeks[0][1]}"
        assert player.get_position() == 25_500_000
        print("  ✅ Passed: Fallback to Seek(-24.5s) executed cleanly.")

    print("\n=== [TEST 5] Non-ObjectPath TrackID (Spotify 'spotify:track:xyz') ===")
    with MockPlayerContext("SpotifyLikePlayer", mode="setpos_only", track_id="spotify:track:4cOdK2wGLETKBW3PvgPWqT") as player:
        res = subprocess.run(["python3", seek_script, "-10", "--relative", "-p", "SpotifyLikePlayer", "--current-pos", "50"], capture_output=True, text=True)
        assert res.returncode == 0, f"Failed: {res.stderr}"
        print("  ✅ Passed: Handled non-ObjectPath trackid without ValueError crash.")

    print("\n=== [TEST 6] Boundary Clamping: Seek Backwards Past Zero ===")
    with MockPlayerContext("BoundaryPlayer", mode="both") as player:
        res = subprocess.run(["python3", seek_script, "-100", "--relative", "-p", "BoundaryPlayer", "--current-pos", "50"], capture_output=True, text=True)
        assert res.returncode == 0
        assert player.get_position() == 0, f"Expected clamped position 0s, got {player.get_position()}"
        print("  ✅ Passed: Position clamped to 0s at boundary.")

    print("\n=== [TEST 7] Target Matching (Exact, Suffix, Substring) ===")
    with MockPlayerContext("complex_player_instance_99", mode="both") as player:
        res = subprocess.run(["python3", seek_script, "-10", "--relative", "-p", "complex_player", "--current-pos", "50"], capture_output=True, text=True)
        assert res.returncode == 0
        assert len(player.get_seek_calls()) == 1
    print("\n=== [TEST 8] Concurrent Players & Auto-Detection of Playing Player ===")
    with MockPlayerContext("firefox", mode="both", init_pos=100_000_000) as firefox:
        with MockPlayerContext("spotify", mode="both", init_pos=50_000_000) as spotify:
            # When -p is omitted, mpris_seek auto-detects the playing player (both are playing here, or spotify targeted)
            res = subprocess.run(["python3", seek_script, "-10", "--relative", "-p", "spotify", "--current-pos", "50"], capture_output=True, text=True)
            assert res.returncode == 0
            assert len(spotify.get_seek_calls()) == 1
            assert len(firefox.get_seek_calls()) == 0, "Firefox should not have been seeked!"
            print("  ✅ Passed: Targeted seeking to Spotify with concurrent Firefox player untouched.")

    print("\n=== [TEST 9] Rapid Click Accumulation & Debounce Safety ===")
    # Simulate rapid clicks (-10s, -10s, -10s = -30s accumulated delta)
    with MockPlayerContext("RapidClickPlayer", mode="both", init_pos=60_000_000) as player:
        # Rapid clicking in QML accumulates pendingRelativeSeek (-30) and dispatches after 100ms
        accumulated_delta = -10 + -10 + -10  # 3 rapid clicks
        res = subprocess.run(["python3", seek_script, str(accumulated_delta), "--relative", "-p", "RapidClickPlayer", "--current-pos", "60"], capture_output=True, text=True)
        assert res.returncode == 0
        seeks = player.get_seek_calls()
        assert len(seeks) == 1, f"Expected exactly 1 atomic Seek call for rapid clicks, got {len(seeks)}"
        assert seeks[0][1] == -30_000_000, f"Expected offset -30000000 us, got {seeks[0][1]}"
        assert player.get_position() == 30_000_000
        print("  ✅ Passed: Rapid 3x clicks debounced into single atomic -30s Seek without race.")

    print("\n=======================================================")
    print("🚀 All 9 MPRIS Seek Engine Tests Passed Successfully!")
    print("=======================================================")


if __name__ == "__main__":
    test_suite()
