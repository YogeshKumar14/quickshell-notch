# QuickShell Notch Bug Ledger & Remediation Audit

This document itemizes all discovered functional bugs, visual glitches, performance defects, and edge-case errors discovered during the comprehensive audit across the QuickShell notch codebase.

---

## Master Bug Ledger

| Bug ID | Subsystem | Severity | Category | Description | Status |
|--------|-----------|----------|----------|-------------|--------|
| **BUG-01** | Backend (`scripts/hyprland/apply_all_settings.py`) | Medium | Error Handling | Unvalidated / unknown keys in payload silently accepted with status 0 ("ok") | **FIXED** (`6bd0ed0`) |
| **BUG-02** | Network (`scripts/network/manage_wifi.py`) | High | Functional | Erroneous `--` argument delimiter causes `nmcli dev wifi connect` to fail 100% | **FIXED** (`c6b513c`) |
| **BUG-03** | QML UI (`components/HardwareStats.qml`, `components/SparklineCanvas.qml`) | Medium | Performance | Ungated 2D software Canvas repaints while Tab 3 is hidden or notch is collapsed | **FIXED** (`d25cd09`) |
| **BUG-04** | QML UI (`components/TopNotch.qml`, `components/OsdOverlay.qml`) | Medium | Visual / Functional | Volume OSD clamped to 100 instead of 150; unclamped progress bar track overflow | **FIXED** (`e9bf648`) |
| **BUG-05** | QML UI (`components/StatusBar.qml`) | Low | Robustness | Brittle `.parent.parent.parent.batColor` hierarchy references | **FIXED** (`7121103`) |
| **BUG-06** | QML UI (`components/TopNotch.qml`) | Low | Code Hygiene | Obsolete residual `tabPreloadTimer` never referenced or started | **FIXED** (`a22ea3b`) |
| **BUG-07** | Backend (`scripts/desktop/scan_wallpapers.py`) | Medium | Performance | Hardcoded `ThreadPoolExecutor(max_workers=4)` starves dual-core CPU | **FIXED** (`b62c493`) |

---

## Detailed Itemized Analyses

