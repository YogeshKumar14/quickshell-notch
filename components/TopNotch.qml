import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import "../theme"

Item {
    id: root

    property bool isExpanded: false
    property bool isOsdActive: false
    property string osdIcon: "󰕾"
    property int osdValue: 50
    property real animatedOsdValue: root.osdValue
    property color osdColor: Style.accent
    property ListModel notifModel: null

    Behavior on osdColor {
        ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Behavior on animatedOsdValue {
        SpringAnimation {
            spring: root.expandSpringTension
            damping: root.expandSpringDamping
            epsilon: 0.25
        }
    }

    function showOsd(type, value) {
        if (type === "volume") {
            root.osdIcon = "󰕾";
            root.osdColor = Style.accent;
            root.volumeLevel = value;
            root.osdValue = root.volumeLevel;
        } else if (type === "brightness") {
            root.osdIcon = "󰃠";
            root.osdColor = "#EBCB8B"; // Warm yellow
            root.brightnessLevel = value;
            root.osdValue = root.brightnessLevel;
        }
        
        root.isExpanded = false;
        root.isPowerMenuOpen = false;
        root.isWifiMenuOpen = false;
        root.isBluetoothMenuOpen = false;
        root.isWorkspaceActive = false;
        
        root.isOsdActive = true;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: root.osdTimeoutVal
        repeat: false
        onTriggered: root.isOsdActive = false
    }
    signal openFullSettings()

    // Expose notchBox to shell.qml for input mask
    property alias notchBoxItem: notchBox

    property int currentPage: 0
    property int totalPages: 4

    // Toggle a specific tab open/closed via IPC keybind
    function toggleTab(page) {
        if (root.isExpanded && root.currentPage === page) {
            root.isExpanded = false;
        } else {
            root.currentPage = page;
            root.isExpanded = true;
            focusTabSearchTimer.restart();
        }
    }

    function focusActiveTabSearch() {
        if (root.currentPage === 1 && wallsLoader.item) {
            wallsLoader.forceActiveFocus();
            if (typeof wallsLoader.item.focusSearch === "function") {
                wallsLoader.item.focusSearch();
            }
        } else if (root.currentPage === 2 && appsLoader.item) {
            appsLoader.forceActiveFocus();
            if (typeof appsLoader.item.focusSearch === "function") {
                appsLoader.item.focusSearch();
            }
        }
    }

    Timer {
        id: focusTabSearchTimer
        interval: 80
        repeat: false
        onTriggered: root.focusActiveTabSearch()
    }

    onIsExpandedChanged: {
        if (isExpanded) {
            root.isOsdActive = false;
            root.refreshOccupied();
            workspacePollTimer.running = true;
            root.refreshDeviceLevels();
            devicePollTimer.running = true;
            if (currentPage === 1 || currentPage === 2) {
                focusTabSearchTimer.restart();
            }
            if (wallsLoader.item && typeof wallsLoader.item.refresh === "function") {
                wallsLoader.item.refresh();
            }
            if (appsLoader.item && typeof appsLoader.item.refresh === "function") {
                appsLoader.item.refresh();
            }
        } else {
            root.isWifiMenuOpen = false;
            root.isBluetoothMenuOpen = false;
            root.isPowerMenuOpen = false;
            root.isWifiPasswordPromptOpen = false;
            workspacePollTimer.running = root.isWorkspaceActive;
            devicePollTimer.running = root.isOsdActive;
        }
    }



    onIsPowerMenuOpenChanged: {
        if (isPowerMenuOpen) {
            root.isOsdActive = false;
            root.forceActiveFocus();
        } else if (isExpanded) {
            focusTabSearchTimer.restart();
        }
    }

    onIsWifiMenuOpenChanged: {
        if (isWifiMenuOpen) {
            root.isOsdActive = false;
            root.forceActiveFocus();
        }
    }

    onIsBluetoothMenuOpenChanged: {
        if (isBluetoothMenuOpen) {
            root.isOsdActive = false;
            root.forceActiveFocus();
        }
    }

    // Power Menu State
    property bool isPowerMenuOpen: false
    property int powerSelectedIndex: 0
    property bool isPowerConfirming: false
    property int powerCountdown: 5
    property string pendingPowerCmd: ""
    property string pendingPowerTitle: ""

    // Focus management for keyboard input
    focus: true
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
                    root.cancelPowerAction();
                } else {
                    root.isPowerMenuOpen = false;
                }
                event.accepted = true;
            } else if (root.isNotifMenuOpen) {
                root.isNotifMenuOpen = false;
                event.accepted = true;
            } else if (root.isExpanded) {
                root.isExpanded = false;
                event.accepted = true;
            }
        } else if (root.isPowerMenuOpen) {
            if (root.isPowerConfirming) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.executePendingPower();
                    event.accepted = true;
                }
            } else {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                    root.powerSelectedIndex = (root.powerSelectedIndex - 1 + 4) % 4;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                    root.powerSelectedIndex = (root.powerSelectedIndex + 1) % 4;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    var opts = [
                        { title: "Shutdown", cmd: "systemctl poweroff" },
                        { title: "Reboot", cmd: "systemctl reboot" },
                        { title: "Sleep", cmd: "systemctl suspend" },
                        { title: "Logout", cmd: "hyprctl dispatch exit" }
                    ];
                    var sel = opts[root.powerSelectedIndex];
                    root.triggerPowerAction(sel.title, sel.cmd);
                    event.accepted = true;
                }
            }
        }
    }

    // Delayed unload: tabs stay loaded for 30s after leaving
    property bool wallsTabAlive: false
    property bool appsTabAlive: false

    onCurrentPageChanged: {
        // Activate the tab we're switching TO
        if (currentPage === 1) {
            wallsTabAlive = true;
            wallsUnloadTimer.stop();
            if (wallsLoader.item && typeof wallsLoader.item.refresh === "function") {
                wallsLoader.item.refresh();
            }
        } else {
            // Start 30s countdown to unload Walls tab
            if (wallsTabAlive) wallsUnloadTimer.restart();
        }
        if (currentPage === 2) {
            appsTabAlive = true;
            appsUnloadTimer.stop();
            if (appsLoader.item && typeof appsLoader.item.refresh === "function") {
                appsLoader.item.refresh();
            }
        } else {
            if (appsTabAlive) appsUnloadTimer.restart();
        }
        if (currentPage === 3) {
            sysScanner.running = true;
        }
    }

    Timer {
        id: wallsUnloadTimer
        interval: 30000
        repeat: false
        onTriggered: root.wallsTabAlive = false
    }

    Timer {
        id: appsUnloadTimer
        interval: 30000
        repeat: false
        onTriggered: root.appsTabAlive = false
    }

    // Configurable Notch Parameters loaded live
    property int autoCloseDelay: 5000
    property int compactWidthVal: 130
    property int expandedHeightVal: 420

    // Per-tab expanded notch height: media (0) and stats (3) grow to fit their
    // content exactly; walls (1) and apps (2) keep the user-configured height.
    property int pageChromeHeight: 14 + headerRow.implicitHeight + 10 + tabDots.implicitHeight + 10 + 14
    property int mediaPageContentHeight: mediaColumn ? mediaColumn.implicitHeight : 0
    property int statsPageContentHeight: statsColumn ? statsColumn.implicitHeight : 0
    property int pageNotchHeight: root.currentPage === 0 ? Math.max(root.expandedHeightVal, root.mediaPageContentHeight + root.pageChromeHeight)
        : (root.currentPage === 3 ? Math.max(root.expandedHeightVal, root.statsPageContentHeight + root.pageChromeHeight)
        : root.expandedHeightVal)
    // Window-sized hint: tall enough for the tallest page so spring morphs between
    // page heights never clip (the window is transparent; the mask passes clicks through).
    property int maxPageNotchHeight: Math.max(root.expandedHeightVal, root.mediaPageContentHeight + root.pageChromeHeight, root.statsPageContentHeight + root.pageChromeHeight)
    property int notchRadiusVal: 16
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

    // Visualizer Parameters & Counterparts
    property bool visualizerEnabledVal: true
    property string visualizerStyleVal: "bars"
    property int visualizerHeightVal: 16
    property int visualizerTimeoutVal: 0
    property int visualizerBarCountVal: 12
    property int visualizerWaveWidthVal: 2
    property real visualizerPulsarScaleVal: 1.2
    property int visualizerPauseDelayVal: 1000

    // Dynamic Notch Width scaling according to song title
    property real textWidth: trackTitleText.implicitWidth
    property real dynamicVisNotchWidth: Math.min(360, Math.max(230, 150 + textWidth))

    // Audio Visualizer IPC State
    property var visualizerBars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var visualizerFrame: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property bool isAudioActive: false
    property bool isVisualizerActive: false

    // Throttle frame propagation: runs when any visualizer consumer is potentially visible
    Timer {
        id: visFrameTimer
        interval: 66
        repeat: true
        running: root.isVisualizerActive || (root.isExpanded && root.currentPage === 0)
        onTriggered: root.visualizerFrame = root.visualizerBars
    }

    // Evaluated Visualizer Display State
    property bool showVisualizer: root.visualizerEnabledVal && root.isVisualizerActive && !root.isWorkspaceActive && !root.isOsdActive

    function triggerVisualizerPopup() {
        if (!root.visualizerEnabledVal || root.isExpanded || root.isWorkspaceActive) return;
        visualizerPauseTimer.stop();
        root.isVisualizerActive = true;
        if (root.visualizerTimeoutVal > 0) {
            visualizerDismissTimer.restart();
        }
    }

    function triggerVisualizerDismissal() {
        visualizerDismissTimer.stop();
        if (root.visualizerPauseDelayVal > 0) {
            visualizerPauseTimer.restart();
        } else {
            root.isVisualizerActive = false;
        }
    }

    onIsPlayingChanged: {
        if (root.isPlaying) {
            triggerVisualizerPopup();
        } else {
            triggerVisualizerDismissal();
        }
    }

    onTrackTitleChanged: {
        if (root.isPlaying) {
            triggerVisualizerPopup();
        }
    }

    Timer {
        id: visualizerDismissTimer
        interval: root.visualizerTimeoutVal > 0 ? root.visualizerTimeoutVal : 1000
        repeat: false
        onTriggered: {
            if (root.visualizerTimeoutVal > 0) {
                root.isVisualizerActive = false;
            }
        }
    }

    Timer {
        id: visualizerPauseTimer
        interval: root.visualizerPauseDelayVal > 0 ? root.visualizerPauseDelayVal : 100
        repeat: false
        onTriggered: {
            root.isVisualizerActive = false;
        }
    }

    Process {
        id: visualizerStreamProc
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/notch/stream_audio_visualizer.py"]
        running: root.visualizerEnabledVal
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (parsed.bars !== undefined) {
                        root.visualizerBars = parsed.bars;
                    }
                    if (parsed.active !== undefined) {
                        var wasActive = root.isAudioActive;
                        root.isAudioActive = parsed.active;

                        // Non-MPRIS system audio stream trigger logic.
                        // Guard: while the MPRIS pause-dismissal timer is pending,
                        // system audio must not resurrect the visualizer.
                        if (!root.isPlaying) {
                            if (parsed.active && !wasActive && !visualizerPauseTimer.running) {
                                triggerVisualizerPopup();
                            } else if (!parsed.active) {
                                triggerVisualizerDismissal();
                            }
                        }
                    }
                } catch (e) {
                    console.log("Error parsing visualizer IPC payload:", e);
                }
            }
        }
    }

    // Restart the visualizer stream when the bar count changes so the new
    // count takes effect live (config is regenerated on every cava spawn).
    Timer {
        id: visualizerRestartTimer
        interval: 10
        repeat: false
        onTriggered: visualizerStreamProc.running = true
    }

    // Workspace native QML state (occupiedWorkspaces refreshed on overlay entry + polled)
    property int activeWorkspace: 1
    property var occupiedWorkspaces: [1]

    function refreshOccupied() {
        try {
            var list = [];
            var wsList = Hyprland.workspaces.values;
            for (var i = 0; i < wsList.length; i++) {
                var ws = wsList[i];
                if (ws && ws.toplevels && ws.toplevels.values.length > 0) {
                    list.push(ws.id);
                }
            }
            root.occupiedWorkspaces = list;
        } catch (e) {
            console.warn("refreshOccupied failed:", e);
        }
    }

    // Poll occupancy only while the workspace overlay or the expanded notch
    // is visible; refresh once on entry so data is never stale.
    Timer {
        id: workspacePollTimer
        interval: 500
        repeat: true
        running: false
        onTriggered: root.refreshOccupied()
    }
    property bool isWorkspaceActive: false
    onIsWorkspaceActiveChanged: {
        if (root.isWorkspaceActive) {
            root.isOsdActive = false;
            root.refreshOccupied();
            workspacePollTimer.running = true;
        } else if (!root.isExpanded) {
            workspacePollTimer.running = false;
        }
    }

    // Reactive workspace overlay via focused workspace changes
    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            if (Hyprland.focusedWorkspace) {
                var newActive = Hyprland.focusedWorkspace.id;
                if (root.workspaceOverlayVal && !root.isExpanded && newActive !== root.activeWorkspace) {
                    root.isWorkspaceActive = true;
                    workspaceDismissTimer.restart();
                }
                root.activeWorkspace = newActive;
            }
        }
    }

    Timer {
        id: workspaceDismissTimer
        interval: root.workspaceTimeoutVal
        repeat: false
        onTriggered: root.isWorkspaceActive = false
    }

    // 100% Pixel-Perfect Centering Math for Workspace Handle (Center = 10 + index * 22)
    property int wsIdx: Math.max(0, Math.min(9, root.activeWorkspace - 1))
    property real targetLeft: 2 + wsIdx * 22
    property real targetRight: 18 + wsIdx * 22

    // Dual-Edge Springs for Stretch mode
    property real handleLeft: targetLeft
    property real handleRight: targetRight

    Behavior on handleLeft {
        SpringAnimation { spring: 5.5; damping: 0.38 }
    }

    Behavior on handleRight {
        SpringAnimation { spring: 8.0; damping: 0.22 }
    }

    // Single-Position Handle for Smooth, Linear, and Bounce modes
    property real singleHandleX: targetLeft

    Behavior on singleHandleX {
        enabled: root.wsAnimType !== "stretch"
        SpringAnimation {
            spring: root.wsAnimType === "bounce" ? 8.5 : 5.5
            damping: root.wsAnimType === "bounce" ? 0.18 : 0.30
            epsilon: 0.25
        }
    }

    // SwayNC Notifications Properties
    property int notifCount: 0
    property bool dndActive: false

    // Event-driven SwayNC subscription (replaces 3 polling processes)
    Process {
        id: swayncSubscribeProc
        command: ["swaync-client", "--subscribe-waybar"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (parsed.text !== undefined) {
                        var c = parseInt(parsed.text);
                        if (!isNaN(c)) root.notifCount = c;
                    }
                    if (parsed.class !== undefined) {
                        root.dndActive = parsed.class.indexOf("dnd") !== -1;
                    }
                } catch (e) {}
            }
        }
    }

    // Inhibited status poll removed: value was never consumed anywhere.
    // DnD/notif control processes removed: no UI triggers them; the subscribe
    // stream keeps notifCount/dndActive fresh.

    // Dynamic Ear Size scaling in sync with spring expansion (12px Compact -> 24px Expanded)
    property real earSize: root.isExpanded ? 24 : 12

    Behavior on earSize {
        SpringAnimation {
            spring: root.expandSpringTension
            damping: root.expandSpringDamping
            epsilon: 0.25
        }
    }

    // Notch Expansion Animation Profile
    property real expandSpringTension: 4.5
    property real expandSpringDamping: 0.28

    // Tab Switch Animation Profile
    property real tabSpringTension: 5.5
    property real tabSpringDamping: 0.22

    Process {
        id: loadNotchSettingsProc
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/notch/get_notch_settings.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim());
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
                    if (data.clock_12h !== undefined) root.clockFormatVal = data.clock_12h ? "h:mm A" : "HH:mm";
                    if (data.clock_font_size !== undefined) root.clockFontSizeVal = data.clock_font_size;
                    if (data.battery_warning_threshold !== undefined) root.batteryWarningThresholdVal = data.battery_warning_threshold;
                    if (data.wallpaper_dir !== undefined) root.wallpaperDirVal = data.wallpaper_dir;
                } catch (e) {
                    console.log("Error loading notch settings:", e);
                }
            }
        }
    }

    function refreshNotchSettings() {
        loadNotchSettingsProc.running = true;
    }

    Component.onCompleted: {
        refreshNotchSettings();
        updateClock();
        root.refreshOccupied();
        root.refreshDeviceLevels();
    }

    // Restart the visualizer stream when the bar count changes so the new
    // count takes effect live.
    onVisualizerBarCountValChanged: {
        if (root.visualizerEnabledVal) {
            visualizerStreamProc.running = false;
            visualizerRestartTimer.restart();
        }
    }

    // Fixed root dimensions (624px width allows 32px padding for inverted ears)
    // Height tracks the configurable expanded height so it never clips
    implicitWidth: Style.notchWidthExpanded + 64
    implicitHeight: Math.max(Style.notchHeightExpanded, root.maxPageNotchHeight)

    // Clock string (pure JS — zero process spawns)
    property string timeStr: "00:00"

    function updateClock() {
        var now = new Date();
        root.timeStr = Qt.formatDateTime(now, root.clockFormatVal);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateClock()
    }


    // Configurable Auto-Close Timer when mouse exits expanded notch area
    Timer {
        id: autoCloseTimer
        interval: root.autoCloseDelay
        repeat: false
        onTriggered: {
            if (root.autoCloseDelay > 0 && root.isExpanded && !notchHover.hovered) {
                root.isExpanded = false;
            }
        }
    }

    // Debounced Wallpaper Execution Queue
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
                applyWallpaperProc.command = ["bash", "/home/yogesh/.config/quickshell/scripts/desktop/apply_wallpaper.sh", targetPath];
                applyWallpaperProc.running = true;
            }
        }
    }

    function handleWallpaperSelected(path) {
        root.pendingWallpaperPath = path;
        root.isExpanded = false; // Trigger 500ms contraction animation first
        if (!applyWallpaperProc.running) {
            delayedWallpaperTimer.restart();
        }
    }

    // Dynamic Wallust Accent fetcher
    Process {
        id: wallustAccentProc
        command: ["bash", "/home/yogesh/.config/quickshell/scripts/desktop/get_wallust_colors.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var c = this.text.trim();
                if (c && c.startsWith("#")) {
                    Style.accent = c;
                }
            }
        }
    }

    function refreshAccent() {
        wallustAccentProc.running = true;
    }

    // MPRIS Media properties
    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
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

    Timer {
        id: posTimer
        interval: 500
        running: root.isPlaying && root.activePlayer !== null
        repeat: true
        onTriggered: {
            if (root.activePlayer) {
                root.trackPosition = root.activePlayer.position;
            }
        }
    }

    property int cpuUsage: 0
    property int ramUsage: 0
    property int diskUsage: 0
    property int sysStatsIntervalVal: 2000

    property var cpuHistory: []
    property var ramHistory: []

    property int netRxSpeed: 0
    property int netTxSpeed: 0
    property var netHistory: []

    Process {
        id: sysScanner
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/desktop/get_system_info.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.cpuUsage = data.cpu;
                    root.ramUsage = data.ram;
                    root.diskUsage = data.disk;
                    if (data.net_rx !== undefined) root.netRxSpeed = data.net_rx;
                    if (data.net_tx !== undefined) root.netTxSpeed = data.net_tx;

                    // Accumulate CPU History
                    var cpuArr = [];
                    for (var i = 0; i < root.cpuHistory.length; i++) {
                        cpuArr.push(root.cpuHistory[i]);
                    }
                    cpuArr.push(data.cpu);
                    if (cpuArr.length > 20) cpuArr.shift();
                    root.cpuHistory = cpuArr;

                    // Accumulate RAM History
                    var ramArr = [];
                    for (var j = 0; j < root.ramHistory.length; j++) {
                        ramArr.push(root.ramHistory[j]);
                    }
                    ramArr.push(data.ram);
                    if (ramArr.length > 20) ramArr.shift();
                    root.ramHistory = ramArr;
                    
                    // Accumulate Net History (using max of RX/TX normalized up to 10MB/s roughly for graph scaling)
                    var netArr = [];
                    for (var k = 0; k < root.netHistory.length; k++) {
                        netArr.push(root.netHistory[k]);
                    }
                    // Normalize to a percentage of 10MB/s max for graphing
                    var maxNet = Math.max(root.netRxSpeed, root.netTxSpeed);
                    var netPct = Math.min(100, Math.floor((maxNet / (10 * 1024 * 1024)) * 100));
                    netArr.push(netPct);
                    if (netArr.length > 20) netArr.shift();
                    root.netHistory = netArr;

                } catch(e) {}
            }
        }
    }

    Timer {
        id: sysTimer
        interval: root.sysStatsIntervalVal
        running: root.isExpanded && root.currentPage === 3
        repeat: true
        onTriggered: sysScanner.running = true
    }

    property bool isWifiMenuOpen: false
    property bool isBluetoothMenuOpen: false
    property bool isNotifMenuOpen: false

    property bool wifiPower: false
    property string wifiActiveSsid: ""
    property var wifiNetworks: []

    property bool btPower: false
    property var btDevices: []

    property bool isWifiPasswordPromptOpen: false
    property string wifiPromptSsid: ""
    property string wifiPasswordText: ""
    property bool showWifiPassword: false



    property int volumeLevel: 50
    property int micLevel: 50
    property int brightnessLevel: 50
    property int batteryLevel: 100
    property string batteryStatus: "Unknown"

    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim());
                if (!isNaN(val)) root.volumeLevel = val;
            }
        }
    }

    Process {
        id: setVolProc
        stdout: StdioCollector { onStreamFinished: volProc.running = true }
    }

    Process {
        id: micProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print int($2 * 100)}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim());
                if (!isNaN(val)) root.micLevel = val;
            }
        }
    }

    Process {
        id: setMicProc
        stdout: StdioCollector { onStreamFinished: micProc.running = true }
    }

    Process {
        id: brightnessProc
        command: ["bash", "-c", "brightnessctl -m | awk -F, '{print int($4)}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim());
                if (!isNaN(val)) root.brightnessLevel = val;
            }
        }
    }

    Process {
        id: batteryProc
        command: ["bash", "-c", "echo $(cat /sys/class/power_supply/BAT0/capacity); cat /sys/class/power_supply/BAT0/status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                if (lines.length >= 2) {
                    var val = parseInt(lines[0]);
                    if (!isNaN(val)) root.batteryLevel = val;
                    root.batteryStatus = lines[1].trim();
                }
            }
        }
    }

    // Poll device levels only while the notch is expanded or an OSD is up;
    // refresh once on entry and re-poll after every set operation.
    Timer {
        id: devicePollTimer
        interval: 3000
        repeat: true
        running: false
        onTriggered: root.refreshDeviceLevels()
    }

    function refreshDeviceLevels() {
        volProc.running = true;
        micProc.running = true;
        brightnessProc.running = true;
        batteryProc.running = true;
    }

    onIsOsdActiveChanged: {
        if (root.isOsdActive) {
            root.refreshDeviceLevels();
            devicePollTimer.running = true;
        } else if (!root.isExpanded) {
            devicePollTimer.running = false;
        }
    }

    // Click-outside dismissal no longer needed: PanelWindow mask passes through
    // transparent area clicks directly to the compositor.

    // --- DRIPPING NOTCH CANVAS INVERTED TOP EARS (z: 10 Front Layering + Spring Morph-Scaling) ---
    // Ears rendered at fixed max size (24x24), scaled via transform to avoid per-frame repaints
    Canvas {
        id: leftEarCanvas
        z: 10
        width: 24
        height: 24
        anchors.right: notchBox.left
        anchors.top: notchBox.top
        visible: root.drippingEarsVal

        property real earScale: root.earSize / 24.0
        transform: Scale { origin.x: 24; origin.y: 0; xScale: leftEarCanvas.earScale; yScale: leftEarCanvas.earScale }

        onPaint: {
            var ctx = getContext("2d");
            var s = 24;
            ctx.clearRect(0, 0, s, s);
            ctx.fillStyle = "#000000";
            ctx.beginPath();
            ctx.arc(0, s, s, -Math.PI / 2, 0, false);
            ctx.lineTo(s, 0);
            ctx.closePath();
            ctx.fill();
        }

        onVisibleChanged: if (visible) requestPaint()
        Component.onCompleted: requestPaint()
    }

    Canvas {
        id: rightEarCanvas
        z: 10
        width: 24
        height: 24
        anchors.left: notchBox.right
        anchors.top: notchBox.top
        visible: root.drippingEarsVal

        property real earScale: root.earSize / 24.0
        transform: Scale { origin.x: 0; origin.y: 0; xScale: rightEarCanvas.earScale; yScale: rightEarCanvas.earScale }

        onPaint: {
            var ctx = getContext("2d");
            var s = 24;
            ctx.clearRect(0, 0, s, s);
            ctx.fillStyle = "#000000";
            ctx.beginPath();
            ctx.moveTo(s, 0);
            ctx.lineTo(0, 0);
            ctx.lineTo(0, s);
            ctx.arcTo(0, 0, s, 0, s);
            ctx.closePath();
            ctx.fill();
        }

        onVisibleChanged: if (visible) requestPaint()
        Component.onCompleted: requestPaint()
    }

    // --- INNER NOTCH RECTANGLE (Pure Solid Black Morphing Pill, Dynamic Width according to Song Name) ---
    Rectangle {
        id: notchBox

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: root.isOsdActive ? 280 : ((root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isNotifMenuOpen) ? 320 : (root.isExpanded ? Style.notchWidthExpanded : (root.isWorkspaceActive ? 240 : (root.showVisualizer ? root.dynamicVisNotchWidth : root.compactWidthVal))))
        height: root.isOsdActive ? Style.notchHeightCompact : (root.isPowerMenuOpen ? 260 : ((root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isNotifMenuOpen) ? 320 : (root.isExpanded ? root.pageNotchHeight : Style.notchHeightCompact)))

        color: "#000000"
        border.width: 0

        bottomLeftRadius: (root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isNotifMenuOpen) ? Style.radiusLarge : root.notchRadiusVal
        bottomRightRadius: (root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isNotifMenuOpen) ? Style.radiusLarge : root.notchRadiusVal
        topLeftRadius: 0
        topRightRadius: 0

        clip: true

        // Expansion Morphing Animation: Spring Physics
        Behavior on width {
            SpringAnimation {
                spring: root.expandSpringTension
                damping: root.expandSpringDamping
                epsilon: 0.25
            }
        }

        Behavior on height {
            SpringAnimation {
                spring: root.expandSpringTension
                damping: root.expandSpringDamping
                epsilon: 0.25
            }
        }

        // HoverHandler tracks cursor over notchBox
        HoverHandler {
            id: notchHover
            onHoveredChanged: {
                if (hovered) {
                    autoCloseTimer.stop();
                } else if (root.isExpanded && root.autoCloseDelay > 0) {
                    autoCloseTimer.restart();
                }
            }
        }

        // Compact Notch Click Area (Clicking opens expanded notch at any time)
        MouseArea {
            anchors.fill: parent
            enabled: !root.isExpanded
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.showVisualizer) {
                    root.currentPage = 0; // Directly open Media Tab
                }
                root.isExpanded = true;
                root.isWorkspaceActive = false;
                autoCloseTimer.stop();
            }
        }

        // --- COMPACT CONTENT VIEWPORT (Clock vs Workspaces Overlay vs Music Visualizer) ---
        Item {
            anchors.fill: parent
            opacity: !root.isExpanded ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 160 }
            }

            // 1. COMPACT CLOCK DISPLAY
            Item {
                anchors.fill: parent
                opacity: (!root.isWorkspaceActive && !root.showVisualizer && !root.isOsdActive) ? 1.0 : 0.0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation { duration: 180 }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: root.timeStr
                        font.family: Style.fontFamily
                        font.pixelSize: root.clockFontSizeVal
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        style: Text.Raised
                        styleColor: "#000000"
                        color: Style.textPrimary
                    }

                    Rectangle {
                        width: 14; height: 14; radius: 7
                        color: Style.accent
                        visible: root.notifCount > 0

                        Text {
                            anchors.centerIn: parent
                            text: root.notifCount > 9 ? "9+" : root.notifCount.toString()
                            font.family: Style.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: "#000000"
                        }
                    }
                }
            }

            // 2. REALTIME WORKSPACE OVERLAY (Clicking anywhere on workspace notch opens expanded view!)
            Item {
                anchors.fill: parent
                opacity: root.isWorkspaceActive ? 1.0 : 0.0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation { duration: 180 }
                }

                // Background click area for Workspace Overlay to expand notch
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isExpanded = true;
                        root.isWorkspaceActive = false;
                        autoCloseTimer.stop();
                    }
                }

                Item {
                    anchors.centerIn: parent
                    width: 218
                    height: 14

                    Row {
                        anchors.centerIn: parent
                        spacing: 16

                        Repeater {
                            model: 10

                            Item {
                                width: 6; height: 6

                                property int wsNum: index + 1
                                property bool isOccupied: root.occupiedWorkspaces.indexOf(wsNum) !== -1

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width; height: parent.height; radius: 3
                                    color: isOccupied ? '#00ffd5' : "#3A3A3C"

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: 0
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (wsNum === root.activeWorkspace) {
                                            root.isExpanded = true;
                                            root.isWorkspaceActive = false;
                                            autoCloseTimer.stop();
                                        } else {
                                            Hyprland.dispatch("workspace " + wsNum.toString());
                                            workspaceDismissTimer.restart();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        x: root.wsAnimType === "stretch" ? Math.min(root.handleLeft, root.handleRight) : root.singleHandleX
                        width: root.wsAnimType === "stretch" ? Math.max(16, Math.abs(root.handleRight - root.handleLeft)) : 16
                        height: 7
                        radius: 4
                        color: Style.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // 3. REALTIME CAVA MUSIC VISUALIZER OVERLAY (Dynamic Horizontal Spacing across Notch Width)
            Item {
                anchors.fill: parent
                opacity: root.showVisualizer ? 1.0 : 0.0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation { duration: 180 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    height: Style.notchHeightCompact
                    spacing: 12

                    M3Icon {
                        name: "music_note"
                        size: 16
                        color: Style.accent
                        Layout.alignment: Qt.AlignVCenter

                        SequentialAnimation on opacity {
                            running: root.showVisualizer
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 600 }
                            NumberAnimation { to: 1.0; duration: 600 }
                        }
                    }

                    Item { Layout.fillWidth: true } // Dynamic Left Spacer

                    // Style 1: BARS (100% Centerline Vertical Alignment!)
                    Item {
                        id: barContainer
                        implicitWidth: 64
                        implicitHeight: Style.notchHeightCompact
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.visualizerStyleVal === "bars"

                        property int barCount: Math.max(8, root.visualizerBarCountVal)
                        property real barSpacing: Math.max(1, 4 - Math.floor((barCount - 8) / 4))
                        property real barW: Math.max(2, Math.floor((64 - (barCount - 1) * barSpacing) / barCount))

                        Repeater {
                            model: barContainer.barCount

                            Rectangle {
                                width: barContainer.barW
                                x: index * (barContainer.barW + barContainer.barSpacing)
                                anchors.verticalCenter: parent.verticalCenter

                                property real val: (root.visualizerFrame && index < root.visualizerFrame.length) ? root.visualizerFrame[index] : 0
                                height: Math.max(2, Math.min(root.visualizerHeightVal, (val / 100.0) * root.visualizerHeightVal))
                                radius: 1
                                color: Style.accent
                            }
                        }
                    }

                    // Style 2: WAVE (2D Canvas Frequency Sine Soundwave with Configurable Thickness)
                    Canvas {
                        id: waveCanvas
                        implicitWidth: 100
                        implicitHeight: Style.notchHeightCompact
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.visualizerStyleVal === "wave"

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = Style.accent;
                            ctx.lineWidth = root.visualizerWaveWidthVal;
                            ctx.beginPath();

                            var count = root.visualizerFrame ? root.visualizerFrame.length : 10;
                            var step = width / Math.max(1, count - 1);
                            for (var i = 0; i < count; i++) {
                                var x = i * step;
                                var val = root.visualizerFrame[i] || 0;
                                var amp = (val / 100.0) * (root.visualizerHeightVal / 2);
                                var y = (height / 2) + (i % 2 === 0 ? -amp : amp);
                                if (i === 0) ctx.moveTo(x, y);
                                else ctx.lineTo(x, y);
                            }
                            ctx.stroke();
                        }

                        Connections {
                            target: root
                            function onVisualizerFrameChanged() {
                                if (root.showVisualizer && root.visualizerStyleVal === "wave") {
                                    waveCanvas.requestPaint();
                                }
                            }
                        }
                    }

                    // Style 3: HIGH-END PULSAR (Dynamic Core Pill + Concentric Aura Rings)
                    Item {
                        implicitWidth: 90
                        implicitHeight: Style.notchHeightCompact
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.visualizerStyleVal === "pulsar"

                        function calcAvgAmp() {
                            if (!root.visualizerFrame || root.visualizerFrame.length === 0) return 0;
                            var sum = 0;
                            for (var i = 0; i < root.visualizerFrame.length; i++) sum += root.visualizerFrame[i];
                            return Math.min(1.0, ((sum / root.visualizerFrame.length) / 100.0) * root.visualizerPulsarScaleVal);
                        }

                        // Outer Concentric Glow Ring 2
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(20, 78 * parent.calcAvgAmp())
                            height: Math.max(6, (root.visualizerHeightVal + 4) * parent.calcAvgAmp())
                            radius: height / 2
                            color: "transparent"
                            border.color: Style.accent
                            border.width: 1
                            opacity: 0.35 * parent.calcAvgAmp()
                        }

                        // Outer Concentric Glow Ring 1
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(16, 60 * parent.calcAvgAmp())
                            height: Math.max(5, (root.visualizerHeightVal + 2) * parent.calcAvgAmp())
                            radius: height / 2
                            color: "transparent"
                            border.color: Style.accent
                            border.width: 1.5
                            opacity: 0.6 * parent.calcAvgAmp()
                        }

                        // Inner Solid Glowing Core Pill
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(14, 46 * parent.calcAvgAmp())
                            height: Math.max(4, root.visualizerHeightVal * parent.calcAvgAmp())
                            radius: height / 2
                            color: Style.accent
                        }
                    }

                    Item { Layout.fillWidth: true } // Dynamic Right Spacer

                    Text {
                        id: trackTitleText
                        text: root.trackTitle
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        font.weight: Font.Bold
                        color: Style.textPrimary
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        Layout.maximumWidth: 160
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
            // 4. OSD OVERLAY (Volume & Brightness)
            Item {
                anchors.fill: parent
                opacity: root.isOsdActive ? 1.0 : 0.0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation { duration: 180 }
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    M3Icon {
                        name: root.osdIcon
                        size: 24
                        color: root.osdColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Style.cardBgHover
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            height: parent.height
                            width: parent.width * (root.animatedOsdValue / 100.0)
                            radius: 3
                            color: root.osdColor
                        }
                    }

                    Text {
                        text: Math.round(root.animatedOsdValue) + "%"
                        font.family: Style.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Style.textPrimary
                        Layout.alignment: Qt.AlignVCenter
                        Layout.minimumWidth: 32
                    }
                }
            }
        }

        // --- EXPANDED CONTENT ---
        Item {
            id: expandedContainer
            width: Style.notchWidthExpanded
            height: root.pageNotchHeight
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on height {
                SpringAnimation {
                    spring: root.expandSpringTension
                    damping: root.expandSpringDamping
                    epsilon: 0.25
                }
            }

            opacity: (root.isExpanded && !root.isPowerMenuOpen && !root.isWifiMenuOpen && !root.isBluetoothMenuOpen && !root.isNotifMenuOpen) ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Expanded Header: Text Tabs ("Media", "Walls", "Apps", "Stats") + Gear Icon + Close
                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    spacing: 8

                    // Material 3 Expressive Segmented Button Container
                    Rectangle {
                        implicitHeight: 32
                        implicitWidth: segRow.implicitWidth
                        radius: 16
                        color: Style.cardBg
                        border.color: Style.cardBorder
                        border.width: 1

                        // Sliding Hover Pill
                        Rectangle {
                            id: hoverPill
                            height: 32
                            radius: 16
                            color: Style.cardBgHover
                            z: 0

                            property var hoveredItem: segRow.hoveredIndex >= 0 ? segRepeater.itemAt(segRow.hoveredIndex) : null
                            x: hoveredItem ? hoveredItem.x : slidingPill.x
                            width: hoveredItem ? hoveredItem.width : slidingPill.width
                            opacity: segRow.hoveredIndex >= 0 && segRow.hoveredIndex !== root.currentPage ? 1 : 0

                            Behavior on x { enabled: hoverPill.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                            Behavior on width { enabled: hoverPill.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                            Behavior on opacity { NumberAnimation { duration: root.buttonSpeedVal } }
                        }

                        // Sliding Highlight Pill
                        Rectangle {
                            id: slidingPill
                            height: 32
                            radius: 16
                            color: Style.accent
                            z: 0

                            property var currentItem: (segRepeater.count > 0) ? segRepeater.itemAt(root.currentPage) : null
                            x: currentItem ? currentItem.x : 0
                            width: currentItem ? currentItem.width : 0

                            Behavior on x { enabled: slidingPill.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                            Behavior on width { enabled: slidingPill.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                        }

                        RowLayout {
                            id: segRow
                            anchors.fill: parent
                            spacing: 0
                            z: 1 // Keep tabs above the sliding pill

                            property int hoveredIndex: {
                                for (var i = 0; i < segRepeater.count; i++) {
                                    var item = segRepeater.itemAt(i);
                                    if (item && item.isHovered) return i;
                                }
                                return -1;
                            }

                            Repeater {
                                id: segRepeater
                                model: ["Media", "Walls", "Apps", "Stats"]
                                
                                Rectangle {
                                    property bool isHovered: segMouse.containsMouse
                                    Layout.preferredWidth: segInner.width + 24
                                    Layout.fillHeight: true
                                    radius: 16
                                    color: "transparent"

                                    Row {
                                        id: segInner
                                        anchors.centerIn: parent
                                        spacing: 0

                                        Text {
                                            text: modelData
                                            font.family: Style.fontFamily
                                            font.pixelSize: Style.fontSizeSmall
                                            font.weight: Font.Bold
                                            color: root.currentPage === index ? "#000" : Style.textPrimary
                                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                        }
                                    }

                                    MouseArea {
                                        id: segMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.currentPage = index
                                    }

                                    // Dynamic M3 Divider
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 1
                                        height: 16
                                        color: Style.cardBorder
                                        visible: index < 3 && root.currentPage !== index && root.currentPage !== index + 1
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Compact Battery Status
                    RowLayout {
                        spacing: 6
                        Layout.rightMargin: 4
                        M3Icon {
                            name: root.batteryStatus === "Charging" ? "󰂄" : (root.batteryLevel > 90 ? "󰁹" : (root.batteryLevel > 50 ? "󰁾" : (root.batteryLevel > root.batteryWarningThresholdVal ? "󰁻" : "󰂎")))
                            size: 18
                            color: root.batteryStatus === "Charging" ? "#A3BE8C" : (root.batteryLevel <= root.batteryWarningThresholdVal ? "#BF616A" : Style.textPrimary)
                        }
                        Text {
                            text: root.batteryLevel + "%"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            font.weight: Font.Bold
                            color: Style.textPrimary
                        }
                    }

                    // WiFi Status Button with Micro-Animations
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: root.isWifiMenuOpen ? Style.accent : (wifiM.containsMouse ? Style.cardBgHover : Style.cardBg)
                        border.color: Style.cardBorder

                        scale: (root.buttonAnimsVal && wifiM.pressed) ? 0.95 : ((root.buttonAnimsVal && wifiM.containsMouse) ? 1.08 : 1.0)
                        Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: root.wifiPower ? "󰖩" : "󰖪"
                            size: 16
                            color: root.isWifiMenuOpen ? "#000" : (root.wifiPower ? Style.accent : Style.textSecondary)
                        }

                        MouseArea {
                            id: wifiM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isWifiMenuOpen = !root.isWifiMenuOpen;
                                root.isBluetoothMenuOpen = false;
                                root.isPowerMenuOpen = false;
                            }
                        }
                    }

                    // Bluetooth Status Button with Micro-Animations
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: root.isBluetoothMenuOpen ? Style.accent : (btM.containsMouse ? Style.cardBgHover : Style.cardBg)
                        border.color: Style.cardBorder

                        scale: (root.buttonAnimsVal && btM.pressed) ? 0.95 : ((root.buttonAnimsVal && btM.containsMouse) ? 1.08 : 1.0)
                        Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: root.btPower ? "󰂯" : "󰂲"
                            size: 16
                            color: root.isBluetoothMenuOpen ? "#000" : (root.btPower ? Style.accent : Style.textSecondary)
                        }

                        MouseArea {
                            id: btM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isBluetoothMenuOpen = !root.isBluetoothMenuOpen;
                                root.isWifiMenuOpen = false;
                                root.isPowerMenuOpen = false;
                            }
                        }
                    }

                    // Notification Bell Icon button with Micro-Animations
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: notifM.containsMouse ? Style.cardBgHover : Style.cardBg
                        border.color: Style.cardBorder

                        scale: (root.buttonAnimsVal && notifM.pressed) ? 0.95 : ((root.buttonAnimsVal && notifM.containsMouse) ? 1.08 : 1.0)
                        Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "󰂜"
                            size: 16
                            color: root.isNotifMenuOpen ? "#000" : (root.notifCount > 0 ? Style.accent : Style.textSecondary)
                        }

                        // Notification count badge
                        Rectangle {
                            visible: root.notifCount > 0
                            width: 14; height: 14; radius: 7
                            color: Style.accent
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -2
                            anchors.rightMargin: -2

                            Text {
                                anchors.centerIn: parent
                                text: root.notifCount > 9 ? "9+" : root.notifCount.toString()
                                font.family: Style.fontFamily
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                color: "#000"
                            }
                        }

                        MouseArea {
                            id: notifM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isNotifMenuOpen = !root.isNotifMenuOpen;
                                root.isWifiMenuOpen = false;
                                root.isBluetoothMenuOpen = false;
                                root.isPowerMenuOpen = false;
                            }
                        }
                    }

                    // Power Button with Micro-Animations
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: root.isPowerMenuOpen ? Style.danger : (powerM.containsMouse ? Style.cardBgHover : Style.cardBg)
                        border.color: Style.cardBorder

                        scale: (root.buttonAnimsVal && powerM.pressed) ? 0.95 : ((root.buttonAnimsVal && powerM.containsMouse) ? 1.08 : 1.0)
                        Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "󰐥"
                            size: 16
                            color: root.isPowerMenuOpen ? "#FFF" : (powerM.containsMouse ? Style.danger : Style.textSecondary)
                        }

                        MouseArea {
                            id: powerM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isPowerMenuOpen = !root.isPowerMenuOpen;
                                root.isPowerConfirming = false;
                                root.powerSelectedIndex = 0;
                            }
                        }
                    }

                    // Gear Icon button with Micro-Animations
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: gearM.containsMouse ? Style.cardBgHover : Style.cardBg
                        border.color: Style.cardBorder

                        scale: (root.buttonAnimsVal && gearM.pressed) ? 0.95 : ((root.buttonAnimsVal && gearM.containsMouse) ? 1.08 : 1.0)
                        Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "󰒓"
                            size: 16
                            color: gearM.containsMouse ? Style.accent : Style.textSecondary
                        }

                        MouseArea {
                            id: gearM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isExpanded = false;
                                root.openFullSettings();
                            }
                        }
                    }

                }

                // Tab Switch Viewport with SpringAnimation Profile
                Item {
                    id: pageViewport
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    focus: true

                    property real targetX: -root.currentPage * pageViewport.width
                    property real currentX: targetX

                    Behavior on currentX {
                        SpringAnimation {
                            spring: root.tabSpringTension
                            damping: root.tabSpringDamping
                            epsilon: 0.25
                        }
                    }

                    Row {
                        focus: true
                        x: pageViewport.currentX
                        width: pageViewport.width * root.totalPages
                        height: pageViewport.height

                        // PAGE 0: Media + Quick Controls Combined
                        ScrollView {
                            width: pageViewport.width
                            height: pageViewport.height
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                id: mediaColumn
                                width: pageViewport.width
                                spacing: 14

                                // MPRIS Track Card (Dynamic Island Card Style)
                                Rectangle {
                                    id: mprisCard
                                    Layout.fillWidth: true
                                    implicitHeight: mprisContent.implicitHeight + 28
                                    radius: Style.radiusMedium // Matches the volume and mic cards

                                    color: Style.cardBg
                                    border.color: Style.cardBorder

                                    MouseArea {
                                        id: mediaHoverArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }

                                    ColumnLayout {
                                        id: mprisContent
                                        anchors.fill: parent
                                        anchors.margins: 14

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 16

                                        // Left: Circular Album Art (Spinning Vinyl) + Visualizer (lazy-loaded when media tab active)
                                        Loader {
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredWidth: 80
                                            Layout.preferredHeight: 80
                                            Layout.minimumHeight: 80
                                            active: root.currentPage === 0
                                            sourceComponent: Item {
                                                width: 80; height: 80

                                                property real avgAmp: (root.visualizerFrame && root.visualizerFrame.length > 0)
                                                    ? root.visualizerFrame.reduce(function(sum, v) { return sum + v; }, 0) / root.visualizerFrame.length / 100.0
                                                    : 0
                                                
                                                // Circular Visualizer
                                                Repeater {
                                                    model: 24
                                                    Item {
                                                        width: 4
                                                        height: 40
                                                        x: 38
                                                        y: 0
                                                        
                                                        transformOrigin: Item.Bottom
                                                        rotation: (360 / 24) * index
                                                        
                                                        Rectangle {
                                                            property real val: (root.visualizerFrame && root.visualizerFrame.length > 0) ? root.visualizerFrame[index % root.visualizerFrame.length] : 0
                                                            width: 4
                                                            height: Math.max(4, (val / 100.0) * root.visualizerHeightVal)
                                                            radius: 2
                                                            color: Style.accent
                                                            anchors.bottom: parent.bottom
                                                            anchors.bottomMargin: 36
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    width: 62; height: 62; radius: 31
                                                    anchors.centerIn: parent
                                                    color: Style.cardBgHover
                                                    border.color: Style.cardBorder
                                                    clip: true
                                                    scale: 1.0 + (avgAmp * 0.06)
                                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                                                    
                                                    Item {
                                                        anchors.fill: parent
                                                        visible: dynamicAlbumArt.source.toString() !== ""

                                                        RotationAnimation on rotation {
                                                            from: 0
                                                            to: 360
                                                            duration: 10000
                                                            loops: Animation.Infinite
                                                            running: true
                                                            paused: !root.isPlaying
                                                        }

                                                        Image {
                                                            id: dynamicAlbumArt
                                                            anchors.fill: parent
                                                            source: (root.activePlayer && root.activePlayer.trackArtUrl) ? root.activePlayer.trackArtUrl : ""
                                                            fillMode: Image.PreserveAspectCrop
                                                            visible: false
                                                        }

                                                        OpacityMask {
                                                            anchors.fill: parent
                                                            source: dynamicAlbumArt
                                                            maskSource: Rectangle {
                                                                width: 62; height: 62; radius: 31
                                                            }
                                                        }
                                                    }

                                                    Rectangle {
                                                        width: 14; height: 14; radius: 7
                                                        anchors.centerIn: parent
                                                        color: Style.background
                                                        visible: dynamicAlbumArt.source.toString() !== ""
                                                    }

                                                    M3Icon {
                                                        anchors.centerIn: parent
                                                        name: "music_note"
                                                        size: 24
                                                        color: Style.accent
                                                        visible: !(root.activePlayer && root.activePlayer.trackArtUrl && root.activePlayer.trackArtUrl !== "")
                                                    }
                                                }
                                            }
                                        }

                                        // Center: Track Info
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: root.trackTitle
                                                font.family: Style.fontFamily
                                                font.pixelSize: Style.fontSizeLarge
                                                font.weight: Font.Bold
                                                font.letterSpacing: 0.5
                                                color: Style.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: root.trackArtist
                                                font.family: Style.fontFamily
                                                font.pixelSize: Style.fontSizeNormal
                                                color: Style.textSecondary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        // Right: Playback Controls (Always Visible)
                                        Item {
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredWidth: 140
                                            Layout.preferredHeight: 60
                                            Layout.minimumHeight: 60

                                            RowLayout {
                                                anchors.fill: parent
                                                spacing: 12

                                                Item { Layout.fillWidth: true } // Push controls to right
                                                
                                                // Media Prev Button
                                                Rectangle {
                                                    Layout.alignment: Qt.AlignVCenter
                                                    width: 32; height: 32; radius: 16; color: Style.cardBgHover
                                                    scale: (root.buttonAnimsVal && prevM.pressed) ? 0.90 : ((root.buttonAnimsVal && prevM.containsMouse) ? 1.15 : 1.0)
                                                    Behavior on scale { enabled: root.buttonAnimsVal; SpringAnimation { spring: 3.5; damping: 0.6; mass: 1.0 } }
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                                    M3Icon { anchors.centerIn: parent; name: "skip_previous"; color: Style.textPrimary; size: 24 }
                                                    MouseArea { id: prevM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.previous() }
                                                }

                                                // Media Play/Pause Button
                                                Rectangle {
                                                    Layout.alignment: Qt.AlignVCenter
                                                    width: 40; height: 40; radius: 20; color: Style.accent
                                                    scale: (root.buttonAnimsVal && playM.pressed) ? 0.90 : ((root.buttonAnimsVal && playM.containsMouse) ? 1.15 : 1.0)
                                                    Behavior on scale { enabled: root.buttonAnimsVal; SpringAnimation { spring: 3.5; damping: 0.6; mass: 1.0 } }
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                                    M3Icon { anchors.centerIn: parent; name: root.isPlaying ? "pause" : "play_arrow"; color: "#000000"; size: 28 }
                                                    MouseArea { id: playM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.togglePlaying() }
                                                }

                                                // Media Next Button
                                                Rectangle {
                                                    Layout.alignment: Qt.AlignVCenter
                                                    width: 32; height: 32; radius: 16; color: Style.cardBgHover
                                                    scale: (root.buttonAnimsVal && nextM.pressed) ? 0.90 : ((root.buttonAnimsVal && nextM.containsMouse) ? 1.15 : 1.0)
                                                    Behavior on scale { enabled: root.buttonAnimsVal; SpringAnimation { spring: 3.5; damping: 0.6; mass: 1.0 } }
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                                    M3Icon { anchors.centerIn: parent; name: "skip_next"; color: Style.textPrimary; size: 24 }
                                                    MouseArea { id: nextM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.next() }
                                                }
                                            }
                                        }
                                    }
                                }
                                }

                                // Master Volume Card with CustomSlider
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 76
                                    radius: Style.radiusMedium
                                    color: Style.cardBg
                                    border.color: Style.cardBorder

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            M3Icon { name: "volume_up"; color: Style.textPrimary; size: 18 }
                                            Text { text: "Master Volume"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                            Item { Layout.fillWidth: true }
                                            Text { text: root.volumeLevel + "%"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.accent }
                                        }

                                        CustomSlider {
                                            Layout.fillWidth: true
                                            from: 0; to: 100
                                            value: root.volumeLevel
                                            onMoved: function(val) {
                                                root.volumeLevel = Math.round(val);
                                                if (!volumeThrottleTimer.running) {
                                                    volumeThrottleTimer.start();
                                                }
                                            }
                                            Timer {
                                                id: volumeThrottleTimer
                                                interval: 50
                                                onTriggered: {
                                                    setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", root.volumeLevel + "%"];
                                                    setVolProc.running = true;
                                                }
                                            }
                                        }
                                    }
                                }


                                // Microphone Card with CustomSlider
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 76
                                    radius: Style.radiusMedium
                                    color: Style.cardBg
                                    border.color: Style.cardBorder

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            M3Icon { name: "mic"; color: Style.textPrimary; size: 18 }
                                            Text { text: "Microphone Input"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                            Item { Layout.fillWidth: true }
                                            Text { text: root.micLevel + "%"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.accent }
                                        }

                                        CustomSlider {
                                            Layout.fillWidth: true
                                            from: 0; to: 100
                                            value: root.micLevel
                                            onMoved: function(val) {
                                                root.micLevel = Math.round(val);
                                                if (!micThrottleTimer.running) {
                                                    micThrottleTimer.start();
                                                }
                                            }
                                            Timer {
                                                id: micThrottleTimer
                                                interval: 50
                                                onTriggered: {
                                                    setMicProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", root.micLevel + "%"];
                                                    setMicProc.running = true;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // PAGE 1: Wallpaper Selector (Loader: 30s delayed unload)
                        Item {
                            width: pageViewport.width
                            height: pageViewport.height
                            clip: true
                            focus: true
                            Loader {
                                id: wallsLoader
                                anchors.fill: parent
                                active: root.wallsTabAlive
                                focus: true
                                sourceComponent: WallpaperSelector {
                                    isOpen: true
                                    wallpaperDir: root.wallpaperDirVal
                                    onWallpaperSelected: function(path) {
                                        root.handleWallpaperSelected(path);
                                    }
                                }
                            }
                        }

                        // PAGE 2: App Launcher (Loader: 30s delayed unload)
                        Item {
                            width: pageViewport.width
                            height: pageViewport.height
                            clip: true
                            focus: true
                            Loader {
                                id: appsLoader
                                anchors.fill: parent
                                active: root.appsTabAlive
                                focus: true
                                sourceComponent: AppLauncher {
                                    appColumns: root.appColumnsVal
                                    onAppLaunched: {
                                        root.isExpanded = false;
                                    }
                                }
                            }
                        }

                        // PAGE 3: Hardware Stats Dashboard
                        Item {
                            width: pageViewport.width
                            height: pageViewport.height
                            clip: true

                            ColumnLayout {
                                id: statsColumn
                                anchors.fill: parent
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    // CPU Usage Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 134
                                        radius: Style.radiusMedium
                                        color: Style.cardBg
                                        border.color: Style.cardBorder

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 4

                                            RowLayout {
                                                spacing: 6
                                                M3Icon { name: "memory"; color: Style.textPrimary; size: 16 }
                                                Text { text: "CPU Usage"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.textPrimary }
                                                Item { Layout.fillWidth: true }
                                                Text { text: root.cpuUsage + "%"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.accent }
                                            }

                                            SparklineCanvas {
                                                Layout.fillWidth: true
                                                hist: root.cpuHistory
                                                currentVal: root.cpuUsage
                                                thresholdColors: true
                                            }
                                        }
                                    }

                                    // RAM Usage Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 134
                                        radius: Style.radiusMedium
                                        color: Style.cardBg
                                        border.color: Style.cardBorder

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 4

                                            RowLayout {
                                                spacing: 6
                                                M3Icon { name: "memory"; color: Style.textPrimary; size: 16 }
                                                Text { text: "RAM Memory"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.textPrimary }
                                                Item { Layout.fillWidth: true }
                                                Text { text: root.ramUsage + "%"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.accent }
                                            }

                                            SparklineCanvas {
                                                Layout.fillWidth: true
                                                hist: root.ramHistory
                                                currentVal: root.ramUsage
                                                thresholdColors: true
                                            }
                                        }
                                    }
                                } // End Row 1

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    // Network Usage Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 134
                                        radius: Style.radiusMedium
                                        color: Style.cardBg
                                        border.color: Style.cardBorder

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 4

                                            RowLayout {
                                                spacing: 6
                                                M3Icon { name: "wifi"; color: Style.textPrimary; size: 16 }
                                                Text { text: "Network"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.textPrimary }
                                                Item { Layout.fillWidth: true }
                                                Text { 
                                                    function formatBytes(bytes) {
                                                        if (bytes < 1024) return bytes + "B/s";
                                                        if (bytes < 1024*1024) return (bytes/1024).toFixed(0) + "K/s";
                                                        return (bytes/(1024*1024)).toFixed(1) + "M/s";
                                                    }
                                                    text: "⇣" + formatBytes(root.netRxSpeed) + " ⇡" + formatBytes(root.netTxSpeed)
                                                    font.family: Style.fontFamily
                                                    font.pixelSize: 10
                                                    font.weight: Font.Bold
                                                    color: Style.accent
                                                }
                                            }

                                            SparklineCanvas {
                                                Layout.fillWidth: true
                                                hist: root.netHistory
                                            }
                                        }
                                    }

                                    // Disk Storage Radial Gauge
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 134
                                        radius: Style.radiusMedium
                                        color: Style.cardBg
                                        border.color: Style.cardBorder

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 4

                                            RowLayout {
                                                spacing: 6
                                                M3Icon { name: "hard_drive"; color: Style.textPrimary; size: 16 }
                                                Text { text: "Disk (Root)"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.textPrimary }
                                                Item { Layout.fillWidth: true }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                implicitHeight: 64

                                                Canvas {
                                                    id: diskRadial
                                                    anchors.fill: parent
                                                    property real val: root.diskUsage
                                                    onValChanged: requestPaint()

                                                    onPaint: {
                                                        var ctx = getContext("2d");
                                                        ctx.clearRect(0, 0, width, height);
                                                        var cx = width / 2;
                                                        var cy = height / 2;
                                                        var r = Math.min(width, height) / 2 - 6;

                                                        // Background track
                                                        ctx.beginPath();
                                                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                                        ctx.lineWidth = 10;
                                                        ctx.strokeStyle = Style.cardBgHover;
                                                        ctx.stroke();

                                                        // Accent progress
                                                        ctx.beginPath();
                                                        var endAngle = (root.diskUsage / 100.0) * 2 * Math.PI;
                                                        ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + endAngle);
                                                        ctx.strokeStyle = Style.accent;
                                                        ctx.lineCap = "round";
                                                        ctx.stroke();
                                                    }
                                                }

                                                Text {
                                                    text: root.diskUsage + "%"
                                                    anchors.centerIn: parent
                                                    font.family: Style.fontFamily
                                                    font.pixelSize: 14
                                                    font.weight: Font.Bold
                                                    color: Style.textPrimary
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // iOS-STYLE SLIDING PILL TAB INDICATOR
                Item {
                    id: tabDots
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 104
                    implicitHeight: 14

                    // Fixed Grey Background Dots
                    Row {
                        id: tabDotRow
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: root.totalPages
                            Rectangle {
                                width: 7; height: 7; radius: 4
                                color: "#3A3A3C"
                            }
                        }
                    }

                    // Single Active Accent Pill Handle Sliding Smoothly & Centered Over Dots
                    Rectangle {
                        width: 18; height: 7; radius: 4
                        color: Style.accent
                        anchors.verticalCenter: parent.verticalCenter
                        x: 14.5 + (root.currentPage * 19)

                        Behavior on x {
                            SpringAnimation { spring: 5.0; damping: 0.3 }
                        }
                    }
                }
            }
        }

        // Background Click Area inside notchBox: collapses notch when clicking empty space
        MouseArea {
            anchors.fill: parent
            z: -1
            enabled: root.isExpanded || root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen || root.isNotifMenuOpen
            onClicked: {
                if (root.isPowerMenuOpen) root.isPowerMenuOpen = false;
                else if (root.isWifiMenuOpen) root.isWifiMenuOpen = false;
                else if (root.isBluetoothMenuOpen) root.isBluetoothMenuOpen = false;
                else if (root.isNotifMenuOpen) root.isNotifMenuOpen = false;
                else if (root.isExpanded) root.isExpanded = false;
            }
        }

        // Integrated Power Menu View Overlay inside notchBox (Morphed State)
        PowerMenu {
            id: powerMenuOverlay
            isOpen: root.isPowerMenuOpen
            isConfirming: root.isPowerConfirming
            selectedIndex: root.powerSelectedIndex
            pendingTitle: root.pendingPowerTitle
            countdown: root.powerCountdown
            pendingCmd: root.pendingPowerCmd
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
        }

        function cancelPowerAction() { powerMenuOverlay.cancel(); }
        function executePendingPower() { powerMenuOverlay.execute(); }
        function triggerPowerAction(title, cmd) { powerMenuOverlay.trigger(title, cmd); }

        // Integrated WiFi Menu View Overlay inside notchBox (Morphed State)
        WifiMenu {
            id: wifiMenuOverlay
            isOpen: root.isWifiMenuOpen
            wifiPower: root.wifiPower
            wifiActiveSsid: root.wifiActiveSsid
            wifiNetworks: root.wifiNetworks
            isPasswordPromptOpen: root.isWifiPasswordPromptOpen
            promptSsid: root.wifiPromptSsid
            passwordText: root.wifiPasswordText
            showPassword: root.showWifiPassword
            onWifiPowerChanged: root.wifiPower = wifiMenuOverlay.wifiPower
            onWifiActiveSsidChanged: root.wifiActiveSsid = wifiMenuOverlay.wifiActiveSsid
            onWifiNetworksChanged: root.wifiNetworks = wifiMenuOverlay.wifiNetworks
            onIsPasswordPromptOpenChanged: root.isWifiPasswordPromptOpen = wifiMenuOverlay.isPasswordPromptOpen
            onPromptSsidChanged: root.wifiPromptSsid = wifiMenuOverlay.promptSsid
            onPasswordTextChanged: root.wifiPasswordText = wifiMenuOverlay.passwordText
            onShowPasswordChanged: root.showWifiPassword = wifiMenuOverlay.showPassword
        }

        // Integrated Bluetooth Menu View Overlay inside notchBox (Morphed State)
        BluetoothMenu {
            id: bluetoothMenuOverlay
            isOpen: root.isBluetoothMenuOpen
            btPower: root.btPower
            btDevices: root.btDevices
            onBtPowerChanged: root.btPower = bluetoothMenuOverlay.btPower
            onBtDevicesChanged: root.btDevices = bluetoothMenuOverlay.btDevices
        }

        // Integrated Notification History View Overlay inside notchBox (Morphed State)
        NotificationHistory {
            id: notifHistoryOverlay
            isOpen: root.isNotifMenuOpen
            notifModel: root.notifModel
            onNotifCountChanged: root.notifCount = notifHistoryOverlay.notifCount
        }
    }
}
