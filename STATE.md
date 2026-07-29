# STATE.md — QuickShell Notch Project

Handoff document. Last updated: 2026-07-29.

---

## 1. Project Architecture & Stack

QuickShell (QML) notch/status bar for Hyprland with Python/Bash backends.

**Tech stack:**
- **UI:** QML via QuickShell framework (LayerShell, Wayland)
- **Backend scripts:** Python 3 (`py_compile` validated), Bash (`bash -n` validated)
- **Compositor:** Hyprland (Lua + Conf dual-write), SwayNC (notification D-Bus)
- **Audio:** CAVA (visualizer), WirePlumber (volume), MPRIS (media)
- **Networking:** nmcli (WiFi), bluetoothctl (Bluetooth)
- **Theming:** Wallust (dynamic accent from wallpaper), pure black palette
- **Animation:** SpringAnimation (tension/damping) for all smooth transitions

**Entry point:** `shell.qml` — orchestrates 3 PanelWindow surfaces + IPC socket.

**Architecture:**
```
shell.qml
├── NotificationServer → notifHistoryModel (ListModel)
├── PanelWindow (notifPopupsWindow) → NotificationPopups (dripping ears, swipe dismiss)
├── PanelWindow (notchWindow) → TopNotch (~2500 lines — core component)
│   ├── Compact overlays: clock, workspace dots, audio visualizer, OSD
│   ├── Expanded tabs: Media, Walls, Apps, Stats (4 tabs, segmented control)
│   ├── Menu overlays: PowerMenu, WifiMenu, BluetoothMenu (extracted components)
│   └── NotificationHistory (bell icon, swipe-to-dismiss, clear all)
├── PanelWindow (settingsWindow) → SettingsWindow (4-tab settings panel)
├── HyprlandFocusGrab → active when notch expanded/menu open
├── SocketServer (/tmp/quickshell-notch.sock) → IPC handler
└── SettingsWindow → SpringAnimation-driven settings panel
```

**IPC protocol:** Unix socket at `/tmp/quickshell-notch.sock`
Commands: `toggle`, `close`, `walls`, `apps`, `osd:vol:{0-100}`, `osd:bri:{0-100}`

**Settings flow:** `notch_settings.json` ↔ `get_notch_settings.py` ↔ `apply_all_settings.py` → Hyprland Lua + Conf

**Notch morphing states:**
- `isOsdActive` → 280px wide
- `isPowerMenuOpen || isWifiMenuOpen || isBluetoothMenuOpen || isNotifMenuOpen` → 320x320
- `isExpanded` → 560x420
- `isWorkspaceActive` → 240px wide
- `showVisualizer` → dynamic width (230-360px)
- Default compact → 130x30

**Spring animation constants (current):**
- `expandSpringTension: 4.5`, `expandSpringDamping: 0.28`
- `tabSpringTension: 5.5`, `tabSpringDamping: 0.22`
- `buttonSpeedVal: 120`

---

## 2. Recent Modifications

### Phase 0: Baseline Commit (COMPLETED)
- `package-lock.json` added to `.gitignore`
- `launch_quickshell.sh` fix committed (adds swaync kill before quickshell launch)
- Commit: `d190e91`

### Phase 1: Bug Fixes (COMPLETED)
- `TopNotch.qml:68` — `totalPages: 5` → `totalPages: 4` (only 4 tabs exist)
- `TopNotch.qml:1535` — Fixed stale comment ("Notifs" → "Stats")
- `get_notch_settings.py:36` — Removed dead `visualizer_dot_size` from DEFAULTS
- `set_hypr_option.sh:75-79` — Reset now restores `notch_settings.json` to defaults
- `TopNotch.qml:1113-1120` — Added `isNotifMenuOpen` property

### Phase 2: Component Extraction (COMPLETED)
- Created `components/PowerMenu.qml` — extracted from TopNotch.qml:2516-2710
- Created `components/WifiMenu.qml` — extracted from TopNotch.qml:2712-3062
- Created `components/BluetoothMenu.qml` — extracted from TopNotch.qml:3064-3244
- Removed ~730 lines of inline menus + old Process/Timer objects from TopNotch.qml
- Fixed stray `Process {` brace error that broke QML syntax

### Phase 3: Notification History Feature (COMPLETED)
- Created `components/NotificationHistory.qml` — scrollable list, swipe-to-dismiss, clear all
- Added bell icon button in expanded header row
- Wired `notifModel` from `shell.qml` → `TopNotch` → `NotificationHistory`
- Updated `HyprlandFocusGrab` to include `isNotifMenuOpen`
- Added bell icon to M3Icon map (`"notifications"`)

### Phase 4: WiFi/BT Device Limits (COMPLETED)
- `manage_wifi.py:46` — `networks[:6]` → `networks[:12]`
- `manage_bluetooth.py:34` — `devices[:5]` → `devices[:10]`

### Bug Batch 1: 4 Bugs Fixed (COMPLETED)
1. **Bell icon missing glyph** — Added `"notifications"` to M3Icon `iconMap`
2. **ESC doesn't close notification menu** — Added `isNotifMenuOpen` branch to `Keys.onPressed`
3. **Black area click doesn't close all menus** — MouseArea `enabled` now includes all menu states; `onClicked` closes whichever is open
4. **Tab pill misaligned** — Changed `x: 4 + (currentPage * 19)` → `x: 14.5 + (currentPage * 19)`