### BUG-01: `apply_all_settings.py` Unvalidated / Unknown Keys Silently Ignored
- **Affected File**: [`scripts/hyprland/apply_all_settings.py`](file:///home/yogesh/.config/quickshell/scripts/hyprland/apply_all_settings.py#L98-L110)
- **Severity**: Medium
- **Category**: Error Handling / State Validation
- **Description**: When payloads containing unknown keys or invalid types (e.g. `{"hyprland": {"shadow_color": [1, 2, 3]}}`) were passed, `apply_all_settings.py` only looped over known keys in `KEYWORD_MAP`. Unknown keys in the `hyprland` dictionary were ignored without errors, returning exit code 0 and `{"status": "ok", "note": "no hypr settings in payload"}` rather than rejecting invalid input.
- **Root Cause**: Looping over `KEYWORD_MAP.items()` instead of validating all keys in `hypr_data.items()`.
- **Fix**: Updated `apply_all_settings.py` to validate every key in `hypr_data.items()` against `KEYWORD_MAP`, appending descriptive errors for unknown keys and invalid types.
- **Commit**: `6bd0ed0` — `fix(hyprland): reject unknown keys and validate types in apply_all_settings`
- **Verification**: Verified with `pytest tests/test_adversarial_m1.py` (12/12 passed).

---

### BUG-02: `manage_wifi.py` `--` Argument Breaks Wi-Fi Connection
- **Affected File**: [`scripts/network/manage_wifi.py`](file:///home/yogesh/.config/quickshell/scripts/network/manage_wifi.py#L124)
- **Severity**: High
- **Category**: Functional / Process Execution
- **Description**: Connecting to a network from the Wi-Fi drawer fails 100% of the time. Running `python3 manage_wifi.py connect <ssid> <password>` executes:
  ```bash
  nmcli dev wifi connect -- <ssid> password <password>
  ```
  `nmcli` does not parse `--` as an option delimiter; it parses `--` as the target SSID name, and treats `<ssid>` as an `invalid extra argument`, exiting with code 2.
- **Root Cause**: Inappropriate inclusion of `--` in `args = ["nmcli", "dev", "wifi", "connect", "--", ssid]`.
- **Fix**: Removed `--` from the argument list: `args = ["nmcli", "dev", "wifi", "connect", ssid]`.
- **Commit**: `c6b513c` — `fix(wifi): remove erroneous delimiter in nmcli wifi connect command`
- **Verification**: Verified with nmcli execution; valid positional argument without syntax errors.

---

### BUG-03: `SparklineCanvas` Ungated 2D Repaints Off-Screen / While Collapsed
- **Affected File**: [`components/SparklineCanvas.qml`](file:///home/yogesh/.config/quickshell/components/SparklineCanvas.qml#L24-L25), [`components/HardwareStats.qml`](file:///home/yogesh/.config/quickshell/components/HardwareStats.qml#L79-L156)
- **Severity**: Medium
- **Category**: Performance / Resource Leak
- **Description**: In `HardwareStats.qml`, `diskRadial` guards its 2D canvas repaints with `root.isActiveTab`. However, all 3 `SparklineCanvas` instances (CPU, RAM, NET) lacked an active tab guard. Whenever system stats update, all 3 sparkline canvases execute software 2D Canvas redraws (`clearRect`, `stroke`, `createLinearGradient`, `fill`) even when the notch is completely collapsed or user is on Media, Apps, or Wallpapers tabs. On the AMD dual-core CPU, this produces unnecessary CPU cycles.
- **Root Cause**: `SparklineCanvas.qml` lacked an `active` property to gate `requestPaint()`, and `HardwareStats.qml` never passed `active: root.isActiveTab`.
- **Fix**:
  1. Added `property bool active: true`, `renderTarget: Canvas.FramebufferObject`, and `renderStrategy: Canvas.Cooperative` to `SparklineCanvas.qml`.
  2. Gated `requestPaint()` on `active && visible && width > 0`.
  3. Bound `active: root.isActiveTab` across CPU, RAM, and NET sparklines in `HardwareStats.qml`.
- **Commit**: `d25cd09` — `perf(stats): gate sparkline 2D canvas repaints to active expanded tab`
- **Verification**: Validated with `qmllint` and `validate_codebase.sh`.

---

### BUG-04: Volume OSD Upper Clamping & Track Overflow Beyond 100%
- **Affected File**: [`components/TopNotch.qml`](file:///home/yogesh/.config/quickshell/components/TopNotch.qml#L114), [`components/OsdOverlay.qml`](file:///home/yogesh/.config/quickshell/components/OsdOverlay.qml#L67-L80)
- **Severity**: Medium
- **Category**: Visual / Functional Logic
- **Description**: PipeWire and `shell.qml` support volume up to 150% (`osd:vol:150` for audio boost). However, `TopNotch.qml:showOsd()` clamped `root.osdValue = Math.max(0, Math.min(100, num))`, discarding boosted volume levels between 101% and 150%. Furthermore, in `OsdOverlay.qml`, the inner progress bar width was calculated as `parent.width * (root.animatedOsdValue / 100.0)` without an upper bound or clipping on the track, resulting in the bar overflowing the track rectangle.
- **Root Cause**: Hardcoded upper clamp to 100 in `showOsd()` and missing track clipping / bar width bounding in `OsdOverlay.qml`.
- **Fix**:
  1. In `TopNotch.qml`: allow up to 150 for volume OSD: `var maxVal = (type === "vol" || type === "volume") ? 150 : 100; root.osdValue = Math.max(0, Math.min(maxVal, num));`.
  2. In `OsdOverlay.qml`: add `clip: true` on the track, clamp bar width to `Math.max(0, Math.min(parent.width, parent.width * (root.animatedOsdValue / 100.0)))`, and tint the boosted region with `Style.warning`.
- **Commit**: `e9bf648` — `fix(osd): allow volume boost up to 150% and clamp progress bar track overflow`
- **Verification**: Verified with `qmllint` and IPC test suite `test_t2_bva_osd_volume_upper_boundary`.

---

### BUG-05: `StatusBar.qml` Fragile Battery Color Hierarchy Traversal
- **Affected File**: [`components/StatusBar.qml`](file:///home/yogesh/.config/quickshell/components/StatusBar.qml#L329-L368)
- **Severity**: Low
- **Category**: Robustness / Binding Safety
- **Description**: In `StatusBar.qml`, the battery inner fill rectangle and terminal cap accessed `batColor` using `.parent.parent.parent.batColor` and `.parent.parent.batColor`. Any minor change to layout hierarchy causes these bindings to evaluate to `undefined`.
- **Root Cause**: Implicit parent hierarchy walking instead of scoped component ID.
- **Fix**: Assigned `id: batteryDisplayRow` to the battery `RowLayout` and referenced `batteryDisplayRow.batColor` directly.
- **Commit**: `7121103` — `fix(statusbar): direct batteryDisplayRow id reference for resilient color binding`
- **Verification**: Validated with `qmllint` and `validate_codebase.sh`.

---

### BUG-06: `TopNotch.qml` Residual Obsolete `tabPreloadTimer`
- **Affected File**: [`components/TopNotch.qml`](file:///home/yogesh/.config/quickshell/components/TopNotch.qml#L912-L921)
- **Severity**: Low
- **Category**: Code Hygiene / Dead Code
- **Description**: `tabPreloadTimer` (350ms) was left behind after the lazy-load refactor in Milestone 2. It is never started, restarted, or queried anywhere in the codebase.
- **Root Cause**: Dead code left over from Milestone 2.
- **Fix**: Removed the dead `tabPreloadTimer` block.
- **Commit**: `a22ea3b` — `refactor(notch): clean up dead tabPreloadTimer in TopNotch`
- **Verification**: Validated with `qmllint` and `validate_codebase.sh`.

---

### BUG-07: `scan_wallpapers.py` Dual-Core CPU Starvation During Thumbnail Generation
- **Affected File**: [`scripts/desktop/scan_wallpapers.py`](file:///home/yogesh/.config/quickshell/scripts/desktop/scan_wallpapers.py#L115)
- **Severity**: Medium
- **Category**: Resource Management / Host Sensitivity
- **Description**: `scan_wallpapers.py` used `ThreadPoolExecutor(max_workers=4)`. On host systems with 2 CPU threads (AMD A9-9425), running 4 concurrent PIL image decoding threads consumes 100% CPU across both cores, starving Wayland rendering and causing UI frame drops.
- **Root Cause**: Hardcoded thread count not adapted to hardware thread count.
- **Fix**: Dynamically scaled workers with `min(2, os.cpu_count() or 1)`.
- **Commit**: `b62c493` — `perf(wallpaper): scale thumbnail workers dynamically to host core capacity`
- **Verification**: Executed `python3 scripts/desktop/scan_wallpapers.py` and validated thumbnail pipeline with `test_all_features.py` Module 8.
