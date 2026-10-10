# Project: QuickShell Hyprland Notch Bar Overhaul & Optimization

## Architecture
- **UI / QML Scene Graph**: `shell.qml` (LayerShell entry point, input passthrough mask, IPC socket server, settings loader), `components/TopNotch.qml` (macro state controller, pill morphing geometry, MPRIS bindings, CAVA streamer process), tabs (MediaController, AppLauncher, WallpaperSelector, HardwareStats), drawers (AudioMenu, NotificationHistory, WifiMenu, BluetoothMenu), OSD overlays (Volume, Brightness), and `SettingsWindow.qml` (macOS-style control panel).
- **Audio & Visualizer Pipeline**: `scripts/notch/stream_audio_visualizer.py` streams 30fps CAVA audio spectrum JSON over stdout to QML `SplitParser`.
- **System Backends**: Python scripts with WirePlumber `wpctl`, D-Bus notifications / MPRIS, Hyprland pure Lua config (`quickshell_hypr.lua`), Linux `/proc` and `/sys` hardware monitors.
- **IPC Protocol**: Unix domain socket at `/tmp/quickshell-notch.sock` driven by `scripts/notch/notch_ipc.py`.

## Code Layout
- `shell.qml`, `components/*.qml`: QML frontend scene graph.
- `scripts/core/`: validation pipeline (`validate_codebase.sh`), process utilities (`process_utils.py`), test runners (`test_all_features.py`).
- `scripts/notch/`: CAVA visualizer daemon (`stream_audio_visualizer.py`), IPC client (`notch_ipc.py`), settings loader (`get_notch_settings.py`), MPRIS seeking helpers (`mpris_seek.py`, `mpris_duration.py`).
- `scripts/hyprland/`: Pure Lua settings persistence and live-apply (`apply_all_settings.py`, `apply_hypr_option.py`, `persist_hypr_state.py`).
- `scripts/desktop/`, `scripts/network/`: hardware, audio, wifi, bluetooth, wallpaper scripts.
- `ARCHITECTURE.md`, `AGENTS.md`, `CHANGELOG.md`, `README.md`: architectural and release documentation.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Feature Branch Creation | Initialize `perf/notch-overhaul-and-audit` from HEAD | M0 | AGENTS.md |
| 2 | Baseline Performance Telemetry | Measure RAM RSS (MB) & active/idle CPU (%) | M0 | R1 |
| 3 | Authentic E2E Test Infrastructure | Live-subsystem test harness without synthetic mocks | E2E Track | R3 |
| 4 | Tier 1 Test Suite: Feature Coverage | ≥5 tests per feature for PipeWire, D-Bus, CAVA, Hyprland, IPC | E2E Track | R3 |
| 5 | Tier 2 Test Suite: Boundary & Corner Cases | Boundary clamping, error states, corrupted JSON, NaN, limits | E2E Track | R3 |
| 6 | Tier 3 Test Suite: Pairwise Interactions | Cross-feature interactions and concurrent state transitions | E2E Track | R3 |
| 7 | Tier 4 Test Suite: Real-World Workloads | End-to-end user workflows, sustained stress bursts | E2E Track | R3 |
| 8 | E2E Test Suite Publication | Generate and validate TEST_READY.md | E2E Track | R3 |
| 9 | CAVA Streamer Disk Polling Removal | Stop opening `notch_settings.json` every 10 frames in streamer loop | M1 | Survey 2 |
| 10 | Streamer PR_SET_PDEATHSIG Self-Protection | Prevent orphan Python/CAVA processes on QuickShell crash | M1 | Survey 2 |
| 11 | CAVA Lifecycle Decoupling & Sleep Mode | Prevent kill/spawn churn on drawer toggles; 0% CPU on silence | M1 | Survey 2 |
| 12 | Hyprland Lua Options Batching | Collapse 30 sequential forks into 1 `hyprctl eval` in `apply_all_settings.py` | M1 | Survey 2 |
| 13 | IPC Error Handling & Socket Pipeline | Fix exit code propagation in `notch_ipc.py` and buffering in `shell.qml` | M1 | Survey 2 |
| 14 | StatusBar Camera Dot Idle CPU Fix | Stop infinite 60fps animation repainting scene graph when idle | M2 | Survey 2 |
| 15 | MPRIS Instantiator Player Lifecycle Fix | Add `onObjectAdded`/`onObjectRemoved` to prevent zombie CAVA leaks | M2 | Survey 1 & 2 |
| 16 | MediaController Playerctl Polling Gating | Stop 500ms `playerctl` polling when notch is collapsed | M2 | Survey 1 |
| 17 | Canvas Rasterization Optimization | Eliminate software 2D Canvas repaints during spring animations | M2 | Survey 1 |
| 18 | Lazy-Load Tabs & Smooth Tab Snap | Replace 350ms eager preloading and eliminate hard tab snapping | M2 | Survey 1 |
| 19 | Icon & Mask Off-Screen FBO Optimization | Cache SVG overlays and eliminate redundant OpacityMasks | M2 | Survey 1 |
| 20 | Systematic Bug Ledger Creation | Itemize all bugs across tabs, drawers, OSDs, settings in BUG_LEDGER.md | M3 | R2 |
| 21 | Comprehensive Bug Remediation | Sequentially fix all bugs in ledger with validation checks | M3 | R2 |
| 22 | Pass 100% E2E Tests (Tiers 1-4) | Execute full authentic test suite until 100% pass | M4 | Final Phase 1 |
| 23 | Adversarial Coverage Hardening (Tier 5) | White-box adversarial testing and code gap elimination | M5 | Final Phase 2 |
| 24 | Visual Regression & Motion Verification | Capture frame sequences and recordings across all transitions | M5 | R4 |
| 25 | Post-Optimization Benchmarking | Measure RSS and CPU reductions demonstrating verified gains | M6 | Acceptance Criteria |
| 26 | Complete Architectural Docs Update | Update ARCHITECTURE.md, README.md, AGENTS.md, benchmarks | M6 | R6 |
| 27 | Git Commit History & Release Readiness | Verify atomic conventional commits and feature branch status | M6 | R5 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M0 | Branch & Baseline Profiling | Create `perf/notch-overhaul-and-audit`, record baseline RSS/CPU in BENCHMARKS_BASELINE.md | none | DONE |
| E2E | Authentic E2E Testing Suite | Build Tiers 1-4 authentic test suite and publish TEST_READY.md | M0 | DONE |
| M1 | Backend & Streaming Optimization | Eliminate CAVA disk polling, orphan hazard, CAVA churn, batch Hyprland eval, fix IPC | M0 | DONE |
| M2 | Scene Graph & Rendering Optimization | Fix camera dot idle CPU, MPRIS Instantiator leak, playerctl polling, Canvas rasterization | M0, M1 | DONE |
| M3 | Bug Discovery & Itemized Remediation | Create BUG_LEDGER.md, fix all functional and visual bugs across all states | M1, M2 | DONE |
| M4 | Final Milestone Phase 1: Pass E2E Tests | Pass 100% of authentic E2E test suite (Tiers 1-4) | E2E, M3 | DONE |
| M5 | Final Milestone Phase 2: Adversarial & Visual | Adversarial stress testing (Tier 5) and frame-capture visual regression | M4 | DONE |
| M6 | Architectural Docs & Victory Preparation | Sync ARCHITECTURE.md, AGENTS.md, post-opt benchmarks, Victory Audit prep | M5 | DONE |

## Interface Contracts
### Visualizer Daemon ↔ QML TopNotch
- Streamer emits single newline-delimited JSON: `{"bars": [int, ...], "active": bool}\n`.
- Silent state: emits `{"bars": [0...], "active": false}\n` once, then throttles stdout completely.
- Process lifecycle: sets `PR_SET_PDEATHSIG(SIGTERM)` on self; responds gracefully to SIGTERM with cleanup.
### Settings Pipeline ↔ Hyprland Lua
- `apply_all_settings.py` batches all Hyprland options into single `hyprctl eval 'hl.config({ ... })'`.
- Colors must be converted to `rgba(rrggbbaa)` format.
- Notch settings written atomically to `notch_settings.json`.
### IPC Socket Server (`shell.qml`) ↔ Clients (`notch_ipc.py`)
- Socket at `/tmp/quickshell-notch.sock`.
- Commands newline-terminated ASCII.
- Client exits 0 on success, non-zero on failure. Server drains command buffer without prematurely disconnecting.
