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
- **Tab 0 — MPRIS Media Controller**: Fully functional music controller with dynamic album art, circular visualizer, seek-enabled timeline slider, volume/mic controls, and metadata (native `Quickshell.Services.Mpris`, no extra daemons).
- **Tab 1 — Fast App Launcher**: Desktop application scanner with icon path matching and flatpak walk-pruning. Caches results and re-scans when packages change.
- **Tab 2 — Wallpaper Selector**: Dynamic grid with parallel thumbnail generation. Sets wallpapers via `awww` with Wallust palette transitions.
- **Tab 3 — Hardware Stats Dashboard**: Real-time graphs for CPU, RAM, and Network load using custom sparkline canvas paths, plus disk storage tracking. Polling sleeps while the tab is hidden (0% idle overhead) and the polling interval is configurable.
- **Audio Routing Drawer**: Dedicated menu for switching audio sinks, sources, and controlling per-stream volume via PipeWire / WirePlumber.
- **Wi-Fi & Bluetooth Panels**: Connect to networks, toggle devices, and manage saved connections via `nmcli` and `bluetoothctl` backends.
- **Audio Visualizer**: CAVA-driven reactive bars that animate when audio plays and hide when idle.
- **Notification Center**: Notification history styled to match the notch. QuickShell hosts the notification D-Bus interface directly.
- **Settings Controller**: Adjust animation physics, visualizer styles, polling rates, notch geometry, and Hyprland options — all applied live, persisted across restarts.

---

## Requirements

- **Hyprland** ≥ 0.49 (uses the `hyprland-toplevel-mapping-v1` protocol; tested on 0.56.x with both legacy `hyprland.conf` and the new Lua config parser)
- **QuickShell** (Hyprland-enabled build)
- **Python 3.10+** (backend scripts, standard library only)

---

## Installation on Arch Linux

### Method 1: Automated Installer (Recommended)

QuickShell Top Notch includes an automated, idempotent installation script that resolves dependencies, registers fonts, bootstraps Matugen templates, sets up configuration links, and installs the CLI helper.

```bash
# 1. Clone into your config directory:
git clone https://github.com/YogeshKumar14/quickshell-notch.git ~/.config/quickshell
cd ~/.config/quickshell

# 2. Run the interactive installer:
./install.sh
```

Or run directly via one-liner:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YogeshKumar14/quickshell-notch/main/install.sh)
```

#### Installer Flags & Options
| Flag | Description |
|------|-------------|
| `-y`, `--yes` | Non-interactive mode (auto-confirms package installation and setup) |
| `--dry-run` | Inspect actions without modifying files or system packages |
| `--hyprland` | Automatically append autostart and persistence imports to `hyprland.conf` / `hyprland.lua` |
| `--no-deps` | Skip dependency checks and package installation |
| `--no-fonts` | Skip Apple SF Pro / SF Mono font installation |
| `--copy` | Copy repository files to `~/.config/quickshell` instead of symlinking |
| `-h`, `--help` | Display full help and options |

---

### Method 2: Arch Linux PKGBUILD / AUR

A standard Arch Linux compliant `PKGBUILD` is included in the repository root and `packaging/` directory.

#### Using an AUR Helper (e.g. `yay` or `paru`):
```bash
# Release package:
yay -S quickshell-notch

# Or latest development branch:
yay -S quickshell-notch-git
```

#### Manual Build with `makepkg`:
```bash
git clone https://github.com/YogeshKumar14/quickshell-notch.git
cd quickshell-notch
makepkg -si

# Initialize user configuration and templates:
quickshell-notch init
```

---

### Method 3: Manual Installation & Dependency Reference

If you prefer to install dependencies manually:

```bash
# Official repositories (Arch [extra])
sudo pacman -S --needed \
  quickshell \
  hyprland \
  swaync \
  cava \
  matugen \
  awww \
  pipewire \
  pipewire-pulse \
  wireplumber \
  playerctl \
  socat \
  grim \
  ffmpeg \
  libnotify \
  brightnessctl \
  networkmanager \
  bluez \
  bluez-utils \
  python \
  python-pillow \
  python-dbus \
  python-gobject \
  python-requests \
  qt6-5compat \
  qt6-svg \
  fontconfig \
  ttf-jetbrains-mono-nerd
