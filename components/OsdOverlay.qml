/**
 * OsdOverlay.qml — Volume & Brightness On-Screen Display Overlay for QuickShell Notch
 *
 * Renders the compact OSD popup when triggered via IPC (osd:vol:<0-100> or osd:bri:<0-100>):
 *   - Rotating M3 icon with ±45° spring impulse on brightness adjustments
 *   - Dynamic smooth progress fill bar with animated value interpolation
 *   - Crisp typography percentage readout
 */

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    /** Whether OSD popup is currently visible */
    property bool isOsdActive: false
    /** Material Symbol icon name */
    property string osdIcon: "volume_up"
    /** Target OSD percentage value (0..100) */
    property int osdValue: 50
    /** Spring-interpolated percentage value for smooth bar animations */
    property real animatedOsdValue: root.osdValue
    /** Dynamic accent/warning tint color */
    property color osdColor: Style.accent
    /** Spring-driven icon rotation angle in degrees */
    property real osdIconRotation: 0

    anchors.fill: parent
    opacity: root.isOsdActive ? 1.0 : 0.0
    scale: root.isOsdActive ? 1.0 : 0.92
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }
    Behavior on scale {
        NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutQuad }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 12

        M3Icon {
            name: root.osdIcon
            size: 20
            color: root.osdColor
            Layout.alignment: Qt.AlignVCenter
            rotation: root.osdIconRotation

            Behavior on rotation {
                SpringAnimation {
                    spring: Style.springExpandTension
                    damping: Style.springExpandDamping
                    epsilon: 0.25
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Style.cardBgHover
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                height: parent.height
                width: parent.width * (root.animatedOsdValue / 100.0)
                radius: 3
                color: root.osdColor
            }
        }

        Text {
            text: Math.round(root.animatedOsdValue) + "%"
            font.family: Style.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Style.textPrimary
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 32
        }
    }
}
