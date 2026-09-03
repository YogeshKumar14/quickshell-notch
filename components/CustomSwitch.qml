/**
 * CustomSwitch.qml — macOS Toggle Switch for QuickShell Notch
 *
 * Provides an authentic Apple-style toggle switch:
 *   - Spring-animated sliding circular knob with tactile micro-scaling
 *   - Smooth animated track transitions (Wallust System Accent when active vs dark gray #39393D inactive)
 */

import QtQuick
import "../theme"

Item {
    id: root

    /** Boolean state of the switch */
    property bool checked: false

    /** Emitted when switch state is toggled by user interaction */
    signal toggled(bool newState)

    implicitWidth: 42
    implicitHeight: 24

    // Track
    Rectangle {
        id: track
        anchors.fill: parent
        radius: 12
        color: root.checked ? Style.accent : "#39393D"

        Behavior on color {
            ColorAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad }
        }
    }

    // Sliding Circular Thumb Knob
    Rectangle {
        id: thumb
        width: 20
        height: 20
        radius: 10
        color: "#FFFFFF"
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 2 : 2

        Behavior on x {
            SpringAnimation { spring: 3.5; damping: 0.65; mass: 1.0 }
        }

        scale: mouseArea.pressed ? 1.10 : (mouseArea.containsMouse ? 1.05 : 1.0)

        Behavior on scale {
            SpringAnimation { spring: 4.5; damping: 0.5; mass: 1.0 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
