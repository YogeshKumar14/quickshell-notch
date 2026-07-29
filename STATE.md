# STATE.md — QuickShell Notch Project

Handoff document. Last updated: 2026-07-29.

---

## 1. Project Architecture & Stack

QuickShell (QML) notch/status bar for Hyprland with Python/Bash backends.
Entry point: `shell.qml` — orchestrates 3 PanelWindow surfaces + IPC socket.

**Tech stack:**
- **UI:** QML via QuickShell framework (LayerShell/Wayland), pure black palette
- **Backend:** Python 3 (`py_compile`), Bash (`bash -n`)
- **Compositor:** Hyprland (Lua+Conf dual-write), SwayNC (notification D-Bus)
- **Audio:** CAVA, WirePlumber, MPRIS
- **Networking:** nmcli (WiFi), bluetoothctl (Bluetooth)
- **Theming:** Wallust (dynamic accent from wallpaper)
- **Animation:** SpringAnimation for notch morphing; NumberAnimation with bezier curves for popups

**Architecture tree:**
```
shell.qml
├── NotificationServer (D-Bus) → notifHistoryModel (ListModel)
├── PanelWindow (Overlay) → NotificationPopups (dripping ear popups, swipe/tap dismiss)
├── PanelWindow (Overlay) → TopNotch (~2500 lines)
│   ├── Compact: clock, workspace dots, audio visualizer, OSD
│   ├── Expanded: Media, Walls, Apps, Stats (4 tabs)
│   ├── Menus: PowerMenu, WifiMenu, BluetoothMenu
│   └── NotificationHistory (bell icon, swipe dismiss, clear all)
├── HyprlandFocusGrab → active when notch/menu open
├── SocketServer (/tmp/quickshell-notch.sock) → IPC
└── SettingsWindow → settings panel
```

**IPC protocol:** `toggle`, `close`, `walls`, `apps`, `osd:vol:{0-100}`, `osd:bri:{0-100}`

**Notch morphing dimensions:**
| State | Width | Height |
|-------|-------|--------|
| Compact (default) | 130 | 30 |
| OSD active | 280 | 30 |
| Power/WiFi/BT/Notif menu | 320 | 320 |
| Expanded (4 tabs) | 560 | 420 |
| Visualizer overlay | 230–360 (dynamic) | 30 |

---

## 2. Notification Popup System

File: `components/NotificationPopups.qml` (committed).

**Architecture:**
- `ListModel` (`popupModel`) stores scalar fields only
- Parallel `notifObjectMap` holds raw QObject refs (ListModel drops non-scalars)
- Shared single `dismissTimer` (1s interval, checks timestamps) — replaces per-notification QML Timers
- `notifTimestamps` + `pausedTimestamps` dicts for auto-dismiss management
- `ListView` with `spacing: -24` (overlapping delegates)
- `mask: Region { item: popupsComp.popupArea }` on PanelWindow for input passthrough

**Delegate:**
```
Item (delegateRoot)
├── Item (contentItem) — draggable wrapper
│   ├── MouseArea (drag.target: contentItem, Drag.XAxis only)
│   │   ├── Tap → dismiss (deltaX < 10)
│   │   ├── Swipe right > 80px → dismiss
│   │   ├── Hover → pause/resume auto-dismiss timer
│   │   └── Snap back to x: 0
│   ├── Rectangle (bgRect) — 350px wide, anchored right
│   │   └── ColumnLayout: app icon + name, summary, body preview
│   ├── Canvas (top-left ear) — visible: index === 0, animated by earShown
│   └── Canvas (bottom-right ear) — animated by isBottom
```

**Transitions:** Add (300ms OutCubic + 500ms OutQuint), Displaced (500ms OutQuint), Remove (250ms OutCubic + 400ms OutCubic), Ear (300ms OutCubic + 400ms OutBack).

---

## 3. Recent Modifications — BOTH SESSIONS

### Session 1 (committed, NotificationPopups work)

Commits on `main` (newest first):

