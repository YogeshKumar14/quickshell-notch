import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    required property bool isOpen
    required property ListModel notifModel

    signal closeRequested()

    property int notifCount: notifModel ? notifModel.count : 0
    property bool isClearing: false
    property int expandedIndex: -1
    property int expandedExtraHeight: 0
    property real expandSpringTension: 4.5
    property real expandSpringDamping: 0.28

    anchors.fill: parent
    z: 99

    // Swallow clicks outside interactive children so they don't fall through
    // to the compact notch click area while the stack is open
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.ArrowCursor
        onClicked: root.closeRequested()
    }

    opacity: isOpen ? 1.0 : 0.0
    visible: isOpen || opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    onIsOpenChanged: {
        if (!isOpen) {
            expandedIndex = -1;
            expandedExtraHeight = 0;
        }
    }

    Timer {
        id: clearTimer
        interval: 180
        repeat: true
        onTriggered: {
            if (root.notifModel.count > 0) {
                root.notifModel.remove(0);
            } else {
                root.isClearing = false;
                stop();
            }
        }
    }

    function dismissNotification(index) {
        if (root.expandedIndex === index) {
            root.expandedIndex = -1;
            root.expandedExtraHeight = 0;
        }
        if (notifModel) {
            notifModel.remove(index);
        }
    }

    function clearAll() {
        if (notifModel && notifModel.count > 0 && !isClearing) {
            root.expandedIndex = -1;
            root.expandedExtraHeight = 0;
            isClearing = true;
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

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "x"; to: 60; duration: 150; easing.type: Easing.OutCubic }
                }
            }

            displaced: Transition {
                SpringAnimation {
                    properties: "y"
                    spring: root.expandSpringTension
                    damping: root.expandSpringDamping
                    epsilon: 0.25
                }
            }

            delegate: Rectangle {
                id: notifDelegate
                width: notifList.width
                height: isExpanded ? Math.max(56, delegateContent.implicitHeight + 16) : 56
                radius: Style.radiusSmall
                color: notifItemM.containsMouse ? "#121214" : "#0A0A0C"
                border.color: isExpanded ? Style.accent : "#222225"
                border.width: 1
                clip: true

                property bool isExpanded: root.expandedIndex === index
                property real dragOffset: 0
                x: dragOffset

                onIsExpandedChanged: {
                    if (isExpanded) {
                        root.expandedExtraHeight = Math.max(0, delegateContent.implicitHeight + 16 - 56);
                    }
                }

                Behavior on height {
                    SpringAnimation {
                        spring: root.expandSpringTension
                        damping: root.expandSpringDamping
                        epsilon: 0.25
                    }
                }
                Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on dragOffset {
                    enabled: !notifItemM.dragActive
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    id: delegateContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    onImplicitHeightChanged: {
                        if (notifDelegate.isExpanded) {
                            root.expandedExtraHeight = Math.max(0, delegateContent.implicitHeight + 16 - 56);
                        }
                    }

                    // App icon or default bell
                    M3Icon {
                        name: "notifications"
                        color: Style.accent
                        size: 16
                        Layout.alignment: Qt.AlignTop
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
                            text: model.body || ""
                            font.family: Style.fontFamily
                            font.pixelSize: 9
                            color: Style.textSecondary
                            Layout.fillWidth: true
                            wrapMode: notifDelegate.isExpanded ? Text.WordWrap : Text.NoWrap
                            elide: notifDelegate.isExpanded ? Text.ElideNone : Text.ElideRight
                            maximumLineCount: notifDelegate.isExpanded ? -1 : 1
                            visible: text !== ""
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
                        Layout.alignment: Qt.AlignTop
                    }

                    // Quick dismiss button on hover
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: closeBtnM.containsMouse ? Style.cardBgHover : "transparent"
                        visible: notifItemM.containsMouse && !notifItemM.dragActive
                        Layout.alignment: Qt.AlignTop

                        M3Icon {
                            anchors.centerIn: parent
                            name: "close"
                            size: 12
                            color: closeBtnM.containsMouse ? Style.danger : Style.textMuted
                        }

                        MouseArea {
                            id: closeBtnM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dismissNotification(index)
                        }
                    }
                }

                // Swipe-to-dismiss + click-to-expand
                MouseArea {
                    id: notifItemM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: notifItemM.dragActive ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                    property real startGlobalX: 0
                    property bool dragActive: false

                    onPressed: function(mouse) {
                        var pt = mapToItem(notifList, mouse.x, mouse.y);
                        startGlobalX = pt.x;
                        dragActive = false;
                    }

                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            var pt = mapToItem(notifList, mouse.x, mouse.y);
                            var deltaX = pt.x - startGlobalX;
                            if (Math.abs(deltaX) > 15) {
                                dragActive = true;
                                notifDelegate.dragOffset = deltaX;
                            }
                        }
                    }

                    onReleased: {
                        if (dragActive) {
                            if (Math.abs(notifDelegate.dragOffset) > 80) {
                                root.dismissNotification(index);
                            } else {
                                notifDelegate.dragOffset = 0;
                            }
                            dragActive = false;
                        } else {
                            if (root.expandedIndex === index) {
                                root.expandedIndex = -1;
                                root.expandedExtraHeight = 0;
                            } else {
                                root.expandedIndex = index;
                                notifList.positionViewAtIndex(index, ListView.Contain);
                            }
                        }
                    }

                    onCanceled: {
                        notifDelegate.dragOffset = 0;
                        dragActive = false;
                    }
                }
            }
        }
    }
}