```

| Package | Why it's needed |
|---------|-----------------|
| `quickshell` | QML runtime and desktop shell engine |
| `hyprland` | Window manager; notch integrates with Hyprland IPC and layer-shell |
| `matugen` | Material You (CAM16) dynamic accent color generator |
| `awww` | High-performance Wayland wallpaper daemon |
| `cava` | Audio visualizer stream backend |
| `pipewire` + `wireplumber` | Audio routing drawer and volume/mic control |
| `playerctl` + `python-dbus` | MPRIS media controller and duration/seek resolvers |
| `python-pillow` | Parallel wallpaper thumbnail generation |
| `networkmanager` + `bluez-utils` | `nmcli` / `bluetoothctl` network and bluetooth drawers |
| `swaync` | Notification backend (QuickShell hosts notification server directly) |
| `qt6-5compat` | Provides `Qt5Compat.GraphicalEffects` for image blending |
| SF Pro & SF Mono Fonts | macOS system typography (automatically registered by `install.sh`) |

#### Fonts Setup
```bash
bash ~/.config/quickshell/scripts/core/download_macos_fonts.sh
```

#### Matugen Accent Colors Setup
The notch uses Matugen (or Wallust) to generate colors dynamically from your wallpaper. Bootstrapping templates:
```bash
mkdir -p ~/.config/matugen
cp -r ~/.config/quickshell/templates/matugen/* ~/.config/matugen/
```
Generate your initial palette:
```bash
matugen image ~/Pictures/wallpapers/your-wallpaper.jpg -m dark --source-color-index 0
```
*(The notch falls back to system blue `#0A84FF` if no palette is found).*

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

### 8. First run & Management

Use the `quickshell-notch` CLI helper (installed in `~/.local/bin` or `/usr/bin`):

```bash
# Launch or cleanly restart
quickshell-notch launch

# Check status & IPC socket
quickshell-notch status

# Stop daemon
quickshell-notch stop
```

Runtime logs live at `/run/user/$UID/quickshell/by-id/*/log.qslog` — check there if something looks broken.

### 9. Hyprland Keybinds

Control the notch dynamically using the `quickshell-notch` command or raw IPC:

```ini
# Toggle expand/collapse
bind = SUPER, N, exec, quickshell-notch toggle

# Quick tab switches
bind = SUPER, M, exec, quickshell-notch nook
bind = SUPER, SPACE, exec, quickshell-notch apps
bind = SUPER, W, exec, quickshell-notch walls

# Volume & Brightness OSD
bind = , XF86AudioRaiseVolume, exec, quickshell-notch osd volume up
bind = , XF86AudioLowerVolume, exec, quickshell-notch osd volume down
bind = , XF86MonBrightnessUp, exec, quickshell-notch osd brightness up
bind = , XF86MonBrightnessDown, exec, quickshell-notch osd brightness down
```

---

## Uninstallation

To cleanly remove QuickShell Top Notch, installed font assets, and runtime caches:

```bash
# Clean uninstall (preserves your custom notch_settings.json):
./uninstall.sh

