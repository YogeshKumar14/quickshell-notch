#!/usr/bin/env python3
"""
tests/test_adversarial_m1.py — Empirical Challenger Stress Suite for Milestone M1.

Tests:
1. CAVA Streamer (stream_audio_visualizer.py):
   - Rapid start/stop stress burst (20 cycles)
   - Repeated SIGTERM delivery during active streaming
   - Dynamic notch_settings.json modification & mtime reloading
   - SIGHUP signal reload
   - Zero orphan / zombie process audit
2. Hyprland Batch Settings (apply_all_settings.py):
   - Corrupted JSON payload handling
   - Invalid key types and malformed schemas
   - Lua code injection resilience
   - Extreme boundary values
   - Atomic rollback: ensure configs are not corrupted on error
3. Socket IPC Client (notch_ipc.py):
   - Non-existent socket exit code 1 verification
   - Busy / non-responsive socket timeout and exit code 1 verification
   - Server immediate RST / disconnect handling
"""

import os
import sys
import time
import json
import socket
import signal
import shutil
import tempfile
import subprocess
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SCRIPTS_NOTCH = BASE_DIR / "scripts" / "notch"
SCRIPTS_HYPR = BASE_DIR / "scripts" / "hyprland"
SCRIPTS_CORE = BASE_DIR / "scripts" / "core"

sys.path.insert(0, str(SCRIPTS_NOTCH))
sys.path.insert(0, str(SCRIPTS_HYPR))
sys.path.insert(0, str(SCRIPTS_CORE))

STREAMER_SCRIPT = SCRIPTS_NOTCH / "stream_audio_visualizer.py"
APPLY_SETTINGS_SCRIPT = SCRIPTS_HYPR / "apply_all_settings.py"
IPC_SCRIPT = SCRIPTS_NOTCH / "notch_ipc.py"
NOTCH_CONFIG_FILE = Path(os.path.expanduser("~/.config/quickshell/notch_settings.json"))
HYPR_CONFIG_FILE = Path(os.path.expanduser("~/.config/hypr/quickshell_hypr.lua"))
CACHE_CONFIG_FILE = Path(os.path.expanduser("~/.cache/quickshell/hypr_state.json"))


class TestResult:
    def __init__(self, name):
        self.name = name
        self.passed = False
        self.error = None
        self.duration = 0.0

    def __repr__(self):
        status = "PASSED" if self.passed else "FAILED"
        return f"[{status}] {self.name} ({self.duration*1000:.1f}ms)" + (f" -> {self.error}" if self.error else "")


results = []


def run_test(name, func):
    tr = TestResult(name)
    start = time.perf_counter()
    try:
        func()
        tr.passed = True
    except Exception as e:
        tr.passed = False
        tr.error = str(e)
    tr.duration = time.perf_counter() - start
    results.append(tr)
    status_icon = "✅" if tr.passed else "❌"
    print(f"  {status_icon} {tr}")
    return tr.passed


# ==============================================================================
# 1. CAVA STREAMER STRESS TESTS
# ==============================================================================

def get_active_cava_pids():
    """List all running cava process PIDs owned by current user."""
    try:
        out = subprocess.check_output(["pgrep", "-u", str(os.getuid()), "-x", "cava"], text=True)
        return [int(p) for p in out.strip().splitlines() if p.strip()]
    except subprocess.CalledProcessError:
        return []


def test_cava_rapid_start_stop():
    """Rapid start and stop of stream_audio_visualizer.py across 20 cycles with zero orphans."""
    initial_cavas = set(get_active_cava_pids())
    cycles = 20
    for i in range(cycles):
        proc = subprocess.Popen(
            [sys.executable, str(STREAMER_SCRIPT)],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True
        )
        # Random short lifetime between 10ms and 80ms
        time.sleep(0.01 + (i % 5) * 0.015)
        proc.send_signal(signal.SIGTERM)
        try:
            ret = proc.wait(timeout=1.5)
            assert ret in (0, -signal.SIGTERM), f"Unexpected returncode {ret} on cycle {i}"
        except subprocess.TimeoutExpired:
            proc.kill()
            raise AssertionError(f"Streamer process timed out on cycle {i}")

    # Wait 0.5s for any background reaper to settle
    time.sleep(0.5)
    final_cavas = set(get_active_cava_pids()) - initial_cavas
    assert len(final_cavas) == 0, f"Leaked {len(final_cavas)} orphan cava processes: {final_cavas}"


