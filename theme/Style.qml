/**
 * Style.qml — Material 3 Expressive Design System & Design Tokens
 *
 * Provides a centralized singleton for:
 *   - Dark-mode surface, card, border, and text palettes
 *   - Dynamic Wallust accent color integration
 *   - iOS battery status semantic colors
 *   - Standardized spring physics profiles (expand, tab, micro-interactions)
 *   - Standardized transition timing curves and radii
 *   - Proportional system typography
 */

pragma Singleton
import QtQuick

QtObject {
    // === Pure Black OLED Palette ===
    /** Pure black notch background */
    readonly property color background: "#000000"
    /** Elevated card surface background */
    readonly property color cardBg: "#1C1C1E"
    /** Hovered card surface background */
    readonly property color cardBgHover: "#2C2C2E"
    /** Card border outline color */
    readonly property color cardBorder: "#2C2C2E"

    // === Typography Colors ===
    /** Primary readable white text */
    readonly property color textPrimary: "#FFFFFF"
    /** Secondary dimmed text for subtitles */
    readonly property color textSecondary: "#A0A0A5"
    /** Muted text for captions and placeholders */
    readonly property color textMuted: "#636366"
    /** Dark text contrast color when rendered on top of accent */
    readonly property color textOnAccent: "#000000"

    // === Surface & Item Colors ===
    readonly property color surfaceDark: "#0A0A0C"
    readonly property color surfaceHover: "#121214"
    readonly property color surfaceBorderSubtle: "#222225"
    readonly property color surfaceWindow: "#141416"
    readonly property color divider: "#2A2A2D"
    readonly property color inputBorder: "#3C3C3E"
    readonly property color controlBorder: "#3A3A3C"
    readonly property color overlayLight: "#1AFFFFFF"

    // === List Item & Card Delegate Backgrounds ===
    readonly property color itemBg: "#0A0A0C"
    readonly property color itemBgHover: "#121214"
    readonly property color itemBgActive: "#1C1C1E"
    readonly property color itemBorder: "#222225"

    // === OSD & Status Semantic Colors ===
    readonly property color warningYellow: "#EBCB8B"
    readonly property color success: "#30D158"
    readonly property color iosGreen: "#30D158"
    readonly property color warning: "#FF9F0A"
    readonly property color danger: "#FF453A"
    readonly property color iosRed: "#FF453A"
    readonly property color iosYellow: "#FFD60A"
    readonly property color purple: "#BF5AF2"
    readonly property color teal: "#64D2FF"

    // === Dynamic Wallust Accent Color ===
    /** Dynamic accent color synced from active wallpaper */
    property color accent: "#0A84FF"

    // === Animation & Transition Timing (ms) ===
    /** Micro-interactions: press feedback, icon color switches */
    readonly property int animFast: 120
    /** Standard transitions: opacity, list hovers, dialog fades */
    readonly property int animNormal: 180
    /** Entrance/exit: window scales, large crossfades */
    readonly property int animSlow: 250
    /** Continuous loading spinner cycle duration */
    readonly property int animSpinner: 1000

    // === Spring Physics Profiles ===
    /** Notch expansion spring tension */
    readonly property real springExpandTension: 4.5
    /** Notch expansion spring damping */
    readonly property real springExpandDamping: 0.28
    /** Tab sliding highlight spring tension */
    readonly property real springTabTension: 5.5
    /** Tab sliding highlight spring damping */
    readonly property real springTabDamping: 0.22
    /** Micro-interaction spring tension */
    readonly property real springMicroTension: 4.0
    /** Micro-interaction spring damping */
    readonly property real springMicroDamping: 0.60
    /** Minimum threshold delta to terminate spring oscillation */
    readonly property real springEpsilon: 0.05

    // === Notch Dimensions (px) ===
    readonly property int notchHeightCompact: 30
    readonly property int notchWidthExpanded: 580
    readonly property int notchHeightExpanded: 106

    // === Corner Radii (px) ===
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 14
    readonly property int radiusLarge: 22

    // === System Typography ===
    readonly property string fontFamily: "sans-serif"
    readonly property string fontFamilyMono: "monospace"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeTitle: 18
}
