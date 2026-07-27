import QtQuick
import "../theme"

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1

    signal moved(real val)

    implicitWidth: 200
    implicitHeight: 24

    // Background Track
    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: "#2C2C2E"

        // Active Accent Fill
        Rectangle {
            height: parent.height
            width: {
                var span = root.to > root.from ? (root.to - root.from) : 1.0;
                return Math.max(0, Math.min(track.width, ((root.value - root.from) / span) * track.width));
            }
            radius: 3
            color: Style.accent
        }
    }

    // White Pill Thumb Handle
    Rectangle {
        id: handle
        width: 16
        height: 16
        radius: 8
        color: "#FFFFFF"
        anchors.verticalCenter: parent.verticalCenter
        x: {
            var span = root.to > root.from ? (root.to - root.from) : 1.0;
            return Math.max(0, Math.min(track.width - width, ((root.value - root.from) / span) * (track.width - width)));
        }

        border.color: sliderMouse.containsMouse ? Style.accent : "#2C2C2E"
        border.width: 1

        scale: sliderMouse.pressed ? 1.25 : (sliderMouse.containsMouse ? 1.15 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: sliderMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateValue(mouseX) {
            var span = root.to > root.from ? (root.to - root.from) : 1.0;
            var ratio = Math.max(0, Math.min(1, mouseX / root.width));
            var rawVal = root.from + ratio * span;
            if (root.stepSize > 0) {
                rawVal = Math.round((rawVal - root.from) / root.stepSize) * root.stepSize + root.from;
            }
            rawVal = Math.max(root.from, Math.min(root.to, rawVal));
            root.value = rawVal;
            root.moved(root.value);
        }

        onPressed: function(mouse) {
            updateValue(mouse.x);
        }

        onPositionChanged: function(mouse) {
            if (pressed) {
                updateValue(mouse.x);
            }
        }
    }
}