| Commit | Description |
|--------|-------------|
| `0364a6c` | Fix: ear re-animation when notification becomes top after dismissal |
| `910544d` | Fix missing isBottom + remove dead code |
| `68decc0` | Fix ear animations — direction + bottom-right ear entrance |
| `9aa546c` | Animate ear entrance + bottom-left corner radius |
| `1f3cbad` | Fix: popup input passthrough — mask PanelWindow to bgRect only |
| `9bf2586` | Fix popup: ear timing, jitter, click dismiss, X-axis drag |
| `ef1663b` | Fix popup gaps and exit jitter |
| `6322c87` | Fix popup bugs: ear placement, remove border, exit animation |
| `a84efc1` | Rewrite NotificationPopups — Celestia-inspired with connected drip ears |
| `f8cf193` | Fix: connected drip popups — stable layout at rapid arrival rate |
| `0d9a827` | Fix: bell/gear cross-highlight, connected drip popups, smooth clear-all |

**Committed files:** `components/NotificationPopups.qml`, `shell.qml`

### Session 2 (uncommitted — multiple feature areas)

All changes below are **unstaged/uncommitted** in the working tree.

#### a) Visualizer Frame Throttling (`TopNotch.qml`)
- Added `visualizerFrame` intermediate property with a 66ms `visFrameTimer` that copies `visualizerBars` → `visualizerFrame` at throttled rate
- All visualizer consumers (bars Repeater, wave Canvas, pulsar) now read from `visualizerFrame` instead of `visualizerBars`
- Removed the conditional `if (showVisualizer || ...)` guard on `visualizerBars` writes — bars are now always captured from the Python process
- Pulsar visualizer: changed `avgAmp` (property binding) to `calcAvgAmp()` (function) to avoid binding evaluation loops

#### b) Workspace Occupancy Reactive Binding (`TopNotch.qml:398-407`)
- **Replaced** `property var occupiedWorkspaces: [1]` (static placeholder) with a **reactive QML property binding**:
  ```qml
  property var occupiedWorkspaces: {
      var list = [];
      for (var i = 0; i < Hyprland.workspaces.count; i++) {
          var ws = Hyprland.workspaces.get(i);
          if (ws && ws.toplevels && ws.toplevels.count > 0)
              list.push(ws.id);
      }
      return list;
  }
  ```
- **Removed:** `refreshOccupied()` function (iterated `Hyprland.toplevels` checking `win.workspace.id`)
- **Removed:** `onRawEvent` handler for `createworkspace/destroyworkspace/openwindow/closewindow/movewindow`
- **Removed:** `hyprctl workspaces` polling Process + 500ms `occupiedPoller` timer
- **Removed:** `Qt.callLater(refreshOccupied)` from `onFocusedWorkspaceChanged`
- **Removed:** `root.refreshOccupied()` + double `Qt.callLater` from `Component.onCompleted`
- **Kept:** `Connections { onFocusedWorkspaceChanged }` for overlay trigger logic (`isWorkspaceActive`)
- **Rationale:** Each `HyprlandWorkspace.toplevels` sub-model is maintained by QuickShell's IPC event system; the binding auto-updates when toplevels are added/removed — no polling, no manual refresh.

#### c) CAVA Audio Source Change (`cava_config`)
- Changed audio source from `alsa_output.pci-0000_00_09.2.analog-stereo.monitor` to `bluez_output.41_42_FF_86_FD_A2.1.monitor` (Bluetooth sink)

#### d) stream_audio_visualizer.py Simplification
- Removed periodic config monitoring loop (`get_bar_count()`, `write_cava_config()`, `last_mtime`)
- Removed inner break/restart logic that re-spawned CAVA when config changed
- `get_default_monitor()` renamed to `get_monitor()`
- Outer sleep changed from 0.5s → 1.0s

