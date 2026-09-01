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

    /** Emitted when user closes the audio drawer */
    signal closeRequested()

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

    function setSink(id) {
        audioActionProc.command = ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "set-sink", id.toString()];
        audioActionProc.running = true;
    }

    function setSource(id) {
        audioActionProc.command = ["python3", Quickshell.shellDir + "/scripts/desktop/manage_audio.py", "set-source", id.toString()];
        audioActionProc.running = true;
    }

    function getSinkIcon(name) {
        var lower = name.toLowerCase();
        if (lower.indexOf("bluetooth") !== -1 || lower.indexOf("thunder") !== -1 || lower.indexOf("airpod") !== -1 || lower.indexOf("buds") !== -1) return "bluetooth";
        if (lower.indexOf("tv") !== -1 || lower.indexOf("hdmi") !== -1 || lower.indexOf("displayport") !== -1) return "desktop_windows";
        return "volume_up";
    }

    function getSourceIcon(name) {
        return "mic";
    }

    // Transparent Background MouseArea to absorb clicks and dismiss on empty area click
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onClicked: root.closeRequested()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Header Row: Icon, Title, Rescan Spinner, and Close Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            M3Icon {
                name: "volume_up"
                size: 15
                color: Style.accent
            }

            Text {
                text: "Audio Output & Input Devices"
                font.family: Style.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Style.textPrimary
                Layout.fillWidth: true
            }

            // Rescan Button with Rotation Animation
            Rectangle {
                width: 20; height: 20; radius: 10
                color: rescanMA.containsMouse ? "#2C2C2E" : "transparent"
                smooth: true; antialiasing: true

                M3Icon {
                    id: rescanIcon
                    anchors.centerIn: parent
                    name: "restart_alt"
                    size: 13
                    color: Style.textMuted
                    transformOrigin: Item.Center

                    RotationAnimation on rotation {
                        running: audioProc.running || audioActionProc.running
                        from: 0; to: 360; loops: Animation.Infinite; duration: 900
                        onRunningChanged: {
                            if (!running) rescanIcon.rotation = 0;
                        }
                    }
                }

                MouseArea {
                    id: rescanMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refresh()
                }
            }

            // Close Button
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

        // Main 2-Column Device Routing Grid
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // =================================================================
            // COLUMN 1: OUTPUT SINKS (Speakers, Headphones, DACs)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: "#1C1C1E"
                border.color: "#2C2C2E"
                border.width: 1.0

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // Section Title
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        M3Icon {
                            name: "volume_up"
                            size: 11
                            color: Style.accent
                        }

                        Text {
                            text: "OUTPUT (" + root.sinks.length + ")"
                            font.family: Style.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: Style.textMuted
                            Layout.fillWidth: true
                        }
                    }

                    // Sinks List
                    ListView {
                        id: sinkListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: root.sinks

                        delegate: Rectangle {
                            width: sinkListView.width
                            height: 28
                            radius: 7
                            color: modelData.active ? "#2C2C2E" : (sinkItemMA.containsMouse ? "#242426" : "#141416")
                            border.color: modelData.active ? Style.accent : "#222224"
                            border.width: 1.0
                            smooth: true; antialiasing: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 7

                                M3Icon {
                                    name: root.getSinkIcon(modelData.name)
                                    size: 12
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
                                    width: 14; height: 14; radius: 7
                                    color: Style.accent
                                    visible: modelData.active
                                    smooth: true; antialiasing: true

                                    M3Icon {
                                        anchors.centerIn: parent
                                        name: "done"
                                        size: 9
                                        color: "#000000"
                                    }
                                }
                            }

                            MouseArea {
                                id: sinkItemMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setSink(modelData.id)
                            }
                        }
                    }
                }
            }

            // =================================================================
            // COLUMN 2: INPUT SOURCES (Microphones, Cameras)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: "#1C1C1E"
                border.color: "#2C2C2E"
                border.width: 1.0

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // Section Title
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        M3Icon {
                            name: "mic"
                            size: 11
                            color: "#30D158"
                        }

                        Text {
                            text: "INPUT (" + root.sources.length + ")"
                            font.family: Style.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: Style.textMuted
                            Layout.fillWidth: true
                        }
                    }

                    // Sources List
                    ListView {
                        id: sourceListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: root.sources

                        delegate: Rectangle {
                            width: sourceListView.width
                            height: 28
                            radius: 7
                            color: modelData.active ? "#2C2C2E" : (sourceItemMA.containsMouse ? "#242426" : "#141416")
                            border.color: modelData.active ? Style.accent : "#222224"
                            border.width: 1.0
                            smooth: true; antialiasing: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 7

                                M3Icon {
                                    name: root.getSourceIcon(modelData.name)
                                    size: 12
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
                                    width: 14; height: 14; radius: 7
                                    color: Style.accent
                                    visible: modelData.active
                                    smooth: true; antialiasing: true

                                    M3Icon {
                                        anchors.centerIn: parent
                                        name: "done"
                                        size: 9
                                        color: "#000000"
                                    }
                                }
                            }

                            MouseArea {
                                id: sourceItemMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setSource(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
