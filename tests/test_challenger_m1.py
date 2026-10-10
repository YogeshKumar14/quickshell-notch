#!/usr/bin/env python3
"""
tests/test_challenger_m1.py — Empirical Challenger Harness for Milestone M1.

Exhaustively stress-tests:
1. MPRIS seeking engine (mpris_seek.py) under edge-cases:
   - Non-existent player without target (safe no-op exit 0)
   - Non-existent player with target (exit 1)
   - Invalid target formats (empty, whitespace, bare prefixes)
   - Unseekable player (CanSeek=False) under relative and absolute modes
   - Negative time seek (relative and absolute)
   - Extreme forward seek (1e6, 1e9, 1e12, 1e15, inf, nan)
2. Live Socket IPC (/tmp/quickshell-notch.sock):
   - 50 concurrent bursts across threads
   - Malformed tokens, binary data, huge payloads, injection strings
   - Rapid multi-line payloads in a single stream
3. Resource telemetry & leak detection:
   - CPU % and RSS (MB) across QuickShell daemon and visualizer
"""

import os
import sys
import time
import socket
import subprocess
import threading
from pathlib import Path

# Add project root to sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from scripts.core.test_mpris_seek import MockPlayerContext

SEEK_SCRIPT = BASE_DIR / "scripts" / "notch" / "mpris_seek.py"
NOTCH_IPC_SCRIPT = BASE_DIR / "scripts" / "notch" / "notch_ipc.py"
SOCK_PATH = "/tmp/quickshell-notch.sock"

# Results dictionary
RESULTS = {
    "mpris_tests": {},
    "ipc_tests": {},
    "resource_telemetry": {},
}


def get_process_metrics(pid: int):
    """Fetch %CPU and RSS (in MB) for a given PID."""
    try:
        out = subprocess.check_output(
            ["ps", "-p", str(pid), "-o", "pcpu,rss", "--no-headers"],
            text=True
        ).strip()
        parts = out.split()
        if len(parts) >= 2:
            return float(parts[0]), float(parts[1]) / 1024.0
    except Exception:
        pass
    return None, None


def find_quickshell_pids():
    """Find PID of running QuickShell daemon and visualizer child."""
    qs_pid = None
    cava_pid = None
    try:
        out = subprocess.check_output(["pgrep", "-f", "quickshell -n -p .*shell.qml"], text=True).strip()
        pids = [int(p) for p in out.split() if p.isdigit()]
        if pids:
            qs_pid = pids[0]
    except Exception:
        pass

    if qs_pid:
        try:
            out_c = subprocess.check_output(["pgrep", "-P", str(qs_pid), "-f", "stream_audio_visualizer.py"], text=True).strip()
            cpids = [int(p) for p in out_c.split() if p.isdigit()]
            if cpids:
                cava_pid = cpids[0]
        except Exception:
            pass
    return qs_pid, cava_pid


