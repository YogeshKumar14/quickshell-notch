import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    required property bool isOpen
    property bool btPower: false
    property var btDevices: []

    anchors.fill: parent
    z: 99

    opacity: isOpen ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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
        id: btToggler
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.btPower = data.power;
                    root.btDevices = data.devices;
                } catch(e) {}
                scanTimer.restart();
            }
        }
    }

    Timer {
        id: scanTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: btScanner.running = true
    }

    Timer {
        id: autoScanTimer
        interval: 5000
        running: root.isOpen
        repeat: true
        onTriggered: btScanner.running = true
    }

    function toggleConnection(mac) {
        btToggler.running = false;
        btToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_bluetooth.py", "toggle_conn", mac];
        btToggler.running = true;
    }

    function togglePower(val) {
        root.btPower = val;
        btToggler.running = false;
        btToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_bluetooth.py", val ? "on" : "off"];
        btToggler.running = true;
    }

    function rescan() {
        btScanner.running = false;
        btScanner.running = true;
    }

    Component.onCompleted: btScanner.running = true

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

            Rectangle {
                width: 24; height: 24; radius: 12
                color: btRefM.containsMouse ? Style.cardBgHover : Style.cardBg
                border.color: Style.cardBorder
                visible: root.btPower
                M3Icon {
                    id: btRefText
                    anchors.centerIn: parent
                    name: "restart_alt"
                    size: 14
                    color: Style.textPrimary

                    transformOrigin: Item.Center
                    RotationAnimation on rotation {
                        running: btScanner.running || btToggler.running
                        from: 0; to: 360; loops: Animation.Infinite; duration: 1000
                        onRunningChanged: {
                            if (!running) btRefText.rotation = 0;
                        }
                    }
                }
                MouseArea {
                    id: btRefM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.rescan()
                }
            }

            CustomSwitch {
                checked: root.btPower
                onToggled: function(val) {
                    root.togglePower(val);
                }
            }
        }

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
                M3Icon {
                    id: btActiveIcon
                    name: "restart_alt"
                    color: Style.accent; size: 16
                    transformOrigin: Item.Center
                    RotationAnimation on rotation {
                        running: btToggler.running
                        from: 0; to: 360; loops: Animation.Infinite; duration: 1000
                        onRunningChanged: {
                            if (!running) btActiveIcon.rotation = 0;
                        }
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
                M3Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: !root.btPower ? "bluetooth_disabled" : "restart_alt"
                    size: 32
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

                    M3Icon {
                        name: "bluetooth"
                        color: modelData.connected ? Style.accent : Style.textSecondary
                        size: 16
                    }

                    Text {
                        text: modelData.name
                        font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall
                        color: Style.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    M3Icon {
                        name: modelData.connected ? "done" : ""
                        color: Style.accent
                        size: 16
                    }
                }

                MouseArea {
                    id: devM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleConnection(modelData.mac)
                }
            }
        }
    }
}