#### e) apply_all_settings.py — Targeted hyprctl keyword (no reload)
- Replaced `subprocess.run(["hyprctl", "reload"])` with targeted `hyprctl keyword` calls per-setting
- Added `KEYWORD_MAP` dictionary mapping setting name → (`hyprctl_key`, `converter`)
- Added `apply_hyprctl_keyword()` helper function
- Now applies live changes instantly without full config reload

#### f) set_hypr_option.sh — hyprctl keyword + persist delegation
- Replaced Lua REPL (`hyprctl repl "hl.config({...})"`) calls with `hyprctl keyword` for all option types
- Replaced inline Python persistence script with delegation to `persist_hypr_state.py`:
  ```bash
  python3 "$PERSIST_SCRIPT" "$TYPE" "$VAL"
  ```
- Added explicit `exit 1` on unknown type (was silently fallthrough)

#### g) persist_hypr_state.py (NEW FILE)
- Extracted from inline Python in `set_hypr_option.sh`
- Handles dual-write to `quickshell_hypr.lua` + `quickshell_hypr.conf`
- Manages `~/.cache/quickshell/hypr_state.json` for state tracking
- Auto-appends `dofile`/`source` lines to main Hyprland config files

#### h) launch_quickshell.sh — Path-prefixed pkill
- Changed `pkill -9 -f cava` → `pkill -9 -f "/stream_audio_visualizer.py"` (path prefix to avoid system-wide matches)

#### i) NotificationPopups — Shared Timer Optimization (NOT committed)
- Replaced per-notification QML Timer objects (created/destroyed per notification) with a single shared `dismissTimer` (1s interval, checks `notifTimestamps[nid]`)
- Replaced `timerMap` dict with `notifTimestamps` + `pausedTimestamps` timestamp dicts
- Reduces QML object churn

#### j) MPRIS Track Card Vertical Centering Fix (`TopNotch.qml`)
- Restructured MPRIS Track Card from flat `RowLayout` → `ColumnLayout` wrapper containing `RowLayout`
- Vinyl art wrapped in `Loader { active: root.currentPage === 0 }` (lazy loads only when Media tab is visible)
- Vinyl gets `scale: 1.0 + (avgAmp * 0.06)` pulse on beat (NumberAnimation 120ms OutQuad)
- Vinyl `Loader` has `Layout.minimumHeight: 80`
- Controls Item has `Layout.minimumHeight: 60`
- Card `implicitHeight` changed from hardcoded 90 → `mprisContent.implicitHeight + 28` (dynamic height)
- Pulsar visualizer bars use `root.visualizerHeightVal` (configurable) instead of hardcoded 16

---

## 4. Active State & Blockers

### Working tree status: DIRTY (9 modified, 1 new)

```
 M STATE.md
 M cava_config
 M components/NotificationPopups.qml
 M components/TopNotch.qml
 M scripts/core/launch_quickshell.sh
 M scripts/hyprland/apply_all_settings.py
 M scripts/hyprland/set_hypr_option.sh
 M scripts/notch/stream_audio_visualizer.py
?? scripts/hyprland/persist_hypr_state.py
```

Latest commit: `0364a6c` — 14 commits ahead of likely origin (never pushed).

### What has been validated
- `~/.config/quickshell/scripts/core/validate_codebase.sh` — **PASSES** (qmllint + py_compile + bash -n)

### What has NOT been tested yet
- ✅ Workspace occupancy reactive binding passes qmllint but **not runtime-tested** (sandbox not launched)
- ✅ MPRIS Track Card restructuring not runtime-tested
- ✅ Visualizer frame throttling not runtime-tested
- ✅ `stream_audio_visualizer.py` simplification not runtime-tested
- ✅ `apply_all_settings.py` hyprctl keyword changes not runtime-tested
- ✅ `persist_hypr_state.py` not runtime-tested

### Known pre-existing issues (not introduced by this session)
- `TopNotch.qml:1802` — anchors on layout-managed item (qmllint warning)
- Missing M3Icon SVG files: `refresh.svg`, `desktop_windows.svg`, `keyboard.svg`, `notifications_none.svg`

