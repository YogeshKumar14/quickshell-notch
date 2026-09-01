/**
 * StatusBar.qml — Expanded Notch Header Bar & Quick Actions for QuickShell Notch
 *
 * Renders the top header row of the expanded notch:
 *   - M3 Segmented Button Tab Switcher ("Media", "Walls", "Apps", "Stats") with spring sliding highlight
 *   - Modern iOS-style dynamic micro-battery capsule with charging bolt & 4-tier color palette
 *   - Quick-action buttons: Wi-Fi, Bluetooth, Notification Bell with badge, Power, Settings
 */

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    /** Currently active tab index (0=Media, 1=Walls, 2=Apps, 3=Stats) */
    property int currentPage: 0
    /** Spring tension for tab highlight sliding */
    property real tabSpringTension: 5.5
    /** Spring damping for tab highlight sliding */
    property real tabSpringDamping: 0.22
    /** Micro-interaction animation duration in milliseconds */
    property int buttonSpeed: 180
    /** Whether button scale micro-animations are enabled */
    property bool buttonAnims: true

    /** Current battery percentage (0..100) */
    property int batteryLevel: 100
    /** Current battery status string ("Charging", "Discharging", "Full") */
    property string batteryStatus: "Discharging"
    /** Battery low-power warning threshold percentage */
    property int batteryWarningThreshold: 20

    /** Current Wi-Fi power state */
    property bool wifiPower: true
    /** Whether Wi-Fi sub-menu overlay is open */
    property bool isWifiMenuOpen: false

    /** Current Bluetooth power state */
    property bool btPower: false
    /** Whether Bluetooth sub-menu overlay is open */
    property bool isBluetoothMenuOpen: false

    /** Unread notification badge count */
    property int notifCount: 0
    /** Whether notification history drawer is open */
    property bool isNotifMenuOpen: false

    /** Whether power confirmation menu is open */
    property bool isPowerMenuOpen: false

    /** Helper function determining battery color per iOS guidelines */
    function getBatteryColor(level, status, warningThreshold) {
        if (level <= 10) return Style.iosRed;
        if (level <= warningThreshold) return Style.iosYellow;
        return Style.textPrimary;
    }

    /** Emitted when user selects a tab */
    signal tabSelected(int index)
    /** Emitted when user toggles Wi-Fi menu */
    signal wifiToggled()
    /** Emitted when user toggles Bluetooth menu */
    signal bluetoothToggled()
    /** Emitted when user toggles Notification menu */
    signal notifToggled()
    /** Emitted when user toggles Power menu */
    signal powerToggled()
    /** Emitted when user clicks Settings gear */
    signal settingsClicked()

    implicitHeight: 20

    // Center Hardware Camera Privacy Indicator Dot (Exact Mathematical Center of Notch)
    Rectangle {
        anchors.centerIn: parent
        width: 4; height: 4; radius: 2
        color: "#22C55E"
        opacity: 0.95
        z: 10

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: true
            NumberAnimation { from: 0.95; to: 0.4; duration: 1200; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.4; to: 0.95; duration: 1200; easing.type: Easing.InOutQuad }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 6

        // Minimal Borderless Tab Switcher (Matching Reference)
        Row {
            id: tabRow
            spacing: 12
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                id: tabRepeater
                model: [ "home", "inbox", "wallpaper", "trending_up" ]

                Item {
                    width: 16
                    height: 16

                    property bool isSelected: root.currentPage === index
                    property bool isHovered: tabMouse.containsMouse

                    scale: (root.buttonAnims && tabMouse.pressed) ? 0.85 : ((root.buttonAnims && (isSelected || isHovered)) ? 1.15 : 1.0)
                    Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

                    M3Icon {
                        anchors.centerIn: parent
                        name: modelData
                        size: 13
                        color: isSelected ? "#FFFFFF" : (isHovered ? "#E5E5EA" : "#7C7C80")
                        Behavior on color { ColorAnimation { duration: root.buttonSpeed; easing.type: Easing.OutQuad } }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabSelected(index)
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

    // Modern M3 Expressive Dynamic Battery Capsule
    RowLayout {
        spacing: 4
        Layout.rightMargin: 2
        Layout.alignment: Qt.AlignVCenter

        readonly property color batColor: root.getBatteryColor(root.batteryLevel, root.batteryStatus, root.batteryWarningThreshold)

        // Rounded Battery Capsule
        Item {
            implicitWidth: 20
            implicitHeight: 11
            Layout.alignment: Qt.AlignVCenter

            // Outer Pill Body
            Rectangle {
                id: batBody
                width: 17
                height: 9.5
                radius: 3
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                border.color: parent.parent.batColor
                border.width: 1.0

                Behavior on border.color { ColorAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad } }

                // Fluid Inner Fill Bar
                Rectangle {
                    id: batFill
                    x: 1.2
                    y: 1.2
                    height: parent.height - 2.4
                    width: Math.max(0, Math.min(parent.width - 2.4, (parent.width - 2.4) * (root.batteryLevel / 100.0)))
                    radius: 1.5
                    color: parent.parent.parent.batColor
                    opacity: root.batteryStatus === "Charging" ? 0.45 : 0.90

                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad } }
                }

                // Centered Yellow Bolt Icon when Charging
                M3Icon {
                    name: "bolt"
                    size: 8
                    color: Style.iosYellow
                    visible: root.batteryStatus === "Charging"
                    anchors.centerIn: parent
                    z: 5
                }
            }

            // Positive Terminal Cap
            Rectangle {
                anchors.left: batBody.right
                anchors.leftMargin: 0.8
                anchors.verticalCenter: batBody.verticalCenter
                width: 1.2
                height: 3.5
                radius: 0.6
                color: parent.parent.batColor

                Behavior on color { ColorAnimation { duration: Style.animNormal; easing.type: Easing.OutQuad } }
            }
        }

        // Crisp White Percentage Text
        Text {
            text: root.batteryLevel + "%"
            font.family: Style.fontFamilyMono
            font.pixelSize: 9
            font.weight: Font.Bold
            color: Style.textPrimary
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // WiFi Status Button (Borderless Glyph)
    Item {
        width: 14; height: 16
        scale: (root.buttonAnims && wifiM.pressed) ? 0.85 : ((root.buttonAnims && wifiM.containsMouse) ? 1.15 : 1.0)
        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

        M3Icon {
            anchors.centerIn: parent
            name: root.wifiPower ? "wifi" : "wifi_off"
            size: 13
            color: root.isWifiMenuOpen ? Style.accent : (wifiM.containsMouse ? "#FFFFFF" : (root.wifiPower ? "#AEAEB2" : "#636366"))
            Behavior on color { ColorAnimation { duration: root.buttonSpeed; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            id: wifiM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.wifiToggled()
        }
    }

    // Bluetooth Status Button (Borderless Glyph)
    Item {
        width: 14; height: 16
        scale: (root.buttonAnims && btM.pressed) ? 0.85 : ((root.buttonAnims && btM.containsMouse) ? 1.15 : 1.0)
        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

        M3Icon {
            anchors.centerIn: parent
            name: root.btPower ? "bluetooth" : "bluetooth_disabled"
            size: 13
            color: root.isBluetoothMenuOpen ? Style.accent : (btM.containsMouse ? "#FFFFFF" : (root.btPower ? "#AEAEB2" : "#636366"))
            Behavior on color { ColorAnimation { duration: root.buttonSpeed; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            id: btM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.bluetoothToggled()
        }
    }

    // Notification Bell Icon (Borderless Glyph)
    Item {
        width: 14; height: 16
        scale: (root.buttonAnims && notifM.pressed) ? 0.85 : ((root.buttonAnims && notifM.containsMouse) ? 1.15 : 1.0)
        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

        M3Icon {
            anchors.centerIn: parent
            name: "notifications"
            size: 13
            color: root.isNotifMenuOpen ? Style.accent : (notifM.containsMouse ? "#FFFFFF" : (root.notifCount > 0 ? Style.accent : "#AEAEB2"))
            Behavior on color { ColorAnimation { duration: root.buttonSpeed; easing.type: Easing.OutQuad } }
        }

        // Notification count badge with spring entrance pop
        Rectangle {
            visible: root.notifCount > 0
            scale: root.notifCount > 0 ? 1.0 : 0.0
            Behavior on scale { SpringAnimation { spring: 6.0; damping: 0.4 } }
            width: 8; height: 8; radius: 4
            color: Style.accent
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 0
            anchors.rightMargin: -2

            Text {
                anchors.centerIn: parent
                text: root.notifCount > 9 ? "9+" : root.notifCount.toString()
                font.family: Style.fontFamily
                font.pixelSize: 6
                font.weight: Font.Bold
                color: Style.textOnAccent
            }
        }

        MouseArea {
            id: notifM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.notifToggled()
        }
    }

    // Power Button (Borderless Glyph)
    Item {
        width: 14; height: 16
        scale: (root.buttonAnims && powerM.pressed) ? 0.85 : ((root.buttonAnims && powerM.containsMouse) ? 1.15 : 1.0)
        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

        M3Icon {
            anchors.centerIn: parent
            name: "power_settings_new"
            size: 13
            color: root.isPowerMenuOpen ? Style.danger : (powerM.containsMouse ? Style.danger : "#AEAEB2")
            Behavior on color { ColorAnimation { duration: root.buttonSpeed; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            id: powerM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.powerToggled()
        }
    }

    // Settings Gear Icon (Borderless Glyph)
    Item {
        width: 14; height: 16
        scale: (root.buttonAnims && gearM.pressed) ? 0.85 : ((root.buttonAnims && gearM.containsMouse) ? 1.15 : 1.0)
        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }

        M3Icon {
            anchors.centerIn: parent
            name: "settings"
            size: 13
            color: gearM.containsMouse ? "#FFFFFF" : "#AEAEB2"
            Behavior on color { ColorAnimation { duration: root.buttonSpeed; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            id: gearM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.settingsClicked()
        }
    }
}
}
