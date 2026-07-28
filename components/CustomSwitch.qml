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
            SpringAnimation { spring: 3.0; damping: 0.7; mass: 1.0 }
        }

        scale: mouseArea.pressed ? 1.15 : (mouseArea.containsMouse ? 1.06 : 1.0)

        Behavior on scale {
            SpringAnimation { spring: 4.0; damping: 0.6; mass: 1.0 }
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