# Complete purge (removes configs, settings, and hyprland persistence):
./uninstall.sh --purge
```

Or if installed via pacman / AUR:
```bash
sudo pacman -R quickshell-notch
```

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
| `nook` | Toggle media controller tab (Tab 0) |
| `apps` | Toggle app launcher tab (Tab 1) |
| `walls` | Toggle wallpaper selector tab (Tab 2) |
| `audio` | Toggle audio routing drawer |
| `notifs` | Toggle notification history drawer |
| `notifs:clear` | Clear all notifications with staggered animation |
| `settings` | Toggle settings window |
| `osd:vol:{0-100}` | Show volume OSD |
| `osd:bri:{0-100}` | Show brightness OSD |

---

## Directory Structure

```
~/.config/quickshell/
├── shell.qml                      # Main entry point (LayerShell window + input mask)
├── components/                    # Modular QML layouts and tabs
│   ├── TopNotch.qml               # Primary notch orchestrator & geometry state machine
│   ├── CompactPill.qml            # Collapsed notch: clock, workspace dots, CAVA visualizer
│   ├── MediaController.qml        # Tab 0: MPRIS media controls, circular visualizer, sliders
│   ├── AppLauncher.qml            # Tab 1: App grid launcher with cached matching
│   ├── WallpaperSelector.qml      # Tab 2: Wallpaper grid selector & thumbnail cache
│   ├── HardwareStats.qml          # Tab 3: Real-time CPU/RAM/Disk/Network gauges
│   ├── StatusBar.qml              # Expanded header bar, segmented tab switcher, battery capsule
│   ├── OsdOverlay.qml             # Volume/brightness OSD popup with rotating icon impulse
│   ├── AudioMenu.qml              # Audio sink/source switcher and stream controls
│   ├── WifiMenu.qml               # Wi-Fi networks panel
│   ├── BluetoothMenu.qml          # Bluetooth devices panel
│   ├── PowerMenu.qml              # Power actions overlay
│   ├── NotificationHistory.qml    # Notification history drawer & D-Bus integration
│   ├── SettingsWindow.qml         # Configuration options panel
│   ├── CustomSlider.qml           # Styled slider
│   ├── CustomSwitch.qml           # Styled toggle switch
│   ├── M3Icon.qml                 # macOS SF Symbols & glyph vector icon renderer
│   └── SparklineCanvas.qml        # CPU/RAM graph rendering
├── scripts/
│   ├── core/
│   │   ├── launch_quickshell.sh   # Clean relaunch (kills strays first)
│   │   ├── validate_codebase.sh   # QML/Python/Bash validation pipeline
│   │   ├── sandbox.sh             # Non-disruptive test instance launcher
│   │   ├── test_all_features.py   # Comprehensive automated test suite
│   │   ├── atomic_write.py        # Crash-resilient atomic file write helper
│   │   ├── process_utils.py       # PR_SET_PDEATHSIG child process lifecycle safety
│   │   ├── osd.sh                 # Volume/brightness OSD helper
│   │   ├── download_macos_icons.sh # Fetches Apple macOS SF Symbols SVGs
│   │   └── download_m3_icons.sh   # Legacy redirect to download_macos_icons.sh
│   ├── desktop/
│   │   ├── get_apps.py            # Desktop entry scanner with caching
│   │   ├── scan_wallpapers.py     # Parallel wallpaper thumbnail generator
│   │   ├── apply_wallpaper.sh     # awww-daemon wallpaper setter
│   │   ├── get_wallust_colors.sh  # Reads accent color from wal cache
│   │   ├── get_device_levels.py   # Audio (wpctl), brightness, battery sysfs poller
│   │   ├── get_system_info.py     # Zero-dependency /proc parser (CPU, RAM, Disk, Net)
│   │   └── manage_audio.py        # PipeWire / WirePlumber audio stream & device manager
│   ├── hyprland/
│   │   ├── apply_all_settings.py  # Atomic dual-write of notch+hypr settings
│   │   ├── apply_hypr_option.py   # hyprctl live-apply (lua-aware fallback)
│   │   ├── persist_hypr_state.py  # Writes lua + conf persistence files
│   │   ├── set_hypr_option.sh     # Shell wrapper for live apply
│   │   ├── get_hypr_options.py    # Reads active Hyprland options
│   │   └── hypr_keymap.py         # Hyprland option keys and type converters
│   ├── network/
│   │   ├── manage_wifi.py         # nmcli backend (scan/connect/status)
│   │   └── manage_bluetooth.py    # bluetoothctl backend
│   └── notch/
│       ├── notch_ipc.py           # IPC socket client (keybind commands)
│       ├── get_notch_settings.py  # Reads notch_settings.json (defaults live here)
│       └── stream_audio_visualizer.py  # CAVA child → JSON stream (pdeathsig)
├── theme/
│   └── Style.qml                  # Global colors, fonts, radii
├── assets/
│   ├── icons/                     # Apple macOS SF Symbols SVGs (M3Icon/MacIcon table)
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