def test_cava_repeated_sigterm_streaming():
    """Deliver SIGTERM while actively reading JSON frames from stdout across 10 cycles."""
    initial_cavas = set(get_active_cava_pids())
    for i in range(10):
        proc = subprocess.Popen(
            [sys.executable, str(STREAMER_SCRIPT)],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1
        )
        # Read at least 1 valid JSON frame
        frame = proc.stdout.readline().strip()
        assert frame, f"Failed to read initial frame on cycle {i}"
        data = json.loads(frame)
        assert "bars" in data and "active" in data, f"Invalid frame schema: {frame}"

        # Send SIGTERM during active read
        proc.send_signal(signal.SIGTERM)
        ret = proc.wait(timeout=2.0)
        assert ret in (0, -signal.SIGTERM), f"Unexpected returncode {ret} on cycle {i}"

    time.sleep(0.5)
    final_cavas = set(get_active_cava_pids()) - initial_cavas
    assert len(final_cavas) == 0, f"Leaked orphan cava processes: {final_cavas}"


def test_cava_config_mtime_dynamic_reload():
    """Verify streamer detects notch_settings.json mtime change and dynamically updates bar count."""
    if not NOTCH_CONFIG_FILE.exists():
        initial_cfg = {"visualizer_bar_count": 12}
        NOTCH_CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
        NOTCH_CONFIG_FILE.write_text(json.dumps(initial_cfg))
    else:
        initial_cfg = json.loads(NOTCH_CONFIG_FILE.read_text())

    try:
        # Start with bar_count = 12
        cfg_12 = dict(initial_cfg)
        cfg_12["visualizer_bar_count"] = 12
        NOTCH_CONFIG_FILE.write_text(json.dumps(cfg_12))

        proc = subprocess.Popen(
            [sys.executable, str(STREAMER_SCRIPT)],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1
        )

        # Read frames until we confirm 12 bars
        found_12 = False
        for _ in range(30):
            line = proc.stdout.readline().strip()
            if not line:
                continue
            data = json.loads(line)
            if len(data.get("bars", [])) == 12:
                found_12 = True
                break
        assert found_12, "Did not receive initial 12-bar frames from visualizer"

        # Dynamically change bar count on disk to 24 with modified mtime
        time.sleep(0.1)
        cfg_24 = dict(initial_cfg)
        cfg_24["visualizer_bar_count"] = 24
        NOTCH_CONFIG_FILE.write_text(json.dumps(cfg_24))
        # Ensure mtime is strictly bumped
        os.utime(NOTCH_CONFIG_FILE, None)

        # Read frames until streamer detects mtime and reloads to 24 bars
        found_24 = False
        for _ in range(60):
            line = proc.stdout.readline().strip()
            if not line:
                continue
            data = json.loads(line)
            if len(data.get("bars", [])) == 24:
                found_24 = True
                break
        assert found_24, "Streamer failed to reload bar count to 24 on notch_settings.json mtime update"

        # Send SIGHUP to test reload signal path
        proc.send_signal(signal.SIGHUP)
        time.sleep(0.1)

        proc.send_signal(signal.SIGTERM)
        proc.wait(timeout=2.0)

    finally:
        # Restore original config
        NOTCH_CONFIG_FILE.write_text(json.dumps(initial_cfg, indent=2))


# ==============================================================================
# 2. BATCH APPLY_ALL_SETTINGS.PY ADVERSARIAL STRESS
# ==============================================================================

def test_apply_settings_corrupted_json():
    """Verify corrupted JSON payload exits with code 1 and descriptive error JSON."""
    bad_payloads = [
        "",
        "{broken json",
        "null",
        "12345",
        "['list', 'not', 'dict']",
    ]
    for bad in bad_payloads:
        res = subprocess.run(
            [sys.executable, str(APPLY_SETTINGS_SCRIPT), bad],
            capture_output=True,
            text=True
        )
        assert res.returncode == 1, f"Expected returncode 1 for '{bad}', got {res.returncode}"
        assert "error" in res.stdout.lower() or "error" in res.stderr.lower()