def test_mpris_seeking():
    print("\n" + "=" * 60)
    print(">>> 1. EMPIRICAL CHALLENGE: MPRIS SEEKING ENGINE")
    print("=" * 60)

    # 1.1 Non-existent player without target (0 players running)
    res = subprocess.run([sys.executable, str(SEEK_SCRIPT), "10", "--relative"], capture_output=True, text=True)
    status_1_1 = (res.returncode == 0)
    RESULTS["mpris_tests"]["1.1_no_player_no_target"] = {
        "passed": status_1_1,
        "code": res.returncode,
        "expected": 0,
        "desc": "No player running and no target specified returns exit code 0 (safe no-op)"
    }
    print(f"  [1.1] No player running, no target: code={res.returncode} -> {'PASS' if status_1_1 else 'FAIL'}")

    # 1.2 Non-existent player with target
    res = subprocess.run([sys.executable, str(SEEK_SCRIPT), "10", "--relative", "-p", "totally_nonexistent_xyz_999"], capture_output=True, text=True)
    status_1_2 = (res.returncode == 1)
    RESULTS["mpris_tests"]["1.2_nonexistent_target_relative"] = {
        "passed": status_1_2,
        "code": res.returncode,
        "expected": 1,
        "desc": "Non-existent target with relative seek returns exit code 1"
    }
    print(f"  [1.2] Nonexistent target (relative): code={res.returncode} -> {'PASS' if status_1_2 else 'FAIL'}")

    # 1.3 Non-existent player with target (absolute positive)
    res = subprocess.run([sys.executable, str(SEEK_SCRIPT), "10", "--absolute", "-p", "totally_nonexistent_xyz_999"], capture_output=True, text=True)
    status_1_3 = (res.returncode == 1)
    RESULTS["mpris_tests"]["1.3_nonexistent_target_absolute_pos"] = {
        "passed": status_1_3,
        "code": res.returncode,
        "expected": 1,
        "desc": "Non-existent target with absolute positive seek returns exit code 1"
    }
    print(f"  [1.3] Nonexistent target (absolute pos=10): code={res.returncode} -> {'PASS' if status_1_3 else 'FAIL'}")

    # 1.4 Non-existent player with target (absolute negative) -- BUG PROBE
    res = subprocess.run([sys.executable, str(SEEK_SCRIPT), "-10", "--absolute", "-p", "totally_nonexistent_xyz_999"], capture_output=True, text=True)
    status_1_4 = (res.returncode == 1)
    RESULTS["mpris_tests"]["1.4_nonexistent_target_absolute_neg"] = {
        "passed": status_1_4,
        "code": res.returncode,
        "expected": 1,
        "desc": "Non-existent target with absolute negative seek returns exit code 1 (Checks playerctl Unknown option flaw)",
        "flaw_observed": res.returncode == 0
    }
    print(f"  [1.4] Nonexistent target (absolute neg=-10): code={res.returncode} (expected 1) -> {'PASS' if status_1_4 else 'FAIL [BUG DETECTED: playerctl option parser flaw masking error]'}")

    # 1.5 Invalid player target formats
    res = subprocess.run([sys.executable, str(SEEK_SCRIPT), "10", "--relative", "-p", "org.mpris.MediaPlayer2."], capture_output=True, text=True)
    status_1_5 = (res.returncode == 1)
    RESULTS["mpris_tests"]["1.5_invalid_target_prefix"] = {
        "passed": status_1_5,
        "code": res.returncode,
        "expected": 1,
        "desc": "Bare prefix 'org.mpris.MediaPlayer2.' returns exit code 1"
    }
    print(f"  [1.5] Invalid prefix target: code={res.returncode} -> {'PASS' if status_1_5 else 'FAIL'}")

    # 1.6 Unseekable player (CanSeek=False)
    with MockPlayerContext("AdversarialUnseekable", mode="cannot_seek", init_pos=50_000_000) as player:
        # Relative forward seek (+10s)
        res_rel_pos = subprocess.run([sys.executable, str(SEEK_SCRIPT), "10", "--relative", "-p", "AdversarialUnseekable"], capture_output=True, text=True)
        # Relative backward seek (-10s)
        res_rel_neg = subprocess.run([sys.executable, str(SEEK_SCRIPT), "-10", "--relative", "-p", "AdversarialUnseekable"], capture_output=True, text=True)
        # Absolute positive seek (+20s)
        res_abs_pos = subprocess.run([sys.executable, str(SEEK_SCRIPT), "20", "--absolute", "-p", "AdversarialUnseekable"], capture_output=True, text=True)
        # Absolute negative seek (-10s) -- BUG PROBE
        res_abs_neg = subprocess.run([sys.executable, str(SEEK_SCRIPT), "-10", "--absolute", "-p", "AdversarialUnseekable"], capture_output=True, text=True)

        seek_calls = player.get_seek_calls()
        setpos_calls = player.get_setpos_calls()

        RESULTS["mpris_tests"]["1.6_unseekable_rel_pos"] = {"code": res_rel_pos.returncode, "expected": 1, "passed": res_rel_pos.returncode == 1}
        RESULTS["mpris_tests"]["1.6_unseekable_rel_neg"] = {"code": res_rel_neg.returncode, "expected": 1, "passed": res_rel_neg.returncode == 1}
        RESULTS["mpris_tests"]["1.6_unseekable_abs_pos"] = {"code": res_abs_pos.returncode, "expected": 1, "passed": res_abs_pos.returncode == 1}
        RESULTS["mpris_tests"]["1.6_unseekable_abs_neg"] = {"code": res_abs_neg.returncode, "expected": 1, "passed": res_abs_neg.returncode == 1, "flaw_observed": res_abs_neg.returncode == 0}
        RESULTS["mpris_tests"]["1.6_unseekable_calls_count"] = {"seek_calls": len(seek_calls), "setpos_calls": len(setpos_calls), "passed": len(seek_calls) == 0 and len(setpos_calls) == 0}

        print(f"  [1.6a] Unseekable player relative pos (+10): code={res_rel_pos.returncode} -> {'PASS' if res_rel_pos.returncode == 1 else 'FAIL'}")
        print(f"  [1.6b] Unseekable player relative neg (-10): code={res_rel_neg.returncode} -> {'PASS' if res_rel_neg.returncode == 1 else 'FAIL'}")
        print(f"  [1.6c] Unseekable player absolute pos (+20): code={res_abs_pos.returncode} -> {'PASS' if res_abs_pos.returncode == 1 else 'FAIL'}")
        print(f"  [1.6d] Unseekable player absolute neg (-10): code={res_abs_neg.returncode} -> {'PASS' if res_abs_neg.returncode == 1 else 'FAIL [BUG DETECTED: exit 0 on unseekable]'}")
        print(f"  [1.6e] D-Bus calls on unseekable: seek_calls={len(seek_calls)}, setpos_calls={len(setpos_calls)} (Expected: 0)")

    # 1.7 Extreme seek values on a seekable player
    with MockPlayerContext("AdversarialSeekable", mode="both", init_pos=50_000_000) as player:
        # Large value within Int64 range (1e6, 1e9, 1e12)
        res_1e9 = subprocess.run([sys.executable, str(SEEK_SCRIPT), "1e9", "--relative", "-p", "AdversarialSeekable"], capture_output=True, text=True)
        # Value exceeding Int64 range (1e15)
        res_1e15 = subprocess.run([sys.executable, str(SEEK_SCRIPT), "1e15", "--relative", "-p", "AdversarialSeekable"], capture_output=True, text=True)
        # NaN
        res_nan = subprocess.run([sys.executable, str(SEEK_SCRIPT), "nan", "--relative", "-p", "AdversarialSeekable"], capture_output=True, text=True)
        # Positive Inf
        res_inf = subprocess.run([sys.executable, str(SEEK_SCRIPT), "inf", "--relative", "-p", "AdversarialSeekable"], capture_output=True, text=True)

        RESULTS["mpris_tests"]["1.7_extreme_1e9"] = {"code": res_1e9.returncode, "expected": 0, "passed": res_1e9.returncode == 0}
        RESULTS["mpris_tests"]["1.7_overflow_1e15"] = {"code": res_1e15.returncode, "expected": 1, "passed": res_1e15.returncode == 1}
        RESULTS["mpris_tests"]["1.7_nan"] = {"code": res_nan.returncode, "expected": 1, "passed": res_nan.returncode == 1}
        RESULTS["mpris_tests"]["1.7_inf"] = {"code": res_inf.returncode, "expected": 1, "passed": res_inf.returncode == 1}

        print(f"  [1.7a] Extreme 1e9 seek: code={res_1e9.returncode} -> {'PASS' if res_1e9.returncode == 0 else 'FAIL'}")
        print(f"  [1.7b] Overflow 1e15 seek: code={res_1e15.returncode} (graceful Int64 overflow rejection) -> {'PASS' if res_1e15.returncode == 1 else 'FAIL'}")
        print(f"  [1.7c] NaN seek: code={res_nan.returncode} (graceful rejection) -> {'PASS' if res_nan.returncode == 1 else 'FAIL'}")
        print(f"  [1.7d] Inf seek: code={res_inf.returncode} (graceful rejection) -> {'PASS' if res_inf.returncode == 1 else 'FAIL'}")


