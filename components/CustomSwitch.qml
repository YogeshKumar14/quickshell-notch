/**
 * CustomSwitch.qml — Material 3 Expressive Toggle Switch for QuickShell Notch
 *
 * Provides a tactile toggle switch:
 *   - Spring-animated sliding pill thumb with press/hover physical micro-scaling
 *   - Smooth animated track color transitions (accent active vs dimmed border inactive)
 */

import QtQuick
import "../theme"

Item {
    id: root

    /** Boolean state of the switch */
    property bool checked: false

    /** Emitted when switch state is toggled by user interaction */
    signal toggled(bool newState)

    implicitWidth: 46
    implicitHeight: 26

    // Track
    Rectangle {
        id: track
        anchors.fill: parent
        radius: 13
        color: root.checked ? Style.accent : Style.controlBorder

        Behavior on color {
            ColorAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad }
        }
    }

    // Sliding Pill Thumb
    Rectangle {
        id: thumb
        width: 22
        height: 22
        radius: 11
        color: Style.textPrimary
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
        onClicked: root.toggled(!root.checked)
    }
}
