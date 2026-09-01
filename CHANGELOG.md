# Changelog

All notable changes to QuickShell Top Notch are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/).

## [2.1.0] - 2026-09-01

### Added
- **Audio & Sound Devices Notch Drawer**: Dedicated sub-notch quick settings overlay (`components/AudioMenu.qml` & `scripts/desktop/manage_audio.py`) featuring Master Output Volume & Microphone Level cards with instant mute toggles, optimistic interactive pill sliders, dynamic Output & Input device switching with Bluetooth badges, and background click-to-dismiss.
- **Microsecond/Second Scrubber Normalization & Realtime Polling**: Automatic unit detection across all media players with active 500ms `playerctl position` polling and direct click/drag seeking for 100% accurate timeline tracking.
- **Centered Camera Privacy Indicator**: Anchored hardware privacy dot to the exact mathematical center axis of the notch header.
- **Stabilized Visualizer Spectrum**: Integer subpixel coordinate rounding (`Math.round`) and critically damped spring easing eliminating whole-cluster vertical jitter.
- **Symmetric 12px Notch Padding**: Standardized symmetric margins across header bar, media dashboard, apps tray, and wallpapers grid.
- **Retina 2x Mipmapped Vector Icons**: Enabled 2x density, smooth filtering, and mipmapping in `components/M3Icon.qml` for crisp retina navigation glyphs.
- **Zero Card Clipping Geometry**: Inset App Launcher and Wallpaper Selector cards (60px height with 6px vertical headroom) preventing magic highlight borders and card edges from clipping against the viewport AABB scissor.
- **Zero-Delay OSD Pipeline**: Optimized `scripts/core/osd.sh` and spring dynamics for instantaneous volume and brightness feedback.
- **149-Test Comprehensive Verification Suite**: Added Module 14 testing PipeWire wpctl audio backend and drawer integrations with 100% pass rate.

## [2.0.0] - 2026-09-01

### Added
- **NotchNook Modern 3-Column Landscape Architecture**: Re-architected expanded notch with compact 106px height, 3-column media controller, 7-day live calendar timeline, and hardware stats dashboard.
- **Hardware-Accelerated OpacityMask Squircle Clipping**: True anti-aliased squircle corner clipping across album art, compact thumbnails, and 16:9 wallpaper preview cards eliminating SceneGraph AABB scissor corner bleed.
- **Visualizer DSP Signal Conditioning & Spring Damping**: Exponential Moving Average (EMA) low-pass filter and noise floor deadband in Python CAVA streamer, paired with spring-damped bar heights in QML.
- **Minimal Borderless Header Navigation**: Clean floating glyphs (`🏠`, `📥`, `⏱️`, `📈`) matching reference design with spring scale micro-interactions and smooth color transitions.
- **Continuous Realtime Scrubber Timestamps**: Sub-second MPRIS timeline position polling with live progress scrubber and `replay_10` circular rewind button.
- **OSD Morphing & Zero-Clipping Pipeline**: Dynamic notch morphing to $240\times 34\text{px}$ OSD pill with rotating Sun icon ($\pm 45^\circ$), clamped percentages ($0-100\%$), and automatic pre-expansion restoration.
- **Comprehensive 144-Test Aggressive Verification Harness**: Added Module 13 stress testing rapid IPC morphing bursts, Scrubber division-by-zero bounds, and `OpacityMask` declarations.

## [1.2.0] - 2026-08-26

### Added
- Modern Material 3 Expressive Dynamic Battery Capsule (19×10.5px) with animated fluid fill bar and embedded charging lightning bolt
- Apple iOS 4-tier Dark Mode Battery Palette (Charging Green `#30D158`, Normal White `#FFFFFF`, Low Power Yellow `#FFD60A`, Critical Red `#FF453A`) with crisp solid white percentage text
- Customizable Magic Highlight Animation settings in Settings App (Spring, Smooth, Linear, and Off modes)
- Magic Highlight Glide Tension (1.0–10.0) and Damping (0.10–0.80) slider controls in Settings App
- Grid Card Entrance Duration (60ms–300ms) slider control for Wallpaper Selector and App Launcher
- Spinning spring physics animation on Brightness OSD icon (+45° on increase, -45° on decrease)
- Comprehensive 80-test aggressive end-to-end test suite (`scripts/core/test_all_features.py`) covering QML syntax, backend schemas, Hyprland dual-write, IPC socket stress & fuzzing, D-Bus floods, and process lifecycle / leak auditing
- Full sandbox isolation (`tempfile.TemporaryDirectory`) for test harness to protect user config and live Hyprland settings

### Changed
- Scaled OSD icon size to 20px for balanced proportions

## [1.1.1] - 2026-08-26

### Fixed
- Restored dark solid surface colors (`itemBg`, `itemBgHover`, `itemBgActive`, `itemBorder`) in `Style.qml` to fix white popup rectangles across Notification, Power, Wi-Fi, and Bluetooth panels
- Fixed unassigned property warnings on Power menu confirmation button scale animation

### Changed
- Restored warm gold/yellow (`#EBCB8B` via `Style.warningYellow`) for Brightness OSD
- Restored dynamic volume level icons (`volume_off`, `volume_down`, `volume_up`) for Volume OSD

## [1.1.0] - 2026-08-26

### Added
- Standardized animation tokens and spring physics profiles in `Style.qml`
- Corner radius morphing on notch pill with `Easing.OutQuad` during menu transitions
- Coordinated scale and opacity entrance/exit animations for Settings window and OSD overlay
- Tab crossfade transitions in Settings window replacing abrupt switches
- Breathing scale pulse animation on Power menu confirmation countdown
- Spring-physics scale pop entrance for notification count badges
- Smooth delegate hover transitions in Wi-Fi and Bluetooth network lists
- Crossfade transitions for notification history empty states
- `add` and `displaced` transitions for App Launcher and Wallpaper Selector search grids
- Spring physics tracking on App Launcher and Wallpaper Selector highlight boxes
- Official Material Symbols `close.svg` and `error.svg` icon assets

### Changed
- Replaced all legacy NerdFont glyphs with native `M3Icon` components
- Centralized 80+ hardcoded hex colors across all components to `Style.*` properties
- Standardized all opacity and micro-interaction animations to use `Easing.OutQuad` curves
- Added startup layout guards to prevent component fly-in on initialization

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
