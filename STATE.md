# STATE.md — QuickShell Notch Project

Handoff document. Last updated: 2026-07-31 (end of "audit & remediation" session).

---

## 1. Current Architecture & Stack

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
├── notifHistoryModel (ListModel) ← NotificationServer (D-Bus)
├── PanelWindow (Overlay) → NotificationPopups (dripping ear popups, swipe/tap dismiss)
├── PanelWindow (Overlay) → TopNotch (~2530 lines)
│   ├── Compact: clock, workspace dots, audio visualizer, OSD
│   ├── Expanded: Media, Walls, Apps, Stats (4 tabs)
│   ├── Menus: PowerMenu, WifiMenu, BluetoothMenu
│   └── NotificationHistory (bell icon, swipe dismiss, clear all)
├── HyprlandFocusGrab → active when notch/menu open
├── SocketServer (/tmp/quickshell-notch.sock) → IPC
└── SettingsWindow → settings panel
```

**IPC protocol:** `toggle`, `close`, `walls`, `apps`, `osd:vol:{0-100}`, `osd:bri:{0-100}` (one command per socket connection).

**Notch morphing dimensions:**
| State | Width | Height |
|-------|-------|--------|
| Compact (default) | 130 | 30 |
| OSD active | 280 | 30 |
| Power/WiFi/BT/Notif menu | 320 | 260–320 |
| Expanded (4 tabs) | 560 | `expandedHeightVal` (350–480, default 420) |

---

## 2. Recent Modifications

### Session commits (12, all local — origin is 12 commits behind)

| Commit | Description |
|--------|-------------|
| `60edda0` | Fix: quote layout value in legacy conf output (injection guard) |
| `e3fb959` | **Phase 5 — dead code**: removed dead Process objects/badge/props/Style tokens, extracted `SparklineCanvas`, deleted 4 orphan scripts, hardened launcher/validator, README path fix |
| `f805ea2` | **Phase 4 — poll gating**: device/workspace polls gated to visible states, visualizer honors enable toggle, notification dismiss race fix |
| `d227371` | **Phase 3 — settings correctness**: validation before write, `hyprctl eval` fallback for lua parser, apply feedback, notification history fixes |
| `7349959` | Chore: gitignore `cava_config.*` (per-instance cava configs) |
| `13e8285` | **Phase 2 — data integrity**: atomic writes everywhere, corruption-safe settings, hardened visualizer, single-source defaults |
| `68dfcea` | **Phase 1 — safety**: PowerMenu shutdown-bug fix, keyboard flow wiring, PID-targeted sandbox |

### Committed earlier (still unpushed, context for the 12-commit gap)
`4462132` (refreshOccupied dedup + cava ALSA source), `7976b51` (SVG icons), `3e4e278` (workspace binding/MPRIS/throttle/hyprctl keyword feat), `f3ff998` (Timer-based workspace refresh), `0364a6c` + 4 earlier notification-popup fixes.

### Working tree: CLEAN except STATE.md (this file)

All 5 phases are committed and runtime-tested (see §3).

### Phase 3–5 details (committed)

**Phase 3 (correctness) — `d227371`:**
- `scripts/hyprland/apply_all_settings.py`: validates/converts ALL values BEFORE writing (aborts with error payload on bad values); `active_border`/`inactive_border` in KEYWORD_MAP; partial payloads MERGE into existing state (previously reset unset keys to defaults); accepts flat payloads; per-key live failures → `{"status": "partial", "errors": [...]}`; syncs `~/.cache/quickshell/hypr_state.json`.
- NEW `scripts/hyprland/apply_hypr_option.py` (shared live-apply helper): `hyprctl keyword` **silently no-ops on non-legacy (lua) parsers** (exits 0, applies nothing) → detects and falls back to `hyprctl eval 'hl.config({...})'` (merges, does not reset other settings). `normalize_color()` (bare 8-hex AARRGGBB canonical), `swap_color()` (aarrggbb↔rrggbbaa). Color formats probed: lua eval accepts `"rgba(rrggbbaa)"`/`"rgba(aarrggbb)"`/`"0x..."`, rejects bare 8-hex; legacy conf needs `rgba(aarrggbb)`.
- `set_hypr_option.sh`: delegates live apply to `apply_hypr_option.py`; persists only on successful live apply.
- `persist_hypr_state.py`: colors normalized to canonical; lua file emits RGBA byte order; legacy conf emits AARRGGBB; layout value quoted in conf (injection guard, `60edda0`).
- `stream_audio_visualizer.py`: `sweep_stale_configs()` startup cleanup of dead `cava_config.<pid>` files.
- SettingsWindow apply feedback (onExited + stdout status, `isApplyFailed`), CustomSwitch binding-preserving toggles, NotificationHistory typed ListModel + Clear All `remove(0)`, MPRIS pause→cava resurrection guard, dynamic implicitHeight (no clip), network script timeouts + PDEATHSIG, apply_wallpaper awww wait loop, spinner rotation reset, osd.sh socket timeouts.

**Phase 4 (poll gating) — `f805ea2`:**
- `workspacePollTimer` (500ms) gated on `isWorkspaceActive || isExpanded`, `refreshOccupied()` on entry; `devicePollTimer` (3s) gated on `isExpanded || isOsdActive`, `refreshDeviceLevels()` on entry (verified: refresh on expand/OSD, 3s beats while visible, immediate stop on collapse/dismiss).
- `visualizerStreamProc.running: root.visualizerEnabledVal`; bar-count change restarts the stream live.
- Deleted dead `isInhibited` 10s swaync poll.
- NotificationPopups: removal by nid (`removeById`), guarded `dismiss()` (try/catch) — fixes stale-index TypeError race.
- **Process restart semantics (verified live)**: Timer-driven `proc.running = true` DOES restart finished Processes (earlier "single-shot" conclusion was a sampling artifact — wpctl exits in ~5ms, 50ms-spaced pgrep sampling missed it).

**Phase 5 (dead code + extraction) — `e3fb959`:**
- Removed: 4 never-started swaync control Processes + `setBrightnessProc` (no UI set path), zero-width badge wrapper, `formatTime()`, `selectedIndex`, `trackLength`, unused setting props (`clock12hVal`, `networkRefreshIntervalVal`, `expandAnimType`, `tabAnimType`).
- `clock_12h` setting now wired: overrides `clock_format` → `"h:mm A"` / `"HH:mm"`.
- NEW `components/SparklineCanvas.qml`: CPU/RAM/Net graphs extracted from 3×45-line inline Canvas blocks (hist + currentVal + thresholdColors).
- Style.qml: removed 6 unused tokens.
- Deleted orphan scripts: `get_occupied_workspaces.py`, `download_cdn.py`, `download_missing_icons.py`, `replace_icons.py`.
- `launch_quickshell.sh`: escaped regex dots, kill-wait loop (up to 3s) before relaunch.
- `validate_codebase.sh`: excludes `scratch_*`/`test_*` from QML lint.
- README: stale `scripts/core/launch_quickshell.sh` paths fixed.

---

## 3. Active State & Blockers

### Validation status
- `~/.config/quickshell/scripts/core/validate_codebase.sh` — **PASSES** (qmllint + py_compile + bash -n).
- All 5 phases live-relaunched and smoke-tested: IPC toggle/close/OSD OK, zero QSLog errors, poll gating verified via log timeline (refresh on entry, 3s beats while visible, stop on collapse), settings apply success+failure paths, Process restart semantics verified.

### Runtime test checklist (used this session — all passed)
1. SettingsWindow: apply success AND failure paths render
2. Apply from Settings → `hypr_state.json` updated + border colors in both hypr files (verified live: gaps_in 2, rounding 5, borders ffd595bd/ff020007)
3. CustomSwitch: toggle persists across reopen
4. NotificationHistory: 3+ notifications → Clear All empties model; zero TypeErrors
5. Power menu keyboard flow: Enter/Escape work; background-click during countdown must NOT power off
6. WiFi/BT: spinner resets to 0°
7. OSD via `scripts/core/osd.sh volume up` (no traceback spam)
8. Expanded height slider at 480 → notch not clipped
9. MPRIS pause → system audio during dismissal window must NOT re-show visualizer
10. `set_hypr_option.sh gaps_in 6` → persists only on hyprctl success (uses eval fallback on lua parser)

### Blockers
- **Push blocked**: `git push origin main` fails — no `gh` CLI, no git credential helper, SSH key (`id_ed25519`) not registered with GitHub. 12 commits local. User chose "skip push for now".
- **Sandbox caveat**: `-n` (no-duplicate) means a sandbox cannot run while the live instance is up; `sandbox.sh` now kills only its own PID (safe), but the live bar must be stopped first.

### Known issues still open (lower priority — not requested)
- `get_system_info.py` negative network speeds after counter reset (no clamp)
- `get_apps.py` user-local/Flatpak apps shadowed by system ones (no dedupe)
- `manage_wifi.py` SSIDs containing `:` break `-t` parsing; WiFi password visible via `ps` (pass via stdin)
- `CustomSlider.qml` double-emits `moved` on release
- SettingsWindow discards unapplied draft on close
- `notifHistoryModel` unbounded (no cap)
- M3Icon stale comments (light_mode/wifi_off/bluetooth_disabled now exist) + dead assets (`check.svg`, `delete.svg`, `volume_down.svg`)
- `get_wallust_colors.sh` sources arbitrary cache file
- Settings keys `expand_anim_type`/`tab_anim_type`/`network_refresh` round-trip but have no consumer (SettingsWindow shows sliders for network_refresh and a 12h toggle that are effectively inert; `clock_12h` is now wired)

### User-specific state
- `notch_settings.json`: `visualizer_bar_count: 20` (live user value, not the 12 default); `clock_12h: true`, `clock_format: "h:mm A"`.
- `~/.cache/quickshell/hypr_state.json`: 20 keys, user's original values restored and live-verified.

---

## 4. Next Steps

### Immediate (next session, in order)
1. **Push to origin** (after auth is set up): `git push origin main` — 12 commits ahead; user must supply GitHub auth (PAT/credential helper/SSH key registration). Commit this STATE.md first.
2. **Optional cleanups** (from §3 open issues): dead M3Icon assets + stale comments; `get_system_info.py` negative-speed clamp; `manage_wifi.py` `:` SSID parsing + stdin password; SettingsWindow draft persistence; notifModel cap. Wire or remove inert settings (`network_refresh` slider, `expand_anim_type`/`tab_anim_type` keys).
3. **Feature candidates** (queued but not requested): notification action buttons (`NotificationServer.actions`), urgency-based popup theming, max-popup-count setting, sound/haptic feedback on arrival.

### Key constraints (from AGENTS.md — unchanged)
- **Hyprland dual-write**: every setting MUST write to BOTH `~/.config/hypr/quickshell_hypr.lua` AND `~/.config/hypr/quickshell_hypr.conf` (handled by `persist_hypr_state.py`/`apply_all_settings.py`; never bypass)
- **Live settings**: `hyprctl keyword <key> <value>`, never `hyprctl reload`
- **Child lifecycle**: Python children MUST use `ctypes` + `PR_SET_PDEATHSIG(SIGTERM)`
- **Validation before commit**: `~/.config/quickshell/scripts/core/validate_codebase.sh`
- **Sandbox**: `QUICKSHELL_SANDBOX=1 quickshell -n -p ~/.config/quickshell/shell.qml` (scripts skip Hyprland side-effects)
- **Live deploy**: `pkill -9 -x quickshell || true; nohup quickshell -n -p ~/.config/quickshell/shell.qml >/dev/null 2>&1 &` or `scripts/core/launch_quickshell.sh`
- **Animation**: never hard-cut transitions; SpringAnimation for morphing, NumberAnimation bezier for popups
- **Input passthrough**: PanelWindow `mask: Region { item: notchComp.notchBoxItem }`
