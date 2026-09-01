/**
 * M3Icon.qml — Material Symbols Rounded Vector Icon Renderer
 *
 * Maps icon names and legacy Nerd Font glyphs to local SVG assets:
 *   - Automatically resolves SVG assets relative to component directory
 *   - Applies dynamic ColorOverlay with animated color transitions
 *   - Supports asynchronous SVG rasterization with custom sourceSize constraints
 */

import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"

Item {
    id: root

    /** Icon name (e.g. "volume_up", "settings") or Nerd Font Unicode glyph */
    property string name: ""
    /** Tint color applied via ColorOverlay */
    property color color: Style.textPrimary
    /** Square dimension in pixels */
    property int size: 24

    implicitWidth: size
    implicitHeight: size

    /** Lookup table mapping legacy Nerd Font glyphs to SVG asset names */
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

    /** Returns resolved SVG basename for a given input glyph/name */
    function getSvgName(inputName) {
        return (root.iconMap && root.iconMap[inputName]) || inputName;
    }

    Image {
        id: img
        anchors.fill: parent
        source: name !== "" ? Qt.resolvedUrl("../assets/icons/" + getSvgName(name) + ".svg") : ""
        sourceSize: Qt.size(Math.max(24, Math.min(64, size * 2)), Math.max(24, Math.min(64, size * 2)))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        antialiasing: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: img
        source: img
        color: root.color
        smooth: true
        antialiasing: true
        visible: img.status === Image.Ready

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
