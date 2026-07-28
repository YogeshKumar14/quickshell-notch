import QtQuick
import QtQuick.Controls.Basic
import "../theme"

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1

    signal moved(real val)

    implicitWidth: 200
    implicitHeight: 22

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

        // Emit the legacy custom signal so SettingsWindow.qml doesn't break
        onMoved: {
            root.moved(control.value)
        }
        
        onPressedChanged: {
            if (!control.pressed) {
                root.moved(control.value)
            }
        }

        scale: control.pressed ? 0.99 : (control.hovered ? 1.005 : 1.0)
        Behavior on scale { SpringAnimation { spring: 4.0; damping: 0.6; mass: 1.0 } }

        background: Rectangle {
            width: control.availableWidth
            height: control.height
            radius: height / 2
            color: Style.cardBgHover

            Rectangle {
                width: Math.max(height, control.visualPosition * parent.width)
                height: parent.height
                color: Style.accent
                radius: height / 2

                Behavior on width {
                    SpringAnimation { spring: 3.5; damping: 0.7; mass: 1.0 }
                }
            }
        }

        handle: Item {}
    }
}
