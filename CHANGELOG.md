# Changelog

All notable changes to QuickShell Top Notch are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-08-26

### Added
- Dynamic pill morphing with spring physics animations
- MPRIS media controller with album art and seek bar
- Wallpaper selector with parallel thumbnail generation
- Fast app launcher with icon resolution and caching
- Wi-Fi and Bluetooth interactive panels
- SwayNC notification history with expandable cards
- CAVA audio visualizer (bars, wave, pulsar modes)
- System stats dashboard (CPU, RAM, disk, network)
- iOS-style Hyprland settings window with live preview
- IPC socket for keybind integration
- Workspace overlay dots on compact pill
- Power menu with countdown confirmation
- OSD overlays for volume and brightness
- Wallust-driven dynamic accent theming

### Security
- Hardened atomic writes with secure tempfile
- Input sanitization on Wi-Fi SSID, Bluetooth MAC, Hyprland layout
- Isolated runtime files to XDG_RUNTIME_DIR
- Safe regex-based wallust color extraction (no shell eval)
- Setting key validation against DEFAULTS whitelist

### Performance
- Non-blocking CPU/RAM stats via /dev/shm state snapshots
- Direct sysfs reads for brightness and battery
- Cached thumbnail verification skip for wallpapers
- Guarded Canvas repaints behind visibility checks
- Static M3Icon lookup table (no per-render allocation)
