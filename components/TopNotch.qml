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
    property int totalPages: 5

    // Keyboard selection index for grid tabs (-1 = no selection)
    property int selectedIndex: 0

    // Toggle a specific tab open/closed via IPC keybind
    function toggleTab(page) {
        if (root.isExpanded && root.currentPage === page) {
            root.isExpanded = false;
        } else {
            root.currentPage = page;
            root.isExpanded = true;
            root.selectedIndex = 0;
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

    Process {
        id: powerProc
    }

    Timer {
        id: powerCountdownTimer
        interval: 1000
        repeat: true
        running: root.isPowerConfirming
        onTriggered: {
            if (root.powerCountdown > 1) {
                root.powerCountdown -= 1;
            } else {
                root.powerCountdownTimer.stop();
                root.executePendingPower();
            }
        }
    }

    function triggerPowerAction(title, cmd) {
        root.pendingPowerTitle = title;
        root.pendingPowerCmd = cmd;
        root.powerCountdown = 5;
        root.isPowerConfirming = true;
        powerCountdownTimer.restart();
    }

    function executePendingPower() {
        if (root.pendingPowerCmd !== "") {
            powerProc.command = ["bash", "-c", root.pendingPowerCmd];
            powerProc.running = true;
        }
        root.isPowerConfirming = false;
        root.isPowerMenuOpen = false;
        root.isExpanded = false;
    }

    function cancelPowerAction() {
        powerCountdownTimer.stop();
        root.isPowerConfirming = false;
    }

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
        // Reset keyboard selection
        selectedIndex = 0;

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
        if (currentPage === 4) {
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
    property int notchRadiusVal: 16
    property bool drippingEarsVal: true
    property bool clock12hVal: false
    property string clockFormatVal: "h:mm A"
    property int clockFontSizeVal: 14
    property int batteryWarningThresholdVal: 20
    property int osdTimeoutVal: 2000
    property bool workspaceOverlayVal: true
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
    property bool isAudioActive: false
    property bool isVisualizerActive: false

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
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (parsed.bars !== undefined) root.visualizerBars = parsed.bars;
                    if (parsed.active !== undefined) {
                        var wasActive = root.isAudioActive;
                        root.isAudioActive = parsed.active;

                        // Non-MPRIS system audio stream trigger logic (doesn't interfere with MPRIS playback timers!)
                        if (!root.isPlaying) {
                            if (parsed.active && !wasActive) {
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

    // Workspace native QML state
    property int activeWorkspace: 1
    property var occupiedWorkspaces: [1]
    property bool isWorkspaceActive: false
    onIsWorkspaceActiveChanged: { if (isWorkspaceActive) root.isOsdActive = false; }

    // High-speed direct Hyprland IPC poll for accurate occupied workspace array
    Process {
        id: occupiedProc
        command: ["bash", "-c", "hyprctl workspaces | awk 'BEGIN {printf \"[\"} /^workspace ID/ {id=$3} /windows:/ {if($2>0) {if(c++) printf \",\"; printf id}} END {print \"]\"}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.occupiedWorkspaces = JSON.parse(this.text.trim());
                } catch(e) {}
            }
        }
    }

    Timer {
        id: occupiedPoller
        interval: 500
        repeat: true
        running: true
        onTriggered: {
            if (!occupiedProc.running) {
                occupiedProc.running = true;
            }
        }
    }

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
    property bool isInhibited: false

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

    // Inhibited status poll (not available via subscribe, low-frequency 10s poll)
    Process {
        id: swayncInhibitedProc
        command: ["swaync-client", "-I"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.isInhibited = this.text.trim().toLowerCase() === "true";
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: swayncInhibitedProc.running = true
    }

    Process {
        id: toggleDndProc
        command: ["swaync-client", "-d"]
    }

    Process {
        id: dismissLatestProc
        command: ["swaync-client", "--close-latest"]
    }

    Process {
        id: clearNotifsProc
        command: ["swaync-client", "-C"]
    }

    Process {
        id: openSwayncProc
        command: ["swaync-client", "-t"]
    }

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
    property string expandAnimType: "outback"
    property real expandSpringTension: 4.5
    property real expandSpringDamping: 0.28

    // Tab Switch Animation Profile
    property string tabAnimType: "spring"
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
                    if (data.clock_12h !== undefined) root.clock12hVal = data.clock_12h;
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
                    if (data.expand_anim_type !== undefined) root.expandAnimType = data.expand_anim_type;
                    if (data.expand_tension !== undefined) root.expandSpringTension = data.expand_tension;
                    if (data.expand_damping !== undefined) root.expandSpringDamping = data.expand_damping;
                    if (data.tab_anim_type !== undefined) root.tabAnimType = data.tab_anim_type;
                    if (data.tab_tension !== undefined) root.tabSpringTension = data.tab_tension;
                    if (data.tab_damping !== undefined) root.tabSpringDamping = data.tab_damping;
                    if (data.stats_interval !== undefined) root.sysStatsIntervalVal = data.stats_interval;
                    if (data.network_refresh !== undefined) root.networkRefreshIntervalVal = data.network_refresh;
                    if (data.osd_timeout !== undefined) root.osdTimeoutVal = data.osd_timeout;
                    if (data.clock_format !== undefined) root.clockFormatVal = data.clock_format;
                    if (data.clock_font_size !== undefined) root.clockFontSizeVal = data.clock_font_size;
                    if (data.battery_warning_threshold !== undefined) root.batteryWarningThresholdVal = data.battery_warning_threshold;
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
        wifiScanner.running = true;
        btScanner.running = true;
    }

    // Fixed root dimensions (624px width allows 32px padding for inverted ears)
    implicitWidth: Style.notchWidthExpanded + 64
    implicitHeight: Style.notchHeightExpanded

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

    property real trackLength: activePlayer && activePlayer.length ? activePlayer.length : 0
    property real trackPosition: activePlayer && activePlayer.position ? activePlayer.position : 0

    onActivePlayerChanged: {
        if (activePlayer) {
            root.trackPosition = activePlayer.position;
        } else {
            root.trackPosition = 0;
        }
    }

    function formatTime(microsecs) {
        if (isNaN(microsecs) || microsecs <= 0) return "00:00";
        var totalSecs = Math.floor(microsecs / 1000000);
        var mins = Math.floor(totalSecs / 60);
        var secs = totalSecs % 60;
        return (mins < 10 ? "0" + mins : mins) + ":" + (secs < 10 ? "0" + secs : secs);
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
    property int networkRefreshIntervalVal: 5000

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
        running: root.isExpanded && root.currentPage === 4
        repeat: true
        onTriggered: sysScanner.running = true
    }

    property bool isWifiMenuOpen: false
    property bool isBluetoothMenuOpen: false

    property bool wifiPower: false
    property string wifiActiveSsid: ""
    property var wifiNetworks: []

    property bool btPower: false
    property var btDevices: []

    property bool isWifiPasswordPromptOpen: false
    property string wifiPromptSsid: ""
    property string wifiPasswordText: ""
    property bool showWifiPassword: false

    Process {
        id: wifiScanner
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_wifi.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.wifiPower = data.power;
                    root.wifiActiveSsid = data.active;
                    root.wifiNetworks = data.networks;
                } catch(e) {}
            }
        }
    }

    Process {
        id: btScanner
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_bluetooth.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.btPower = data.power;
                    root.btDevices = data.devices;
                } catch(e) {}
            }
        }
    }

    Process {
        id: wifiToggler
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.wifiPower = data.power;
                    root.wifiActiveSsid = data.active;
                    root.wifiNetworks = data.networks;
                } catch(e) {}
            }
        }
    }

    Process {
        id: btToggler
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.btPower = data.power;
                    root.btDevices = data.devices;
                } catch(e) {}
            }
        }
    }

    Timer {
        id: wifiTimer
        interval: root.networkRefreshIntervalVal
        running: root.isWifiMenuOpen
        repeat: true
        onTriggered: wifiScanner.running = true
    }

    Timer {
        id: btTimer
        interval: root.networkRefreshIntervalVal
        running: root.isBluetoothMenuOpen
        repeat: true
        onTriggered: btScanner.running = true
    }

    Timer {
        id: wifiScanTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: wifiScanner.running = true
    }

    Timer {
        id: btScanTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: btScanner.running = true
    }



    property int volumeLevel: 50
    property int micLevel: 50
    property int brightnessLevel: 50
    property int batteryLevel: 100
    property string batteryStatus: "Unknown"

    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim());
                if (!isNaN(val)) root.volumeLevel = val;
            }
        }
    }

    Process {
        id: setVolProc
    }

    Process {
        id: micProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print int($2 * 100)}'"]
        running: true
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
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim());
                if (!isNaN(val)) root.brightnessLevel = val;
            }
        }
    }

    Process {
        id: setBrightnessProc
        stdout: StdioCollector { onStreamFinished: brightnessProc.running = true }
    }

    Process {
        id: batteryProc
        command: ["bash", "-c", "echo $(cat /sys/class/power_supply/BAT0/capacity); cat /sys/class/power_supply/BAT0/status"]
        running: true
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

    // Low-frequency poll to track external changes (hardware keys, battery drain)
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            volProc.running = true;
            micProc.running = true;
            brightnessProc.running = true;
            batteryProc.running = true;
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

        width: root.isOsdActive ? 280 : ((root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen) ? 320 : (root.isExpanded ? Style.notchWidthExpanded : (root.isWorkspaceActive ? 240 : (root.showVisualizer ? root.dynamicVisNotchWidth : root.compactWidthVal))))
        height: root.isOsdActive ? Style.notchHeightCompact : (root.isPowerMenuOpen ? 260 : ((root.isWifiMenuOpen || root.isBluetoothMenuOpen) ? 320 : (root.isExpanded ? root.expandedHeightVal : Style.notchHeightCompact)))

        color: "#000000"
        border.width: 0

        bottomLeftRadius: (root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen) ? Style.radiusLarge : root.notchRadiusVal
        bottomRightRadius: (root.isPowerMenuOpen || root.isWifiMenuOpen || root.isBluetoothMenuOpen) ? Style.radiusLarge : root.notchRadiusVal
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
                            font.family: Style.fontFamilyMono
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
                                    color: isOccupied ? "#FFFFFF" : "#3A3A3C"

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

                    Text {
                        text: "󰎆"
                        font.family: Style.fontFamilyMono
                        font.pixelSize: 13
                        color: Style.accent
                        verticalAlignment: Text.AlignVCenter
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

                                property real val: (root.visualizerBars && index < root.visualizerBars.length) ? root.visualizerBars[index] : 0
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

                            var count = root.visualizerBars ? root.visualizerBars.length : 10;
                            var step = width / Math.max(1, count - 1);
                            for (var i = 0; i < count; i++) {
                                var x = i * step;
                                var val = root.visualizerBars[i] || 0;
                                var amp = (val / 100.0) * (root.visualizerHeightVal / 2);
                                var y = (height / 2) + (i % 2 === 0 ? -amp : amp);
                                if (i === 0) ctx.moveTo(x, y);
                                else ctx.lineTo(x, y);
                            }
                            ctx.stroke();
                        }

                        Connections {
                            target: root
                            function onVisualizerBarsChanged() {
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

                        property real avgAmp: {
                            if (!root.visualizerBars || root.visualizerBars.length === 0) return 0;
                            var sum = 0;
                            for (var i = 0; i < root.visualizerBars.length; i++) sum += root.visualizerBars[i];
                            return Math.min(1.0, ((sum / root.visualizerBars.length) / 100.0) * root.visualizerPulsarScaleVal);
                        }

                        // Outer Concentric Glow Ring 2
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(20, 78 * parent.avgAmp)
                            height: Math.max(6, (root.visualizerHeightVal + 4) * parent.avgAmp)
                            radius: height / 2
                            color: "transparent"
                            border.color: Style.accent
                            border.width: 1
                            opacity: 0.35 * parent.avgAmp
                        }

                        // Outer Concentric Glow Ring 1
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(16, 60 * parent.avgAmp)
                            height: Math.max(5, (root.visualizerHeightVal + 2) * parent.avgAmp)
                            radius: height / 2
                            color: "transparent"
                            border.color: Style.accent
                            border.width: 1.5
                            opacity: 0.6 * parent.avgAmp
                        }

                        // Inner Solid Glowing Core Pill
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(14, 46 * parent.avgAmp)
                            height: Math.max(4, root.visualizerHeightVal * parent.avgAmp)
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

                    Text {
                        text: root.osdIcon
                        font.family: Style.fontFamilyMono
                        font.pixelSize: 18
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
            height: root.expandedHeightVal
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            opacity: (root.isExpanded && !root.isPowerMenuOpen && !root.isWifiMenuOpen && !root.isBluetoothMenuOpen) ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Expanded Header: Text Tabs ("Media", "Walls", "Apps", "Notifs") + Gear Icon + Close
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: ["Media", "Walls", "Apps", "Notifs", "Stats"]
                            Rectangle {
                                implicitWidth: tabRow.implicitWidth + 16
                                implicitHeight: 28
                                radius: 14
                                color: root.currentPage === index ? Style.accent : Style.cardBg
                                border.color: Style.cardBorder

                                scale: (root.buttonAnimsVal && tabBtnM.pressed) ? 0.95 : ((root.buttonAnimsVal && tabBtnM.containsMouse) ? 1.05 : 1.0)
                                Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                RowLayout {
                                    id: tabRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        id: tabTxt
                                        text: modelData
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontSizeSmall
                                        font.weight: Font.Bold
                                        color: root.currentPage === index ? "#000" : Style.textSecondary

                                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                    }

                                    Rectangle {
                                        width: 12; height: 12; radius: 6
                                        color: root.currentPage === index ? "#000000" : Style.accent
                                        visible: index === 3 && root.notifCount > 0

                                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.notifCount > 9 ? "9+" : root.notifCount.toString()
                                            font.family: Style.fontFamily
                                            font.pixelSize: 7
                                            font.weight: Font.Bold
                                            color: root.currentPage === index ? Style.accent : "#000000"

                                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: tabBtnM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentPage = index
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Compact Battery Status
                    RowLayout {
                        spacing: 6
                        Layout.rightMargin: 4
                        Text {
                            text: root.batteryStatus === "Charging" ? "󰂄" : (root.batteryLevel > 90 ? "󰁹" : (root.batteryLevel > 50 ? "󰁾" : (root.batteryLevel > root.batteryWarningThresholdVal ? "󰁻" : "󰂎")))
                            font.family: Style.fontFamilyMono
                            font.pixelSize: 14
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

                        Text {
                            anchors.centerIn: parent
                            text: root.wifiPower ? "󰖩" : "󰖪"
                            font.family: Style.fontFamilyMono
                            font.pixelSize: 13
                            color: root.isWifiMenuOpen ? "#000" : (root.wifiPower ? Style.accent : Style.textSecondary)
                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
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
                                if (root.isWifiMenuOpen) wifiScanner.running = true;
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

                        Text {
                            anchors.centerIn: parent
                            text: root.btPower ? "󰂯" : "󰂲"
                            font.family: Style.fontFamilyMono
                            font.pixelSize: 13
                            color: root.isBluetoothMenuOpen ? "#000" : (root.btPower ? Style.accent : Style.textSecondary)
                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
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
                                if (root.isBluetoothMenuOpen) btScanner.running = true;
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

                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: Style.fontFamilyMono
                            font.pixelSize: 13
                            color: root.isPowerMenuOpen ? "#FFF" : (powerM.containsMouse ? Style.danger : Style.textSecondary)
                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
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

                        Text {
                            anchors.centerIn: parent
                            text: "󰒓"
                            font.family: Style.fontFamilyMono
                            font.pixelSize: 13
                            color: gearM.containsMouse ? Style.accent : Style.textSecondary
                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
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
                                width: pageViewport.width
                                spacing: 14

                                Text {
                                    text: "Media & Audio Controls"
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeLarge
                                    font.weight: Font.Bold
                                    color: Style.accent
                                }

                                // MPRIS Track Card (Dynamic Island Card Style)
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 90
                                    radius: Style.radiusMedium // Matches the volume and mic cards

                                    color: Style.cardBg
                                    border.color: Style.cardBorder

                                    MouseArea {
                                        id: mediaHoverArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 16

                                        // Left: Circular Album Art (Spinning Vinyl)
                                        Rectangle {
                                            width: 62; height: 62; radius: 31
                                            color: Style.cardBgHover
                                            border.color: Style.cardBorder
                                            clip: true
                                            
                                            // The rotating vinyl container
                                            Item {
                                                anchors.fill: parent
                                                visible: dynamicAlbumArt.source.toString() !== ""

                                                RotationAnimation on rotation {
                                                    from: 0
                                                    to: 360
                                                    duration: 10000 // 10 seconds for a full vinyl rotation
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

                                            // Vinyl Center Hole Cutout (Static over the rotating image)
                                            Rectangle {
                                                width: 14; height: 14; radius: 7
                                                anchors.centerIn: parent
                                                color: Style.background
                                                visible: dynamicAlbumArt.source.toString() !== ""
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰎆"
                                                font.family: Style.fontFamilyMono
                                                font.pixelSize: 24
                                                color: Style.accent
                                                visible: !(root.activePlayer && root.activePlayer.trackArtUrl && root.activePlayer.trackArtUrl !== "")
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

                                        // Right: Dynamic Swap (Visualizer <-> Controls)
                                        Item {
                                            width: 140
                                            height: 60

                                            property bool isHovered: mediaHoverArea.containsMouse || 
                                                (typeof prevM !== "undefined" && prevM.containsMouse) || 
                                                (typeof playM !== "undefined" && playM.containsMouse) || 
                                                (typeof nextM !== "undefined" && nextM.containsMouse)

                                            // Live Visualizer (Visible when NOT hovered)
                                            RowLayout {
                                                anchors.fill: parent
                                                spacing: 4
                                                opacity: parent.isHovered ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                                                visible: opacity > 0.01

                                                Item { Layout.fillWidth: true } // Push visualizer to right

                                                Repeater {
                                                    model: 10
                                                    Rectangle {
                                                        width: 4
                                                        property real val: (root.visualizerBars && index < root.visualizerBars.length) ? root.visualizerBars[index] : 0
                                                        height: Math.max(4, Math.min(30, (val / 100.0) * 30))
                                                        radius: 2
                                                        color: Style.accent
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }

                                            // Playback Controls (Visible WHEN hovered)
                                            RowLayout {
                                                anchors.fill: parent
                                                spacing: 12
                                                opacity: parent.isHovered ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                                                visible: opacity > 0.01

                                                Item { Layout.fillWidth: true } // Push controls to right
                                                
                                                // Media Prev Button
                                                Rectangle {
                                                    width: 32; height: 32; radius: 16; color: Style.cardBgHover
                                                    scale: (root.buttonAnimsVal && prevM.pressed) ? 0.92 : ((root.buttonAnimsVal && prevM.containsMouse) ? 1.08 : 1.0)
                                                    Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                                    Text { anchors.centerIn: parent; text: "󰒮"; font.family: Style.fontFamilyMono; color: Style.textPrimary; font.pixelSize: 14 }
                                                    MouseArea { id: prevM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.previous() }
                                                }

                                                // Media Play/Pause Button
                                                Rectangle {
                                                    width: 40; height: 40; radius: 20; color: Style.accent
                                                    scale: (root.buttonAnimsVal && playM.pressed) ? 0.92 : ((root.buttonAnimsVal && playM.containsMouse) ? 1.08 : 1.0)
                                                    Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                                    Text { anchors.centerIn: parent; text: root.isPlaying ? "󰏤" : "󰐊"; font.family: Style.fontFamilyMono; color: "#000"; font.pixelSize: 18; font.weight: Font.Bold }
                                                    MouseArea { id: playM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.togglePlaying() }
                                                }

                                                // Media Next Button
                                                Rectangle {
                                                    width: 32; height: 32; radius: 16; color: Style.cardBgHover
                                                    scale: (root.buttonAnimsVal && nextM.pressed) ? 0.92 : ((root.buttonAnimsVal && nextM.containsMouse) ? 1.08 : 1.0)
                                                    Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                                    Text { anchors.centerIn: parent; text: "󰒭"; font.family: Style.fontFamilyMono; color: Style.textPrimary; font.pixelSize: 14 }
                                                    MouseArea { id: nextM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.next() }
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
                                            Text { text: "󰕾  Master Volume"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
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
                                            Text { text: "󰍬  Microphone Input"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
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

                        // PAGE 3: ENHANCED iOS NOTIFICATION CONTROL CENTER
                        Item {
                            width: pageViewport.width
                            height: pageViewport.height
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 12

                                Text {
                                    text: "SwayNC Control Center"
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeLarge
                                    font.weight: Font.Bold
                                    color: Style.accent
                                }

                                // CARD 1: Status Overview & DND Switch
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 110
                                    radius: Style.radiusMedium
                                    color: Style.cardBg
                                    border.color: Style.cardBorder

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 14

                                        Rectangle {
                                            width: 58; height: 58; radius: Style.radiusMedium
                                            color: root.dndActive ? Style.danger : Style.cardBgHover
                                            border.color: Style.cardBorder

                                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.dndActive ? "󰂛" : "󰂚"
                                                font.family: Style.fontFamilyMono
                                                font.pixelSize: 26
                                                color: root.dndActive ? "#FFFFFF" : Style.accent

                                                Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3

                                            Text {
                                                text: root.notifCount === 0 ? "No Notifications" : root.notifCount + " Unread Notification" + (root.notifCount > 1 ? "s" : "")
                                                font.family: Style.fontFamily
                                                font.pixelSize: Style.fontSizeTitle
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
                                            }

                                            Text {
                                                text: root.dndActive ? "Do Not Disturb (DND) Active" : "Normal Notification Mode"
                                                font.family: Style.fontFamily
                                                font.pixelSize: Style.fontSizeSmall
                                                color: root.dndActive ? Style.danger : Style.textSecondary

                                                Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                            }
                                        }

                                        CustomSwitch {
                                            Layout.alignment: Qt.AlignVCenter
                                            checked: root.dndActive
                                            onToggled: function(val) {
                                                toggleDndProc.running = true;
                                            }
                                        }
                                    }
                                }

                                // CARD 2: 3-Button Quick Action Grid (With Smooth ColorAnimation Fade-In)
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 58
                                    radius: Style.radiusMedium
                                    color: Style.cardBg
                                    border.color: Style.cardBorder

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        // Dismiss Latest Button
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: Style.radiusSmall
                                            color: dismissM.containsMouse ? Style.cardBgHover : Style.cardBg
                                            border.color: Style.cardBorder

                                            scale: (root.buttonAnimsVal && dismissM.pressed) ? 0.95 : ((root.buttonAnimsVal && dismissM.containsMouse) ? 1.04 : 1.0)
                                            Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "󰈅"; font.family: Style.fontFamilyMono; font.pixelSize: 13; color: Style.accent }
                                                Text { text: "Dismiss Latest"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textPrimary }
                                            }

                                            MouseArea {
                                                id: dismissM
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: dismissLatestProc.running = true
                                            }
                                        }

                                        // Clear All Button (Smooth Red Background & Text Color Fade-In)
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: Style.radiusSmall
                                            color: clearM.containsMouse ? Style.danger : Style.cardBgHover
                                            border.color: Style.cardBorder

                                            scale: (root.buttonAnimsVal && clearM.pressed) ? 0.95 : ((root.buttonAnimsVal && clearM.containsMouse) ? 1.04 : 1.0)
                                            Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text {
                                                    text: "󰅖"
                                                    font.family: Style.fontFamilyMono
                                                    font.pixelSize: 13
                                                    color: clearM.containsMouse ? "#FFF" : Style.danger
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                                }
                                                Text {
                                                    text: "Clear All"
                                                    font.family: Style.fontFamily
                                                    font.pixelSize: Style.fontSizeSmall
                                                    font.weight: Font.Bold
                                                    color: clearM.containsMouse ? "#FFF" : Style.textPrimary
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                                }
                                            }

                                            MouseArea {
                                                id: clearM
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: clearNotifsProc.running = true
                                            }
                                        }

                                        // Open SwayNC Control Center Panel Button (Smooth Blue Background & Text Color Fade-In)
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: Style.radiusSmall
                                            color: openCcM.containsMouse ? Style.accent : Style.cardBgHover
                                            border.color: Style.cardBorder

                                            scale: (root.buttonAnimsVal && openCcM.pressed) ? 0.95 : ((root.buttonAnimsVal && openCcM.containsMouse) ? 1.04 : 1.0)
                                            Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                            Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text {
                                                    text: "󰍹"
                                                    font.family: Style.fontFamilyMono; font.pixelSize: 13
                                                    color: openCcM.containsMouse ? "#000" : Style.accent
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                                }
                                                Text {
                                                    text: "Open Panel"
                                                    font.family: Style.fontFamily
                                                    font.pixelSize: Style.fontSizeSmall
                                                    font.weight: Font.Bold
                                                    color: openCcM.containsMouse ? "#000" : Style.textPrimary
                                                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                                }
                                            }

                                            MouseArea {
                                                id: openCcM
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.isExpanded = false;
                                                    openSwayncProc.running = true;
                                                }
                                            }
                                        }
                                    }
                                }

                                // CARD 3: System Inhibitor & Privacy Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 52
                                    radius: Style.radiusMedium
                                    color: Style.cardBg
                                    border.color: Style.cardBorder

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text { text: "󰌾"; font.family: Style.fontFamilyMono; font.pixelSize: 16; color: root.isInhibited ? Style.danger : Style.success }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: "System Inhibitor Status"
                                                font.family: Style.fontFamily
                                                font.pixelSize: Style.fontSizeSmall
                                                font.weight: Font.Bold
                                                color: Style.textPrimary
                                            }

                                            Text {
                                                text: root.isInhibited ? "Notifications Suppressed (Game/Fullscreen App Active)" : "Notification Popups Active & Allowed"
                                                font.family: Style.fontFamily
                                                font.pixelSize: 10
                                                color: root.isInhibited ? Style.danger : Style.textSecondary
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // PAGE 4: Hardware Stats Dashboard
                        Item {
                            width: pageViewport.width
                            height: pageViewport.height
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 12

                                Text {
                                    text: "System Hardware Monitor"
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeLarge
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                    style: Text.Raised
                                    styleColor: "#000000"
                                    color: Style.accent
                                }

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
                                                Text { text: "󰻠 CPU Usage"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.textPrimary }
                                                Item { Layout.fillWidth: true }
                                                Text { text: root.cpuUsage + "%"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.accent }
                                            }

                                            Canvas {
                                                id: cpuGraph
                                                Layout.fillWidth: true
                                                implicitHeight: 42
                                                property var hist: root.cpuHistory
                                                onHistChanged: requestPaint()

                                                onPaint: {
                                                    var ctx = getContext("2d");
                                                    ctx.clearRect(0, 0, width, height);
                                                    if (!hist || hist.length < 2) return;

                                                    var val = root.cpuUsage;
                                                    var colorObj = Style.accent;
                                                    if (val > 80) colorObj = Style.danger;
                                                    else if (val > 60) colorObj = Style.warning;

                                                    ctx.strokeStyle = colorObj;
                                                    ctx.lineWidth = 1.3;
                                                    ctx.beginPath();

                                                    var step = width / (hist.length - 1);
                                                    for (var i = 0; i < hist.length; i++) {
                                                        var x = i * step;
                                                        var y = height - (hist[i] / 100.0 * (height - 4)) - 2;
                                                        if (i === 0) ctx.moveTo(x, y);
                                                        else ctx.lineTo(x, y);
                                                    }
                                                    ctx.stroke();

                                                    ctx.lineTo(width, height);
                                                    ctx.lineTo(0, height);
                                                    ctx.closePath();
                                                    var grad = ctx.createLinearGradient(0, 0, 0, height);
                                                    grad.addColorStop(0, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.08));
                                                    grad.addColorStop(1, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.0));
                                                    ctx.fillStyle = grad;
                                                    ctx.fill();
                                                }
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
                                                Text { text: "󰍛 RAM Memory"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.textPrimary }
                                                Item { Layout.fillWidth: true }
                                                Text { text: root.ramUsage + "%"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.accent }
                                            }

                                            Canvas {
                                                id: ramGraph
                                                Layout.fillWidth: true
                                                implicitHeight: 42
                                                property var hist: root.ramHistory
                                                onHistChanged: requestPaint()

                                                onPaint: {
                                                    var ctx = getContext("2d");
                                                    ctx.clearRect(0, 0, width, height);
                                                    if (!hist || hist.length < 2) return;

                                                    var val = root.ramUsage;
                                                    var colorObj = Style.accent;
                                                    if (val > 80) colorObj = Style.danger;
                                                    else if (val > 60) colorObj = Style.warning;

                                                    ctx.strokeStyle = colorObj;
                                                    ctx.lineWidth = 1.3;
                                                    ctx.beginPath();

                                                    var step = width / (hist.length - 1);
                                                    for (var i = 0; i < hist.length; i++) {
                                                        var x = i * step;
                                                        var y = height - (hist[i] / 100.0 * (height - 4)) - 2;
                                                        if (i === 0) ctx.moveTo(x, y);
                                                        else ctx.lineTo(x, y);
                                                    }
                                                    ctx.stroke();

                                                    ctx.lineTo(width, height);
                                                    ctx.lineTo(0, height);
                                                    ctx.closePath();
                                                    var grad = ctx.createLinearGradient(0, 0, 0, height);
                                                    grad.addColorStop(0, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.08));
                                                    grad.addColorStop(1, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.0));
                                                    ctx.fillStyle = grad;
                                                    ctx.fill();
                                                }
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
                                                Text { text: "󰈀 Network"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.textPrimary }
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

                                            Canvas {
                                                id: netGraph
                                                Layout.fillWidth: true
                                                implicitHeight: 42
                                                property var hist: root.netHistory
                                                onHistChanged: requestPaint()

                                                onPaint: {
                                                    var ctx = getContext("2d");
                                                    ctx.clearRect(0, 0, width, height);
                                                    if (!hist || hist.length < 2) return;

                                                    var colorObj = Style.accent;
                                                    ctx.strokeStyle = colorObj;
                                                    ctx.lineWidth = 1.3;
                                                    ctx.beginPath();

                                                    var step = width / (hist.length - 1);
                                                    for (var i = 0; i < hist.length; i++) {
                                                        var x = i * step;
                                                        var y = height - (hist[i] / 100.0 * (height - 4)) - 2;
                                                        if (i === 0) ctx.moveTo(x, y);
                                                        else ctx.lineTo(x, y);
                                                    }
                                                    ctx.stroke();

                                                    ctx.lineTo(width, height);
                                                    ctx.lineTo(0, height);
                                                    ctx.closePath();
                                                    var grad = ctx.createLinearGradient(0, 0, 0, height);
                                                    grad.addColorStop(0, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.08));
                                                    grad.addColorStop(1, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.0));
                                                    ctx.fillStyle = grad;
                                                    ctx.fill();
                                                }
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
                                                Text { text: "󰋊 Disk (Root)"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; font.weight: Font.Bold; color: Style.textPrimary }
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
                        x: 4 + (root.currentPage * 19)

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
            enabled: root.isExpanded
            onClicked: root.isExpanded = false
        }

        // Integrated Power Menu View Overlay inside notchBox (Morphed State)
        Item {
            id: powerMenuOverlay
            anchors.fill: parent
            z: 99

            opacity: root.isPowerMenuOpen ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.isPowerConfirming ? "Confirm Action" : "Power Options"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeLarge
                    font.weight: Font.Bold
                    color: Style.textPrimary
                }

                // Stacked View Container for Smooth Jitter-Free Transitions
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Normal 2x2 Grid View
                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        rowSpacing: 10
                        columnSpacing: 10

                        opacity: root.isPowerConfirming ? 0.0 : 1.0
                        scale: root.isPowerConfirming ? 0.94 : 1.0
                        visible: opacity > 0.01

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Repeater {
                            model: [
                                { title: "Shutdown", icon: "󰐥", color: Style.danger, cmd: "systemctl poweroff" },
                                { title: "Reboot", icon: "󰑐", color: Style.warning, cmd: "systemctl reboot" },
                                { title: "Sleep", icon: "󰤄", color: Style.teal, cmd: "systemctl suspend" },
                                { title: "Logout", icon: "󰍃", color: Style.purple, cmd: "hyprctl dispatch exit" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Style.radiusMedium
                                color: index === root.powerSelectedIndex ? "#1C1C1E" : (pCardM.containsMouse ? "#121214" : "#0D0D0F")
                                border.color: index === root.powerSelectedIndex ? modelData.color : "#222225"
                                border.width: index === root.powerSelectedIndex ? 2 : 1
                                scale: index === root.powerSelectedIndex ? 1.04 : 1.0

                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: 38; height: 38; radius: 19
                                        color: Qt.alpha(modelData.color, index === root.powerSelectedIndex ? 0.25 : 0.15)
                                        border.color: Qt.alpha(modelData.color, 0.4)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            font.family: Style.fontFamilyMono
                                            font.pixelSize: 18
                                            color: modelData.color
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.title
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontSizeSmall
                                        font.weight: Font.Bold
                                        color: Style.textPrimary
                                    }
                                }

                                MouseArea {
                                    id: pCardM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.powerSelectedIndex = index
                                    onClicked: root.triggerPowerAction(modelData.title, modelData.cmd)
                                }
                            }
                        }
                    }

                    // Confirmation Step View
                    ColumnLayout {
                        anchors.fill: parent
                        Layout.alignment: Qt.AlignCenter
                        spacing: 12

                        opacity: root.isPowerConfirming ? 1.0 : 0.0
                        scale: root.isPowerConfirming ? 1.0 : 1.06
                        visible: opacity > 0.01

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.pendingPowerTitle + "?"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeTitle
                            font.weight: Font.Bold
                            color: Style.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Executing in " + root.powerCountdown + "s"
                            font.family: Style.fontFamilyMono
                            font.pixelSize: Style.fontSizeNormal
                            color: Style.accent
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            // Cancel Button
                            Rectangle {
                                implicitWidth: 100
                                implicitHeight: 36
                                radius: 18
                                color: pCancelM.containsMouse ? "#2C2C2E" : "#1C1C1E"
                                border.color: "#3A3A3C"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeNormal
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                }

                                MouseArea {
                                    id: pCancelM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.cancelPowerAction()
                                }
                            }

                            // Confirm Button
                            Rectangle {
                                implicitWidth: 100
                                implicitHeight: 36
                                radius: 18
                                color: Style.danger

                                Text {
                                    anchors.centerIn: parent
                                    text: "Confirm"
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeNormal
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    id: pConfirmM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.executePendingPower()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Integrated WiFi Menu View Overlay inside notchBox (Morphed State)
        Item {
            id: wifiMenuOverlay
            anchors.fill: parent
            z: 99

            opacity: root.isWifiMenuOpen ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8


                    Text {
                        text: root.isWifiPasswordPromptOpen ? "Enter Password" : "Wi-Fi Network"
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeLarge
                        font.weight: Font.Bold
                        color: Style.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    // Manual Scan Refresh Button with rotation animation
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: wifiRefM.containsMouse ? Style.cardBgHover : Style.cardBg
                        border.color: Style.cardBorder
                        visible: !root.isWifiPasswordPromptOpen && root.wifiPower
                        Text {
                            id: wifiRefText
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: Style.fontFamilyMono
                            font.pixelSize: 11
                            color: Style.textPrimary

                            transformOrigin: Item.Center
                            RotationAnimation on rotation {
                                running: wifiScanner.running || wifiToggler.running
                                from: 0; to: 360; loops: Animation.Infinite; duration: 1000
                            }
                        }
                        MouseArea {
                            id: wifiRefM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiScanner.running = false;
                                wifiScanner.running = true;
                            }
                        }
                    }

                    CustomSwitch {
                        visible: !root.isWifiPasswordPromptOpen
                        checked: root.wifiPower
                        onToggled: function(val) {
                            root.wifiPower = val;
                            wifiToggler.running = false;
                            wifiToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_wifi.py", val ? "on" : "off"];
                            wifiToggler.running = true;
                            wifiScanTimer.restart();
                        }
                    }
                }

                // Shared Container for transitioning scan lists and password text fields
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true

                    // View A: Password Entry View (Native inside Notch)
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12
                        opacity: root.isWifiPasswordPromptOpen ? 1.0 : 0.0
                        scale: root.isWifiPasswordPromptOpen ? 1.0 : 0.92
                        visible: opacity > 0.01

                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        Text {
                            Layout.alignment: Qt.AlignLeft
                            text: "Connecting to: " + root.wifiPromptSsid
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeNormal
                            font.weight: Font.DemiBold
                            color: Style.textSecondary
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: Style.radiusSmall
                            color: "#0E0E10"
                            border.color: wifiPasswordInput.activeFocus ? Style.accent : "#222225"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "󰌾"
                                    font.family: Style.fontFamilyMono
                                    color: Style.textMuted
                                    font.pixelSize: 13
                                }

                                TextInput {
                                    id: wifiPasswordInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontSizeNormal
                                    color: Style.textPrimary
                                    selectByMouse: true
                                    echoMode: root.showWifiPassword ? TextInput.Normal : TextInput.Password
                                    text: root.wifiPasswordText
                                    focus: root.isWifiPasswordPromptOpen
                                    onTextChanged: root.wifiPasswordText = text
                                    verticalAlignment: TextInput.AlignVCenter

                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Escape) {
                                            root.isWifiPasswordPromptOpen = false;
                                            root.forceActiveFocus();
                                            event.accepted = true;
                                        }
                                    }

                                    KeyNavigation.tab: wifiCancelBtn

                                    onAccepted: {
                                        wifiToggler.running = false;
                                        wifiToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_wifi.py", "connect", root.wifiPromptSsid, root.wifiPasswordText];
                                        wifiToggler.running = true;
                                        root.isWifiPasswordPromptOpen = false;
                                        wifiScanTimer.restart();
                                    }
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.showWifiPassword ? "󰈈" : "󰈉"
                                        font.family: Style.fontFamilyMono
                                        font.pixelSize: 12
                                        color: wifiEyeM.containsMouse ? Style.textPrimary : Style.textMuted
                                    }
                                    MouseArea {
                                        id: wifiEyeM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.showWifiPassword = !root.showWifiPassword
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignRight
                            spacing: 10

                            Rectangle {
                                id: wifiCancelBtn
                                implicitWidth: 80; implicitHeight: 32; radius: 16
                                color: wifiCancelM.containsMouse ? "#2C2C2E" : "#1C1C1E"
                                border.color: "#3A3A3C"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold
                                    color: Style.textPrimary
                                }
                                MouseArea {
                                    id: wifiCancelM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.isWifiPasswordPromptOpen = false;
                                        root.forceActiveFocus();
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: 80; implicitHeight: 32; radius: 16
                                color: Style.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: "Connect"
                                    font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: "#000000"
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wifiToggler.running = false;
                                        wifiToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_wifi.py", "connect", root.wifiPromptSsid, root.wifiPasswordText];
                                        wifiToggler.running = true;
                                        root.isWifiPasswordPromptOpen = false;
                                        wifiScanTimer.restart();
                                    }
                                }
                            }
                        }
                    }

                    // View B: Standard Wifi List View
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6
                        opacity: root.isWifiPasswordPromptOpen ? 0.0 : 1.0
                        scale: root.isWifiPasswordPromptOpen ? 0.92 : 1.0
                        visible: opacity > 0.01

                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        // Connected or Connecting Network indicator Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: Style.radiusSmall
                            color: "#0F0F12"
                            border.color: Style.accent
                            border.width: 1
                            visible: root.wifiPower && (root.wifiActiveSsid !== "" || wifiToggler.running)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                spacing: 8
                                Text {
                                    id: wifiActiveIcon
                                    text: wifiToggler.running ? "󰑐" : "󰖩"
                                    font.family: Style.fontFamilyMono; color: Style.accent; font.pixelSize: 13
                                    transformOrigin: Item.Center
                                    RotationAnimation on rotation {
                                        running: wifiToggler.running
                                        from: 0; to: 360; loops: Animation.Infinite; duration: 1000
                                    }
                                }
                                Text {
                                    text: wifiToggler.running ? "Connecting to: " + root.wifiPromptSsid : "Connected: " + root.wifiActiveSsid
                                    font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text { text: wifiToggler.running ? "" : "󰄬"; font.family: Style.fontFamilyMono; color: Style.accent; font.pixelSize: 11 }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            color: "transparent"
                            visible: !root.wifiPower || root.wifiNetworks.length === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: !root.wifiPower ? "󰖪" : "󰑐"
                                    font.family: Style.fontFamilyMono; font.pixelSize: 32
                                    color: Style.textMuted
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: !root.wifiPower ? "Wi-Fi is Powered Off" : "Scanning networks..."
                                    font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal
                                    color: Style.textSecondary
                                }
                            }
                        }

                        ListView {
                            id: wifiList
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: root.wifiPower ? root.wifiNetworks : []
                            clip: true
                            spacing: 4
                            visible: root.wifiPower && root.wifiNetworks.length > 0

                            delegate: Rectangle {
                                width: wifiList.width; height: 32; radius: Style.radiusSmall
                                color: modelData.active ? "#1C1C1E" : (netM.containsMouse ? "#121214" : "#0A0A0C")
                                border.color: modelData.active ? Style.accent : "#222225"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8; anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: "󰖩"
                                        font.family: Style.fontFamilyMono
                                        color: modelData.active ? Style.accent : Style.textSecondary
                                        font.pixelSize: 11
                                        opacity: modelData.signal > 75 ? 1.0 : (modelData.signal > 50 ? 0.75 : (modelData.signal > 25 ? 0.5 : 0.25))
                                    }

                                    Text {
                                        text: modelData.ssid
                                        font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall
                                        color: Style.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.active ? "󰄬" : (modelData.security ? "󰌾" : "")
                                        font.family: Style.fontFamilyMono
                                        color: modelData.active ? Style.accent : Style.textMuted
                                        font.pixelSize: 10
                                    }
                                }

                                MouseArea {
                                    id: netM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.security && modelData.security !== "--" && !modelData.active && !modelData.saved) {
                                            root.wifiPromptSsid = modelData.ssid;
                                            root.wifiPasswordText = "";
                                            root.showWifiPassword = false;
                                            root.isWifiPasswordPromptOpen = true;
                                            wifiPasswordInput.forceActiveFocus();
                                        } else {
                                            wifiToggler.running = false;
                                            wifiToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_wifi.py", "connect", modelData.ssid];
                                            wifiToggler.running = true;
                                            wifiScanTimer.restart();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Integrated Bluetooth Menu View Overlay inside notchBox (Morphed State)
        Item {
            id: bluetoothMenuOverlay
            anchors.fill: parent
            z: 99

            opacity: root.isBluetoothMenuOpen ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8


                    Text {
                        text: "Bluetooth"
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeLarge
                        font.weight: Font.Bold
                        color: Style.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    // Manual Scan Refresh Button with rotation animation
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: btRefM.containsMouse ? Style.cardBgHover : Style.cardBg
                        border.color: Style.cardBorder
                        visible: root.btPower
                        Text {
                            id: btRefText
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: Style.fontFamilyMono
                            font.pixelSize: 11
                            color: Style.textPrimary

                            transformOrigin: Item.Center
                            RotationAnimation on rotation {
                                running: btScanner.running || btToggler.running
                                from: 0; to: 360; loops: Animation.Infinite; duration: 1000
                            }
                        }
                        MouseArea {
                            id: btRefM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btScanner.running = false;
                                btScanner.running = true;
                            }
                        }
                    }

                    CustomSwitch {
                        checked: root.btPower
                        onToggled: function(val) {
                            root.btPower = val;
                            btToggler.running = false;
                            btToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_bluetooth.py", val ? "on" : "off"];
                            btToggler.running = true;
                            btScanTimer.restart();
                        }
                    }
                }

                // Connecting Device Indicator Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Style.radiusSmall
                    color: "#0F0F12"
                    border.color: Style.accent
                    border.width: 1
                    visible: root.btPower && btToggler.running

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 8
                        Text {
                            id: btActiveIcon
                            text: "󰑐"
                            font.family: Style.fontFamilyMono; color: Style.accent; font.pixelSize: 13
                            transformOrigin: Item.Center
                            RotationAnimation on rotation {
                                running: btToggler.running
                                from: 0; to: 360; loops: Animation.Infinite; duration: 1000
                            }
                        }
                        Text {
                            text: "Updating connection..."
                            font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal
                            font.weight: Font.Bold
                            color: Style.textPrimary
                            Layout.fillWidth: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: "transparent"
                    visible: !root.btPower || root.btDevices.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: !root.btPower ? "󰂲" : "󰑐"
                            font.family: Style.fontFamilyMono; font.pixelSize: 32
                            color: Style.textMuted
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: !root.btPower ? "Bluetooth is Powered Off" : "No devices found"
                            font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal
                            color: Style.textSecondary
                        }
                    }
                }

                ListView {
                    id: btList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: root.btPower ? root.btDevices : []
                    clip: true
                    spacing: 4
                    visible: root.btPower && root.btDevices.length > 0

                    delegate: Rectangle {
                        width: btList.width; height: 32; radius: Style.radiusSmall
                        color: modelData.connected ? "#1C1C1E" : (devM.containsMouse ? "#121214" : "#0A0A0C")
                        border.color: modelData.connected ? Style.accent : "#222225"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: modelData.connected ? "󰂱" : "󰂯"
                                font.family: Style.fontFamilyMono
                                color: modelData.connected ? Style.accent : Style.textSecondary
                                font.pixelSize: 11
                            }

                            Text {
                                text: modelData.name
                                font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall
                                color: Style.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.connected ? "󰄬" : ""
                                font.family: Style.fontFamilyMono
                                color: Style.accent
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            id: devM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btToggler.running = false;
                                btToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_bluetooth.py", "toggle_conn", modelData.mac];
                                btToggler.running = true;
                                btScanTimer.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}
