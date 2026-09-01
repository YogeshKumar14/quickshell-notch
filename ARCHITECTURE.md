# QuickShell Notch — System Architecture Specification (v2.0.0)

This document provides a comprehensive technical reference for the architecture, component topology, data flows, persistence pipelines, and lifecycle models of the **QuickShell Notch** desktop shell for Hyprland.

---

## 1. System Overview

QuickShell Notch is an expressive, hardware-integrated desktop status bar and interactive dynamic island for the **Hyprland Wayland Compositor**. Built on **QuickShell (Qt6 / QML)** and backed by asynchronous Python and POSIX shell daemons, it combines lightweight resource utilization with fluid spring-physics animations.

```mermaid
graph TD
    subgraph Wayland["Wayland Compositor & Hyprland"]
        HL["Hyprland IPC Socket"]
        DBus["D-Bus Session Bus"]
        SysFS["Linux /proc & /sys"]
    end

    subgraph ShellSurface["QuickShell Runtime (shell.qml)"]
        LayerShell["LayerShell Top Panel Surface"]
        NotifServer["Notification Server Daemon"]
        IPCSocket["/tmp/quickshell-notch.sock"]
        Notch["TopNotch.qml (Orchestrator)"]
    end

    subgraph Decomposed["Modular QML Sub-Components"]
        CompactPill["CompactPill.qml (Collapsed State)"]
        MediaCtrl["MediaController.qml (MPRIS & Sliders)"]
        OSD["OsdOverlay.qml (Vol/Bri Popup)"]
        StatusBar["StatusBar.qml (Header & Battery)"]
        Stats["HardwareStats.qml (Resource Gauges)"]
    end

    subgraph Overlays["Drawer & Tab Overlays"]
        Walls["WallpaperSelector.qml"]
        Apps["AppLauncher.qml"]
        Wifi["WifiMenu.qml"]
        BT["BluetoothMenu.qml"]
        Power["PowerMenu.qml"]
        Notifs["NotificationHistory.qml"]
        Settings["SettingsWindow.qml"]
    end

    subgraph Backends["Asynchronous Python Backends"]
        CAVA["stream_audio_visualizer.py"]
        DevLevels["get_device_levels.py"]
        SysInfo["get_system_info.py"]
        AppScanner["get_apps.py"]
        WallScanner["scan_wallpapers.py"]
        WifiBackend["manage_wifi.py"]
        BTBackend["manage_bluetooth.py"]
        DualWrite["apply_all_settings.py"]
    end

    LayerShell --> Notch
    IPCSocket --> Notch
    NotifServer --> Notifs
    Notch --> CompactPill
    Notch --> MediaCtrl
    Notch --> OSD
    Notch --> StatusBar
    Notch --> Stats
    Notch --> Walls
    Notch --> Apps
    Notch --> Wifi
    Notch --> BT
    Notch --> Power
    Notch --> Notifs
    Notch --> Settings

    CompactPill -.-> CAVA
    MediaCtrl -.-> CAVA
    Stats -.-> SysInfo
    StatusBar -.-> DevLevels
    Walls -.-> WallScanner
    Apps -.-> AppScanner
    Wifi -.-> WifiBackend
    BT -.-> BTBackend
    Settings -.-> DualWrite
    DualWrite --> HL
```

---

## 2. Directory Structure

```
~/.config/quickshell/
├── shell.qml                     # Wayland LayerShell root surface, IPC server, NotificationServer
├── components/                   # Modular QML UI Components
│   ├── TopNotch.qml              # High-level orchestrator & geometry morphing state machine
│   ├── CompactPill.qml           # Collapsed notch: clock, workspace dots, CAVA visualizer
│   ├── MediaController.qml       # PAGE 0: MPRIS media controls, circular visualizer, volume/mic
│   ├── WallpaperSelector.qml     # PAGE 1: Wallpaper grid, thumbnail cache, search filter
│   ├── AppLauncher.qml           # PAGE 2: Application grid, fuzzy search, .desktop launcher
│   ├── HardwareStats.qml         # PAGE 3: CPU/RAM/Disk/Network realtime sparkline gauges
│   ├── StatusBar.qml             # Expanded header row, segmented tab switcher, iOS battery capsule
│   ├── OsdOverlay.qml            # Volume/brightness OSD popup with rotating icon impulse
│   ├── WifiMenu.qml              # Wi-Fi network scanner and connection drawer
│   ├── BluetoothMenu.qml         # Bluetooth device manager drawer
│   ├── PowerMenu.qml             # Power actions (lock, logout, suspend, reboot, shutdown)
│   ├── NotificationHistory.qml   # Persistent notification center drawer
│   ├── SettingsWindow.qml        # Dedicated GUI settings window (Hyprland + Notch prefs)
│   ├── CustomSlider.qml          # Material 3 pill slider with spring feedback
│   ├── CustomSwitch.qml          # Material 3 toggle switch
│   ├── M3Icon.qml                # Vector SVG icon renderer with color overlays
│   └── SparklineCanvas.qml       # 2D Canvas anti-aliased gradient chart
├── theme/
│   └── Style.qml                 # Centralized design tokens (colors, typography, spring physics)
├── scripts/
│   ├── core/                     # Lifecycle, process safety, and validation tools
│   │   ├── atomic_write.py       # Crash-resilient file write helper
│   │   ├── process_utils.py      # Linux PR_SET_PDEATHSIG child process reaper
│   │   ├── test_all_features.py  # 170+ test automated test harness
│   │   ├── validate_codebase.sh  # QML lint + Python compile + Bash AST validator
│   │   ├── launch_quickshell.sh  # Clean daemon launcher with process reaper
│   │   └── sandbox.sh            # Isolated test environment launcher
│   ├── desktop/                  # Desktop metadata providers
│   │   ├── apply_wallpaper.sh    # Non-blocking wallpaper changer with wallust trigger
│   │   ├── get_apps.py           # .desktop parser with icon heuristic resolver
│   │   ├── get_device_levels.py  # Audio (wpctl), brightness, battery sysfs poller
│   │   ├── get_system_info.py    # Zero-dependency /proc parser (CPU, RAM, Disk, Net)
│   │   ├── get_wallust_colors.sh # Wallust accent color reader
│   │   └── scan_wallpapers.py    # Multi-threaded image scanner & thumbnailer
│   ├── hyprland/                 # Hyprland integration & persistence
│   │   ├── apply_all_settings.py # Atomic dual-write settings applier
│   │   ├── apply_hypr_option.py  # Live hyprctl option applier (Lua / Conf tolerant)
│   │   ├── get_hypr_options.py   # Batch reader for active Hyprland options
│   │   ├── hypr_keymap.py        # Single source of truth for Hyprland option keys
│   │   ├── persist_hypr_state.py # Lua and Conf config syntax generator
│   │   └── set_hypr_option.sh    # Single option persistence CLI shim
│   └── network/                  # Network management backends
│       ├── manage_bluetooth.py   # bluetoothctl device controller
│       └── manage_wifi.py        # nmcli Wi-Fi controller
└── assets/
    └── icons/                    # Material Symbols Rounded SVGs
```

