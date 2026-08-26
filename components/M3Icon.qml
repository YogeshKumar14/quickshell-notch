import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"

Item {
    id: root
    property string name: ""
    property color color: Style.textPrimary
    property int size: 24

    implicitWidth: size
    implicitHeight: size

    readonly property var iconMap: ({
        "󰕾": "volume_up",
        "󰖁": "volume_mute",
        "󰝟": "volume_off",
        "󰃠": "light_mode",
        "󰤨": "wifi",
        "󰤯": "wifi_off",
        "󰖩": "wifi",
        "󰖪": "wifi_off",
        "󰂯": "bluetooth",
        "󰂲": "bluetooth_disabled",
        "󰁹": "battery_full",
        "󰁾": "battery_full",
        "󰁻": "battery_alert",
        "󰂎": "battery_alert",
        "󰂄": "battery_charging_full",
        "󰂃": "battery_alert",
        "󰈅": "apps",
        "󰌾": "lock",
        "󰄬": "done",
        "󰒮": "skip_previous",
        "󰏤": "pause",
        "󰐊": "play_arrow",
        "󰒭": "skip_next",
        "󰍬": "mic",
        "󰍭": "mic_off",
        "󰻠": "memory",
        "󰍛": "memory",
        "󰈀": "wifi",
        "󰋊": "hard_drive",
        "󰂚": "notifications",
        "󰂜": "notifications",
        "󰂛": "notifications_off",
        "󰍉": "search",
        "󰸉": "wallpaper",
        "󰐥": "power_settings_new",
        "󰑐": "restart_alt",
        "󰤄": "coffee",
        "󰍃": "logout",
        "󰒓": "settings",
        "󰎆": "music_note",
        "󰅂": "chevron_right",
        "󰈈": "visibility",
        "󰈉": "visibility_off",
        "󰅖": "close",
        "󰅙": "error"
    })

    function getSvgName(inputName) {
        return (root.iconMap && root.iconMap[inputName]) || inputName;
    }

    Image {
        id: img
        anchors.fill: parent
        source: name !== "" ? "file:///home/yogesh/.config/quickshell/assets/icons/" + getSvgName(name) + ".svg" : ""
        sourceSize: Qt.size(size, size)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: img
        source: img
        color: root.color
        visible: img.status === Image.Ready
        
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
