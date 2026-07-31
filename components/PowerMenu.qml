import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    required property bool isOpen
    property bool isConfirming: false
    property int selectedIndex: 0
    property string pendingTitle: ""
    property int countdown: 5
    property string pendingCmd: ""

    signal triggered(string title, string cmd)
    signal cancelled()
    signal executed()

    anchors.fill: parent
    z: 99

    opacity: isOpen ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    onIsOpenChanged: {
        if (!root.isOpen) {
            countdownTimer.stop();
            root.isConfirming = false;
        }
    }

    Process {
        id: powerProc
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: root.isConfirming
        onTriggered: {
            if (root.countdown > 1) {
                root.countdown -= 1;
            } else {
                countdownTimer.stop();
                root.execute();
            }
        }
    }

    function trigger(title, cmd) {
        root.pendingTitle = title;
        root.pendingCmd = cmd;
        root.countdown = 5;
        root.isConfirming = true;
        countdownTimer.restart();
    }

    function execute() {
        if (!root.isOpen) return;
        if (root.pendingCmd !== "") {
            powerProc.command = ["bash", "-c", root.pendingCmd];
            powerProc.running = true;
        }
        root.isConfirming = false;
        root.executed();
    }

    function cancel() {
        countdownTimer.stop();
        root.isConfirming = false;
        root.cancelled();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.isConfirming ? "Confirm Action" : "Power Options"
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeLarge
            font.weight: Font.Bold
            color: Style.textPrimary
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                opacity: root.isConfirming ? 0.0 : 1.0
                scale: root.isConfirming ? 0.94 : 1.0
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
                        color: index === root.selectedIndex ? "#1C1C1E" : (pCardM.containsMouse ? "#121214" : "#0D0D0F")
                        border.color: index === root.selectedIndex ? modelData.color : "#222225"
                        border.width: index === root.selectedIndex ? 2 : 1
                        scale: index === root.selectedIndex ? 1.04 : 1.0

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 38; height: 38; radius: 19
                                color: Qt.alpha(modelData.color, index === root.selectedIndex ? 0.25 : 0.15)
                                border.color: Qt.alpha(modelData.color, 0.4)
                                border.width: 1

                                M3Icon {
                                    anchors.centerIn: parent
                                    name: modelData.icon
                                    size: 24
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
                            onEntered: root.selectedIndex = index
                            onClicked: root.trigger(modelData.title, modelData.cmd)
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                Layout.alignment: Qt.AlignCenter
                spacing: 12

                opacity: root.isConfirming ? 1.0 : 0.0
                scale: root.isConfirming ? 1.0 : 1.06
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.pendingTitle + "?"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeTitle
                    font.weight: Font.Bold
                    color: Style.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Executing in " + root.countdown + "s"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeNormal
                    color: Style.accent
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

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
                            onClicked: root.cancel()
                        }
                    }

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
                            onClicked: root.execute()
                        }
                    }
                }
            }
        }
    }
}