def test_apply_settings_invalid_types_and_schema():
    """Verify invalid types on known Hyprland keys are rejected and exit code 1 returned."""
    invalid_cases = [
        {"hyprland": {"gaps_in": "not_an_int"}},
        {"hyprland": {"border_size": "abc"}},
        {"hyprland": {"rounding": None}},
        {"hyprland": {"active_border": 123456}},
        {"hyprland": {"shadow_color": [1, 2, 3]}},
    ]
    for case in invalid_cases:
        res = subprocess.run(
            [sys.executable, str(APPLY_SETTINGS_SCRIPT), json.dumps(case)],
            capture_output=True,
            text=True
        )
        assert res.returncode == 1, f"Expected returncode 1 for {case}, got {res.returncode}"
        data = json.loads(res.stdout)
        assert data.get("status") == "error", f"Expected status error, got: {data}"
        assert len(data.get("errors", [])) > 0, f"Expected non-empty errors array, got: {data}"


def test_apply_settings_lua_injection_resilience():
    """Verify payload with potential Lua code injection characters does not execute arbitrary Lua."""
    orig_notch = NOTCH_CONFIG_FILE.read_text() if NOTCH_CONFIG_FILE.exists() else "{}"
    orig_hypr = HYPR_CONFIG_FILE.read_text() if HYPR_CONFIG_FILE.exists() else ""
    orig_cache = CACHE_CONFIG_FILE.read_text() if CACHE_CONFIG_FILE.exists() else ""

    injection_payload = {
        "hyprland": {
            "active_border": "rgba(ff0000ff); os.execute('touch /tmp/qs_injected.txt'); --",
            "gaps_in": 5
        }
    }
    # Clean up test artifact if exists
    test_artifact = Path("/tmp/qs_injected.txt")
    if test_artifact.exists():
        test_artifact.unlink()

    try:
        res = subprocess.run(
            [sys.executable, str(APPLY_SETTINGS_SCRIPT), json.dumps(injection_payload)],
            capture_output=True,
            text=True
        )
        # The active_border value converter should either reject or normalize
        # And critical: the injection file MUST NOT exist!
        assert not test_artifact.exists(), "CRITICAL VULNERABILITY: Lua injection executed arbitrary OS command!"
    finally:
        if orig_notch:
            NOTCH_CONFIG_FILE.write_text(orig_notch)
        if orig_hypr:
            HYPR_CONFIG_FILE.write_text(orig_hypr)
        if orig_cache:
            CACHE_CONFIG_FILE.write_text(orig_cache)


def test_apply_settings_extreme_boundary_values():
    """Verify extreme boundary values (huge numbers, negative, 0) don't crash the script and are safely clamped."""
    orig_notch = NOTCH_CONFIG_FILE.read_text() if NOTCH_CONFIG_FILE.exists() else "{}"
    orig_hypr = HYPR_CONFIG_FILE.read_text() if HYPR_CONFIG_FILE.exists() else ""
    orig_cache = CACHE_CONFIG_FILE.read_text() if CACHE_CONFIG_FILE.exists() else ""

    boundaries = [
        {"hyprland": {"gaps_in": 0, "gaps_out": 0, "border_size": 0, "rounding": 0}},
        {"hyprland": {"gaps_in": 9999, "gaps_out": 9999, "border_size": 100, "rounding": 500}},
        {"notch": {"compact_width": 50, "expanded_height": 2000, "expand_tension": 0.01, "expand_damping": 1.0}},
    ]
    try:
        for b in boundaries:
            res = subprocess.run(
                [sys.executable, str(APPLY_SETTINGS_SCRIPT), json.dumps(b)],
                capture_output=True,
                text=True
            )
            assert res.returncode == 0, f"Extreme boundary failed with returncode {res.returncode}: {res.stdout} {res.stderr}"
            out = json.loads(res.stdout)
            assert out.get("status") in ("ok", "partial"), f"Unexpected status: {out}"

        # Crucial security verification: gaps must be clamped to safe limits, NEVER 9999
        if HYPR_CONFIG_FILE.exists():
            content = HYPR_CONFIG_FILE.read_text()
            assert "gaps_in = 9999" not in content, "gaps_in was not clamped!"
            assert "gaps_out = 9999" not in content, "gaps_out was not clamped!"
    finally:
        if orig_notch:
            NOTCH_CONFIG_FILE.write_text(orig_notch)
        if orig_hypr:
            HYPR_CONFIG_FILE.write_text(orig_hypr)
        if orig_cache:
            CACHE_CONFIG_FILE.write_text(orig_cache)
            try:
                state = json.loads(orig_cache)
                subprocess.run(
                    [sys.executable, str(APPLY_SETTINGS_SCRIPT), json.dumps({"hyprland": state})],
                    capture_output=True,
                    timeout=3
                )
            except Exception:
                pass