### Potential risk areas
- **Workspace reactive binding:** Relies on QML engine tracking `Hyprland.workspaces.get(i).toplevels.count` across iterations. If the QML binding engine misses model mutations (binding expression dependencies in dynamic loops), occupied dots may fail to update. Fallback: add a 500ms polling Timer as safety net.
- **Visualizer frame throttle:** 66ms timer creates a ~1-frame delay. If users notice visualizer sluggishness, reduce interval or remove throttle.
- **Separate `visualizerBars` vs `visualizerFrame`:** Two arrays holding the same data; potential for drift if timer misbehaves. Consider unifying once throttling is verified.
- **MPRIS Loader:** `Loader { active: root.currentPage === 0 }` means vinyl appears/disappears immediately (no crossfade). Add opacity transition if jarring.

---

## 5. Next Steps

### Immediate (before deployment)
1. **Sandbox runtime test:** `QUICKSHELL_SANDBOX=1 quickshell -n -p ~/.config/quickshell/shell.qml`
   - Verify workspace dots highlight when windows are present
   - Verify MPRIS Track Card renders with correct vertical centering
   - Verify visualizer bars update without jank
2. **Fix any runtime issues** discovered in testing
3. **Commit all changes** (or commit in logical groups):
   ```
   git add -A && git commit -m "Feat: Workspace occupancy reactive binding, MPRIS card vertical centering, visualizer throttling, hyprctl keyword settings"
   ```

### After testing
4. **Push to origin:** `git push origin main` (first push of entire project)

### Known work queued (Phase 5 — component extraction)
- Extract workspace dots → standalone `WorkspaceIndicator.qml`
- Extract clock display → standalone `ClockDisplay.qml`
- Extract OSD overlay → standalone `OsdOverlay.qml`
- Extract media card → standalone `MprisTrackCard.qml`
- Extract audio visualizer → standalone `VisualizerOverlay.qml`
- Each extraction should follow existing patterns (`Layout.alignment: Qt.AlignVCenter`, `implicitHeight` from content)

### Potential improvements (not requested)
- Push notification action buttons (rendering `NotificationServer.actions`)
- Urgency-based popup theming (color/style per `urgency` level)
- Configurable max visible popup count (currently 4)
- Sound/haptic feedback on notification arrival

---

## 6. Key Constraints & Patterns

### Hyprland dual-write
Every setting change MUST write to BOTH persistence files:
- `~/.config/hypr/quickshell_hypr.lua`
- `~/.config/hypr/quickshell_hypr.conf`
Handled by `persist_hypr_state.py`. Never bypass.

### Live settings application
Use `hyprctl keyword <key> <value>` — never `hyprctl reload` (full reload is disruptive).
Mapping in `apply_all_settings.py:KEYWORD_MAP` and `set_hypr_option.sh` case statement.

### Child process lifecycle
Python scripts spawning children MUST use `ctypes` + `PR_SET_PDEATHSIG(SIGTERM)` to avoid orphan processes when QuickShell is killed.

### Validation (run before every commit):
```bash
~/.config/quickshell/scripts/core/validate_codebase.sh
```

### Sandbox testing:
```bash
QUICKSHELL_SANDBOX=1 quickshell -n -p ~/.config/quickshell/shell.qml
```

### Live deployment:
```bash
pkill -9 -x quickshell || true
nohup quickshell -n -p ~/.config/quickshell/shell.qml >/dev/null 2>&1 &
```
Or use `scripts/core/launch_quickshell.sh` (also kills cava, stream_audio_visualizer, watch_workspaces, swaync).

### Animation conventions:
- Notch morphing: `SpringAnimation` (tension/damping)
- Popup transitions: `NumberAnimation` with bezier curves (`OutQuint`, `OutCubic`, `OutBack`)
- Never hard-cut state transitions — always animate

### Input passthrough pattern:
PanelWindow `mask: Region { item: visibleContentItem }` — transparent areas click through to windows behind.
