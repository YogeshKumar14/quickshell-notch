/**
 * MediaController.qml — NotchNook 3-Column Dashboard for QuickShell Notch
 *
 * Renders PAGE 0 of the expanded landscape notch:
 *   - Left Column: Squircle album art, track metadata, and inline playback controls
 *   - Middle Column: Live 7-day Calendar Timeline with month header and event/recording status badge
 *   - Right Column: Circular live user profile / camera mirror widget with glossy border
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
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
    /** Audio visualizer frame amplitude array */
    property var visualizerFrame: []
    /** Visualizer peak bar height in pixels */
    property int visualizerHeight: 16

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
    readonly property int mediaContentHeight: 84

    /** Emitted when volume level changes */
    signal volumeChanged(int level)
    /** Emitted when mic level changes */
    signal micChanged(int level)

    clip: false

    /** Current track total length in seconds */
    property real trackLength: (root.activePlayer && root.activePlayer.length > 0) ? (root.activePlayer.length / 1000000.0) : 0

    function formatTime(sec) {
        if (!sec || isNaN(sec) || sec <= 0) return "0:00";
        var mins = Math.floor(sec / 60);
        var secs = Math.floor(sec % 60);
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
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
        for (var offset = -3; offset <= 3; offset++) {
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
    // 1. LEFT COLUMN: MEDIA PLAYER WIDGET (305px)
    // =====================================================================
    Item {
        id: leftColItem
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 305

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Squircle Album Art (56x56px, radius 14px) with OpacityMask & music app badge
            Item {
                width: 56
                height: 56

                // 1. Source Image (hidden, offscreen texture)
                Image {
                    id: albumArtImg
                    anchors.fill: parent
                    source: (root.activePlayer && root.activePlayer.trackArtUrl) ? root.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    sourceSize.width: 112
                    sourceSize.height: 112
                }

                // 2. Vector Mask Shape (Antialiased Squircle)
                Rectangle {
                    id: albumArtMask
                    anchors.fill: parent
                    radius: 14
                    color: "#000000"
                    visible: false
                    smooth: true
                    antialiasing: true
                }

                // 3. Fallback Placeholder if no artwork
                Rectangle {
                    id: albumArtFallback
                    anchors.fill: parent
                    radius: 14
                    color: "#2C2C2E"
                    border.color: "#3A3A3C"
                    border.width: 1
                    visible: albumArtImg.source.toString() === "" || albumArtImg.status !== Image.Ready
                    smooth: true
                    antialiasing: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: Style.accent
                        opacity: 0.20
                    }

                    M3Icon {
                        anchors.centerIn: parent
                        name: "music_note"
                        size: 26
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
                    radius: 14
                    color: "transparent"
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1.0
                    smooth: true
                    antialiasing: true
                }

                // 6. Apple Music / Media App Badge on bottom-right corner
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.bottomMargin: -2
                    anchors.rightMargin: -2
                    width: 16
                    height: 16
                    radius: 5
                    color: "#FA2D48" // Apple Music Red
                    border.color: "#000000"
                    border.width: 1.5
                    smooth: true
                    antialiasing: true
                    z: 5

                    M3Icon {
                        anchors.centerIn: parent
                        name: "music_note"
                        size: 10
                        color: "#FFFFFF"
                    }
                }
            }

            // Track Info, Scrubber & Controls
            Column {
                width: 235
                spacing: 2

                Text {
                    width: parent.width
                    text: root.trackTitle !== "" ? root.trackTitle : "No Media Playing"
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.trackArtist !== "" ? root.trackArtist : "QuickShell Notch"
                    font.family: Style.fontFamily
                    font.pixelSize: 10
                    color: "#8E8E93"
                    elide: Text.ElideRight
                }

                // Scrubber Seek Bar Row
                RowLayout {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: root.formatTime(root.trackPosition)
                        font.family: Style.fontFamilyMono
                        font.pixelSize: 8
                        color: "#8E8E93"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 3
                        radius: 1.5
                        color: "#3A3A3C"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: (root.trackLength > 0) ? Math.min(parent.width, Math.max(0, (root.trackPosition / root.trackLength) * parent.width)) : (root.isPlaying ? 40 : 0)
                            radius: 1.5
                            color: "#FFFFFF"
                        }
                    }

                    Text {
                        text: (root.trackLength > 0) ? root.formatTime(root.trackLength) : "3:16"
                        font.family: Style.fontFamilyMono
                        font.pixelSize: 8
                        color: "#8E8E93"
                    }
                }

                // Playback Controls Row (10s Rewind, Prev, Play/Pause, Next, Device)
                RowLayout {
                    width: parent.width
                    spacing: 12

                    // 10s Rewind (Replay 10)
                    Item {
                        width: 14; height: 14
                        scale: (root.buttonAnims && rewMA.pressed) ? 0.85 : ((root.buttonAnims && rewMA.containsMouse) ? 1.15 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "replay_10"
                            size: 13
                            color: rewMA.containsMouse ? "#FFFFFF" : "#8E8E93"
                        }
                        MouseArea {
                            id: rewMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer && root.activePlayer.canSeek) root.activePlayer.seek(-10000000)
                        }
                    }

                    // Prev Button
                    Item {
                        width: 16; height: 16
                        scale: (root.buttonAnims && prevMA.pressed) ? 0.85 : ((root.buttonAnims && prevMA.containsMouse) ? 1.15 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "skip_previous"
                            size: 13
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            id: prevMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer) root.activePlayer.previous()
                        }
                    }

                    // Play/Pause Button (Large Center Solid)
                    Item {
                        width: 18; height: 18
                        scale: (root.buttonAnims && playMA.pressed) ? 0.85 : ((root.buttonAnims && playMA.containsMouse) ? 1.15 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: root.isPlaying ? "pause" : "play_arrow"
                            size: 17
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            id: playMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                        }
                    }

                    // Next Button
                    Item {
                        width: 16; height: 16
                        scale: (root.buttonAnims && nextMA.pressed) ? 0.85 : ((root.buttonAnims && nextMA.containsMouse) ? 1.15 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "skip_next"
                            size: 13
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            id: nextMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer) root.activePlayer.next()
                        }
                    }

                    // Device / Volume Icon
                    Item {
                        width: 14; height: 14
                        scale: (root.buttonAnims && devMA.pressed) ? 0.85 : ((root.buttonAnims && devMA.containsMouse) ? 1.15 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                        M3Icon {
                            anchors.centerIn: parent
                            name: "volume_up"
                            size: 11
                            color: "#AEAEB2"
                        }
                        MouseArea {
                            id: devMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    // =====================================================================
    // 2. RIGHT COLUMN: CALENDAR & EVENTS DASHBOARD (245px)
    // =====================================================================
    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 245

        Column {
            anchors.centerIn: parent
            spacing: 3

            // Top Row: Month/Year + 7-Day Horizontal Strip
            Row {
                spacing: 8

                // Month / Year Stack
                Column {
                    spacing: 0
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: root.currentMonthStr
                        font.family: Style.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }
                    Text {
                        text: root.todayDate.getFullYear().toString()
                        font.family: Style.fontFamily
                        font.pixelSize: 9
                        color: "#8E8E93"
                    }
                }

                // 7-Day Horizontal Date Strip
                Row {
                    spacing: 4

                    Repeater {
                        model: root.daysList

                        Rectangle {
                            width: modelData.isToday ? 24 : 20
                            height: 32
                            radius: modelData.isToday ? 7 : 0
                            color: modelData.isToday ? "#007AFF" : "transparent"

                            Column {
                                anchors.centerIn: parent
                                spacing: 1

                                // Day of Week
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.dayName.toUpperCase()
                                    font.family: Style.fontFamily
                                    font.pixelSize: 7
                                    font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                    color: modelData.isToday ? "#FFFFFF" : "#8E8E93"
                                }

                                // Day Number
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.dayNum
                                    font.family: Style.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: modelData.isToday ? "#FFFFFF" : "#AEAEB2"
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Row: Event Status Card
            Row {
                spacing: 6
                anchors.left: parent.left
                anchors.leftMargin: 2

                Rectangle {
                    width: 14; height: 14; radius: 4
                    color: "#2C2C2E"

                    M3Icon {
                        anchors.centerIn: parent
                        name: "calendar_today"
                        size: 10
                        color: "#30D158"
                    }
                }

                Column {
                    spacing: 0

                    Text {
                        text: "No events today"
                        font.family: Style.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }

                    Text {
                        text: "Enjoy your free time!"
                        font.family: Style.fontFamily
                        font.pixelSize: 8
                        color: "#8E8E93"
                    }
                }
            }
        }
    }
}
