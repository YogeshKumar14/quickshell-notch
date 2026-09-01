/**
 * AudioMenu.qml — Audio Devices & Volume Drawer for QuickShell Notch
 *
 * Renders the dedicated Audio quick-settings overlay:
 *   - Master Output Volume & Microphone sliders with instant mute toggles
 *   - Audio Output Sinks list with 1-click default device switching
 *   - Audio Input Sources list with active device badges
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    /** Whether Audio menu overlay is currently visible */
    required property bool isOpen

    /** Current volume and mute states */
    property int volumeLevel: 50
    property bool volumeMuted: false
    property int micLevel: 50
    property bool micMuted: false

    /** List of available sinks and sources */
    property var sinks: []
    property var sources: []

    /** Combined device list for ListView binding */
    property var deviceList: {
        var arr = [];
        if (Array.isArray(root.sinks)) {
            for (var i = 0; i < root.sinks.length; i++) arr.push(root.sinks[i]);
        }
        if (Array.isArray(root.sources)) {
            for (var j = 0; j < root.sources.length; j++) arr.push(root.sources[j]);
        }
        return arr;
    }

    /** Emitted when user closes the audio drawer */
    signal closeRequested()
    /** Emitted when volume or device is changed */
    signal volumeChanged(int level)

    anchors.fill: parent
    z: 99

    opacity: isOpen ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Component.onCompleted: root.refresh()

    onIsOpenChanged: {
        if (isOpen) {
            refresh();
        }
    }

    Process {
        id: audioProc
        command: ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.volumeLevel = data.volume !== undefined ? data.volume : root.volumeLevel;
                    root.volumeMuted = data.volume_muted !== undefined ? data.volume_muted : false;
                    root.micLevel = data.mic !== undefined ? data.mic : root.micLevel;
                    root.micMuted = data.mic_muted !== undefined ? data.mic_muted : false;
                    root.sinks = Array.isArray(data.sinks) ? data.sinks : [];
                    root.sources = Array.isArray(data.sources) ? data.sources : [];
                } catch(e) {}
            }
        }
    }

    Process {
        id: audioActionProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.volumeLevel = data.volume !== undefined ? data.volume : root.volumeLevel;
                    root.volumeMuted = data.volume_muted !== undefined ? data.volume_muted : false;
                    root.micLevel = data.mic !== undefined ? data.mic : root.micLevel;
                    root.micMuted = data.mic_muted !== undefined ? data.mic_muted : false;
                    root.sinks = Array.isArray(data.sinks) ? data.sinks : [];
                    root.sources = Array.isArray(data.sources) ? data.sources : [];
                } catch(e) {}
            }
        }
    }

    function refresh() {
        if (!audioProc.running) {
            audioProc.running = true;
        }
    }

    function setVolume(val) {
        audioActionProc.command = ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "set-volume", val.toString()];
        audioActionProc.running = true;
        root.volumeChanged(val);
    }

    function setMic(val) {
        audioActionProc.command = ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "set-mic", val.toString()];
        audioActionProc.running = true;
    }

    function toggleVolumeMute() {
        audioActionProc.command = ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "toggle-volume-mute"];
        audioActionProc.running = true;
    }

    function toggleMicMute() {
        audioActionProc.command = ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "toggle-mic-mute"];
        audioActionProc.running = true;
    }

    function setSink(id) {
        audioActionProc.command = ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "set-sink", id.toString()];
        audioActionProc.running = true;
    }

    function setSource(id) {
        audioActionProc.command = ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "set-source", id.toString()];
        audioActionProc.running = true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Header Row: Icon, Title, and Close Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            M3Icon {
                name: "volume_up"
                size: 16
                color: Style.accent
            }

            Text {
                text: "Audio & Sound Devices"
                font.family: Style.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Style.textPrimary
                Layout.fillWidth: true
            }

            Rectangle {
                width: 20; height: 20; radius: 10
                color: closeMA.containsMouse ? "#2C2C2E" : "transparent"
                smooth: true; antialiasing: true

                M3Icon {
                    anchors.centerIn: parent
                    name: "close"
                    size: 13
                    color: Style.textMuted
                }

                MouseArea {
                    id: closeMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // Main 2-Column Content (Left: Sliders, Right: Sinks & Sources)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Column 1: Volume & Microphone Level Sliders (260px)
            ColumnLayout {
                Layout.preferredWidth: 260
                Layout.fillWidth: false
                Layout.fillHeight: true
                spacing: 8

                // Output Volume Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: "#1C1C1E"
                    border.color: "#2C2C2E"
                    border.width: 1.0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 22; height: 22; radius: 6
                                color: root.volumeMuted ? "#3A1C1C" : "#2C2C2E"
                                border.color: root.volumeMuted ? "#FA2D48" : "transparent"
                                border.width: 1.0

                                M3Icon {
                                    anchors.centerIn: parent
                                    name: root.volumeMuted ? "volume_off" : "volume_up"
                                    size: 12
                                    color: root.volumeMuted ? "#FA2D48" : Style.accent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleVolumeMute()
                                }
                            }

                            Text {
                                text: "Master Volume"
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Style.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: (root.volumeMuted ? "MUTED (" : "") + root.volumeLevel + "%" + (root.volumeMuted ? ")" : "")
                                font.family: Style.fontFamilyMono
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: root.volumeMuted ? "#FA2D48" : Style.textMuted
                            }
                        }

                        CustomSlider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            from: 0; to: 100; stepSize: 1
                            value: root.volumeLevel
                            onMoved: root.setVolume(Math.round(value))
                        }
                    }
                }

                // Microphone Input Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: "#1C1C1E"
                    border.color: "#2C2C2E"
                    border.width: 1.0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 22; height: 22; radius: 6
                                color: root.micMuted ? "#3A1C1C" : "#2C2C2E"
                                border.color: root.micMuted ? "#FA2D48" : "transparent"
                                border.width: 1.0

                                M3Icon {
                                    anchors.centerIn: parent
                                    name: root.micMuted ? "mic_off" : "mic"
                                    size: 12
                                    color: root.micMuted ? "#FA2D48" : "#30D158"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleMicMute()
                                }
                            }

                            Text {
                                text: "Microphone Level"
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Style.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: (root.micMuted ? "MUTED (" : "") + root.micLevel + "%" + (root.micMuted ? ")" : "")
                                font.family: Style.fontFamilyMono
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: root.micMuted ? "#FA2D48" : Style.textMuted
                            }
                        }

                        CustomSlider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            from: 0; to: 100; stepSize: 1
                            value: root.micLevel
                            onMoved: root.setMic(Math.round(value))
                        }
                    }
                }
            }

            // Column 2: Audio Output Sinks & Input Devices List (280px)
            Rectangle {
                Layout.preferredWidth: 280
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: "#1C1C1E"
                border.color: "#2C2C2E"
                border.width: 1.0

                Text {
                    id: devHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 8
                    text: "OUTPUT & INPUT DEVICES (" + root.deviceList.length + ")"
                    font.family: Style.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Style.textMuted
                }

                ListView {
                    id: sinkList
                    anchors.top: devHeader.bottom
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    clip: true
                    spacing: 4
                    model: root.deviceList

                    delegate: Rectangle {
                        width: sinkList.width
                        height: 26
                        radius: 6
                        color: modelData.active ? "#2C2C2E" : (deviceItemMA.containsMouse ? "#242426" : "transparent")
                        border.color: modelData.active ? Style.accent : "transparent"
                        border.width: modelData.active ? 1.0 : 0.0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            M3Icon {
                                name: modelData.name.toLowerCase().indexOf("camera") !== -1 || modelData.name.toLowerCase().indexOf("mic") !== -1
                                    ? "mic"
                                    : (modelData.name.toLowerCase().indexOf("bluetooth") !== -1 || modelData.name.toLowerCase().indexOf("thunder") !== -1 ? "bluetooth" : "volume_up")
                                size: 11
                                color: modelData.active ? Style.accent : Style.textMuted
                            }

                            Text {
                                text: modelData.name
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                font.weight: modelData.active ? Font.Bold : Font.Normal
                                color: modelData.active ? "#FFFFFF" : Style.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 12; height: 12; radius: 6
                                color: Style.accent
                                visible: modelData.active

                                M3Icon {
                                    anchors.centerIn: parent
                                    name: "done"
                                    size: 8
                                    color: "#000000"
                                }
                            }
                        }

                        MouseArea {
                            id: deviceItemMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.name.toLowerCase().indexOf("camera") !== -1 || modelData.name.toLowerCase().indexOf("mic") !== -1) {
                                    root.setSource(modelData.id);
                                } else {
                                    root.setSink(modelData.id);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
