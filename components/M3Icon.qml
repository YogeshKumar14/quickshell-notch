/**
 * M3Icon.qml — macOS SF Symbols Vector Icon Renderer
 *
 * Maps icon names, SF Symbol identifiers, and legacy glyphs to local SVG assets:
 *   - Automatically resolves SVG assets relative to component directory
 *   - Applies dynamic ColorOverlay with animated color transitions
 *   - Supports asynchronous SVG rasterization with custom sourceSize constraints
 */

import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"

Item {
    id: root

    /** Icon name (e.g. "volume_up", "settings", "speaker.wave.3.fill") or Unicode glyph */
    property string name: ""
    /** Tint color applied via ColorOverlay */
    property color color: Style.textPrimary
    /** Square dimension in pixels */
    property int size: 24

    implicitWidth: size
    implicitHeight: size

    /** Lookup table mapping legacy glyphs and aliases to SVG asset names */
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
        "󰅙": "error",

        // macOS SF Symbols Aliases
        "play.fill": "play_arrow",
        "pause.fill": "pause",
        "forward.fill": "skip_next",
        "backward.fill": "skip_previous",
        "speaker.wave.3.fill": "volume_up",
        "speaker.wave.1.fill": "volume_down",
        "speaker.slash.fill": "volume_mute",
        "microphone.fill": "mic",
        "microphone.slash.fill": "mic_off",
        "gearshape.fill": "settings",
        "house.fill": "home",
        "tray.fill": "inbox",
        "bell.fill": "notifications",
        "bell": "notifications_none",
        "bell.slash.fill": "notifications_off",
        "clock.fill": "schedule",
        "chart.line.uptrend.xyaxis": "trending_up",
        "10.arrow.trianglehead.counterclockwise": "replay_10",
        "arrow.counterclockwise": "arrow.counterclockwise",
        "clock.arrow.circlepath": "arrow.counterclockwise",
        "arrow_counterclockwise": "arrow.counterclockwise",
        "calendar.badge.checkmark": "calendar.badge.checkmark",
        "calendar_badge_checkmark": "calendar.badge.checkmark",
        "laptopcomputer": "laptopcomputer",
        "eyedropper": "eyedropper",
        "power": "power"
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
