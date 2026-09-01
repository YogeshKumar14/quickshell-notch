/**
 * TopNotch.qml — Primary Orchestrator & State Machine for QuickShell Notch (v2.0.0)
 *
 * Coordinates all top-notch systems:
 *   - Geometry morphing (compact pill -> dynamic island expanded drawer -> morphed sub-notches)
 *   - Spring physics animations and adaptive height sizing
 *   - Global state machine (isExpanded, currentPage, active sub-menus)
 *   - Seamless dripping inverted ears canvas integration
 *   - Wallust dynamic accent extraction & Hyprland border synchronization
 *   - Integration of sub-components:
 *       - CompactPill (clock, workspace dots, CAVA visualizer)
 *       - MediaController (MPRIS playback, quick sliders)
 *       - OsdOverlay (volume & brightness on-screen display)
 *       - StatusBar (expanded header row, battery capsule, quick actions)
 *       - HardwareStats (system resource monitoring)
 *       - WallpaperSelector & AppLauncher (grid drawers)
 *       - WifiMenu, BluetoothMenu, PowerMenu, NotificationHistory (morphed sub-notches)
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../theme"

FocusScope {
    id: root
    focus: true

    onGrabsFocusChanged: {
        if (root.grabsFocus) {
            root.forceActiveFocus();
        }
    }
    onIsExpandedChanged: {
        if (root.isExpanded) {
            root.forceActiveFocus();
            if (root.currentPage === 1 || root.currentPage === 2) {
                focusTabSearchTimer.restart();
            }
        }
    }

    // =========================================================================
    // 1. STATE PROPERTIES & CONTROLLERS
    // =========================================================================

    /** True if the notch is currently in its expanded state */
    property bool isExpanded: false

    /** Reference to global notification ListModel from shell.qml */
    property ListModel notifModel: null

    /** OSD State */
    property bool isOsdActive: false
    property string osdIcon: "volume_up"
    property int osdValue: 50
    property real animatedOsdValue: root.osdValue
    property color osdColor: Style.accent
    property real osdIconRotation: 0
    property int prevBrightnessLevel: -1
    property bool wasExpandedBeforeOsd: false

    Behavior on osdColor {
        ColorAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad }
    }
    Behavior on animatedOsdValue {
        SpringAnimation {
            spring: 8.0
            damping: 0.40
            epsilon: 0.05
        }
    }

    /** Dispatches OSD popup, morphs notch, and handles brightness spin physics */
    function showOsd(type, value) {
        var num = Math.round(Number(value));
        if (isNaN(num)) num = 0;
        root.osdValue = Math.max(0, Math.min(100, num));

        if (!root.isOsdActive) {
            root.wasExpandedBeforeOsd = root.isExpanded;
        }
        root.isExpanded = false;
        root.isOsdActive = true;
        root.isWorkspaceActive = false;
        workspaceDismissTimer.stop();

        if (type === "vol" || type === "volume") {
            root.osdColor = Style.accent;
            if (root.volumeMuted || root.osdValue === 0) root.osdIcon = "volume_off";
            else if (root.osdValue < 50) root.osdIcon = "volume_down";
            else root.osdIcon = "volume_up";
        } else if (type === "bri" || type === "brightness") {
            root.osdColor = Style.warningYellow;
            root.osdIcon = root.osdValue < 50 ? "brightness_low" : "brightness_high";
            if (root.prevBrightnessLevel >= 0) {
                if (root.osdValue > root.prevBrightnessLevel) root.osdIconRotation += 45;
                else if (root.osdValue < root.prevBrightnessLevel) root.osdIconRotation -= 45;
            }
            root.prevBrightnessLevel = root.osdValue;
        }

        root.isPowerMenuOpen = false;
        root.isWifiMenuOpen = false;
        root.isBluetoothMenuOpen = false;
        root.isNotifMenuOpen = false;
        root.isWifiPasswordPromptOpen = false;
        root.isPowerConfirming = false;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: root.osdTimeoutVal
        onTriggered: {
            root.isOsdActive = false;
            root.osdIconRotation = 0;
            if (root.wasExpandedBeforeOsd) {
                root.isExpanded = true;
                root.wasExpandedBeforeOsd = false;
            }
        }
    }

    /** Expose notchBox to shell.qml for input region masking */
    property alias notchBoxItem: notchBox

    /** Navigation tab index: 0=Media, 1=Walls, 2=Apps, 3=Stats */
    property int currentPage: 0
    property int totalPages: 4

    /** Switch active tab by index */
    function toggleTab(page) {
        if (root.isExpanded && root.currentPage === page) {
            root.isExpanded = false;
            root.currentPage = 0;
            return;
        }
        root.currentPage = page;
        root.isExpanded = true;
        root.isNotifMenuOpen = false;
        root.isPowerMenuOpen = false;
        root.isWifiMenuOpen = false;
        root.isBluetoothMenuOpen = false;
        root.isAudioMenuOpen = false;
        root.focusActiveTabSearch();
    }

    /** Whether the dedicated Audio & Devices drawer is open */
    property bool isAudioMenuOpen: false

    /** Dispatches audio drawer toggle */
    function toggleAudioMenu() {
        root.isAudioMenuOpen = !root.isAudioMenuOpen;
        if (root.isAudioMenuOpen) {
            root.isWifiMenuOpen = false;
            root.isBluetoothMenuOpen = false;
            root.isPowerMenuOpen = false;
            root.isNotifMenuOpen = false;
            root.isExpanded = true;
        }
    }

    /** Handles incoming notifications */
    function handleNewNotification() {
        if (!root.isExpanded && !root.isWifiMenuOpen && !root.isBluetoothMenuOpen && !root.isPowerMenuOpen && !root.isAudioMenuOpen) {
            root.notifMenuAutoOpened = true;
            root.isNotifMenuOpen = true;
        }
    }

    /** Focuses search inputs on active tab */
    function focusActiveTabSearch() {
        focusTabSearchTimer.restart();
    }

    Timer {
        id: focusTabSearchTimer
        interval: 80
        onTriggered: {
            if (root.currentPage === 1 && appsTabLoader.item) {
                appsTabLoader.item.forceActiveFocus();
            } else if (root.currentPage === 2 && wallsTabLoader.item) {
                wallsTabLoader.item.forceActiveFocus();
            }
        }
    }

    // =========================================================================
    // 2. CONFIGURATION & NOTCH DIMENSION PROPERTIES
    // =========================================================================

    property int autoCloseDelay: 5000
    property int compactWidthVal: 130
    property int expandedHeightVal: 106

    property int pageChromeHeight: 10 + 32 + 6 + 10
    property int pageNotchHeight: root.expandedHeightVal
    property int maxPageNotchHeight: Math.max(root.expandedHeightVal, 320)
    property int notchRadiusVal: 22
    property bool drippingEarsVal: true
    property int clockFontSizeVal: 14
    property string clockFormatVal: "h:mm A"
    property int batteryWarningThresholdVal: 20
    property int osdTimeoutVal: 2000
    property bool workspaceOverlayVal: true
    property string wallpaperDirVal: ""
    property int workspaceTimeoutVal: 2500
    property string wsAnimType: "stretch"
    property bool buttonAnimsVal: true
    property int buttonSpeedVal: 180
    property int appColumnsVal: 4

    property string highlightAnimTypeVal: "spring"
    property real highlightSpringTensionVal: 5.5
    property real highlightSpringDampingVal: 0.25
    property int gridAnimDurationVal: 120

    // Visualizer Parameters
    property bool visualizerEnabledVal: true
    property string visualizerStyleVal: "bars"
    property int visualizerHeightVal: 16
    property int visualizerTimeoutVal: 0
    property int visualizerBarCountVal: 12
    property int visualizerWaveWidthVal: 2
    property real visualizerPulsarScaleVal: 1.2
    property int visualizerPauseDelayVal: 1000

    property real textWidth: compactPillComp ? compactPillComp.trackTitleWidth : 0
    property real dynamicVisNotchWidth: root.showVisualizer
        ? Math.max(root.compactWidthVal, Math.min(420, 16 + 18 + 12 + 64 + 12 + root.textWidth + 18))
        : root.compactWidthVal

    property var visualizerBars: []
    property var visualizerFrame: []
    property bool isAudioActive: false
    property bool isVisualizerActive: false
    readonly property bool showVisualizer: root.visualizerEnabledVal && root.isVisualizerActive && !root.isExpanded && !root.isOsdActive && !root.isNotifMenuOpen

    Timer {
        id: visFrameTimer
        interval: 66
        repeat: true
        running: (root.showVisualizer || (root.isExpanded && root.currentPage === 0)) && root.visualizerBars.length > 0
        onTriggered: {
            if (root.visualizerBars.length > 0) root.visualizerFrame = root.visualizerBars;
        }
    }

    function triggerVisualizerPopup() {
        if (!root.visualizerEnabledVal) return;
        visPauseTimer.stop();
        root.isVisualizerActive = true;
        if (root.visualizerTimeoutVal > 0) {
            visTimeoutTimer.restart();
        }
    }

    Timer {
        id: visTimeoutTimer
        interval: root.visualizerTimeoutVal
        onTriggered: root.isVisualizerActive = false
    }

    Timer {
        id: visPauseTimer
        interval: root.visualizerPauseDelayVal
        onTriggered: root.isVisualizerActive = false
    }

    // Ear size geometry
    property real earSize: Math.max(12, Math.min(32, root.notchRadiusVal * 1.5))
    readonly property real effectiveEarSize: Math.max(0, Math.min(root.earSize, notchBox.height - notchBox.bottomLeftRadius))

    // =========================================================================
    // 3. HARDWARE LEVELS & HYPRLAND WORKSPACES
    // =========================================================================

    property int volumeLevel: 50
    property bool volumeMuted: false
    property int micLevel: 50
    property bool micMuted: false
    property int brightnessLevel: 50
    property int batteryLevel: 100
    property string batteryStatus: "Discharging"

    // Hyprland Active & Occupied Workspaces
    property int activeWorkspace: 1
    property var occupiedWorkspaces: [1]
    property bool isWorkspaceActive: false

    // Workspace Dot Stretch Handle Physics
    property real targetHandleX: 0
    property real handleLeft: 0
    property real handleRight: 0
    property real singleHandleX: 0

    Behavior on targetHandleX {
        SpringAnimation { spring: 5.5; damping: 0.22; epsilon: 0.1 }
    }
    Behavior on singleHandleX {
        SpringAnimation { spring: 5.5; damping: 0.22; epsilon: 0.1 }
    }
    Behavior on handleLeft {
        SpringAnimation { spring: 4.8; damping: 0.24; epsilon: 0.1 }
    }
    Behavior on handleRight {
        SpringAnimation { spring: 6.2; damping: 0.20; epsilon: 0.1 }
    }

    function updateHandlePosition(wsNum) {
        var dotCenter = (wsNum - 1) * 14;
        root.targetHandleX = dotCenter;
        root.singleHandleX = dotCenter;
        root.handleLeft = dotCenter - 1;
        root.handleRight = dotCenter + 7;
    }

    Timer {
        id: workspaceDismissTimer
        interval: root.workspaceTimeoutVal
        onTriggered: root.isWorkspaceActive = false
    }

    Connections {
        target: Hyprland
        function onRawEvent(name, data) {
            if (name === "workspace" || name === "focusedmon" || name === "workspacev2") {
                var wsNum = parseInt(data);
                if (!isNaN(wsNum) && wsNum > 0 && wsNum <= 10) {
                    root.activeWorkspace = wsNum;
                    root.updateHandlePosition(wsNum);
                    if (root.workspaceOverlayVal && !root.isExpanded && !root.isOsdActive && !root.isNotifMenuOpen) {
                        root.isWorkspaceActive = true;
                        workspaceDismissTimer.restart();
                    }
                }
            } else if (name === "createworkspace" || name === "destroyworkspace" || name === "movewindow" || name === "openwindow" || name === "closewindow") {
                root.refreshOccupied();
            }
        }
    }

    Process {
        id: occupiedWorkspacesProc
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    var occ = [];
                    for (var i = 0; i < data.length; i++) {
                        var id = data[i].id;
                        if (id > 0 && id <= 10) occ.push(id);
                    }
                    root.occupiedWorkspaces = occ;
                } catch (e) {}
            }
        }
    }

    function refreshOccupied() {
        if (!occupiedWorkspacesProc.running) occupiedWorkspacesProc.running = true;
    }

    // =========================================================================
    // 4. NOTIFICATION & REAPER DATA
    // =========================================================================

    property int notifCount: notifHistoryComp ? notifHistoryComp.activeCount : 0
    property int notifStackChrome: notifHistoryComp ? notifHistoryComp.notifStackChrome : 100
    property int notifStackMaxHeight: notifHistoryComp ? notifHistoryComp.notifStackMaxHeight : 450
    property int notifStackEmptyHeight: notifHistoryComp ? notifHistoryComp.notifStackEmptyHeight : 140
    property int notifStackHeight: notifHistoryComp ? notifHistoryComp.notifStackHeight : 140

    // Spring Constants
    property real expandSpringTension: 5.0
    property real expandSpringDamping: 0.40
    property real tabSpringTension: 5.5
    property real tabSpringDamping: 0.22

    // =========================================================================
    // 5. SETTINGS LOADING & CLOCK PROCESSES
    // =========================================================================

    Process {
        id: loadNotchSettingsProc
        command: ["python3", Quickshell.shellDir + "/scripts/notch/get_notch_settings.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    if (data.auto_close !== undefined) root.autoCloseDelay = data.auto_close;
                    if (data.compact_width !== undefined) root.compactWidthVal = data.compact_width;
                    if (data.expanded_height !== undefined) root.expandedHeightVal = data.expanded_height;
                    if (data.bottom_radius !== undefined) root.notchRadiusVal = data.bottom_radius;
                    if (data.dripping_ears !== undefined) root.drippingEarsVal = data.dripping_ears;
                    if (data.app_columns !== undefined) root.appColumnsVal = data.app_columns;
                    if (data.workspace_overlay !== undefined) root.workspaceOverlayVal = data.workspace_overlay;
                    if (data.workspace_timeout !== undefined) root.workspaceTimeoutVal = data.workspace_timeout;
                    if (data.ws_anim_type !== undefined) root.wsAnimType = data.ws_anim_type;
                    if (data.button_anims !== undefined) root.buttonAnimsVal = data.button_anims;
                    if (data.button_speed !== undefined) root.buttonSpeedVal = data.button_speed;
                    if (data.visualizer_enabled !== undefined) root.visualizerEnabledVal = data.visualizer_enabled;
                    if (data.visualizer_style !== undefined) root.visualizerStyleVal = data.visualizer_style;
                    if (data.visualizer_height !== undefined) root.visualizerHeightVal = data.visualizer_height;
                    if (data.visualizer_timeout !== undefined) root.visualizerTimeoutVal = data.visualizer_timeout;
                    if (data.visualizer_bar_count !== undefined) root.visualizerBarCountVal = data.visualizer_bar_count;
                    if (data.visualizer_wave_width !== undefined) root.visualizerWaveWidthVal = data.visualizer_wave_width;
                    if (data.visualizer_pulsar_scale !== undefined) root.visualizerPulsarScaleVal = data.visualizer_pulsar_scale;
                    if (data.visualizer_pause_delay !== undefined) root.visualizerPauseDelayVal = data.visualizer_pause_delay;
                    if (data.expand_tension !== undefined) root.expandSpringTension = data.expand_tension;
                    if (data.expand_damping !== undefined) root.expandSpringDamping = data.expand_damping;
                    if (data.tab_tension !== undefined) root.tabSpringTension = data.tab_tension;
                    if (data.tab_damping !== undefined) root.tabSpringDamping = data.tab_damping;
                    if (data.stats_interval !== undefined) root.sysStatsIntervalVal = data.stats_interval;
                    if (data.osd_timeout !== undefined) root.osdTimeoutVal = data.osd_timeout;
                    if (data.clock_format !== undefined) root.clockFormatVal = data.clock_format;
                    if (data.clock_font_size !== undefined) root.clockFontSizeVal = data.clock_font_size;
                    if (data.battery_warning_threshold !== undefined) root.batteryWarningThresholdVal = data.battery_warning_threshold;
                    if (data.wallpaper_dir !== undefined) root.wallpaperDirVal = data.wallpaper_dir;
                    if (data.highlight_anim_type !== undefined) root.highlightAnimTypeVal = data.highlight_anim_type;
                    if (data.highlight_spring_tension !== undefined) root.highlightSpringTensionVal = data.highlight_spring_tension;
                    if (data.highlight_spring_damping !== undefined) root.highlightSpringDampingVal = data.highlight_spring_damping;
                    if (data.grid_anim_duration !== undefined) root.gridAnimDurationVal = data.grid_anim_duration;
                } catch (e) {
                    console.log("Error loading notch settings:", e);
                }
            }
        }
    }

    function refreshNotchSettings() {
        loadNotchSettingsProc.running = true;
    }

    property string timeStr: ""
    function updateClock() {
        root.timeStr = Qt.formatDateTime(new Date(), root.clockFormatVal);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateClock()
    }

    Timer {
        id: autoCloseTimer
        interval: root.autoCloseDelay
        running: false
        repeat: false
        onTriggered: {
            if (root.isExpanded && !root.isWifiMenuOpen && !root.isBluetoothMenuOpen && !root.isPowerMenuOpen && !root.isNotifMenuOpen && !root.isWifiPasswordPromptOpen) {
                root.isExpanded = false;
                root.currentPage = 0;
            }
        }
    }

    // =========================================================================
    // 6. AUDIO VISUALIZER & HARDWARE STATE MONITORS
    // =========================================================================

    Process {
        id: visualizerProc
        command: ["python3", Quickshell.shellDir + "/scripts/notch/stream_audio_visualizer.py"]
        running: root.visualizerEnabledVal
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var obj = JSON.parse(data.trim());
                    if (obj.bars) {
                        root.visualizerBars = obj.bars;
                        var isAct = obj.active === true;
                        if (isAct) {
                            root.isAudioActive = true;
                            root.triggerVisualizerPopup();
                        } else if (root.isAudioActive) {
                            root.isAudioActive = false;
                            visPauseTimer.restart();
                        }
                    }
                } catch (e) {}
            }
        }
    }

    property int sysStatsIntervalVal: 2000
    property int cpuUsage: 0
    property var cpuHistory: [22, 28, 30, 26, 35, 29, 33]
    property int ramUsage: 0
    property var ramHistory: [46, 48, 47, 49, 48, 50, 49]
    property int diskUsage: 0
    property real netRxSpeed: 0
    property real netTxSpeed: 0
    property var netHistory: [12, 18, 8, 25, 14, 30, 20]

    Process {
        id: sysScanner
        command: ["python3", Quickshell.shellDir + "/scripts/desktop/get_system_info.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.cpuUsage = data.cpu || 0;
                    root.ramUsage = data.ram || 0;
                    root.diskUsage = data.disk || 0;
                    root.netRxSpeed = data.net_rx || 0;
                    root.netTxSpeed = data.net_tx || 0;

                    var cpuArr = root.cpuHistory.slice();
                    cpuArr.push(root.cpuUsage);
                    if (cpuArr.length > 20) cpuArr.shift();
                    root.cpuHistory = cpuArr;

                    var ramArr = root.ramHistory.slice();
                    ramArr.push(root.ramUsage);
                    if (ramArr.length > 20) ramArr.shift();
                    root.ramHistory = ramArr;

                    var netArr = root.netHistory.slice();
                    var netNorm = Math.min(100, Math.round((root.netRxSpeed + root.netTxSpeed) / (1024 * 1024) * 10));
                    netArr.push(netNorm);
                    if (netArr.length > 20) netArr.shift();
                    root.netHistory = netArr;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: root.sysStatsIntervalVal
        repeat: true
        running: root.isExpanded && root.currentPage === 3
        onTriggered: if (!sysScanner.running) sysScanner.running = true
    }

    // =========================================================================
    // 7. SUB-MENU DRAWER STATES & CONTROLS
    // =========================================================================

    property bool isWifiMenuOpen: false
    property bool isBluetoothMenuOpen: false
    property bool isNotifMenuOpen: false
    property bool notifMenuAutoOpened: false
    readonly property bool grabsFocus: root.isExpanded || root.isNotifMenuOpen || root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen

    property bool wifiPower: true
    property string wifiActiveSsid: ""
    property var wifiNetworks: []
    property bool btPower: false
    property var btDevices: []

    property bool isWifiPasswordPromptOpen: false
    property string wifiPromptSsid: ""
    property string wifiPasswordText: ""
    property bool showWifiPassword: false

    Process {
        id: wifiStatusProc
        command: ["python3", Quickshell.shellDir + "/scripts/network/manage_wifi.py", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.wifiPower = data && data.power !== undefined ? data.power : false;
                    root.wifiActiveSsid = (data && data.active) || "";
                    if (data && data.networks) root.wifiNetworks = data.networks;
                } catch (e) {}
            }
        }
    }

    Process {
        id: btStatusProc
        command: ["python3", Quickshell.shellDir + "/scripts/network/manage_bluetooth.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.btPower = data && data.power !== undefined ? data.power : false;
                    root.btDevices = (data && data.devices) || [];
                } catch (e) {}
            }
        }
    }

    Process {
        id: deviceLevelsProc
        command: ["python3", Quickshell.shellDir + "/scripts/desktop/get_device_levels.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    if (data.volume !== null && data.volume !== undefined) root.volumeLevel = data.volume;
                    if (data.volume_muted !== undefined) root.volumeMuted = data.volume_muted;
                    if (data.mic !== null && data.mic !== undefined) root.micLevel = data.mic;
                    if (data.mic_muted !== undefined) root.micMuted = data.mic_muted;
                    if (data.brightness !== null && data.brightness !== undefined) root.brightnessLevel = data.brightness;
                    if (data.battery !== null && data.battery !== undefined) root.batteryLevel = data.battery;
                    if (data.battery_status) root.batteryStatus = data.battery_status;
                } catch (e) {}
            }
        }
    }

    Timer {
        id: devicePollTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refreshDeviceLevels()
    }

    function refreshDeviceLevels() {
        if (!deviceLevelsProc.running) deviceLevelsProc.running = true;
    }

    // Power Menu State
    property bool isPowerMenuOpen: false
    property int powerSelectedIndex: 0
    property bool isPowerConfirming: false
    property int powerCountdown: 5
    property string pendingPowerCmd: ""
    property string pendingPowerTitle: ""

    // Lazy Tab Lifecycle Management
    property bool wallsTabAlive: false
    property bool appsTabAlive: false

    onCurrentPageChanged: {
        if (root.currentPage === 1) {
            appsUnloadTimer.stop();
            root.appsTabAlive = true;
        } else if (root.currentPage === 2) {
            wallsUnloadTimer.stop();
            root.wallsTabAlive = true;
        } else if (root.currentPage === 3) {
            sysScanner.running = true;
        }
        if (root.currentPage !== 1 && root.appsTabAlive) appsUnloadTimer.restart();
        if (root.currentPage !== 2 && root.wallsTabAlive) wallsUnloadTimer.restart();
    }

    Timer {
        id: wallsUnloadTimer
        interval: 5000
        onTriggered: root.wallsTabAlive = false
    }

    Timer {
        id: appsUnloadTimer
        interval: 5000
        onTriggered: root.appsTabAlive = false
    }

    // =========================================================================
    // 8. WALLUST COLOR INTEGRATION & WALLPAPER APPLICATION
    // =========================================================================

    property string pendingWallpaperPath: ""

    Process {
        id: applyWallpaperProc
        stdout: StdioCollector {
            onStreamFinished: {
                wallustDelayTimer.restart();
                if (root.pendingWallpaperPath !== "") {
                    delayedWallpaperTimer.restart();
                }
            }
        }
    }

    Timer {
        id: wallustDelayTimer
        interval: 400
        repeat: false
        onTriggered: root.refreshAccent()
    }

    Timer {
        id: delayedWallpaperTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (root.pendingWallpaperPath !== "" && !applyWallpaperProc.running) {
                var targetPath = root.pendingWallpaperPath;
                root.pendingWallpaperPath = "";
                applyWallpaperProc.command = ["bash", Quickshell.shellDir + "/scripts/desktop/apply_wallpaper.sh", targetPath];
                applyWallpaperProc.running = true;
            }
        }
    }

    function handleWallpaperSelected(path) {
        if (!applyWallpaperProc.running) {
            applyWallpaperProc.command = ["bash", Quickshell.shellDir + "/scripts/desktop/apply_wallpaper.sh", path];
            applyWallpaperProc.running = true;
        } else {
            root.pendingWallpaperPath = path;
        }
    }

    // Dynamic Wallust Accent fetcher
    Process {
        id: wallustAccentProc
        command: ["bash", Quickshell.shellDir + "/scripts/desktop/get_wallust_colors.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var c = this.text.trim();
                if (c && c.startsWith("#")) {
                    Style.accent = c;
                    // Sync Hyprland window border to the new accent
                    var aarrggbb = "ff" + c.substring(1).toLowerCase();
                    borderColorSyncProc.running = false;
                    borderColorSyncProc.command = [
                        "bash",
                        Quickshell.shellDir + "/scripts/hyprland/set_hypr_option.sh",
                        "active_border",
                        aarrggbb
                    ];
                    borderColorSyncProc.running = true;
                }
            }
        }
    }

    // Sync Hyprland window border to wallust accent
    Process {
        id: borderColorSyncProc
        stdout: StdioCollector {}
    }

    function refreshAccent() {
        wallustAccentProc.running = true;
    }

    // MPRIS Media properties
    property var activePlayer: {
        var players = Mpris.players.values;
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }
    property string trackTitle: activePlayer && activePlayer.trackTitle ? activePlayer.trackTitle : "No Media Playing"
    property string trackArtist: activePlayer && activePlayer.trackArtist ? activePlayer.trackArtist : "Top Notch"
    property bool isPlaying: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing) : false
    property real trackPosition: activePlayer && activePlayer.position ? activePlayer.position : 0

    onActivePlayerChanged: {
        if (activePlayer) {
            root.trackPosition = activePlayer.position;
        } else {
            root.trackPosition = 0;
        }
    }

    // Continuously update track position while media is playing
    Timer {
        id: trackPosTimer
        interval: 500
        running: root.isPlaying && root.isExpanded && root.currentPage === 0
        repeat: true
        onTriggered: {
            if (root.activePlayer && root.activePlayer.position !== undefined) {
                root.trackPosition = root.activePlayer.position;
            }
        }
    }

    // =========================================================================
    // 9. LIFECYCLE & SIGNALS & KEYBOARD HANDLER
    // =========================================================================

    signal openFullSettings()

    Component.onCompleted: {
        refreshNotchSettings();
        updateClock();
        root.refreshOccupied();
        root.refreshDeviceLevels();
        root.refreshAccent();
        wifiStatusProc.running = true;
        btStatusProc.running = true;
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (root.isWifiMenuOpen) {
                if (root.isWifiPasswordPromptOpen) {
                    root.isWifiPasswordPromptOpen = false;
                } else {
                    root.isWifiMenuOpen = false;
                }
                event.accepted = true;
            } else if (root.isBluetoothMenuOpen) {
                root.isBluetoothMenuOpen = false;
                event.accepted = true;
            } else if (root.isPowerMenuOpen) {
                if (root.isPowerConfirming) {
                    root.isPowerConfirming = false;
                } else {
                    root.isPowerMenuOpen = false;
                }
                event.accepted = true;
            } else if (root.isNotifMenuOpen) {
                root.isNotifMenuOpen = false;
                event.accepted = true;
            } else if (root.isAudioMenuOpen) {
                root.isAudioMenuOpen = false;
                event.accepted = true;
            } else if (root.isExpanded) {
                root.isExpanded = false;
                event.accepted = true;
            }
        } else if (root.isPowerMenuOpen) {
            if (root.isPowerConfirming) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    powerMenuComp.execute();
                    event.accepted = true;
                }
            } else {
                if (event.key === Qt.Key_Left) {
                    root.powerSelectedIndex = (root.powerSelectedIndex - 1 + 5) % 5;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    root.powerSelectedIndex = (root.powerSelectedIndex + 1) % 5;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    var actions = [
                        { title: "Lock", cmd: "hyprlock || swaylock -f" },
                        { title: "Logout", cmd: "hyprctl dispatch exit" },
                        { title: "Suspend", cmd: "systemctl suspend" },
                        { title: "Reboot", cmd: "systemctl reboot" },
                        { title: "Shutdown", cmd: "systemctl poweroff" }
                    ];
                    var chosen = actions[root.powerSelectedIndex];
                    powerMenuComp.trigger(chosen.title, chosen.cmd);
                    event.accepted = true;
                }
            }
        }
    }

    // =========================================================================
    // 10. VISUAL PRESENTATION & GEOMETRY (DRIPPING INVERTED EARS)
    // =========================================================================

    Canvas {
        id: earCanvasLeft
        z: 10
        width: Math.max(1, Math.round(root.effectiveEarSize))
        height: Math.max(1, Math.round(root.effectiveEarSize))
        anchors.top: notchBox.top
        anchors.right: notchBox.left
        visible: root.drippingEarsVal && root.effectiveEarSize > 0

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = "#000000";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(width, height);
            ctx.arcTo(width, 0, 0, 0, width);
            ctx.closePath();
            ctx.fill();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        Component.onCompleted: requestPaint()

        Connections {
            target: root
            function onEarSizeChanged() { earCanvasLeft.requestPaint(); }
            function onDrippingEarsValChanged() { earCanvasLeft.requestPaint(); }
        }
    }

    Canvas {
        id: earCanvasRight
        z: 10
        width: Math.max(1, Math.round(root.effectiveEarSize))
        height: Math.max(1, Math.round(root.effectiveEarSize))
        anchors.top: notchBox.top
        anchors.left: notchBox.right
        visible: root.drippingEarsVal && root.effectiveEarSize > 0

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = "#000000";
            ctx.beginPath();
            ctx.moveTo(width, 0);
            ctx.lineTo(0, 0);
            ctx.lineTo(0, height);
            ctx.arcTo(0, 0, width, 0, width);
            ctx.closePath();
            ctx.fill();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        Component.onCompleted: requestPaint()

        Connections {
            target: root
            function onEarSizeChanged() { earCanvasRight.requestPaint(); }
            function onDrippingEarsValChanged() { earCanvasRight.requestPaint(); }
        }
    }

    // =========================================================================
    // 11. PRIMARY NOTCH BOX (SOLID BLACK MORPHING CONTAINER)
    // =========================================================================

    Rectangle {
        id: notchBox
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: root.isOsdActive
            ? 280
            : ((root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isNotifMenuOpen)
                ? 320
                : (root.isAudioMenuOpen
                    ? Style.notchWidthExpanded
                    : (root.isExpanded
                        ? Style.notchWidthExpanded
                        : (root.isWorkspaceActive ? 240 : (root.showVisualizer ? root.dynamicVisNotchWidth : root.compactWidthVal)))))

        height: root.isOsdActive
            ? Style.notchHeightCompact
            : (root.isPowerMenuOpen
                ? 260
                : ((root.isWifiMenuOpen || root.isBluetoothMenuOpen)
                    ? 320
                    : (root.isNotifMenuOpen
                        ? root.notifStackHeight
                        : (root.isAudioMenuOpen
                            ? 190
                            : (root.isExpanded ? root.pageNotchHeight : Style.notchHeightCompact)))))

        color: "#000000"
        border.width: 0

        bottomLeftRadius: (root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isNotifMenuOpen) ? Style.radiusLarge : root.notchRadiusVal
        bottomRightRadius: (root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isNotifMenuOpen) ? Style.radiusLarge : root.notchRadiusVal
        topLeftRadius: 0
        topRightRadius: 0

        clip: true

        Behavior on bottomLeftRadius {
            NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad }
        }
        Behavior on bottomRightRadius {
            NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad }
        }

        Behavior on width {
            SpringAnimation {
                spring: root.expandSpringTension
                damping: root.expandSpringDamping
                epsilon: 0.20
                mass: 1.0
            }
        }
        Behavior on height {
            SpringAnimation {
                spring: root.expandSpringTension
                damping: root.expandSpringDamping
                epsilon: 0.20
                mass: 1.0
            }
        }

        // Global MouseArea handling expand, collapse & auto-close
        MouseArea {
            id: notchMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (!root.isExpanded && !root.isNotifMenuOpen && !root.isPowerMenuOpen && !root.isWifiMenuOpen && !root.isBluetoothMenuOpen && !root.isAudioMenuOpen) ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: autoCloseTimer.stop()
            onExited: {
                if (root.isExpanded) autoCloseTimer.restart();
            }
            onClicked: function(mouse) {
                if (!root.isExpanded && !root.isNotifMenuOpen && !root.isPowerMenuOpen && !root.isWifiMenuOpen && !root.isBluetoothMenuOpen && !root.isAudioMenuOpen) {
                    if (root.showVisualizer) root.currentPage = 0;
                    root.isExpanded = true;
                    root.isOsdActive = false;
                    root.isWorkspaceActive = false;
                    autoCloseTimer.stop();
                } else {
                    if (root.isPowerMenuOpen) root.isPowerMenuOpen = false;
                    else if (root.isWifiMenuOpen) root.isWifiMenuOpen = false;
                    else if (root.isBluetoothMenuOpen) root.isBluetoothMenuOpen = false;
                    else if (root.isNotifMenuOpen) root.isNotifMenuOpen = false;
                    else if (root.isAudioMenuOpen) root.isAudioMenuOpen = false;
                    else if (root.isExpanded) root.isExpanded = false;
                }
            }
        }

        // --- SUB-COMPONENT 1: COMPACT PILL ---
        CompactPill {
            id: compactPillComp
            anchors.fill: parent
            opacity: (root.isExpanded || root.isNotifMenuOpen || root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isAudioMenuOpen) ? 0.0 : 1.0
            visible: opacity > 0.01

            timeStr: root.timeStr
            clockFontSize: root.clockFontSizeVal
            notifCount: root.notifCount

            activeWorkspace: root.activeWorkspace
            occupiedWorkspaces: root.occupiedWorkspaces
            wsAnimType: root.wsAnimType
            isWorkspaceActive: root.isWorkspaceActive
            handleLeft: root.handleLeft
            handleRight: root.handleRight
            singleHandleX: root.singleHandleX

            showVisualizer: root.showVisualizer
            visualizerStyle: root.visualizerStyleVal
            visualizerBarCount: root.visualizerBarCountVal
            visualizerHeight: root.visualizerHeightVal
            visualizerWaveWidth: root.visualizerWaveWidthVal
            visualizerPulsarScale: root.visualizerPulsarScaleVal
            visualizerFrame: root.visualizerFrame
            trackTitle: root.trackTitle
            trackArtUrl: (root.activePlayer && root.activePlayer.trackArtUrl) ? root.activePlayer.trackArtUrl : ""
            isOsdActive: root.isOsdActive

            onExpandRequested: {
                root.isExpanded = true;
                root.isWorkspaceActive = false;
                autoCloseTimer.stop();
            }
            onWorkspaceSwitchRequested: function(wsNum) {
                Hyprland.dispatch("workspace " + wsNum.toString());
                workspaceDismissTimer.restart();
            }
        }

        // --- SUB-COMPONENT 2: OSD OVERLAY ---
        OsdOverlay {
            id: osdOverlayComp
            isOsdActive: root.isOsdActive
            osdIcon: root.osdIcon
            osdValue: root.osdValue
            animatedOsdValue: root.animatedOsdValue
            osdColor: root.osdColor
            osdIconRotation: root.osdIconRotation
        }

        // --- EXPANDED VIEWPORT CONTENT ---
        Item {
            id: expandedContainer
            width: Style.notchWidthExpanded
            height: root.pageNotchHeight
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: (root.isExpanded && !root.isOsdActive && !root.isNotifMenuOpen && !root.isPowerMenuOpen && !root.isWifiMenuOpen && !root.isBluetoothMenuOpen && !root.isAudioMenuOpen) ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
            }

            // --- SUB-COMPONENT 3: STATUS BAR (HEADER ROW) ---
            StatusBar {
                id: statusBarComp
                anchors.top: parent.top
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                height: 20

                currentPage: root.currentPage
                tabSpringTension: root.tabSpringTension
                tabSpringDamping: root.tabSpringDamping
                buttonSpeed: root.buttonSpeedVal
                buttonAnims: root.buttonAnimsVal

                batteryLevel: root.batteryLevel
                batteryStatus: root.batteryStatus
                batteryWarningThreshold: root.batteryWarningThresholdVal

                wifiPower: root.wifiPower
                isWifiMenuOpen: root.isWifiMenuOpen
                btPower: root.btPower
                isBluetoothMenuOpen: root.isBluetoothMenuOpen

                notifCount: root.notifCount
                isNotifMenuOpen: root.isNotifMenuOpen
                isPowerMenuOpen: root.isPowerMenuOpen

                onTabSelected: function(idx) {
                    root.currentPage = idx;
                    root.isNotifMenuOpen = false;
                    root.isPowerMenuOpen = false;
                    root.isWifiMenuOpen = false;
                    root.isBluetoothMenuOpen = false;
                    root.isAudioMenuOpen = false;
                    root.isWifiPasswordPromptOpen = false;
                    root.isPowerConfirming = false;
                }
                onWifiToggled: {
                    root.isWifiMenuOpen = !root.isWifiMenuOpen;
                    root.isBluetoothMenuOpen = false;
                    root.isPowerMenuOpen = false;
                    root.isNotifMenuOpen = false;
                    root.isAudioMenuOpen = false;
                }
                onBluetoothToggled: {
                    root.isBluetoothMenuOpen = !root.isBluetoothMenuOpen;
                    root.isWifiMenuOpen = false;
                    root.isPowerMenuOpen = false;
                    root.isNotifMenuOpen = false;
                    root.isAudioMenuOpen = false;
                }
                onNotifToggled: {
                    root.notifMenuAutoOpened = false;
                    root.isNotifMenuOpen = !root.isNotifMenuOpen;
                    root.isWifiMenuOpen = false;
                    root.isBluetoothMenuOpen = false;
                    root.isPowerMenuOpen = false;
                    root.isAudioMenuOpen = false;
                }
                onPowerToggled: {
                    root.isPowerMenuOpen = !root.isPowerMenuOpen;
                    root.isPowerConfirming = false;
                    root.powerSelectedIndex = 0;
                    root.isWifiMenuOpen = false;
                    root.isBluetoothMenuOpen = false;
                    root.isNotifMenuOpen = false;
                    root.isAudioMenuOpen = false;
                }
                onSettingsClicked: root.openFullSettings()
            }

            // --- MAIN PAGE CAROUSEL VIEWPORT ---
            Item {
                id: pageViewport
                anchors.top: parent.top
                anchors.topMargin: 28
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                clip: true

                Row {
                    id: pageRow
                    height: parent.height
                    x: -root.currentPage * (pageViewport.width > 0 ? pageViewport.width : 560)

                    Behavior on x {
                        SpringAnimation {
                            spring: root.tabSpringTension
                            damping: root.tabSpringDamping
                            epsilon: Style.springEpsilon
                        }
                    }

                    // PAGE 0: Media Controller (Nook Dashboard)
                    MediaController {
                        id: mediaControllerComp
                        width: pageViewport.width > 0 ? pageViewport.width : 560
                        height: pageViewport.height > 0 ? pageViewport.height : 72
                        activePlayer: root.activePlayer
                        isPlaying: root.isPlaying
                        trackTitle: root.trackTitle
                        trackArtist: root.trackArtist
                        trackPosition: root.trackPosition
                        volumeLevel: root.volumeLevel
                        micLevel: root.micLevel
                        buttonAnims: root.buttonAnimsVal
                        buttonSpeed: root.buttonSpeedVal
                        tabSpringTension: root.tabSpringTension
                        tabSpringDamping: root.tabSpringDamping
                        visualizerFrame: root.visualizerFrame
                        onAudioMenuRequested: root.toggleAudioMenu()
                    }

                    // PAGE 1: Application Launcher (Tray)
                    Item {
                        width: pageViewport.width > 0 ? pageViewport.width : 560
                        height: pageViewport.height > 0 ? pageViewport.height : 72
                        clip: true

                        Loader {
                            id: appsTabLoader
                            anchors.fill: parent
                            active: root.appsTabAlive
                            sourceComponent: AppLauncher {
                                appColumns: root.appColumnsVal
                                highlightAnimType: root.highlightAnimTypeVal
                                highlightSpringTension: root.highlightSpringTensionVal
                                highlightSpringDamping: root.highlightSpringDampingVal
                                gridAnimDuration: root.gridAnimDurationVal
                                onAppLaunched: {
                                    root.isExpanded = false;
                                    root.currentPage = 0;
                                }
                                onCloseRequested: {
                                    root.isExpanded = false;
                                    root.currentPage = 0;
                                }
                            }
                        }
                    }

                    // PAGE 2: Wallpaper Selector (Walls)
                    Item {
                        width: pageViewport.width > 0 ? pageViewport.width : 560
                        height: pageViewport.height > 0 ? pageViewport.height : 72
                        clip: true

                        Loader {
                            id: wallsTabLoader
                            anchors.fill: parent
                            active: root.wallsTabAlive
                            sourceComponent: WallpaperSelector {
                                isOpen: root.isExpanded && root.currentPage === 2
                                wallpaperDir: root.wallpaperDirVal
                                highlightAnimType: root.highlightAnimTypeVal
                                highlightSpringTension: root.highlightSpringTensionVal
                                highlightSpringDamping: root.highlightSpringDampingVal
                                gridAnimDuration: root.gridAnimDurationVal
                                onWallpaperSelected: function(path) {
                                    root.handleWallpaperSelected(path);
                                }
                                onCloseRequested: {
                                    root.isExpanded = false;
                                    root.currentPage = 0;
                                }
                            }
                        }
                    }

                    // PAGE 3: Hardware Stats Dashboard (Stats)
                    HardwareStats {
                        id: hardwareStatsComp
                        width: pageViewport.width > 0 ? pageViewport.width : 560
                        height: pageViewport.height > 0 ? pageViewport.height : 72
                        cpuUsage: root.cpuUsage
                        cpuHistory: root.cpuHistory
                        ramUsage: root.ramUsage
                        ramHistory: root.ramHistory
                        netRxSpeed: root.netRxSpeed
                        netTxSpeed: root.netTxSpeed
                        netHistory: root.netHistory
                        diskUsage: root.diskUsage
                        isActiveTab: root.isExpanded && root.currentPage === 3
                    }
                }
            }
        }

        // =====================================================================
        // 12. SUB-MENU DRAWER OVERLAYS (MORPhed SUB-NOTCHES)
        // =====================================================================

        PowerMenu {
            id: powerMenuComp
            anchors.fill: parent
            isOpen: root.isPowerMenuOpen
            selectedIndex: root.powerSelectedIndex
            isConfirming: root.isPowerConfirming
            countdown: root.powerCountdown
            pendingTitle: root.pendingPowerTitle
            pendingCmd: root.pendingPowerCmd
            onIsConfirmingChanged: root.isPowerConfirming = powerMenuComp.isConfirming
            onSelectedIndexChanged: root.powerSelectedIndex = powerMenuComp.selectedIndex
            onTriggered: function(title, cmd) {
                root.pendingPowerTitle = title;
                root.pendingPowerCmd = cmd;
                root.powerCountdown = 5;
                root.isPowerConfirming = true;
            }
            onCancelled: root.isPowerConfirming = false
            onExecuted: {
                root.isPowerConfirming = false;
                root.isPowerMenuOpen = false;
                root.isExpanded = false;
            }
            onCloseRequested: {
                root.isPowerMenuOpen = false;
                root.isPowerConfirming = false;
            }
        }

        WifiMenu {
            id: wifiMenuComp
            anchors.fill: parent
            isOpen: root.isWifiMenuOpen
            wifiPower: root.wifiPower
            wifiActiveSsid: root.wifiActiveSsid
            wifiNetworks: root.wifiNetworks
            isPasswordPromptOpen: root.isWifiPasswordPromptOpen
            promptSsid: root.wifiPromptSsid
            passwordText: root.wifiPasswordText
            showPassword: root.showWifiPassword
            onWifiPowerChanged: root.wifiPower = wifiMenuComp.wifiPower
            onWifiActiveSsidChanged: root.wifiActiveSsid = wifiMenuComp.wifiActiveSsid
            onWifiNetworksChanged: root.wifiNetworks = wifiMenuComp.wifiNetworks
            onIsPasswordPromptOpenChanged: root.isWifiPasswordPromptOpen = wifiMenuComp.isPasswordPromptOpen
            onPromptSsidChanged: root.wifiPromptSsid = wifiMenuComp.promptSsid
            onPasswordTextChanged: root.wifiPasswordText = wifiMenuComp.passwordText
            onShowPasswordChanged: root.showWifiPassword = wifiMenuComp.showPassword
            onCloseRequested: root.isWifiMenuOpen = false
            onPowerToggled: function(val) {
                root.wifiPower = val;
                wifiStatusProc.running = true;
            }
        }

        BluetoothMenu {
            id: btMenuComp
            anchors.fill: parent
            isOpen: root.isBluetoothMenuOpen
            btPower: root.btPower
            btDevices: root.btDevices
            onBtPowerChanged: root.btPower = btMenuComp.btPower
            onBtDevicesChanged: root.btDevices = btMenuComp.btDevices
            onCloseRequested: root.isBluetoothMenuOpen = false
            onPowerToggled: function(val) {
                root.btPower = val;
                btStatusProc.running = true;
            }
        }

        NotificationHistory {
            id: notifHistoryComp
            anchors.fill: parent
            isOpen: root.isNotifMenuOpen
            notifModel: root.notifModel
            expandSpringTension: root.expandSpringTension
            expandSpringDamping: root.expandSpringDamping
            onCloseRequested: {
                root.isNotifMenuOpen = false;
                root.notifMenuAutoOpened = false;
            }
            onNotifCountChanged: {
                root.notifCount = notifHistoryComp.notifCount;
                if (root.isNotifMenuOpen && notifHistoryComp.notifCount === 0) {
                    root.isNotifMenuOpen = false;
                }
            }
        }

        AudioMenu {
            id: audioMenuComp
            anchors.fill: parent
            isOpen: root.isAudioMenuOpen
            onCloseRequested: root.isAudioMenuOpen = false
            onVolumeChanged: function(val) {
                root.volumeLevel = val;
            }
        }
    }
}