---

## 3. Subsystem Deep-Dive

### 3.1 Orchestration & State Machine (`TopNotch.qml`)
`TopNotch.qml` acts as the root orchestrator. It manages:
- **Geometry State Machine**:
  - Compact Pill: `130px - 420px` width (dynamically stretched by audio track title width or workspace count), `30px` height.
  - Expanded Island: `560px` width, dynamically calculated height (`pageNotchHeight`) based on active tab content.
  - Inverted Dripping Ears: 2D Canvas arcs attached to the top-left and top-right of the notch box for continuous bezel styling.
- **Navigation Lifecycle**:
  - `currentPage`: 0 (Media), 1 (Walls), 2 (Apps), 3 (Stats).
  - Lazy Tab Loading: Wallpaper and App launcher tabs are dynamically activated and unloaded after 5 seconds of inactivity to conserve memory.

### 3.2 Hyprland Dual-Write Persistence Pipeline
Hyprland builds can use either the modern Lua config parser or the legacy configuration format. QuickShell Notch guarantees cross-version compatibility by executing an **Atomic Dual-Write**:

```mermaid
sequenceDiagram
    participant UI as SettingsWindow.qml
    participant Writer as apply_all_settings.py
    participant Cache as ~/.cache/quickshell/hypr_state.json
    participant Lua as ~/.config/hypr/quickshell_hypr.lua
    participant Conf as ~/.config/hypr/quickshell_hypr.conf
    participant Live as apply_hypr_option.py

    UI->>Writer: JSON Settings Payload
    Writer->>Cache: Save Normalized State Cache
    Writer->>Lua: Atomic Write (RGBA byte order: rgba(rrggbbaa))
    Writer->>Conf: Atomic Write (ARGB byte order: rgba(aarrggbb))
    Writer->>Live: Apply live options via hyprctl keyword / eval
```

### 3.3 Child Process Lifecycle & Safety (`PR_SET_PDEATHSIG`)
To prevent orphan child processes (e.g., `cava`, `bluetoothctl`, `nmcli monitor`) from leaking CPU when QuickShell is killed or reloaded, all background Python daemons import `set_pdeathsig()` from `scripts/core/process_utils.py`. This leverages the Linux kernel's `prctl(PR_SET_PDEATHSIG, SIGTERM)` so child processes terminate instantly upon parent death.

### 3.4 IPC Socket Interface (`/tmp/quickshell-notch.sock`)
The shell listens on a local Unix Domain Socket for fast keybind integration:

| Command | Action |
|---|---|
| `toggle` | Toggle between compact pill and expanded island |
| `close` | Immediately collapse notch and close all open sub-menus |
| `walls` | Toggle directly to the Wallpaper Selector tab (PAGE 1) |
| `apps` | Toggle directly to the App Launcher tab (PAGE 2) |
| `osd:vol:<0-100>` | Display Volume OSD with percentage and icon animation |
| `osd:bri:<0-100>` | Display Brightness OSD with ±45° rotating sun/moon impulse |

---

## 4. Design System & Tokens (`theme/Style.qml`)

QuickShell Notch implements the **Material 3 Expressive UI** design language:
- **Surfaces**: Pure OLED black (`#000000`) root with elevated card containers (`#1C1C1E`) and subtle borders (`#2C2C2E`).
- **Dynamic Accent**: Wallust-extracted dominant color automatically synchronized with the active wallpaper.
- **iOS Semantic Battery**: Charging (`#30D158`), Normal (`#FFFFFF`), Low Power (`#FFD60A`), Critical (`#FF453A`).
- **Physics**: Natural spring physics (`tension: 4.5..5.5`, `damping: 0.22..0.28`) driving geometry morphing, tab highlights, and icon impulses. No hard snapping transitions.

---

## 5. Development & Verification

### Codebase Validation
```bash
~/.config/quickshell/scripts/core/validate_codebase.sh
```
Checks QML syntax (`qmllint`), Python syntax (`py_compile`), and Bash scripts (`bash -n`).

### Automated Test Suite
```bash
python3 ~/.config/quickshell/scripts/core/test_all_features.py
```
Runs 170+ automated tests across 12 modules in an isolated temporary sandbox.
