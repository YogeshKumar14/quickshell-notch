# QuickShell Top Notch

[![Release](https://img.shields.io/badge/release-v2.4.0-blue.svg?style=flat-square)](https://github.com/YogeshKumar14/quickshell-notch/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat-square)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-195%20passed-brightgreen.svg?style=flat-square)](scripts/core/test_all_features.py)
[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-supported-1793D1.svg?style=flat-square&logo=arch-linux&logoColor=white)](install.sh)
[![Hyprland](https://img.shields.io/badge/Hyprland-%E2%89%A50.49-00A86B.svg?style=flat-square)](https://hyprland.org)
[![QuickShell](https://img.shields.io/badge/QuickShell-v0.3.1+-orange.svg?style=flat-square)](https://quickshell.outfoxxed.me/)

A customized, high-performance desktop status bar and interactive dynamic island built with [QuickShell](https://quickshell.outfoxxed.me/) (Qt6 / QML), styled with dynamic [Matugen](https://github.com/InioX/matugen) (and [Wallust](https://github.com/explosion-mental/wallust)) Material You palette extraction, typography in Apple SF Pro & SF Mono, and vector iconography via official Apple SF Symbols. Deeply integrated with Hyprland, PipeWire / WirePlumber, NetworkManager, BlueZ, and SwayNC.

Top Notch morphs dynamically between a compact top-center status pill and an expanded 3-column system control dashboard — powered by unified single-body spring scaling, synchronized visualizer dynamics, and zero-snap calibrated bounce physics.

---

## Showcase

### Dynamic Dashboard
![Notch Expanded Dashboard](assets/2026-07-28-132607_hyprshot.png)

### Widget Integrations
![Notch Widgets](assets/2026-07-27-223516_hyprshot.png)

### Video Demo
<video src="assets/notch_demo.mp4" width="100%" controls="controls"></video>

---

## Features

- **Unified Single-Body Spring Scaling**: Re-anchored viewport container where media controls, 7-day calendar timeline, and header bar scale organically as an indivisible unified body with notch physical spring physics ($4.5 / 0.30$ spring, `springPageEpsilon: 0.0005`, zero end-of-transition snap).
- **Synchronized Visualizer & Compact Pill Dynamics**: Real-time spring scaling (`pillSpringScale`) and vertical bounce follow-through (`bounceCenterY`) across all compact pill states (audio visualizer spectrum, clock readout, and workspace indicators). A seamless visualizer expansion handshake (`wasVisualizerActive`, 350ms settling timer) completely eliminates visualizer crushing, premature pill narrowing, and clock flashing during expansion.
- **Workspace Overlay**: Real-time workspace indicators on the compact pill — occupied workspaces are highlighted, clicking a dot jumps to that workspace, and clicking anywhere expands the notch.
- **Tab 0 — MPRIS Media Controller**: Modern 3-column landscape architecture with dynamic album art, hardware-accelerated anti-aliased squircle corner clipping (`OpacityMask`), circular audio visualizer, multi-tier track duration resolver ([`mpris_duration.py`](scripts/notch/mpris_duration.py)), atomic seeking engine with $-10\text{s}$ rewind button ([`mpris_seek.py`](scripts/notch/mpris_seek.py)), jitter-free fluid sliders (`Easing.OutQuad`), and native `Quickshell.Services.Mpris`.
- **Tab 1 — Fast App Launcher**: Desktop application scanner with icon path matching, search filtering, and flatpak walk-pruning. Caches results and automatically re-scans when packages change.
- **Tab 2 — Wallpaper Selector**: Dynamic grid with parallel thumbnail generation, active wallpaper highlight, and atomic wallpaper changes via `awww` paired with Matugen / Wallust palette transitions.
- **Tab 3 — Hardware Stats Dashboard**: Real-time CPU, RAM, and Network load graphs rendered with anti-aliased sparkline canvas paths, plus disk storage monitoring. Polling automatically sleeps while hidden (0% idle overhead) with configurable refresh intervals.
- **Dedicated Audio Routing Drawer**: Dedicated 2-column quick settings overlay ([`AudioMenu.qml`](components/AudioMenu.qml)) for 1-click Output Sink (Speakers, Bluetooth Headphones, DACs) and Input Source (Microphones) routing via PipeWire `wpctl`, smart vector icon detection, active checkmark badges, and outside click-to-dismiss.
- **Wi-Fi & Bluetooth Panels**: Interactive drawers to scan networks, connect, toggle devices, and view signal strength via `nmcli` and `bluetoothctl` backends.
- **Per-Frequency Multi-Band Audio Visualizer**: CAVA-driven reactive spectrum with 3 customizable visualizer styles (bars, wave, pulsar), DSP noise floor filtering, and battery-saver sleep mode when collapsed or idle.
- **Notification Center**: QuickShell hosts the D-Bus notification server directly; drawer displays notification history cards with smooth 180ms staggered card dismissal animations (`notifs`, `notifs:clear`).
- **Volume & Brightness OSD**: Compact $240\times 34\text{px}$ OSD overlay with rotating Sun icon ($\pm 45^\circ$), jitter-free fluid sliders (`Easing.OutQuad`), and instantaneous dismissal on notch/drawer interaction.
- **Material 3 Expressive Dynamic Battery Capsule**: Battery capsule (19×10.5px) with solid crisp white outline, animated fluid fill bar, light bright yellow charging bolt (`#FFE81F`), and Apple iOS 4-tier dark mode palette (Charging Green `#30D158`, Normal White `#FFFFFF`, Low Power Yellow `#FFD60A`, Critical Red `#FF453A`).
- **Official Apple SF Symbols & SF Pro Typography**: Official Apple SF Symbols vector icons ([`components/M3Icon.qml`](components/M3Icon.qml) with 2x retina density and mipmapping) and Apple SF Pro / SF Mono typography hierarchy.
- **Matugen 4.2.0 Dynamic Theming**: High-speed zero-cache CAM16 palette generation pipeline with 11 custom Material You templates ([`templates/matugen/`](templates/matugen/)) for Hyprland, SwayNC, Cava, Waybar, Kitty, Rofi, etc., with backward-compatible Wallust support.
- **Settings Controller**: 4-card grouped Settings window with Matugen/Wallust gliding pills, jitter-free fluid sliders, live Hyprland persistence dual-write, animation tuning, and notch geometry controls.
- **Direct Tab Switching IPC**: Direct navigation via socket commands (`stats`, `tab:0`, `tab:1`, `tab:2`, `tab:3`) allowing instant tab switching without toggling the notch closed.
- **Comprehensive Verification Suite**: 195-test automated verification harness ([`scripts/core/test_all_features.py`](scripts/core/test_all_features.py)) covering QML syntax, backend schemas, Hyprland dual-write, IPC socket stress & fuzzing, D-Bus floods, process lifecycle, seeking engine, and PipeWire routing.

---

## Requirements

- **Hyprland** ≥ 0.49 (uses the `hyprland-toplevel-mapping-v1` protocol; tested on 0.56.x with both legacy `hyprland.conf` and the new Lua config parser)
- **QuickShell** ≥ 0.3.1 (Hyprland-enabled build)
- **Python** 3.10+ (with `python-pillow`, `python-dbus`, `python-gobject`, `python-requests`)
- **PipeWire** & **WirePlumber** (audio routing and volume control)

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
| `--link` | Symlink repository to `~/.config/quickshell` (default when cloned outside) |
| `--copy` | Copy repository files to `~/.config/quickshell` instead of symlinking |
| `-h`, `--help` | Display full help and options |

---

### Method 2: Arch Linux PKGBUILD / AUR

A standard Arch Linux compliant [`PKGBUILD`](PKGBUILD) is included in the repository root and [`packaging/`](packaging/) directory.

#### Using an AUR Helper (e.g. `paru` or `yay`):
```bash
# Release package:
paru -S quickshell-notch
# or:
yay -S quickshell-notch

# Or latest development branch:
paru -S quickshell-notch-git
# or:
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

#### Official Repositories (Arch `[extra]`):
```bash
sudo pacman -S --needed \
  hyprland \
  pipewire \
  pipewire-pulse \
  wireplumber \
  cava \
  playerctl \
  socat \
  grim \
  ffmpeg \
  libnotify \
  brightnessctl \
  networkmanager \
  bluez \
  bluez-utils \
  swaync \
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

#### AUR Packages (via `paru` or `yay`):
```bash
paru -S --needed quickshell matugen awww
# or:
yay -S --needed quickshell matugen awww
```
*(Note: on distributions where `quickshell`, `matugen`, or `awww` are packaged in official repos, `pacman -S` may be used directly).*

#### Dependency Breakdown
| Package | Why it's needed |
|---------|-----------------|
| `quickshell` | QML runtime and desktop shell engine |
| `hyprland` | Wayland window manager; notch integrates with Hyprland IPC and layer-shell |
| `matugen` | Material You (CAM16) dynamic accent color generator |
| `awww` | High-performance Wayland wallpaper daemon |
| `cava` | Audio visualizer stream backend |
| `pipewire` + `wireplumber` | Audio routing drawer and volume/mic control |
| `playerctl` + `python-dbus` | MPRIS media controller, track duration, and seeking engine |
| `python-pillow` | Parallel wallpaper thumbnail generation |
| `python-gobject` | D-Bus and GLib event loops for media backends |
| `python-requests` | Vector icon asset download helper |
| `networkmanager` + `bluez-utils` | `nmcli` / `bluetoothctl` network and Bluetooth drawers |
| `swaync` | Notification backend helper (QuickShell hosts notification server directly) |
| `qt6-5compat` | Provides `Qt5Compat.GraphicalEffects` for image blending and squircle masking |
| `qt6-svg` | Vector SVG icon rendering |
| SF Pro & SF Mono Fonts | macOS system typography (automatically registered by `install.sh`) |

#### Fonts Setup
```bash
bash ~/.config/quickshell/scripts/core/download_macos_fonts.sh
```

#### Matugen Accent Colors Setup
The notch uses Matugen (with Wallust compatibility) to generate colors dynamically from your wallpaper. Bootstrapping templates:
```bash
mkdir -p ~/.config/matugen
cp -r ~/.config/quickshell/templates/matugen/* ~/.config/matugen/
```
Generate your initial palette:
```bash
matugen image ~/Pictures/wallpapers/your-wallpaper.jpg -m dark --source-color-index 0
```
*(The notch falls back to system blue `#0A84FF` if no palette is found).*

---

### Integrate with Hyprland

**Option A — Standard `hyprland.conf`:**

```ini
exec-once = bash ~/.config/quickshell/scripts/core/launch_quickshell.sh

# Persistence imports for dynamically applied settings
source = ~/.config/hypr/quickshell_hypr.conf
```

**Option B — Lua Config (`hyprland.lua`):**

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("$HOME/.config/quickshell/scripts/core/launch_quickshell.sh")
end)

-- Persistence imports for dynamically applied settings
import("quickshell_hypr.lua")
```

The launcher script ([`launch_quickshell.sh`](scripts/core/launch_quickshell.sh)) terminates any stale `quickshell`, `cava`, visualizer, and `swaync` processes before starting QuickShell against `shell.qml`. Use the same script whenever you want a clean restart.

---

### First Run & Management

Use the `quickshell-notch` CLI helper (installed in `~/.local/bin` or `/usr/bin`):

```bash
# Daemon Lifecycle
quickshell-notch launch        # Launch or cleanly restart the daemon
quickshell-notch status        # Check daemon status, PID, and socket connectivity
quickshell-notch stop          # Stop the daemon and background helpers
quickshell-notch restart       # Clean restart

# Direct Notch Navigation
quickshell-notch toggle        # Toggle expand/collapse
quickshell-notch close         # Collapse notch
quickshell-notch nook          # Toggle Media Controller tab (Tab 0)
quickshell-notch apps          # Toggle App Launcher tab (Tab 1)
quickshell-notch walls         # Toggle Wallpaper Selector tab (Tab 2)
quickshell-notch stats         # Toggle Hardware Stats tab (Tab 3)
quickshell-notch tab 0         # Switch directly to tab index (0..3)

# Drawers & Overlays
quickshell-notch audio         # Toggle Audio routing drawer
quickshell-notch notifs        # Toggle Notification drawer
quickshell-notch notifs:clear  # Clear notifications with staggered animation
quickshell-notch wifi          # Toggle Wi-Fi drawer
quickshell-notch bluetooth     # Toggle Bluetooth drawer
quickshell-notch settings      # Open Notch Settings window

# Hardware OSD
quickshell-notch osd volume up           # Step volume up (+5%) and show OSD
quickshell-notch osd volume down         # Step volume down (-5%) and show OSD
quickshell-notch osd brightness up       # Step brightness up (+5%) and show OSD
quickshell-notch osd brightness down     # Step brightness down (-5%) and show OSD

# Codebase Validation
quickshell-notch validate      # Run QML, Python, and Bash validation pipeline
```

Runtime logs live at `/run/user/$UID/quickshell/by-id/*/log.qslog` — check there if something looks broken.

---

### Hyprland Keybinds

Control the notch dynamically using `quickshell-notch` or direct IPC commands:

```ini
# Toggle expand/collapse
bind = SUPER, N, exec, quickshell-notch toggle

# Quick tab switches
bind = SUPER, M, exec, quickshell-notch nook
bind = SUPER, SPACE, exec, quickshell-notch apps
bind = SUPER, W, exec, quickshell-notch walls
bind = SUPER, S, exec, quickshell-notch stats

# Drawers
bind = SUPER, A, exec, quickshell-notch audio
bind = SUPER, COMMA, exec, quickshell-notch notifs

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

# Complete purge (removes configs, settings, and Hyprland persistence):
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

These files are written atomically and must be imported/sourced inside your main Hyprland configuration so options like border sizes, rounding, shadows, and gaps persist across restarts. The same option is written in the correct syntax for each parser (`rgba(...)` byte order differs between the Lua and legacy conf parsers).

> On Hyprland builds with the non-legacy (Lua) config parser, `hyprctl keyword` silently no-ops. All live-apply paths detect this and fall back to `hyprctl eval` + `hl.config(...)` merging automatically.

---

## IPC Socket Reference

Socket path: `/tmp/quickshell-notch.sock` — send commands directly via `quickshell-notch ipc <cmd>` or [`scripts/notch/notch_ipc.py`](scripts/notch/notch_ipc.py):

| Command | Action |
|---------|--------|
| `toggle` | Expand or collapse notch |
| `close` | Collapse expanded notch |
| `nook` | Toggle Media Controller tab (Tab 0) |
| `apps` / `tray` | Toggle App Launcher tab (Tab 1) |
| `walls` | Toggle Wallpaper Selector tab (Tab 2) |
| `stats` | Toggle Hardware Stats tab (Tab 3) |
| `tab:<0-3>` | Direct switch to tab index (0: Media, 1: Apps, 2: Wallpapers, 3: Stats) |
| `audio` | Toggle Audio Output & Input device routing drawer |
| `notifs` | Toggle Notification history drawer |
| `notifs:clear` | Clear active notifications with staggered 180ms card dismissal |
| `wifi` | Toggle Wi-Fi network selector drawer |
| `bluetooth` / `bt` | Toggle Bluetooth device drawer |
| `settings` | Toggle Notch Settings window |
| `settings:tab:<0-3>` | Open Settings window directly to tab index (0: Notch, 1: Hyprland, 2: Visualizer, 3: Network/Style) |
| `osd:vol:<0-150>` | Display Volume OSD with percentage |
| `osd:bri:<0-100>` | Display Brightness OSD with percentage |
| `reload_settings` | Reload notch and Hyprland configuration from disk |

---

## Directory Structure

```
~/.config/quickshell/
├── shell.qml                      # Main entry point (LayerShell surface, IPC server, Notification server)
├── notch_settings.json            # Runtime notch preferences & user settings
├── install.sh                     # Idempotent Arch Linux installer
├── uninstall.sh                   # Clean removal and rollback script
├── PKGBUILD                       # Arch Linux packaging definition
├── bin/
│   └── quickshell-notch           # Unified CLI management and IPC utility
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
│   ├── SettingsWindow.qml         # Configuration options panel (4-tab grouped cards)
│   ├── CustomSlider.qml           # Fluid slider with Easing.OutQuad monotonicity
│   ├── CustomSwitch.qml           # Styled toggle switch
│   ├── M3Icon.qml                 # Apple macOS SF Symbols & glyph vector icon renderer
│   ├── MacIcon.qml                # Vector icon lookup helper
│   └── SparklineCanvas.qml        # CPU/RAM graph rendering
├── packaging/
│   ├── PKGBUILD                   # Arch Linux build script
│   ├── PKGBUILD-git               # Arch Linux development build script
│   ├── quickshell-notch.desktop   # XDG Desktop application entry
│   └── quickshell-notch.install   # Post-installation / upgrade pacman hook
├── templates/
│   └── matugen/
│       ├── config.toml            # Matugen configuration definition
│       └── templates/             # 11 Material You templates (Hyprland, CAVA, SwayNC, etc.)
├── scripts/
│   ├── core/
│   │   ├── launch_quickshell.sh   # Clean relaunch (kills strays first)
│   │   ├── validate_codebase.sh   # QML/Python/Bash validation pipeline
│   │   ├── sandbox.sh             # Non-disruptive test instance launcher
│   │   ├── test_all_features.py   # 195-test comprehensive verification test suite
│   │   ├── test_mpris_seek.py     # Exhaustive verification suite for MPRIS seeking engine
│   │   ├── atomic_write.py        # Crash-resilient atomic file write helper
│   │   ├── process_utils.py       # PR_SET_PDEATHSIG child process lifecycle safety
│   │   ├── osd.sh                 # Volume/brightness OSD helper
│   │   ├── download_macos_fonts.sh # Apple SF Pro & SF Mono font downloader
│   │   ├── download_macos_icons.sh # Apple macOS SF Symbols SVGs downloader
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
│   │   ├── apply_all_settings.py  # Atomic dual-write of notch + Hyprland settings
│   │   ├── apply_hypr_option.py   # hyprctl live-apply (Lua-aware fallback)
│   │   ├── persist_hypr_state.py  # Writes Lua + Conf persistence files
│   │   ├── set_hypr_option.sh     # Shell wrapper for live apply
│   │   ├── get_hypr_options.py    # Reads active Hyprland options
│   │   └── hypr_keymap.py         # Hyprland option keys and type converters
│   ├── network/
│   │   ├── manage_wifi.py         # nmcli backend (scan/connect/status)
│   │   └── manage_bluetooth.py    # bluetoothctl backend
│   └── notch/
│       ├── notch_ipc.py           # IPC socket client (keybind commands)
│       ├── get_notch_settings.py  # Reads notch_settings.json (defaults live here)
│       ├── stream_audio_visualizer.py # CAVA child → JSON stream (pdeathsig)
│       ├── mpris_duration.py      # Multi-tier track duration resolver with caching
│       └── mpris_seek.py          # Atomic MPRIS seek engine with D-Bus / playerctl fallback
├── theme/
│   └── Style.qml                  # Global colors, fonts, radii, and spring physics tokens
└── assets/
    ├── icons/                     # Apple macOS SF Symbols SVGs
    ├── fonts/                     # SF Pro & SF Mono system typography
    └── *.png / notch_demo.mp4     # README showcase media
```

---

## Development & Testing

### Codebase Validation Pipeline

Before committing or reloading, run the static validation pipeline:

```bash
quickshell-notch validate
# or:
~/.config/quickshell/scripts/core/validate_codebase.sh
```

This verifies QML syntax (`qmllint`), Python backend compilation (`py_compile`), and Bash script syntax (`bash -n`). A non-zero exit means do **not** reload or commit.

### Comprehensive Automated Test Suite

Run the full 195-test automated verification suite:

```bash
python3 ~/.config/quickshell/scripts/core/test_all_features.py
```

The suite audits 15 subsystems including QML syntax, settings schema type coercion, Hyprland dual-write persistence, IPC socket stress and fuzzing, notification D-Bus floods, process lifecycle orphan scans, wallpaper pipelines, desktop app scanner, network backends, hardware gauges, SceneGraph squircle masking, PipeWire `wpctl` routing, and MPRIS track duration & seek fallbacks.

### Sandbox Mode

For non-disruptive UI development:

```bash
QUICKSHELL_SANDBOX=1 quickshell -n -p ~/.config/quickshell/shell.qml
# or:
bash ~/.config/quickshell/scripts/core/sandbox.sh
```

Scripts detect `QUICKSHELL_SANDBOX=1` and skip all Hyprland side-effects (no settings writes, no wallpaper changes, IPC socket disabled).

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| Notch doesn't appear | The launcher must run **inside** a Hyprland session (`HYPRLAND_INSTANCE_SIGNATURE` set). Check `/run/user/$UID/quickshell/by-id/*/log.qslog` for runtime errors. |
| Accent colors default blue | Matugen or Wallust haven't generated colors: run `matugen image <wallpaper>` or verify `~/.config/matugen/templates` exists. |
| Notifications don't pop up | Normal: QuickShell hosts the notification D-Bus interface directly; the launcher terminates `swaync` to prevent conflicts. Do not autostart `swaync` separately. |
| Audio device switching not updating | Verify PipeWire and WirePlumber are active: `systemctl --user status pipewire wireplumber`. |
| Wi-Fi / Bluetooth panels always empty | NetworkManager or Bluetooth services not active: `sudo systemctl enable --now NetworkManager bluetooth`. |
| Visualizer never animates | `cava` missing or PipeWire daemon not running (`pipewire`, `pipewire-pulse`, `wireplumber`). |
| Settings don't survive Hyprland restart | Persistence files must be imported in your Hyprland config (`source = ~/.config/hypr/quickshell_hypr.conf` or `import("quickshell_hypr.lua")`). |
| Clipped or misaligned expanded notch | The expanded height is dynamic per tab; adjust `expanded_height` in Settings window → Notch tab. |

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

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