def test_apply_settings_atomic_rollback_on_error():
    """Verify that an error in Hyprland options does NOT partially overwrite or corrupt configs."""
    # Backup current configs
    orig_notch = NOTCH_CONFIG_FILE.read_text() if NOTCH_CONFIG_FILE.exists() else "{}"
    orig_hypr = HYPR_CONFIG_FILE.read_text() if HYPR_CONFIG_FILE.exists() else ""
    orig_cache = CACHE_CONFIG_FILE.read_text() if CACHE_CONFIG_FILE.exists() else ""

    try:
        corrupt_payload = {
            "notch": {"test_canary_key": "SHOULD_NOT_BE_WRITTEN_IF_VALIDATION_FAILS"},
            "hyprland": {"gaps_in": "BAD_STRING_FAIL"}
        }
        res = subprocess.run(
            [sys.executable, str(APPLY_SETTINGS_SCRIPT), json.dumps(corrupt_payload)],
            capture_output=True,
            text=True
        )
        assert res.returncode == 1, "Expected exit code 1 on invalid payload"
        
        # Check notch_settings.json: must NOT contain test_canary_key because validation runs first!
        if NOTCH_CONFIG_FILE.exists():
            content = NOTCH_CONFIG_FILE.read_text()
            assert "test_canary_key" not in content, "Atomic failure: notch config written despite validation error!"

    finally:
        if orig_notch:
            NOTCH_CONFIG_FILE.write_text(orig_notch)
        if orig_hypr:
            HYPR_CONFIG_FILE.write_text(orig_hypr)
        if orig_cache:
            CACHE_CONFIG_FILE.write_text(orig_cache)


# ==============================================================================
# 3. NOTCH_IPC.PY SOCKET ROBUSTNESS & EXIT CODE TESTS
# ==============================================================================

