# QuickShell Top Notch

A customized, high-performance desktop status bar and control center built with [QuickShell](https://quickshell.outfoxxed.me/), styled with [Wallust](https://github.com/explosion-mental/wallust) accent colors, and deeply integrated with Hyprland, NetworkManager, BlueZ, and SwayNC.

Top Notch morphs dynamically between a compact top-center status pill and an expanded, tabbed system control dashboard — all with spring-physics animations.

## Showcase

### Dynamic Dashboard
![Notch Expanded Dashboard](assets/2026-07-28-132607_hyprshot.png)

### Widget Integrations
![Notch Widgets](assets/2026-07-27-223516_hyprshot.png)

### Video Demo
<video src="assets/notch_demo.mp4" width="100%" controls="controls"></video>

---

## Features

- **Dynamic Pill Morphing**: Spring-physics morphing between compact, expanded, and power-menu states.
- **Workspace Overlay**: Real-time workspace dots on the compact pill — occupied workspaces are highlighted, clicking a dot jumps to that workspace, clicking anywhere expands the notch.
- **Hardware Stats Dashboard**: Real-time graphs for CPU and RAM load using custom canvas paths, plus disk storage tracking. Polling sleeps while the tab is hidden (0% idle overhead) and the polling interval is configurable.
- **MPRIS Media Controller**: Fully functional music controller with dynamic album art, seek-enabled timeline slider, volume controls, and metadata (native `Quickshell.Services.Mpris`, no extra daemons).
- **Fast App Launcher**: Desktop application scanner with icon path matching and flatpak walk-pruning. Caches results and re-scans when packages change.
- **Wallpaper Selector**: Dynamic grid with parallel thumbnail generation. Sets wallpapers via `awww` with Wallust palette transitions.
- **SwayNC Notification Panel**: Notification popups and history styled to match the notch. QuickShell hosts the notification D-Bus interface directly.
- **Wi-Fi & Bluetooth Panels**: Connect to networks, toggle devices, and manage saved connections via `nmcli` and `bluetoothctl` backends.
- **Audio Visualizer**: CAVA-driven reactive bars that animate when audio plays and hide when idle.
- **Settings Controller**: Adjust animation physics, visualizer styles, polling rates, notch geometry, and Hyprland options — all applied live, persisted across restarts.

---

## Requirements

- **Hyprland** ≥ 0.49 (uses the `hyprland-toplevel-mapping-v1` protocol; tested on 0.56.x with both legacy `hyprland.conf` and the new Lua config parser)
- **QuickShell** (Hyprland-enabled build)
- **Python 3.10+** (backend scripts, standard library only)

---

## Installation — Fresh Arch Linux + Hyprland

### 1. Base Arch Linux installation

If you don't have Arch installed yet, follow the [official installation guide](https://wiki.archlinux.org/title/Installation_guide) (`archinstall` or manual pacstrap). After reboot, install a minimal base:

```bash
# Base development tools (needed for AUR builds later)
sudo pacman -S --needed base-devel git
```

### 2. Install Hyprland and desktop essentials

```bash
# Hyprland + display environment
sudo pacman -S hyprland xdg-desktop-portal-hyprland

# Audio (PipeWire) — needed for the CAVA visualizer and volume/mic controls
sudo pacman -S pipewire pipewire-pulse wireplumber

# Network & Bluetooth — provides nmcli and bluetoothctl used by the notch
sudo pacman -S networkmanager bluez bluez-utils

# A terminal, notifications backend, and wallpaper/theme tooling
sudo pacman -S kitty swaync

# Enable the services
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
```

> **Tip**: also install `xdg-desktop-portal-gtk` for correct file dialogs in Flatpak apps, and any GPU/display drivers your hardware needs before launching Hyprland for the first time.

### 3. Install an AUR helper

QuickShell, Wallust, and `awww` are not in the official repos, so you need an AUR helper. Install `paru`:

```bash
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru
makepkg -si
```

### 4. Install the notch dependencies

```bash
# Official repositories
sudo pacman -S --needed \
  hyprland \
  swaync \
  cava \
  python-pillow \
  ttf-jetbrains-mono-nerd \
  ttf-ubuntu-font-family \
  ttf-inter

# AUR packages (via paru)
paru -S quickshell-git wallust-bin awww
```

| Package | Why it's needed |
|---------|-----------------|
| `hyprland` | The notch integrates with Hyprland's IPC socket and window-mapping protocol |
| `quickshell-git` | The QML runtime/engine the notch is built on (Hyprland-enabled build) |
| `swaync` | Notification backend. **Do not autostart it yourself** — the notch's launcher manages it and QuickShell hosts the notification interface |
| `cava` | Audio visualizer stream (now in the official `extra` repo) |
| `awww` | Wallpaper daemon; the wallpaper selector applies images through it |
| `wallust-bin` | Generates the accent color palette from your wallpaper |
| `python-pillow` | Parallel wallpaper thumbnail generation |
| `networkmanager` + `bluez-utils` | `nmcli` / `bluetoothctl` backends for the Wi-Fi and Bluetooth panels |
| Nerd Fonts | Glyph icons used throughout the UI (JetBrains Mono Nerd Font ships the glyph set) |

### 5. Clone the configuration

```bash
git clone https://github.com/YogeshKumar14/quickshell-notch.git ~/.config/quickshell
```

### 6. Configure Wallust (accent colors)

The notch reads its accent color from the Wallust shell template. Set up Wallust so it writes `~/.cache/wal/colors.sh`:

```bash
mkdir -p ~/.config/wallust
```

Create `~/.config/wallust/wallust.toml` (minimal example):

```toml
wallpaper = "~/.config/wallust/current_wallpaper"   # path to your wallpaper
backend = "wal"
palette = 16

[template]
  "shell-colors" = { output = "~/.cache/wal/colors.sh" }
```

Then generate the palette once:

```bash
wallust run ~/Pictures/wallpapers/your-wallpaper.jpg
```

Verify it worked:

```bash
cat ~/.cache/wal/colors.sh | head   # should contain color0..color15 hex values
```

> The notch falls back to a default blue accent (`#0A84FF`) when the file is missing, so a wrong Wallust setup only breaks theming, not the notch itself.

### 7. Integrate with Hyprland

**Option A — standard `hyprland.conf`:**

```ini
exec-once = bash ~/.config/quickshell/scripts/core/launch_quickshell.sh

# Persistence imports for dynamically applied settings
source = ~/.config/hypr/quickshell_hypr.conf
```

**Option B — Lua config (`hyprland.lua`):**

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("$HOME/.config/quickshell/scripts/core/launch_quickshell.sh")
end)

