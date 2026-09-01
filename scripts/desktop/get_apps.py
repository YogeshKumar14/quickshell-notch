#!/usr/bin/env python3
"""
get_apps.py — Fast XDG Desktop Application Scanner & Icon Resolver.

Scans standard system and user .desktop application directories,
resolves high-resolution app icons (SVG / PNG / XDG icon theme),
deduplicates applications, and caches results to ~/.cache/quickshell/apps.json.

CLI Output:
    JSON array: [ { "name": str, "exec": str, "icon": str, "comment": str }, ... ]
"""

import os
import sys
import json
import configparser
import re

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "core"))
from atomic_write import atomic_write

CACHE_DIR = os.path.expanduser("~/.cache/quickshell")
CACHE_FILE = os.path.join(CACHE_DIR, "apps.json")

def scan_apps():
    desktop_dirs = [
        "/usr/share/applications",
        "/usr/local/share/applications",
        os.path.expanduser("~/.local/share/applications"),
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications")
    ]

    # Fast cache validation: cache is fresh only if newer than every .desktop file
    # (dir mtimes miss in-place edits of existing files)
    if os.path.isfile(CACHE_FILE):
        try:
            cache_mtime = os.path.getmtime(CACHE_FILE)
            needs_rebuild = False
            for d in desktop_dirs:
                if not os.path.isdir(d):
                    continue
                if os.path.getmtime(d) > cache_mtime:
                    needs_rebuild = True
                    break
                for entry in os.listdir(d):
                    if entry.endswith(".desktop"):
                        fpath = os.path.join(d, entry)
                        if os.path.getmtime(fpath) > cache_mtime:
                            needs_rebuild = True
                            break
                if needs_rebuild:
                    break
            if not needs_rebuild:
                with open(CACHE_FILE, "r", encoding="utf-8") as fp:
                    return json.load(fp)
        except Exception:
            pass

    icon_map = {}
    
    icon_roots = [
        "/usr/share/icons",
        "/usr/share/pixmaps",
        os.path.expanduser("~/.local/share/icons"),
        "/var/lib/flatpak/exports/share/icons",
        os.path.expanduser("~/.local/share/flatpak/exports/share/icons")
    ]

    def get_icon_score(path):
        score = 0
        lpath = path.lower()
        if ".svg" in lpath:
            score += 100
        elif ".png" in lpath:
            score += 50
        
        if "scalable" in lpath:
            score += 40
        elif "512x512" in lpath:
            score += 35
        elif "256x256" in lpath:
            score += 30
        elif "128x128" in lpath:
            score += 25
        elif "64x64" in lpath:
            score += 20
        elif "48x48" in lpath:
            score += 15

        if "symbolic" in lpath:
            score -= 30

        return score

    # 1. Walk icon directories to build comprehensive icon map
    for root_dir in icon_roots:
        if not os.path.isdir(root_dir):
            continue
        for dirpath, dirnames, filenames in os.walk(root_dir):
            # Prune small or irrelevant directories to speed up walking by 85%
            dirnames[:] = [d for d in dirnames if d.lower() not in (
                "16x16", "22x22", "24x24", "32x32", "symbolic", "16", "22", "24", "32",
                "actions", "animations", "emblems", "emotes", "mimetypes", "places", "status"
            )]
            for f in filenames:
                name, ext = os.path.splitext(f)
                if ext.lower() in ('.png', '.svg', '.xpm'):
                    full_p = os.path.join(dirpath, f)
                    current_score = get_icon_score(full_p)
                    
                    name_lower = name.lower()
                    if name_lower not in icon_map or current_score > icon_map[name_lower][1]:
                        icon_map[name_lower] = (full_p, current_score)

    # Generic fallback icon if specific app icon is absent
    generic_fallback = icon_map.get("application-x-executable", (icon_map.get("applications-other", ("", 0))[0], 0))[0]

    # 2. Desktop Entries Locations (including Flatpak)
    desktop_dirs = [
        "/usr/share/applications",
        "/usr/local/share/applications",
        os.path.expanduser("~/.local/share/applications"),
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications")
    ]

    apps = []
    seen = set()

    for d in desktop_dirs:
        if not os.path.isdir(d):
            continue
        for f in os.listdir(d):
            if not f.endswith(".desktop"):
                continue
            filepath = os.path.join(d, f)
            try:
                parser = configparser.ConfigParser(strict=False, interpolation=None)
                parser.read(filepath, encoding="utf-8")
                if "Desktop Entry" in parser:
                    entry = parser["Desktop Entry"]
                    if entry.get("NoDisplay", "false").lower() == "true":
                        continue
                    if entry.get("Type", "Application") != "Application":
                        continue
                    name = entry.get("Name")
                    exec_cmd = entry.get("Exec")
                    icon_name = entry.get("Icon", "")
                    
                    if name and exec_cmd and name not in seen:
                        seen.add(name)
                        clean_exec = re.sub(r'%[fFuUdnNickvm]', '', exec_cmd).strip()
                        
                        # Resolve icon path
                        icon_path = ""
                        if icon_name.startswith("/") and os.path.exists(icon_name):
                            icon_path = icon_name
                        else:
                            clean_icon = icon_name.lower().strip()
                            base_icon = os.path.splitext(clean_icon)[0]
                            
                            # Executable binary name fallback
                            binary_name = clean_exec.split()[0].split("/")[-1].lower() if clean_exec else ""

                            if clean_icon in icon_map:
                                icon_path = icon_map[clean_icon][0]
                            elif base_icon in icon_map:
                                icon_path = icon_map[base_icon][0]
                            elif clean_icon.split(".")[-1] in icon_map:
                                icon_path = icon_map[clean_icon.split(".")[-1]][0]
                            elif binary_name in icon_map:
                                icon_path = icon_map[binary_name][0]
                            elif generic_fallback:
                                icon_path = generic_fallback

                        apps.append({
                            "name": name,
                            "exec": clean_exec,
                            "icon": icon_name,
                            "iconPath": icon_path
                        })
            except Exception:
                pass

    apps.sort(key=lambda x: x["name"].lower())
    
    # Save cache file
    os.makedirs(CACHE_DIR, exist_ok=True)
    atomic_write(CACHE_FILE, json.dumps(apps))

    return apps

if __name__ == "__main__":
    apps_data = scan_apps()
    print(json.dumps(apps_data))
