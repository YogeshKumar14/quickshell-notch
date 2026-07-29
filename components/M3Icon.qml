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

    function getSvgName(inputName) {
        // Map Nerd Font characters to M3 SVG names
        const iconMap = {
            "󰕾": "volume_up",
            "󰖁": "volume_mute",
            "󰝟": "volume_off",
            "󰃠": "light_mode", // Need to download light_mode
            "󰤨": "wifi",
            "󰤯": "wifi_off", // Need to download wifi_off
            "󰖩": "wifi",
            "󰖪": "wifi_off",
            "󰂯": "bluetooth",
            "󰂲": "bluetooth_disabled", // Need to download bluetooth_disabled
            "󰁹": "battery_full",
            "󰁾": "battery_full",
            "󰁻": "battery_alert",
            "󰂎": "battery_alert",
            "󰂄": "battery_charging_full",
            "󰂃": "battery_alert",
            "󰈅": "apps",
            "󰌾": "lock", // Lock icon for wifi password and inhibitor (if applicable)
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
            "󰤄": "coffee", // Sleep mapped to coffee for now
            "󰍃": "logout",
            "󰒓": "settings",
            "󰎆": "music_note",
            "󰅂": "chevron_right",
            "󰈈": "visibility",
            "󰈉": "visibility_off"
        };
        return iconMap[inputName] || inputName;
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