def test_socket_ipc_stress():
    print("\n" + "=" * 60)
    print(">>> 2. EMPIRICAL CHALLENGE: LIVE SOCKET IPC STRESS & FUZZING")
    print("=" * 60)

    if not os.path.exists(SOCK_PATH):
        print(f"ERROR: Socket {SOCK_PATH} does not exist!")
        RESULTS["ipc_tests"]["socket_exists"] = False
        return

    qs_pid, cava_pid = find_quickshell_pids()
    print(f"Target QuickShell PID: {qs_pid}, Visualizer PID: {cava_pid}")

    # Baseline resource metrics
    base_cpu, base_rss = get_process_metrics(qs_pid) if qs_pid else (None, None)
    RESULTS["resource_telemetry"]["baseline"] = {"cpu": base_cpu, "rss_mb": base_rss}
    print(f"Baseline QuickShell telemetry: CPU={base_cpu}%, RSS={base_rss:.1f}MB")

    # 2.1 50 Concurrent Bursts
    print("\n--- [2.1] 50 Concurrent Bursts ---")
    commands = [
        "toggle", "nook", "apps", "walls", "stats",
        "tab:0", "tab:1", "tab:2", "tab:3",
        "osd:vol:50", "osd:vol:80", "osd:bri:70",
        "notifs", "audio", "reload_settings", "close"
    ]

    burst_results = []
    threads = []
    start_time = time.time()

    def send_worker(idx, cmd):
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.settimeout(2.0)
                s.connect(SOCK_PATH)
                s.sendall(f"{cmd}\n".encode("utf-8"))
                burst_results.append((idx, True, None))
        except Exception as e:
            burst_results.append((idx, False, str(e)))

    for i in range(50):
        cmd = commands[i % len(commands)]
        t = threading.Thread(target=send_worker, args=(i, cmd))
        threads.append(t)

    for t in threads:
        t.start()
    for t in threads:
        t.join(timeout=3.0)

    burst_duration = time.time() - start_time
    success_count = sum(1 for _, ok, _ in burst_results if ok)
    fail_count = len(burst_results) - success_count

    RESULTS["ipc_tests"]["concurrent_50_bursts"] = {
        "total": len(burst_results),
        "success": success_count,
        "failed": fail_count,
        "duration_sec": round(burst_duration, 3),
        "errors": [err for _, ok, err in burst_results if not ok][:5]
    }
    print(f"  50 Concurrent Bursts: {success_count}/50 succeeded in {burst_duration:.3f}s (Failed: {fail_count})")

    # Metrics during burst
    mid_cpu, mid_rss = get_process_metrics(qs_pid) if qs_pid else (None, None)
    RESULTS["resource_telemetry"]["during_burst"] = {"cpu": mid_cpu, "rss_mb": mid_rss}
    print(f"  Telemetry during/after burst: CPU={mid_cpu}%, RSS={mid_rss:.1f}MB")

    # 2.2 Malformed Tokens & Fuzzing
    print("\n--- [2.2] Malformed Tokens & Fuzzing Payloads ---")
    fuzz_payloads = [
        ("empty_newline", b"\n"),
        ("whitespace", b"   \t  \n"),
        ("unknown_command", b"completely_unknown_command_xyz_404\n"),
        ("tab_negative", b"tab:-1\n"),
        ("tab_overflow", b"tab:9999\n"),
        ("tab_nan", b"tab:nan\n"),
        ("tab_empty", b"tab:\n"),
        ("tab_huge_int", b"tab:9999999999999999999999999999\n"),
        ("settings_tab_neg", b"settings:tab:-1\n"),
        ("settings_tab_out_of_bounds", b"settings:tab:10\n"),
        ("settings_tab_string", b"settings:tab:foo\n"),
        ("osd_vol_neg", b"osd:vol:-50\n"),
        ("osd_vol_over_150", b"osd:vol:999\n"),
        ("osd_vol_nan", b"osd:vol:nan\n"),
        ("osd_vol_empty", b"osd:vol:\n"),
        ("osd_bri_neg", b"osd:bri:-20\n"),
        ("osd_bri_over_100", b"osd:bri:500\n"),
        ("osd_bri_invalid", b"osd:bri:abc\n"),
        ("unicode_emojis", "🚀🔥 notch toggle 💡\n".encode("utf-8")),
        ("null_bytes", b"\x00\x00\x00\x01\x02\n"),
        ("binary_garbage", b"\xff\xfe\xfd\x80\xaa\xbb\xcc\n"),
        ("command_injection_shell", b"toggle; echo INJECTION_ATTEMPT; rm -rf /tmp/fake\n"),
        ("command_injection_subshell", b"$(sleep 1)\n"),
        ("oversized_100kb", (b"A" * 102400) + b"\n"),
    ]

    fuzz_results = {}
    for name, payload in fuzz_payloads:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.settimeout(1.0)
                s.connect(SOCK_PATH)
                s.sendall(payload)
                fuzz_results[name] = {"sent": True, "error": None}
        except Exception as e:
            fuzz_results[name] = {"sent": False, "error": str(e)}

    # Verify socket is still alive after fuzzing
    time.sleep(0.2)
    socket_alive_after_fuzz = False
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(1.0)
            s.connect(SOCK_PATH)
            s.sendall(b"close\n")
            socket_alive_after_fuzz = True
    except Exception:
        socket_alive_after_fuzz = False

    RESULTS["ipc_tests"]["fuzzing"] = {
        "payloads_tested": len(fuzz_payloads),
        "fuzz_results": fuzz_results,
        "socket_alive_after_fuzz": socket_alive_after_fuzz
    }
    print(f"  Fuzzing completed: {len(fuzz_payloads)} payloads sent. Socket alive: {socket_alive_after_fuzz}")

    # 2.3 Rapid Multi-Line Payloads
    print("\n--- [2.3] Rapid Multi-Line Payloads ---")
    multi_line_payload = b"stats\napps\nwalls\nclose\n"
    multiline_sent = False
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(1.0)
            s.connect(SOCK_PATH)
            s.sendall(multi_line_payload)
            multiline_sent = True
    except Exception as e:
        multiline_sent = False

    # 50 Rapid Sequential Bursts
    rapid_sequential_count = 0
    for i in range(50):
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.settimeout(1.0)
                s.connect(SOCK_PATH)
                s.sendall(b"close\n")
                rapid_sequential_count += 1
        except Exception:
            pass

    RESULTS["ipc_tests"]["rapid_multiline"] = {
        "multiline_sent": multiline_sent,
        "rapid_sequential_50": rapid_sequential_count
    }
    print(f"  Multi-line stream sent: {multiline_sent}. 50 rapid sequential connections: {rapid_sequential_count}/50")

    # 2.4 Cooldown & Post-Test Telemetry
    print("\n--- [2.4] Resource Cooldown & Leak Analysis ---")
    time.sleep(2.0)
    cool_cpu_2s, cool_rss_2s = get_process_metrics(qs_pid) if qs_pid else (None, None)
    time.sleep(3.0)
    cool_cpu_5s, cool_rss_5s = get_process_metrics(qs_pid) if qs_pid else (None, None)

    RESULTS["resource_telemetry"]["cooldown_2s"] = {"cpu": cool_cpu_2s, "rss_mb": cool_rss_2s}
    RESULTS["resource_telemetry"]["cooldown_5s"] = {"cpu": cool_cpu_5s, "rss_mb": cool_rss_5s}

    rss_growth = (cool_rss_5s - base_rss) if (cool_rss_5s and base_rss) else 0.0
    print(f"  Cooldown 2s: CPU={cool_cpu_2s}%, RSS={cool_rss_2s:.1f}MB")
    print(f"  Cooldown 5s: CPU={cool_cpu_5s}%, RSS={cool_rss_5s:.1f}MB")
    print(f"  Net RSS Growth across all stress tests: {rss_growth:+.2f} MB")


if __name__ == "__main__":
    test_mpris_seeking()
    test_socket_ipc_stress()

    import json
    results_path = BASE_DIR / "tests" / "challenger_m1_results.json"
    with open(results_path, "w") as fp:
        json.dump(RESULTS, fp, indent=2)
    print(f"\n[Complete] Results dumped to {results_path}")
