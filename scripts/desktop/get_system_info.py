#!/usr/bin/env python3
import time
import json
import os

STATE_FILE = f"/dev/shm/quickshell_sysinfo_{os.getuid()}.json"

def read_cpu_raw():
    try:
        with open("/proc/stat", "r") as fp:
            line = fp.readline()
        parts = [float(x) for x in line.split()[1:]]
        idle = parts[3] + parts[4]
        total = sum(parts)
        return total, idle
    except Exception:
        return 0.0, 0.0

def get_ram_usage():
    try:
        mem = {}
        with open("/proc/meminfo", "r") as fp:
            for line in fp:
                parts = line.split()
                if len(parts) >= 2:
                    mem[parts[0].rstrip(":")] = float(parts[1])
        total = mem.get("MemTotal", 1.0)
        available = mem.get("MemAvailable", mem.get("MemFree", 0.0) + mem.get("Buffers", 0.0) + mem.get("Cached", 0.0))
        used = max(0.0, total - available)
        return int((used / total) * 100)
    except Exception:
        return 0

def get_disk_usage():
    try:
        stat = os.statvfs('/')
        total = stat.f_blocks * stat.f_frsize
        free = stat.f_bfree * stat.f_frsize
        used = total - free
        if total > 0:
            return int((used / total) * 100)
        return 0
    except Exception:
        return 0

def get_net_bytes():
    rx = 0
    tx = 0
    try:
        with open("/proc/net/dev", "r") as f:
            lines = f.readlines()[2:]
            for line in lines:
                parts = line.split(":")
                if len(parts) == 2:
                    if parts[0].strip() == "lo": continue
                    data = parts[1].split()
                    rx += int(data[0])
                    tx += int(data[8])
    except Exception:
        pass
    return rx, tx

def main():
    now = time.time()
    cur_total, cur_idle = read_cpu_raw()
    cur_rx, cur_tx = get_net_bytes()
    
    cpu = 0
    rx_speed = 0
    tx_speed = 0
    
    prev = None
    if os.path.isfile(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as fp:
                prev = json.load(fp)
        except Exception:
            pass
            
    if prev and (0.4 <= (now - prev.get("time", 0)) <= 10.0):
        dt = now - prev["time"]
        total_diff = cur_total - prev["cpu_total"]
        idle_diff = cur_idle - prev["cpu_idle"]
        if total_diff > 0:
            cpu = max(0, min(100, int((1.0 - (idle_diff / total_diff)) * 100)))
        rx_diff = max(0, cur_rx - prev["net_rx"])
        tx_diff = max(0, cur_tx - prev["net_tx"])
        rx_speed = int(rx_diff / dt)
        tx_speed = int(tx_diff / dt)
    else:
        time.sleep(0.05)
        new_total, new_idle = read_cpu_raw()
        new_rx, new_tx = get_net_bytes()
        dt = 0.05
        total_diff = new_total - cur_total
        idle_diff = new_idle - cur_idle
        if total_diff > 0:
            cpu = max(0, min(100, int((1.0 - (idle_diff / total_diff)) * 100)))
        rx_speed = int(max(0, new_rx - cur_rx) / dt)
        tx_speed = int(max(0, new_tx - cur_tx) / dt)
        cur_total, cur_idle = new_total, new_idle
        cur_rx, cur_tx = new_rx, new_tx
        now = time.time()

    try:
        with open(STATE_FILE, "w") as fp:
            json.dump({
                "time": now,
                "cpu_total": cur_total,
                "cpu_idle": cur_idle,
                "net_rx": cur_rx,
                "net_tx": cur_tx
            }, fp)
    except Exception:
        pass

    ram = get_ram_usage()
    disk = get_disk_usage()
    print(json.dumps({"cpu": cpu, "ram": ram, "disk": disk, "net_rx": rx_speed, "net_tx": tx_speed}))

if __name__ == "__main__":
    main()
