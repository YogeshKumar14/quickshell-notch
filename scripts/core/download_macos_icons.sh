#!/bin/bash
# download_macos_icons.sh — Utility script to download Apple macOS SF Symbols SVG icons.
#
# Usage:
#   bash scripts/core/download_macos_icons.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$(cd "${SCRIPT_DIR}/../../assets/icons" && pwd)"
mkdir -p "${ICONS_DIR}"

python3 - <<'EOF'
import urllib.request
import os

icons_dir = os.environ.get("ICONS_DIR")

ICON_MAP = {
    # Media & Playback
    "play_arrow": "play.fill",
    "play": "play.fill",
    "pause": "pause.fill",
    "skip_next": "forward.fill",
    "skip_previous": "backward.fill",
    "fast_forward": "forward.end.fill",
    "fast_rewind": "backward.end.fill",
    "replay_10": "10.arrow.trianglehead.counterclockwise",
    "music_note": "music.note",
    "shuffle": "shuffle",
    "graphic_eq": "waveform",

    # Volume & Audio
    "volume_up": "speaker.wave.3.fill",
    "volume_down": "speaker.wave.1.fill",
    "volume_mute": "speaker.slash.fill",
    "volume_off": "speaker.slash.fill",
    "mic": "microphone.fill",
    "mic_off": "microphone.slash.fill",
    "laptopcomputer": "laptopcomputer",
    "airplay": "airplay.audio",

    # Connectivity & Hardware
    "wifi": "wifi",
    "wifi_off": "wifi.slash",
    "memory": "cpu",
    "hard_drive": "internaldrive",
    "mouse": "computermouse.fill",
    "keyboard": "keyboard.fill",
    "desktop_windows": "display",
    "display": "display",

    # Battery
    "battery_full": "battery.100percent",
    "battery_6_bar": "battery.100percent",
    "battery_5_bar": "battery.75percent",
    "battery_4_bar": "battery.50percent",
    "battery_3_bar": "battery.50percent",
    "battery_2_bar": "battery.25percent",
    "battery_1_bar": "battery.25percent",
    "battery_0_bar": "battery.0percent",
    "battery_alert": "battery.0percent",
    "battery_charging_full": "battery.100percent.bolt",
    "battery_charging_90": "battery.100percent.bolt",
    "battery_charging_80": "battery.100percent.bolt",
    "battery_charging_60": "battery.100percent.bolt",
    "battery_charging_50": "battery.100percent.bolt",
    "battery_charging_30": "battery.100percent.bolt",
    "battery_charging_20": "battery.100percent.bolt",
    "bolt": "bolt.fill",

    # Navigation & System Controls
    "home": "house.fill",
    "inbox": "tray.fill",
    "apps": "square.grid.2x2.fill",
    "space_dashboard": "square.grid.2x2",
    "settings": "gearshape.fill",
    "gearshape": "gearshape.fill",
    "power_settings_new": "power",
    "power": "power",
    "restart_alt": "arrow.clockwise",
    "refresh": "arrow.clockwise",
    "arrow.counterclockwise": "arrow.counterclockwise",
    "logout": "rectangle.portrait.and.arrow.right",
    "lock": "lock.fill",
    "coffee": "cup.and.saucer.fill",
    "close": "xmark",
    "search": "magnifyingglass",
    "delete": "trash.fill",
    "push_pin": "pin.fill",
    "chevron_right": "chevron.right",

    # Notifications & Status
    "notifications": "bell.fill",
    "notifications_none": "bell",
    "notifications_off": "bell.slash.fill",
    "check": "checkmark",
    "done": "checkmark",
    "check_circle": "checkmark.circle.fill",
    "error": "exclamationmark.circle.fill",
    "pending": "ellipsis.circle.fill",
    "fiber_manual_record": "circle.fill",

    # Display, Brightness & Time
    "brightness_high": "sun.max.fill",
    "brightness_low": "sun.min.fill",
    "light_mode": "sun.max.fill",
    "calendar_today": "calendar",
    "calendar_badge_checkmark": "calendar.badge.checkmark",
    "calendar": "calendar",
    "schedule": "clock.fill",
    "timer": "timer",
    "clock": "clock.fill",

    # Custom & Misc
    "wallpaper": "photo.fill",
    "palette": "paintpalette.fill",
    "eyedropper": "eyedropper.halffull",
    "touch_app": "hand.point.up.left.fill",
    "tune": "slider.horizontal.3",
    "trending_up": "chart.line.uptrend.xyaxis",
    "monitoring": "chart.xyaxis.line",
    "blur_on": "circle.hexagongrid.fill",
    "aspect_ratio": "aspectratio.fill",
    "view_carousel": "square.stack.3d.down.right.fill",
    "visibility": "eye.fill",
    "visibility_off": "eye.slash.fill",
    "auto_awesome": "sparkles",
    "person": "person.fill",
}

base_url = "https://raw.githubusercontent.com/brendanballon/sfsymbols-svg/master/symbols/"

for target_name, sym_name in ICON_MAP.items():
    dst = os.path.join(icons_dir, f"{target_name}.svg")
    url = f"{base_url}{sym_name}.svg"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req) as resp, open(dst, "wb") as f:
            f.write(resp.read())
        print(f"Downloaded {target_name}.svg ({sym_name})")
    except Exception as e:
        print(f"Failed {target_name}.svg ({sym_name}): {e}")

# Apple macOS Bluetooth rune icons
bt_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M6.5 6.5l11 11L12 23V1l5.5 5.5-11 11"/>
</svg>"""
with open(os.path.join(icons_dir, "bluetooth.svg"), "w") as f:
    f.write(bt_svg)

bt_dis_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M6.5 6.5l11 11L12 23V1l5.5 5.5-11 11"/>
  <line x1="3.5" y1="3.5" x2="20.5" y2="20.5" stroke="black" stroke-width="2.2" stroke-linecap="round"/>
</svg>"""
with open(os.path.join(icons_dir, "bluetooth_disabled.svg"), "w") as f:
    f.write(bt_dis_svg)
EOF

echo "macOS SF Symbols downloaded successfully."
