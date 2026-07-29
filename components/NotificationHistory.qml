import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    required property bool isOpen
    required property var notifModel

    property int notifCount: notifModel ? notifModel.count : 0
    property bool isClearing: false
    property int clearIdx: 0

    anchors.fill: parent
    z: 99

    opacity: isOpen ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Timer {
        id: clearTimer
        interval: 80
        repeat: true
        onTriggered: {
            if (root.clearIdx < root.notifModel.count) {
                root.notifModel.remove(root.clearIdx);
                root.notifCount = root.notifModel.count;
            } else {
                root.isClearing = false;
                root.notifCount = 0;
                stop();
            }
        }
    }

    function dismissNotification(index) {
        if (notifModel) {
            notifModel.remove(index);
            root.notifCount = notifModel.count;
        }
    }

    function clearAll() {
        if (notifModel && notifModel.count > 0 && !isClearing) {
            isClearing = true;
            clearIdx = 0;
            clearTimer.start();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Notifications"
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeLarge
                font.weight: Font.Bold
                color: Style.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Clear All Button
            Rectangle {
                width: clearAllText.width + 16
                height: 24
                radius: 12
                color: clearAllM.containsMouse ? Style.cardBgHover : "transparent"
                visible: root.notifCount > 0

                Text {
                    id: clearAllText
                    anchors.centerIn: parent
                    text: "Clear All"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    font.weight: Font.Bold
                    color: Style.accent
                }

                MouseArea {
                    id: clearAllM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAll()
                }
            }
        }

        // Empty State
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            visible: root.notifCount === 0

            Column {
                anchors.centerIn: parent
                spacing: 8

                M3Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "notifications_none"
                    size: 32
                    color: Style.textMuted
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No notifications"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeNormal
                    color: Style.textSecondary
                }
            }
        }

        // Notification List
        ListView {
            id: notifList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.notifModel
            clip: true
            spacing: 4
            visible: root.notifCount > 0

            delegate: Rectangle {
                width: notifList.width
                height: 48
                radius: Style.radiusSmall
                color: notifItemM.containsMouse ? "#121214" : "#0A0A0C"
                border.color: "#222225"
                border.width: 1

                property real dragOffset: 0

                Behavior on dragOffset { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    // App icon or default bell
                    M3Icon {
                        name: "notifications"
                        color: Style.accent
                        size: 16
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: model.summary || "Notification"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            font.weight: Font.Bold
                            color: Style.textPrimary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: model.appName || ""
                            font.family: Style.fontFamily
                            font.pixelSize: 8
                            color: Style.textMuted
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }

                    Text {
                        text: model.timestamp || ""
                        font.family: Style.fontFamily
                        font.pixelSize: 8
                        color: Style.textMuted
                    }
                }

                // Swipe-to-dismiss
                MouseArea {
                    id: notifItemM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    drag.target: undefined
                    drag.axis: Drag.XAxis

                    property real startX: 0
                    property bool swiping: false

                    onPressed: function(mouse) {
                        startX = mouse.x;
                        swiping = false;
                    }

                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            var dx = mouse.x - startX;
                            if (Math.abs(dx) > 10) {
                                swiping = true;
                                dragOffset = dx;
                            }
                        }
                    }

                    onReleased: {
                        if (swiping && Math.abs(dragOffset) > 80) {
                            root.dismissNotification(index);
                        } else {
                            dragOffset = 0;
                        }
                        swiping = false;
                    }

                    onCanceled: {
                        dragOffset = 0;
                        swiping = false;
                    }
                }
            }
        }
    }
}