### Current git state:
- Branch: `main`
- Latest commit: `d190e91` (Phase 0 baseline)
- Phases 1-4 + Bug Batch 1 are in working tree (uncommitted)

---

## 3. Active State & Blockers

### Bug Batch 2: 5 Bugs Analyzed, NOT YET IMPLEMENTED

#### Bug 1: Gear/notification icon hover cross-highlight (MEDIUM)
- **File:** `TopNotch.qml:1655-1740`
- **Symptom:** Bell button highlights when hovering gear, and vice versa
- **Root cause:** Bell button Rectangle (line 1655) has no explicit `id`. The `notifM` MouseArea (line 1692) `anchors.fill: parent` may be bleeding into gear area. Additionally, line 1660 references `gearM.pressed` instead of `notifM.pressed`.
- **Fix:** Change line 1660 from `gearM.pressed` / `gearM.containsMouse` to `notifM.pressed` / `notifM.containsMouse`

#### Bug 2: Multiple notification pops broken (HIGH)
- **File:** `NotificationPopups.qml:60-62`
- **Symptom:** When multiple notifications exist, removing one removes all from that index onward
- **Root cause:** `popupModel.remove(idx)` without count parameter removes ALL items from idx onward
- **Fix:** Change `popupModel.remove(idx)` → `popupModel.remove(idx, 1)`

#### Bug 3: Pop animation not using spring (MEDIUM)
- **File:** `NotificationPopups.qml:350-360`
- **Symptom:** Swipe-to-dismiss uses `NumberAnimation { duration: 120 }` instead of spring
- **Fix:** Replace with `SpringAnimation { spring: 3.5; damping: 0.75 }` matching existing spring constants

#### Bug 4: Clear all instant removal (MEDIUM)
- **File:** `NotificationHistory.qml` — `clearAll()` method
- **Symptom:** `notifModel.clear()` called immediately, no animated removal
- **Fix:** Add animated removal loop (remove one at a time with delay, or batch with transition)

#### Bug 5: Inverted ear positioning (LOW)
- **File:** `TopNotch.qml:670-870` (Canvas ear geometry)
- **Symptom:** Ears move with popup instead of staying fixed to right bezel edge
- **Fix:** Lock Canvas ear coordinates to right bezel position until popup area ≤ ear area

---

## 4. Next Steps

### Immediate (Bug Batch 2 Implementation)
1. Fix Bug 1: Change `gearM.pressed`/`gearM.containsMouse` → `notifM.pressed`/`notifM.containsMouse` in TopNotch.qml:1660
2. Fix Bug 2: Change `popupModel.remove(idx)` → `popupModel.remove(idx, 1)` in NotificationPopups.qml:62
3. Fix Bug 3: Replace swipe dismiss `NumberAnimation` with `SpringAnimation` in NotificationPopups.qml
4. Fix Bug 4: Add animated removal loop to `clearAll()` in NotificationHistory.qml
5. Fix Bug 5: Adjust Canvas ear geometry in TopNotch.qml to lock to right bezel

### After Bug Batch 2
- Run validation: `~/.config/quickshell/scripts/core/validate_codebase.sh`
- Sandbox test: `QUICKSHELL_SANDBOX=1 quickshell -n -p ~/.config/quickshell/shell.qml`
- Commit all changes with descriptive message

### Future Phases (from original plan)
- **Phase 5:** Extract remaining sub-components (workspace dots, clock, OSD, media card, visualizer)
- Ongoing: Performance monitoring, user testing

---

## 5. Key Constraints & Patterns

### Hyprland dual-write
Any setting change MUST write to BOTH:
- `~/.config/hypr/quickshell_hypr.lua`
- `~/.config/hypr/quickshell_hypr.conf`
Automated in `apply_all_settings.py` and `set_hypr_option.sh` — do not bypass.

### Child process lifecycle
Python scripts spawning children MUST use `ctypes` + `PR_SET_PDEATHSIG(SIGTERM)` so they die when parent QuickShell daemon is killed. Without this, orphan processes leak CPU.

### Adding a new setting requires 3 places:
1. `get_notch_settings.py` — add default to `DEFAULTS` dict
2. `TopNotch.qml` — add property + wire to settings loader
3. `SettingsWindow.qml` — add UI control + wire to apply payload

### Menu overlay pattern:
Each menu (Power/WiFi/BT/Notif) follows:
1. `Item` with `anchors.fill: parent; z: 99`
2. Opacity toggle: `root.isXxxMenuOpen ? 1.0 : 0.0`
3. `Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }`
4. Internal ColumnLayout with `anchors.margins: 14-16`

### Hardcoded paths
All QML Process commands use absolute `/home/yogesh/.config/quickshell/scripts/...` paths (20 occurrences). Inherent to QuickShell's `Process.command` not supporting `~` expansion.

---

## 6. Testing

- Run `~/.config/quickshell/scripts/core/validate_codebase.sh` after each phase
- Sandbox test: `QUICKSHELL_SANDBOX=1 quickshell -n -p ~/.config/quickshell/shell.qml`
- The validation pipeline (qmllint + py_compile + bash -n) has no known failures in current codebase
