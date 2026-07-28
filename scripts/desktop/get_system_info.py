#!/usr/bin/env python3
import time
import json
import os

def get_cpu_usage():
    try:
        with open("/proc/stat", "r") as fp:
            line1 = fp.readline()
        parts1 = [float(x) for x in line1.split()[1:]]
        idle1 = parts1[3] + parts1[4]
        total1 = sum(parts1)
        
        time.sleep(0.1)
        
        with open("/proc/stat", "r") as fp:
            line2 = fp.readline()
        parts2 = [float(x) for x in line2.split()[1:]]
        idle2 = parts2[3] + parts2[4]
        total2 = sum(parts2)
        
        total_diff = total2 - total1
        idle_diff = idle2 - idle1
        if total_diff > 0:
            return int((1.0 - (idle_diff / total_diff)) * 100)
        return 0
    except Exception:
        return 0

def get_ram_usage():
    try:
        mem = {}
        with open("/proc/meminfo", "r") as fp:
            for line in fp:
                parts = line.split()
                if len(parts) >= 2:
                    mem[parts[0].rstrip(":")] = float(parts[1])
        total = mem.get("MemTotal", 1.0)
        free = mem.get("MemFree", 0.0)
        buffers = mem.get("Buffers", 0.0)
        cached = mem.get("Cached", 0.0)
        used = total - free - buffers - cached
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

if __name__ == "__main__":
    cpu = get_cpu_usage()
    ram = get_ram_usage()
    disk = get_disk_usage()
    print(json.dumps({"cpu": cpu, "ram": ram, "disk": disk}))
