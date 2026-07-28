import urllib.request
import os

ICONS = [
    "wifi", "bluetooth", "battery_full", "battery_charging_full", 
    "battery_alert", "memory", "hard_drive", "notifications", 
    "notifications_off", "search", "wallpaper", "apps", "coffee"
]

base_url = "https://raw.githubusercontent.com/google/material-design-icons/master/symbols/web/{}/materialsymbolsrounded/{}_48px.svg"
out_dir = "/home/yogesh/.config/quickshell/assets/icons/"

for icon in ICONS:
    url = base_url.format(icon, icon)
    path = os.path.join(out_dir, f"{icon}.svg")
    print(f"Downloading {icon}...")
    try:
        urllib.request.urlretrieve(url, path)
        print(f"  Success: {icon}")
    except Exception as e:
        print(f"  Failed: {icon} ({e})")
