/**
 * M3Icon.qml — macOS SF Symbols Vector Icon Renderer
 *
 * Maps icon names, SF Symbol identifiers, and legacy glyphs to local SVG assets:
 *   - Automatically resolves SVG assets relative to component directory
 *   - Applies dynamic ColorOverlay with animated color transitions
 *   - High-fidelity vector SVG rendering without box-filter mipmap blurring
 *   - Clean single-FBO ColorOverlay pipeline with dynamic color transitions
 *   - Native vector resolution for UI icons with auto-scaling for sizes > 48px
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

        // macOS SF Symbols Aliases & Official Symbol Mappings
        "play.fill": "play_arrow",
        "play": "play_arrow",
        "pause.fill": "pause",
        "forward.fill": "skip_next",
        "backward.fill": "skip_previous",
        "forward.end.fill": "forward.end.fill",
        "backward.end.fill": "backward.end.fill",
        "fast_forward": "forward.end.fill",
        "fast_rewind": "backward.end.fill",
        "speaker": "speaker",
        "speaker.fill": "speaker.fill",
        "speaker.wave.3.fill": "volume_up",
        "speaker.wave.2.fill": "speaker.wave.2.fill",
        "speaker.wave.1.fill": "volume_down",
        "speaker.slash.fill": "volume_mute",
        "headphones": "headphones",
        "airpods": "airpods",
        "microphone.fill": "mic",
        "microphone.slash.fill": "mic_off",
        "gearshape.fill": "settings",
        "gearshape": "settings",
        "house.fill": "home",
        "tray.fill": "inbox",
        "square.grid.2x2.fill": "apps",
        "square.grid.2x2": "space_dashboard",
        "bell.fill": "notifications",
        "bell": "notifications_none",
        "bell.slash.fill": "notifications_off",
        "clock.fill": "schedule",
        "timer": "timer",
        "chart.line.uptrend.xyaxis": "trending_up",
        "chart.xyaxis.line": "monitoring",
        "10.arrow.trianglehead.counterclockwise": "replay_10",
        "gobackward.10": "replay_10",
        "arrow.clockwise": "restart_alt",
        "arrow.counterclockwise": "arrow.counterclockwise",
        "clock.arrow.circlepath": "arrow.counterclockwise",
        "arrow_counterclockwise": "arrow.counterclockwise",
        "calendar.badge.checkmark": "calendar.badge.checkmark",
        "calendar_badge_checkmark": "calendar.badge.checkmark",
        "calendar": "calendar",
        "laptopcomputer": "laptopcomputer",
        "desktopcomputer": "desktopcomputer",
        "display": "display",
        "eyedropper": "eyedropper",
        "eyedropper.halffull": "eyedropper",
        "power": "power",
        "power_settings_new": "power",
        "cup.and.saucer.fill": "coffee",
        "moon.fill": "moon.fill",
        "photo.fill": "wallpaper",
        "paintpalette.fill": "palette",
        "circle.hexagongrid.fill": "blur_on",
        "slider.horizontal.3": "tune",
        "magnifyingglass": "search",
        "trash.fill": "delete",
        "pin.fill": "push_pin",
        "waveform": "graphic_eq",
        "waveform.path.ecg": "waveform.path.ecg",
        "sun.max.fill": "light_mode",
        "sun.min.fill": "brightness_low",
        "wifi.slash": "wifi_off",
        "lock.fill": "lock",
        "lock.open.fill": "lock.open.fill",
        "checkmark": "done",
        "checkmark.circle.fill": "check_circle",
        "xmark": "close",
        "xmark.circle.fill": "xmark.circle.fill",
        "exclamationmark.circle.fill": "error",
        "bolt.fill": "bolt",
        "bolt": "bolt"
    })

    /** Returns resolved SVG basename for a given input glyph/name */
    function getSvgName(inputName) {
        return (root.iconMap && root.iconMap[inputName]) || inputName;
    }

    Image {
        id: img
        anchors.fill: parent
        source: name !== "" ? Qt.resolvedUrl("../assets/icons/" + getSvgName(name) + ".svg") : ""
        sourceSize: Qt.size(Math.max(48, Math.round(root.size * 3)), Math.max(48, Math.round(root.size * 3)))
        fillMode: Image.PreserveAspectFit
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
        visible: name !== "" && img.status === Image.Ready

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
