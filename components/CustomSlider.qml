/**
 * CustomSlider.qml — Material 3 Expressive Pill Slider for QuickShell Notch
 *
 * Provides a fluid, rounded pill slider control:
 *   - Continuous drag tracking with interactive spring micro-scaling
 *   - Smooth animated fill bar when synchronized programmatically
 *   - Clean two-way binding that prevents slider jitter while dragging
 */

import QtQuick
import QtQuick.Controls.Basic
import "../theme"

Item {
    id: root

    /** Current slider position value */
    property real value: 0
    /** Minimum slider range value */
    property real from: 0
    /** Maximum slider range value */
    property real to: 100
    /** Granularity increment for step snaps */
    property real stepSize: 1
    /** Height of the track in pixels */
    property int trackHeight: 8

    /** Emitted when slider value changes via user interaction */
    signal moved(real val)

    implicitWidth: 200
    implicitHeight: 20

    Slider {
        id: control
        anchors.fill: parent

        from: root.from
        to: root.to
        stepSize: root.stepSize

        // Sync from system ONLY when the user is not holding the slider
        Binding {
            target: control
            property: "value"
            value: root.value
            when: !control.pressed
        }

        onMoved: {
            root.moved(control.value)
        }

        onPressedChanged: {
            if (!control.pressed) {
                root.moved(control.value)
            }
        }

        scale: control.pressed ? 0.98 : (control.hovered ? 1.01 : 1.0)
        Behavior on scale { SpringAnimation { spring: 5.0; damping: 0.3 } }

        background: Rectangle {
            width: control.availableWidth
            height: root.trackHeight
            radius: root.trackHeight / 2
            anchors.centerIn: parent
            color: "#2C2C2E"

            Rectangle {
                width: Math.max(height, control.visualPosition * parent.width)
                height: parent.height
                color: Style.accent
                radius: height / 2

                Behavior on width {
                    enabled: !control.pressed
                    SpringAnimation { spring: 4.0; damping: 0.3 }
                }
            }
        }

        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: "#FFFFFF"
            border.color: "#000000"
            border.width: 1.5

            scale: control.pressed ? 1.25 : (control.hovered ? 1.15 : 1.0)
            Behavior on scale { SpringAnimation { spring: 5.5; damping: 0.25 } }
        }
    }
}
