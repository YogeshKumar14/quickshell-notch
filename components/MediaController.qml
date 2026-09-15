/**
 * MediaController.qml — NotchNook 3-Column Dashboard for QuickShell Notch
 *
 * Renders PAGE 0 of the expanded landscape notch matching macOS NotchNook:
 *   - Left Column: Squircle album art with Apple Music badge, track metadata, timeline scrubber, and playback controls
 *   - Middle/Right Column: Live 7-day Calendar Timeline with month/year header and event/recording status badge
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../theme"

Item {
    id: root

    /** Reference to active MprisPlayer instance */
    property var activePlayer: null
    /** Current track title */
    property string trackTitle: ""
    /** Current track artist */
    property string trackArtist: ""
    /** Current playback position */
    property real trackPosition: 0
    /** Whether media is currently playing */
    property bool isPlaying: false

    /** Master volume level (0..100) */
    property int volumeLevel: 50
    /** Microphone input level (0..100) */
    property int micLevel: 50

    /** Whether micro-interaction button animations are enabled */
    property bool buttonAnims: true
    /** Button scale animation duration / spring tension */
    property int buttonSpeed: 180
    /** Spring tension for buttons */
    property real tabSpringTension: 5.5
    /** Spring damping for buttons */
    property real tabSpringDamping: 0.22

    /** Expose content height to parent */
    readonly property int mediaContentHeight: 100

    /** Emitted when volume level changes */
    signal volumeChanged(int level)
    /** Emitted when mic level changes */
    signal micChanged(int level)
    /** Emitted when user clicks volume/device icon to open audio drawer */
    signal audioMenuRequested()

    clip: false

    /** Whether the active media player explicitly supports seeking operations */
    readonly property bool canSeek: {
        if (!root.activePlayer) return false;
        if (root.activePlayer.canSeek !== undefined) {
            return Boolean(root.activePlayer.canSeek);
        }
        return true;
    }

    /** Local optimistically synced track position in seconds (-1 when uninitialized) */
    property real localTrackPosition: -1
    /** Whether user is actively seeking (scrubbing or rewinding) to prevent polling snap-backs */
    property bool isSeeking: false
    /** Pending accumulated relative seek delta in seconds */
    property real pendingRelativeSeek: 0
    /** Pending target absolute seek position in seconds (-1 if none) */
    property real pendingAbsoluteSeek: -1

    /** Optional external track length passed from parent (in seconds) */
    property real externalTrackLength: 0

    /** Resolved fallback track length in seconds (from playerctl/D-Bus) */
    property real fallbackTrackLength: 0

    /** Internal reactive trigger for recalculating track length */
    property int durationTrigger: 0

    /** In-memory cache for track durations keyed by target::title::artist */
    property var durationCache: ({})

    function getTrackKey() {
        var title = (root.activePlayer && root.activePlayer.trackTitle) ? root.activePlayer.trackTitle.trim() : (root.trackTitle ? root.trackTitle.trim() : "");
        var artist = (root.activePlayer && root.activePlayer.trackArtist) ? root.activePlayer.trackArtist.trim() : (root.trackArtist ? root.trackArtist.trim() : "");
        if (!title || title === "No Media Playing") return "";
        var target = root.getPlayerTarget();
        return target + "::" + title + "::" + artist;
    }

    function normalizeDuration(raw) {
        if (raw === undefined || raw === null) return 0;
        var val = parseFloat(raw);
        if (isNaN(val) || !isFinite(val) || val <= 0) return 0;
        // In MPRIS specification, mpris:length is in microseconds.
        // A value > 100,000 indicates microseconds (>0.1s in us; >27.7 hrs in seconds).
        if (val > 100000) {
            return val / 1000000.0;
        }
        return val;
    }

    property int durationRetryCount: 0

    Timer {
        id: durationRetryTimer
        interval: 600
        repeat: true
        running: false
        onTriggered: {
            if (root.trackLength > 0 || !root.activePlayer) {
                running = false;
                root.durationRetryCount = 0;
                return;
            }
            if (root.durationRetryCount >= 8) {
                running = false;
                return;
            }
            root.durationRetryCount++;
            root.queryTrackDuration();
        }
    }

    function checkAndResolveDuration() {
        var key = root.getTrackKey();
        var dur = 0;
        if (root.activePlayer) {
            if (root.activePlayer.length !== undefined && root.activePlayer.length > 0) {
                dur = root.normalizeDuration(root.activePlayer.length);
            }
            if (dur <= 0 && root.activePlayer.metadata && root.activePlayer.metadata["mpris:length"] !== undefined) {
                dur = root.normalizeDuration(root.activePlayer.metadata["mpris:length"]);
            }
        }
        if (dur <= 0 && root.externalTrackLength > 0) {
            dur = root.normalizeDuration(root.externalTrackLength);
        }
        if (dur <= 0 && key && root.durationCache[key] && root.durationCache[key] > 0) {
            dur = root.durationCache[key];
        }

        if (dur > 0) {
            if (key) root.durationCache[key] = dur;
            root.fallbackTrackLength = dur;
            root.durationTrigger++;
            durationRetryTimer.stop();
            root.durationRetryCount = 0;
        } else if (root.activePlayer && key) {
            root.queryTrackDuration();
            durationRetryTimer.restart();
        }
    }

    Connections {
        target: root.activePlayer
        function onLengthChanged() {
            root.checkAndResolveDuration();
        }
        function onMetadataChanged() {
            root.checkAndResolveDuration();
        }
        function onTrackTitleChanged() {
            root.durationRetryCount = 0;
            root.checkAndResolveDuration();
        }
        function onPlaybackStateChanged() {
            if (root.trackLength <= 0) {
                root.checkAndResolveDuration();
            }
        }
    }

    onActivePlayerChanged: {
        root.localTrackPosition = -1;
        root.isSeeking = false;
        root.pendingRelativeSeek = 0;
        root.pendingAbsoluteSeek = -1;
        seekDispatchTimer.stop();
        seekCooldownTimer.stop();
        root.fallbackTrackLength = 0;
        root.durationRetryCount = 0;
        root.durationTrigger++;
        root.checkAndResolveDuration();
    }

    onTrackTitleChanged: {
        root.localTrackPosition = -1;
        root.isSeeking = false;
        root.pendingRelativeSeek = 0;
        root.pendingAbsoluteSeek = -1;
        seekDispatchTimer.stop();
        seekCooldownTimer.stop();
        root.fallbackTrackLength = 0;
        root.durationRetryCount = 0;
        root.durationTrigger++;
        root.checkAndResolveDuration();
    }

    onTrackArtistChanged: {
        root.durationRetryCount = 0;
        root.durationTrigger++;
        root.checkAndResolveDuration();
    }

    onExternalTrackLengthChanged: {
        if (root.externalTrackLength > 0) {
            var key = root.getTrackKey();
            var dur = root.normalizeDuration(root.externalTrackLength);
            if (dur > 0 && key) {
                root.durationCache[key] = dur;
            }
            root.durationTrigger++;
        }
    }

    onIsPlayingChanged: {
        if (root.trackLength <= 0) {
            root.checkAndResolveDuration();
        }
    }

    onTrackPositionChanged: {
        if (!root.isSeeking && root.localTrackPosition < 0) {
            root.localTrackPosition = root.trackPosition;
        }
    }

    Timer {
        id: seekCooldownTimer
        interval: 1200
        repeat: false
        onTriggered: {
            root.isSeeking = false;
        }
    }

    Timer {
        id: seekDispatchTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.dispatchPendingSeek();
        }
    }

    /** Helper to get clean MPRIS player name for playerctl / D-Bus targeting */
    function getPlayerTarget() {
        if (!root.activePlayer) return "";
        if (root.activePlayer.dbusName && root.activePlayer.dbusName.length > 0) {
            return root.activePlayer.dbusName.replace(/^org\.mpris\.MediaPlayer2\./, "");
        }
        if (root.activePlayer.identity && root.activePlayer.identity.length > 0) {
            return root.activePlayer.identity;
        }
        return "";
    }

    /** Current track total length in seconds (foolproof multi-tier resolution) */
    property real trackLength: {
        var _trigger = root.durationTrigger;
        var key = root.getTrackKey();

        // 1. Direct activePlayer lookup (length property)
        if (root.activePlayer && root.activePlayer.length !== undefined) {
            var directLen = root.normalizeDuration(root.activePlayer.length);
            if (directLen > 0) return directLen;
        }

        // 1b. Direct activePlayer metadata lookup (mpris:length)
        if (root.activePlayer && root.activePlayer.metadata && root.activePlayer.metadata["mpris:length"] !== undefined) {
            var metaLen = root.normalizeDuration(root.activePlayer.metadata["mpris:length"]);
            if (metaLen > 0) return metaLen;
        }

        // 1c. External track length from parent TopNotch
        if (root.externalTrackLength > 0) {
            var extLen = root.normalizeDuration(root.externalTrackLength);
            if (extLen > 0) return extLen;
        }

        // 2. Fallback resolved length from D-Bus / playerctl query
        if (root.fallbackTrackLength > 0) {
            var fbLen = root.normalizeDuration(root.fallbackTrackLength);
            if (fbLen > 0) return fbLen;
        }

        // 3. Cached duration lookup for this track
        if (key && root.durationCache[key] && root.durationCache[key] > 0) {
            return root.durationCache[key];
        }

        return 0;
    }

    /** Clean track elapsed position in seconds (auto-normalized and clamped) */
    property real cleanTrackPosition: {
        var pos = (root.localTrackPosition >= 0) ? root.localTrackPosition : root.trackPosition;
        if (!pos || isNaN(pos) || !isFinite(pos) || pos <= 0) return 0;
        if (pos > 100000) pos = pos / 1000000.0;
        if (root.trackLength > 0) pos = Math.min(root.trackLength, pos);
        return Math.max(0, pos);
    }

    function formatTime(sec) {
        if (!sec || isNaN(sec) || !isFinite(sec) || sec <= 0) return "0:00";
        var totalSec = Math.floor(sec);
        var hrs = Math.floor(totalSec / 3600);
        var mins = Math.floor((totalSec % 3600) / 60);
        var secs = totalSec % 60;
        if (hrs > 0) {
            return hrs + ":" + (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs;
        }
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    function dispatchPendingSeek() {
        if (!root.canSeek) {
            root.pendingAbsoluteSeek = -1;
            root.pendingRelativeSeek = 0;
            root.isSeeking = false;
            return;
        }

        var target = root.getPlayerTarget();
        var absPos = root.pendingAbsoluteSeek;
        var relDelta = root.pendingRelativeSeek;
        root.pendingAbsoluteSeek = -1;
        root.pendingRelativeSeek = 0;

        if (absPos < 0 && relDelta === 0) {
            return;
        }

        var cmd = [
            "python3",
            Quickshell.shellDir + "/scripts/notch/mpris_seek.py"
        ];
        if (target !== "") {
            cmd.push("-p", target);
        }

        if (absPos >= 0) {
            cmd.push(absPos.toFixed(2), "--absolute", "--current-pos", root.cleanTrackPosition.toFixed(2));
        } else if (relDelta !== 0) {
            cmd.push(relDelta.toFixed(2), "--relative", "--current-pos", root.cleanTrackPosition.toFixed(2));
        }

        mprisSeekProc.command = cmd;
        mprisSeekProc.running = false;
        mprisSeekProc.running = true;
    }

    function seekAbsolute(sec) {
        if (!root.canSeek) return;
        if (sec === undefined || isNaN(sec) || !isFinite(sec)) return;
        var targetPos = Math.max(0, sec);
        if (root.trackLength > 0) {
            targetPos = Math.min(root.trackLength, targetPos);
        }
        root.localTrackPosition = targetPos;
        root.isSeeking = true;
        seekCooldownTimer.restart();

        root.pendingRelativeSeek = 0;
        root.pendingAbsoluteSeek = targetPos;
        seekDispatchTimer.restart();
    }

    function seekRelative(deltaSec) {
        if (!root.canSeek) return;
        if (deltaSec === undefined || isNaN(deltaSec) || !isFinite(deltaSec)) return;
        var currentPos = root.cleanTrackPosition;
        var targetPos = Math.max(0, currentPos + deltaSec);
        if (root.trackLength > 0) {
            targetPos = Math.min(root.trackLength, targetPos);
        }
        root.localTrackPosition = targetPos;
        root.isSeeking = true;
        seekCooldownTimer.restart();

        root.pendingAbsoluteSeek = -1;
        root.pendingRelativeSeek += deltaSec;
        seekDispatchTimer.restart();
    }

    // Active 500ms playerctl position polling for sub-second accurate playback timeline
    Process {
        id: playerctlPosProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.isSeeking) return;
                var p = parseFloat(this.text.trim());
                if (!isNaN(p) && p >= 0) {
                    root.localTrackPosition = p;
                }
            }
        }
    }

    // Multi-tier fallback process querying track duration via direct D-Bus & playerctl
    Process {
        id: mprisDurationProc
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text.trim();
                var dur = root.normalizeDuration(raw);
                if (dur > 0) {
                    var key = root.getTrackKey();
                    if (key) {
                        root.durationCache[key] = dur;
                    }
                    root.fallbackTrackLength = dur;
                    root.durationTrigger++;
                    durationRetryTimer.stop();
                    root.durationRetryCount = 0;
                }
            }
        }
    }

    function queryTrackDuration() {
        var target = root.getPlayerTarget();
        var cmd = [
            "python3",
            Quickshell.shellDir + "/scripts/notch/mpris_duration.py"
        ];
        if (target !== "") {
            cmd.push("-p", target);
        }
        mprisDurationProc.command = cmd;
        mprisDurationProc.running = false;
        mprisDurationProc.running = true;
    }

    function pollPlayerctlPosition(force) {
        if (!force && root.isSeeking) return;
        var target = root.getPlayerTarget();
        if (target !== "") {
            playerctlPosProc.command = ["playerctl", "-p", target, "position"];
        } else {
            playerctlPosProc.command = ["playerctl", "position"];
        }
        playerctlPosProc.running = false;
        playerctlPosProc.running = true;
    }

    Timer {
        id: seekSyncTimer
        interval: 150
        repeat: false
        onTriggered: {
            root.isSeeking = false;
            seekCooldownTimer.stop();
            root.pollPlayerctlPosition(true);
        }
    }

    Timer {
        id: posPollingTimer
        interval: 500
        running: root.isPlaying
        repeat: true
        onTriggered: {
            root.pollPlayerctlPosition(false);
        }
    }

    // Real-time clock for calendar
    Timer {
        id: calendarTimer
        interval: 60000
        running: true
        repeat: true
        onTriggered: dateModelUpdate()
    }

    property var todayDate: new Date()
    property string currentMonthStr: todayDate.toLocaleString(Qt.locale(), "MMM")
    property var daysList: {
        var now = root.todayDate;
        var days = [];
        var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        for (var offset = -3; offset <= 4; offset++) {
            var d = new Date(now.getTime() + offset * 86400000);
            days.push({
                offset: offset,
                dayName: dayNames[d.getDay()],
                dayNum: (d.getDate() < 10 ? "0" : "") + d.getDate(),
                isToday: (offset === 0)
            });
        }
        return days;
    }

    function dateModelUpdate() {
        var now = new Date();
        root.todayDate = now;
        root.currentMonthStr = now.toLocaleString(Qt.locale(), "MMM");
    }

    // =====================================================================
    // 1. LEFT COLUMN: MEDIA PLAYER WIDGET (310px)
    // =====================================================================
    Item {
        id: leftColItem
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 310

        // Squircle Album Art (78x78px) with OpacityMask & Apple Music badge
        Item {
            id: albumArtBox
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 78
            height: 78

                readonly property real albumRadius: Style.bottomRadius > 0 ? Style.bottomRadius : Style.radiusLarge

                // 1. Source Image (hidden, offscreen texture)
                Image {
                    id: albumArtImg
                    anchors.fill: parent
                    source: (root.activePlayer && root.activePlayer.trackArtUrl) ? root.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    sourceSize.width: 156
                    sourceSize.height: 156
                    smooth: true
                    mipmap: true
                    antialiasing: true
                }

                // 2. Vector Mask Shape (Antialiased Squircle)
                Rectangle {
                    id: albumArtMask
                    anchors.fill: parent
                    radius: albumArtBox.albumRadius
                    color: "#000000"
                    visible: false
                    smooth: true
                    antialiasing: true

                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                }

                // 3. Fallback Placeholder if no artwork
                Rectangle {
                    id: albumArtFallback
                    anchors.fill: parent
                    radius: albumArtBox.albumRadius
                    color: "#1C1C1E"
                    border.color: "#2C2C2E"
                    border.width: 1
                    visible: albumArtImg.source.toString() === "" || albumArtImg.status !== Image.Ready
                    smooth: true
                    antialiasing: true

                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                    Rectangle {
                        anchors.fill: parent
                        radius: albumArtBox.albumRadius
                        color: Style.accent
                        opacity: 0.12
                        smooth: true
                        antialiasing: true
                    }

                    M3Icon {
                        anchors.centerIn: parent
                        name: "music_note"
                        size: 32
                        color: Style.accent
                    }
                }

                // 4. Alpha-Masked Squircle Artwork
                OpacityMask {
                    anchors.fill: parent
                    source: albumArtImg
                    maskSource: albumArtMask
                    visible: albumArtImg.source.toString() !== "" && albumArtImg.status === Image.Ready
                }

                // 5. Crisp Structural Border Overlay
                Rectangle {
                    anchors.fill: parent
                    radius: albumArtBox.albumRadius
                    color: "transparent"
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1.0
                    smooth: true
                    antialiasing: true

                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                }

                // 6. Apple Music App Badge on bottom-right corner
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.bottomMargin: -2
                    anchors.rightMargin: -2
                    width: 18
                    height: 18
                    radius: 5.5
                    color: Style.appleMusicRed
                    border.color: "#000000"
                    border.width: 1.5
                    smooth: true
                    antialiasing: true
                    z: 5
                    visible: (albumArtImg.source.toString() !== "" && albumArtImg.status === Image.Ready) || root.isPlaying || (root.trackTitle !== "" && root.trackTitle !== "No Media Playing")

                    M3Icon {
                        anchors.centerIn: parent
                        name: "music_note"
                        size: 11
                        color: "#FFFFFF"
                    }
                }
            }

        // Track Info, Scrubber & Controls Column aligned with albumArtBox
        Item {
            id: trackControlsCol
            anchors.left: albumArtBox.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.top: albumArtBox.top
            anchors.bottom: albumArtBox.bottom

            // Track Info (Title & Artist)
            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: scrubberCol.top
                anchors.bottomMargin: 2
                spacing: 1

                Text {
                    width: parent.width
                    text: root.trackTitle !== "" ? root.trackTitle : "No Media Playing"
                    font.family: Style.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.trackArtist !== "" ? root.trackArtist : "Top Notch"
                    font.family: Style.fontFamily
                    font.pixelSize: 11
                    color: Style.textSecondary
                    elide: Text.ElideRight
                }
            }

            // Full-width Scrubber Seek Bar with timestamps directly underneath
            Column {
                id: scrubberCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: controlsRow.top
                anchors.bottomMargin: 2
                spacing: 1

                Item {
                    width: parent.width
                    height: 9

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: (root.canSeek && scrubMouse.containsMouse) ? 4 : 3
                        radius: height / 2
                        color: "#3A3A3C"

                        Behavior on height { NumberAnimation { duration: 100 } }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: (root.trackLength > 0 && parent && parent.width > 0) ? Math.min(parent.width, Math.max(0, (root.cleanTrackPosition / root.trackLength) * parent.width)) : 0
                            radius: height / 2
                            color: "#FFFFFF"
                            opacity: root.canSeek ? 1.0 : 0.6
                        }
                    }

                    MouseArea {
                        id: scrubMouse
                        anchors.fill: parent
                        enabled: root.canSeek && (root.trackLength > 0)
                        hoverEnabled: root.canSeek && (root.trackLength > 0)
                        cursorShape: (root.canSeek && root.trackLength > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: function(mouse) {
                            if (root.canSeek && root.trackLength > 0 && width > 0) {
                                var pct = Math.max(0, Math.min(1.0, mouse.x / width));
                                var targetPos = pct * root.trackLength;
                                root.seekAbsolute(targetPos);
                            }
                        }
                        onPositionChanged: function(mouse) {
                            if (pressed && root.canSeek && root.trackLength > 0 && width > 0) {
                                var pct = Math.max(0, Math.min(1.0, mouse.x / width));
                                var targetPos = pct * root.trackLength;
                                root.seekAbsolute(targetPos);
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 12

                    Text {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        text: root.formatTime(root.cleanTrackPosition)
                        font.family: Style.fontFamilyMono
                        font.pixelSize: 10
                        color: Style.textSecondary
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: (root.trackLength > 0) ? root.formatTime(root.trackLength) : "0:00"
                        font.family: Style.fontFamilyMono
                        font.pixelSize: 10
                        color: Style.textSecondary
                    }
                }
            }

            // Playback Controls Row (10s Rewind on left, Prev/Play/Next centered, Device on right)
            Item {
                id: controlsRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 22

                // 10s Rewind (Replay 10) on left
                Item {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22; height: 22
                    opacity: root.canSeek ? 1.0 : 0.35
                    scale: (root.canSeek && root.buttonAnims && rewMA.pressed) ? 0.85 : ((root.canSeek && root.buttonAnims && rewMA.containsMouse) ? 1.15 : 1.0)
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                    M3Icon {
                        anchors.centerIn: parent
                        name: "replay_10"
                        size: 14
                        color: (root.canSeek && rewMA.containsMouse) ? "#FFFFFF" : Style.textSecondary
                    }
                    MouseArea {
                        id: rewMA
                        anchors.fill: parent
                        enabled: root.canSeek
                        hoverEnabled: root.canSeek
                        cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.canSeek) {
                                root.seekRelative(-10);
                            }
                        }
                    }
                }

                // Prev / Play-Pause / Next Centered
                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    // Prev Button
                    Item {
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        scale: (root.buttonAnims && prevMA.pressed) ? 0.85 : ((root.buttonAnims && prevMA.containsMouse) ? 1.15 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "skip_previous"
                            size: 15
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            id: prevMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer) {
                                    root.activePlayer.previous();
                                } else {
                                    var target = root.getPlayerTarget();
                                    playerctlPrev.command = target ? ["playerctl", "-p", target, "previous"] : ["playerctl", "previous"];
                                    playerctlPrev.running = false;
                                    playerctlPrev.running = true;
                                }
                            }
                        }
                    }

                    // Play/Pause Button (Large Center Solid)
                    Item {
                        width: 20; height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        scale: (root.buttonAnims && playMA.pressed) ? 0.85 : ((root.buttonAnims && playMA.containsMouse) ? 1.15 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: root.isPlaying ? "pause" : "play_arrow"
                            size: 20
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            id: playMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer) {
                                    root.activePlayer.togglePlaying();
                                } else {
                                    var target = root.getPlayerTarget();
                                    playerctlPlayPause.command = target ? ["playerctl", "-p", target, "play-pause"] : ["playerctl", "play-pause"];
                                    playerctlPlayPause.running = false;
                                    playerctlPlayPause.running = true;
                                }
                            }
                        }
                    }

                    // Next Button
                    Item {
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        scale: (root.buttonAnims && nextMA.pressed) ? 0.85 : ((root.buttonAnims && nextMA.containsMouse) ? 1.15 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "skip_next"
                            size: 15
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            id: nextMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer) {
                                    root.activePlayer.next();
                                } else {
                                    var target = root.getPlayerTarget();
                                    playerctlNext.command = target ? ["playerctl", "-p", target, "next"] : ["playerctl", "next"];
                                    playerctlNext.running = false;
                                    playerctlNext.running = true;
                                }
                            }
                        }
                    }
                }

                // Output Device Icon (Matching Reference: macOS MacBook laptop icon) on right
                Item {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16; height: 16
                    scale: (root.buttonAnims && devMA.pressed) ? 0.85 : ((root.buttonAnims && devMA.containsMouse) ? 1.15 : 1.0)
                    Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                    M3Icon {
                        anchors.centerIn: parent
                        name: "laptopcomputer"
                        size: 14
                        color: devMA.containsMouse ? "#FFFFFF" : Style.textSecondary
                    }
                    MouseArea {
                        id: devMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.audioMenuRequested()
                    }
                }
            }
        }
    }

    // =====================================================================
    // 2. RIGHT COLUMN: CALENDAR & EVENTS DASHBOARD (260px)
    // =====================================================================
    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 260

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            spacing: 8

            // Top Row: Month/Year + 8-Day Horizontal Strip
            Row {
                spacing: 8
                anchors.right: parent.right

                // Month / Year Stack
                Column {
                    spacing: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: root.currentMonthStr
                        font.family: Style.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }
                    Text {
                        text: root.todayDate.getFullYear().toString()
                        font.family: Style.fontFamily
                        font.pixelSize: 10
                        color: Style.textSecondary
                    }
                }

                // 8-Day Horizontal Date Strip (Matching Reference)
                Row {
                    spacing: 3
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: root.daysList

                        Rectangle {
                            width: modelData.isToday ? 26 : 22
                            height: modelData.isToday ? 44 : 38
                            radius: modelData.isToday ? 9 : 0
                            anchors.verticalCenter: parent.verticalCenter
                            color: modelData.isToday ? Style.systemBlue : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                // Day of Week (Title Case, e.g. Fri, Sat)
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.dayName
                                    font.family: Style.fontFamily
                                    font.pixelSize: 8
                                    font.weight: modelData.isToday ? Font.DemiBold : Font.Normal
                                    color: modelData.isToday ? "#FFFFFF" : Style.textSecondary
                                }

                                // Day Number
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.dayNum
                                    font.family: Style.fontFamily
                                    font.pixelSize: modelData.isToday ? 13 : 12
                                    font.weight: Font.Bold
                                    color: modelData.isToday ? "#FFFFFF" : "#C7C7CC"
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Row: Event Status Card (Matching Reference: Calendar with Checkmark)
            Row {
                spacing: 8
                anchors.left: parent.left
                anchors.leftMargin: 2

                M3Icon {
                    name: "calendar_badge_checkmark"
                    size: 18
                    color: "#AEAEB2"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "No events today"
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }

                    Text {
                        text: "Enjoy your free time!"
                        font.family: Style.fontFamily
                        font.pixelSize: 10
                        color: Style.textSecondary
                    }
                }
            }
        }
    }

    Process {
        id: playerctlPrev
        command: ["playerctl", "previous"]
    }

    Process {
        id: playerctlPlayPause
        command: ["playerctl", "play-pause"]
    }

    Process {
        id: playerctlNext
        command: ["playerctl", "next"]
    }

    Process {
        id: mprisSeekProc
        stdout: StdioCollector {
            onStreamFinished: {
                seekSyncTimer.restart();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn("[MediaController] mpris_seek error:", this.text.trim());
                }
            }
        }
    }
}