-- Persistence imports for dynamically applied settings
import("quickshell_hypr.lua")
```

The launcher script (`launch_quickshell.sh`) kills any stale `quickshell`, `cava`, visualizer, and `swaync` processes, then starts QuickShell against `shell.qml`. Use the same script whenever you want a clean restart.

### 8. First run

Log out and back into Hyprland (or run the launcher manually once):

```bash
bash ~/.config/quickshell/scripts/core/launch_quickshell.sh
```

You should see the compact pill at the top-center of the screen. Hover/click it to expand the dashboard. To reload after changing anything:

```bash
pkill -9 -x quickshell; bash ~/.config/quickshell/scripts/core/launch_quickshell.sh
```

Runtime logs live at `/run/user/$UID/quickshell/by-id/*/log.qslog` — check there if something looks broken.

### 9. Optional: keybind the notch

The notch exposes a local IPC socket at `/tmp/quickshell-notch.sock`. Add Hyprland keybinds like:

```ini
bind = SUPER, N, exec, python3 ~/.config/quickshell/scripts/notch/notch_ipc.py toggle
bind = SUPER, V, exec, python3 ~/.config/quickshell/scripts/notch/notch_ipc.py osd:vol:50
bind = SUPER, B, exec, python3 ~/.config/quickshell/scripts/notch/notch_ipc.py osd:bri:80
```

See the [IPC reference](#ipc-reference) below for all commands.

---

## Dynamic Settings Persistence

The notch writes user configuration overrides dynamically to **both**:

- `~/.config/hypr/quickshell_hypr.lua`
- `~/.config/hypr/quickshell_hypr.conf`

These files are written atomically and must be imported/sourced inside your main Hyprland configuration (see step 7) so options like border sizes, rounding, shadows, and gaps persist across restarts. The same option is written in the correct syntax for each parser (`rgba(...)` byte order differs between the Lua and legacy conf parsers).

> On Hyprland builds with the non-legacy (Lua) config parser, `hyprctl keyword` silently no-ops. All live-apply paths detect this and fall back to `hyprctl eval` + `hl.config(...)` merging automatically.

---

## IPC Reference

Socket: `/tmp/quickshell-notch.sock` — control via `scripts/notch/notch_ipc.py`:

| Command | Action |
|---------|--------|
| `toggle` | Expand/collapse notch |
| `close` | Collapse notch |
| `walls` | Toggle wallpaper tab |
| `apps` | Toggle app launcher tab |
| `osd:vol:{0-100}` | Show volume OSD |
| `osd:bri:{0-100}` | Show brightness OSD |

---

## Directory Structure

```
~/.config/quickshell/
├── shell.qml                      # Main entry point (LayerShell window + input mask)
├── components/                    # QML layouts and tabs
│   ├── TopNotch.qml               # Primary notch: pill, tabs, media, stats, visualizer
│   ├── AppLauncher.qml            # App grid launcher with cached matching
│   ├── WallpaperSelector.qml      # Wallpaper grid selector
│   ├── WifiMenu.qml               # Wi-Fi networks panel
│   ├── BluetoothMenu.qml          # Bluetooth devices panel
│   ├── PowerMenu.qml              # Power actions overlay
│   ├── SettingsWindow.qml         # Configuration options panel
│   ├── NotificationPopups.qml     # SwayNC-styled notification popups
│   ├── NotificationHistory.qml    # Notification history view
│   ├── CustomSlider.qml           # Styled slider
│   ├── CustomSwitch.qml           # Styled toggle switch
│   ├── M3Icon.qml                 # Nerd Font glyph → M3 SVG icon mapper
│   └── SparklineCanvas.qml        # CPU/RAM graph rendering
├── scripts/
│   ├── core/
│   │   ├── launch_quickshell.sh   # Clean relaunch (kills strays first)
│   │   ├── validate_codebase.sh   # QML/Python/Bash validation pipeline
│   │   ├── sandbox.sh             # Non-disruptive test instance launcher
│   │   ├── osd.sh                 # Volume/brightness OSD helper
│   │   └── download_m3_icons.sh   # Fetches Material Symbols SVGs
│   ├── desktop/
│   │   ├── get_apps.py            # Desktop entry scanner with caching
│   │   ├── scan_wallpapers.py     # Parallel wallpaper thumbnail generator
│   │   ├── apply_wallpaper.sh     # awww-daemon wallpaper setter
│   │   └── get_wallust_colors.sh  # Reads accent color from wal cache
│   ├── hyprland/
│   │   ├── apply_all_settings.py  # Atomic dual-write of notch+hypr settings
│   │   ├── apply_hypr_option.py   # hyprctl live-apply (lua-aware fallback)
│   │   ├── persist_hypr_state.py  # Writes lua + conf persistence files
│   │   └── set_hypr_option.sh     # Shell wrapper for live apply
│   ├── network/
│   │   ├── manage_wifi.py         # nmcli backend (scan/connect/status)
│   │   └── manage_bluetooth.py    # bluetoothctl backend
│   └── notch/
│       ├── notch_ipc.py           # IPC socket client (keybind commands)
│       ├── get_notch_settings.py  # Reads notch_settings.json (defaults live here)
│       ├── set_notch_option.sh    # Writes notch settings
│       └── stream_audio_visualizer.py  # CAVA child → JSON stream (pdeathsig)
├── theme/
│   └── Style.qml                  # Global colors, fonts, radii
├── assets/
│   ├── icons/                     # Material Symbols SVGs (M3Icon table)
│   └── *.png / notch_demo.mp4     # README showcase media
└── notch_settings.json            # Runtime notch preferences
```

---

## Development

### Validation pipeline

Before committing or reloading, run the full static validation:

```bash
~/.config/quickshell/scripts/core/validate_codebase.sh
```

This checks QML (`qmllint`), Python (`py_compile`), and Bash (`bash -n`). A non-zero exit means do **not** reload or commit.

### Sandbox mode

For non-disruptive UI iteration:

```bash
QUICKSHELL_SANDBOX=1 quickshell -n -p ~/.config/quickshell/shell.qml
```

Scripts detect the env var and skip all Hyprland side-effects (no setting writes, no wallpaper changes).

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| Notch doesn't appear | The launcher must run **inside** a Hyprland session (`HYPRLAND_INSTANCE_SIGNATURE` set). Check `/run/user/$UID/quickshell/by-id/*/log.qslog` for IPC errors. |
| Accent colors are default blue | Wallust isn't writing `~/.cache/wal/colors.sh` — run `wallust run <wallpaper>` and verify the file exists. |
| Notifications don't pop up | Normal: QuickShell hosts the notification D-Bus interface; the launcher kills `swaync` deliberately. Don't autostart swaync separately. |
| Wi-Fi / Bluetooth icons always off | `NetworkManager` / `bluetooth` services not running: `sudo systemctl enable --now NetworkManager bluetooth`. |
| Visualizer never animates | `cava` missing or PipeWire not running (`pipewire pipewire-pulse wireplumber`). |
| Settings don't survive Hyprland restart | The persistence files must be imported in your Hyprland config (`source = quickshell_hypr.conf` or `import("quickshell_hypr.lua")`). |
| Clipped/misaligned expanded notch | The expanded height is dynamic per tab; adjust `expanded_height` in Settings → notch tab. |

---

## License

This project is licensed under the MIT License — see the license text below.

```
MIT License

Copyright (c) 2026 Yogesh Kumar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
