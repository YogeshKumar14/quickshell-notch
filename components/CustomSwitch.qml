import QtQuick
import "../theme"

Item {
    id: root

    property bool checked: false
    signal toggled(bool newState)

    implicitWidth: 46
    implicitHeight: 26

    // Track
    Rectangle {
        id: track
        anchors.fill: parent
        radius: 13
        color: root.checked ? Style.accent : "#3A3A3C"

        Behavior on color {
            ColorAnimation { duration: 180 }
        }
    }

    // Sliding Pill Thumb
    Rectangle {
        id: thumb
        width: 22
        height: 22
        radius: 11
        color: "#FFFFFF"
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 2 : 2

        Behavior on x {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        scale: mouseArea.pressed ? 1.15 : (mouseArea.containsMouse ? 1.06 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