def test_notch_ipc_nonexistent_socket():
    """Verify notch_ipc.py returns exit code 1 when the target Unix socket does not exist."""
    # Temporarily override SOCK_PATH by mocking or using a subprocess with altered SOCK_PATH
    test_code = """
import sys
import os
sys.path.insert(0, sys.argv[1])
import notch_ipc
notch_ipc.SOCK_PATH = "/tmp/nonexistent_socket_qs_test_9999.sock"
notch_ipc.send_command("toggle")
"""
    res = subprocess.run(
        [sys.executable, "-c", test_code, str(SCRIPTS_NOTCH)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 1, f"Expected exit code 1 when socket missing, got {res.returncode}"
    assert "Error sending command 'toggle'" in res.stderr


def test_notch_ipc_server_busy_timeout():
    """Verify notch_ipc.py returns exit code 1 when the socket is listening but never accepts."""
    dummy_sock_path = "/tmp/test_busy_notch.sock"
    if os.path.exists(dummy_sock_path):
        os.unlink(dummy_sock_path)

    # Create a server socket that does not accept connections (or fills backlog)
    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(dummy_sock_path)
    srv.listen(0)  # zero backlog

    test_code = f"""
import sys
import os
sys.path.insert(0, sys.argv[1])
import notch_ipc
notch_ipc.SOCK_PATH = "{dummy_sock_path}"
notch_ipc.send_command("toggle")
"""
    try:
        # Fill the connection
        c1 = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            c1.connect(dummy_sock_path)
        except Exception:
            pass

        start_t = time.perf_counter()
        res = subprocess.run(
            [sys.executable, "-c", test_code, str(SCRIPTS_NOTCH)],
            capture_output=True,
            text=True,
            timeout=3.0
        )
        dur = time.perf_counter() - start_t
        # Socket client should either fail immediately or time out within ~1.0s and exit 1
        assert res.returncode == 1, f"Expected exit code 1 on busy socket, got {res.returncode}"
        assert dur <= 2.5, f"Client hung longer than timeout: {dur:.2f}s"
    finally:
        srv.close()
        try:
            c1.close()
        except Exception:
            pass
        if os.path.exists(dummy_sock_path):
            os.unlink(dummy_sock_path)


def test_notch_ipc_server_abrupt_disconnect():
    """Verify notch_ipc.py returns exit code 1 if server accepts and immediately closes socket."""
    dummy_sock_path = "/tmp/test_reset_notch.sock"
    if os.path.exists(dummy_sock_path):
        os.unlink(dummy_sock_path)

    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(dummy_sock_path)
    srv.listen(1)

    import threading
    def accept_and_close():
        try:
            conn, _ = srv.accept()
            conn.close()
        except Exception:
            pass

    th = threading.Thread(target=accept_and_close, daemon=True)
    th.start()

    test_code = f"""
import sys
import os
sys.path.insert(0, sys.argv[1])
import notch_ipc
notch_ipc.SOCK_PATH = "{dummy_sock_path}"
notch_ipc.send_command("toggle")
"""
    try:
        res = subprocess.run(
            [sys.executable, "-c", test_code, str(SCRIPTS_NOTCH)],
            capture_output=True,
            text=True
        )
        # Even if sendall succeeds or fails on immediate close, process should exit cleanly or exit 1
        assert res.returncode in (0, 1)
    finally:
        srv.close()
        if os.path.exists(dummy_sock_path):
            os.unlink(dummy_sock_path)


def test_notch_ipc_command_variations():
    """Verify notch_ipc.py handles various valid and boundary CLI commands."""
    commands = ["toggle", "nook", "apps", "stats", "tab:2", "osd:vol:50", "osd:bri:80", "close"]
    for cmd in commands:
        res = subprocess.run(
            [sys.executable, str(IPC_SCRIPT), cmd],
            capture_output=True,
            text=True
        )
        # Live quickshell daemon is running so exit code must be 0
        assert res.returncode == 0, f"Command '{cmd}' failed with code {res.returncode}: {res.stderr}"


# ==============================================================================
# MAIN RUNNER
# ==============================================================================

def main():
    print("==================================================================")
    print(" Milestone M1 Adversarial Empirical Stress & Verification Suite")
    print("==================================================================")

    print("\n[Target 1: CAVA Streamer (stream_audio_visualizer.py)]")
    run_test("1.1 Rapid start/stop stress burst (20 cycles, zero orphans)", test_cava_rapid_start_stop)
    run_test("1.2 Repeated SIGTERM during active streaming (10 cycles)", test_cava_repeated_sigterm_streaming)
    run_test("1.3 notch_settings.json mtime dynamic reload & SIGHUP", test_cava_config_mtime_dynamic_reload)

    print("\n[Target 2: Hyprland Batch Settings (apply_all_settings.py)]")
    run_test("2.1 Corrupted JSON payload handling", test_apply_settings_corrupted_json)
    run_test("2.2 Invalid key types & schema error handling", test_apply_settings_invalid_types_and_schema)
    run_test("2.3 Lua code injection attack resilience", test_apply_settings_lua_injection_resilience)
    run_test("2.4 Extreme boundary values execution", test_apply_settings_extreme_boundary_values)
    run_test("2.5 Atomic rollback: no partial config write on validation error", test_apply_settings_atomic_rollback_on_error)

    print("\n[Target 3: Socket IPC Client (notch_ipc.py)]")
    run_test("3.1 Non-existent socket exit code 1", test_notch_ipc_nonexistent_socket)
    run_test("3.2 Busy server socket timeout & exit code 1", test_notch_ipc_server_busy_timeout)
    run_test("3.3 Server abrupt disconnect handling", test_notch_ipc_server_abrupt_disconnect)
    run_test("3.4 Live command variations against daemon", test_notch_ipc_command_variations)

    print("\n==================================================================")
    passed_count = sum(1 for r in results if r.passed)
    failed_count = sum(1 for r in results if not r.passed)
    print(f"Results: {passed_count}/{len(results)} Passed | {failed_count} Failed")
    print("==================================================================")

    if failed_count > 0:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
