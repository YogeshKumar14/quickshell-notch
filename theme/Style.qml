pragma Singleton
import QtQuick

QtObject {
    // Pure black palette
    readonly property color background: "#000000"
    readonly property color notchBg: "#000000"
    readonly property color cardBg: "#1C1C1E"
    readonly property color cardBgHover: "#2C2C2E"
    readonly property color cardBorder: "#2C2C2E"
    readonly property color cardBorderHover: "#3A3A3C"

    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A0A0A5"
    readonly property color textMuted: "#636366"

    // Dynamic accent from wallust (default fallback)
    property color accent: "#0A84FF"
    property color accentHover: Qt.lighter(accent, 1.2)

    readonly property color success: "#30D158"
    readonly property color warning: "#FF9F0A"
    readonly property color danger: "#FF453A"
    readonly property color purple: "#BF5AF2"
    readonly property color teal: "#64D2FF"

    // Notch dimensions
    readonly property int notchWidthCompact: 130
    readonly property int notchHeightCompact: 30
    readonly property int notchWidthExpanded: 560
    readonly property int notchHeightExpanded: 420
    readonly property int radiusNotchBottom: 16

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 28
    readonly property int radiusLarge: 32
    readonly property int radiusPill: 100

    // Proportional UI Typography
    readonly property string fontFamily: "Inter, Roboto, Noto Sans, Ubuntu, sans-serif"
    readonly property string fontFamilyMono: "JetBrainsMono Nerd Font, FiraCode Nerd Font, monospace"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeTitle: 18
}
