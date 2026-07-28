import urllib.request
import os

ICONS = [
    "wifi", "wifi_off", "bluetooth", "bluetooth_disabled",
    "battery_full", "battery_charging_full", "battery_alert", 
    "memory", "hard_drive", "notifications", "notifications_off", 
    "search", "wallpaper", "apps", "coffee", "done", "light_mode",
    "mic", "mic_off", "volume_up", "volume_down", "volume_mute", "volume_off",
    "play_arrow", "pause", "skip_next", "skip_previous"
]

base_url = "https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsrounded/{}/default/48px.svg"
out_dir = "/home/yogesh/.config/quickshell/assets/icons/"

for icon in ICONS:
    url = base_url.format(icon)
    path = os.path.join(out_dir, f"{icon}.svg")
    try:
        urllib.request.urlretrieve(url, path)
        print(f"Success: {icon}")
    except Exception as e:
        print(f"Failed: {icon} - {e}")
