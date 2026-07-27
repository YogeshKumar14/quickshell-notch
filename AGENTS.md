# AI Agent Developer Handbook — QuickShell Notch Project

Welcome, AI agent! This repository contains a customized **QuickShell Top Notch** desktop status and options controller, integrated with **Hyprland** (native Lua) and **SwayNC** notification aesthetics. 

This handbook explains the repository architecture, operational commands, and configuration constraints to help you build, test, and optimize features cleanly.

---

## 1. Directory Structure

```
~/.config/quickshell/
├── AGENTS.md                   # This developer handbook
├── shell.qml                   # Main entry point (Scope & Window definitions)
├── components/                 # QML layouts and interactive tabs
│   ├── TopNotch.qml            # The primary Notch logic (contains the pill, states, visualizer, widgets)
│   ├── WallpaperSelector.qml   # Wallpaper grid selector (FocusScope)
│   ├── AppLauncher.qml         # App grid launcher with fast cache matching (FocusScope)
│   ├── SettingsWindow.qml      # Configuration options panels
│   ├── CustomSlider.qml        # Styled sliding controller
│   └── CustomSwitch.qml        # Styled toggle switch
├── scripts/                    # Python and Shell script system integration helpers
│   ├── launch_quickshell.sh    # Relaunches QuickShell cleanly
│   ├── apply_all_settings.py   # Writes active configurations to LUA and CONF
│   ├── set_hypr_option.sh      # Writes dynamic setting updates
│   ├── get_hypr_options.py     # Batch queries Hyprland active properties
│   ├── get_apps.py             # Optimized desktop app scanner with walk-pruning
│   └── stream_audio_visualizer.py  # Zero-lag CAVA audio visualizer stream pipe
└── theme/                      # Styling definitions
    └── Style.qml               # Global colors, typography, margins, and radii
```

---

## 2. Platform Architecture & Constraints

### A. Dynamic Setting Overrides (LUA & CONF Synchronization)
Your system is configured to support both the native **Lua** configuration wrapper (`hyprland.lua`) and standard **CONF** configurations (`hyprland.conf`). 
Whenever a settings option (e.g. Window Drop Shadow, Gaps, Rounding, Border Size) is changed:
1. You **MUST** write the override values to **both** files simultaneously:
   - `~/.config/hypr/quickshell_hypr.lua`
   - `~/.config/hypr/quickshell_hypr.conf`
2. This is automated inside `set_hypr_option.sh` and `apply_all_settings.py`. Do not break this dual-write alignment!

### B. Keyboard Focus & Routing (Wayland/LayerShell)
- Dynamic LayerShell surfaces do not automatically receive keyboard input.
- To focus the notch search bar dynamically, the parent `shell.qml` instantiates `HyprlandFocusGrab` from `Quickshell.Hyprland` and binds it to `notchWindow`.
- Ensure all parent elements, containers, and QML `Loader` objects have `focus: true`.
- Components containing text inputs (`AppLauncher.qml` & `WallpaperSelector.qml`) **MUST** inherit from `FocusScope` at the root level to route focus down to the nested `TextInput` automatically.

### C. Input Mask Passthrough (Clicks Passthrough)
- To prevent transparent sections of the Notch window from blocking desktop mouse interactions, `shell.qml` configures a click mask:
  ```qml
  mask: Region { item: notchComp.notchBoxItem }
  ```
- This guarantees clicks outside the physical notch pill pass through to the windows below.

---

## 3. operational Commands & Cheatsheet

### QML Compilation Dry-Run
Always check that your QML files compile cleanly before starting the daemon:
```bash
timeout 3 quickshell -n -p ~/.config/quickshell/shell.qml
```

### Relaunching the Daemon
To restart the widget and reload files, use the launcher. If you are starting it inside a sandbox terminal, do not background it using `&` (or it will die on exit); execute it as a persistent background task or use `nohup`:
```bash
pkill -9 -x quickshell || true
nohup bash ~/.config/quickshell/scripts/launch_quickshell.sh >/dev/null 2>&1 &
```

### Reloading SwayNC (Notifications)
After modifying `~/.config/swaync/style.css` or `config.json`, trigger a live reload:
```bash
swaync-client -R && swaync-client -rs
```

### Test Notifications
```bash
notify-send -a "SwayNC" "Notification Test" "Hello from the development sandbox!"
```
