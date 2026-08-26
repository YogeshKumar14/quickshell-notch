pragma Singleton
import QtQuick

QtObject {
    // Pure black palette
    readonly property color background: "#000000"
    readonly property color cardBg: "#1C1C1E"
    readonly property color cardBgHover: "#2C2C2E"
    readonly property color cardBorder: "#2C2C2E"

    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A0A0A5"
    readonly property color textMuted: "#636366"

    // === Surface & Item Colors ===
    readonly property color surfaceDark: "#0A0A0C"
    readonly property color surfaceHover: "#121214"
    readonly property color surfaceBorderSubtle: "#222225"
    readonly property color surfaceWindow: "#141416"
    readonly property color divider: "#2A2A2D"
    readonly property color inputBorder: "#3C3C3E"
    readonly property color controlBorder: "#3A3A3C"
    readonly property color overlayLight: "#1AFFFFFF"
    readonly property color textOnAccent: "#000000"

    // List item & card delegate backgrounds
    readonly property color itemBg: "#0A0A0C"
    readonly property color itemBgHover: "#121214"
    readonly property color itemBgActive: "#1C1C1E"
    readonly property color itemBorder: "#222225"

    // OSD Accent Colors
    readonly property color warningYellow: "#EBCB8B"

    // === Animation & Transition Timing ===
    readonly property int animFast: 120        // micro-interactions (press feedback, icon colors)
    readonly property int animNormal: 180      // standard transitions (opacity, list hovers, dialogs)
    readonly property int animSlow: 250        // entrance/exit, window scales, crossfades
    readonly property int animSpinner: 1000    // continuous spinner cycle

    // === Spring Physics Profiles ===
    readonly property real springExpandTension: 4.5
    readonly property real springExpandDamping: 0.28
    readonly property real springTabTension: 5.5
    readonly property real springTabDamping: 0.22
    readonly property real springMicroTension: 4.0
    readonly property real springMicroDamping: 0.60
    readonly property real springEpsilon: 0.25

    // Dynamic accent from wallust (default fallback)
    property color accent: "#0A84FF"

    readonly property color success: "#30D158"
    readonly property color warning: "#FF9F0A"
    readonly property color danger: "#FF453A"
    readonly property color purple: "#BF5AF2"
    readonly property color teal: "#64D2FF"

    // Notch dimensions
    readonly property int notchHeightCompact: 30
    readonly property int notchWidthExpanded: 560
    readonly property int notchHeightExpanded: 420

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 28
    readonly property int radiusLarge: 32

    // Proportional UI Typography
    readonly property string fontFamily: "Inter, Roboto, Noto Sans, Ubuntu, sans-serif"
    readonly property string fontFamilyMono: "JetBrainsMono Nerd Font, FiraCode Nerd Font, monospace"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeTitle: 18
}
