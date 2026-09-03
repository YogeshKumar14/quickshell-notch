/**
 * Style.qml — macOS NotchNook Design System & Design Tokens
 *
 * Provides a centralized singleton matching macOS and NotchNook design:
 *   - Pure black OLED background (#000000)
 *   - Apple Dark Mode surfaces, cards, borders, and typography labels
 *   - Dynamic Wallust accent color integration (default macOS System Blue #0A84FF)
 *   - Apple semantic status colors (Music Red #FA2D48, Green #30D158, Orange #FF9F0A, Red #FF453A)
 *   - Standardized spring physics profiles (expand, tab, micro-interactions)
 *   - Proportional Apple SF Pro system typography
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

    // === Typography Colors (Apple HIG Labels) ===
    /** Primary readable white text */
    readonly property color textPrimary: "#FFFFFF"
    /** Secondary dimmed text for subtitles (macOS Secondary Label) */
    readonly property color textSecondary: "#8E8E93"
    /** Muted text for captions and placeholders (macOS Tertiary Label) */
    readonly property color textMuted: "#636366"
    /** Dark text contrast color when rendered on top of accent */
    readonly property color textOnAccent: "#FFFFFF"

    // === Surface & Item Colors ===
    readonly property color surfaceDark: "#000000"
    readonly property color surfaceHover: "#1C1C1E"
    readonly property color surfaceBorderSubtle: "#2C2C2E"
    readonly property color surfaceWindow: "#161618"
    readonly property color divider: "#2C2C2E"
    readonly property color inputBorder: "#3A3A3C"
    readonly property color controlBorder: "#3A3A3C"
    readonly property color overlayLight: "#1AFFFFFF"

    // === List Item & Card Delegate Backgrounds ===
    readonly property color itemBg: "#161618"
    readonly property color itemBgHover: "#1C1C1E"
    readonly property color itemBgActive: "#2C2C2E"
    readonly property color itemBorder: "#2C2C2E"

    // === macOS & iOS Semantic Colors ===
    readonly property color appleMusicRed: "#FA2D48"
    readonly property color systemBlue: "#0A84FF"
    readonly property color appleBlue: "#0A84FF"
    readonly property color warningYellow: "#FFD60A"
    readonly property color success: "#30D158"
    readonly property color iosGreen: "#30D158"
    readonly property color warning: "#FF9F0A"
    readonly property color danger: "#FF453A"
    readonly property color iosRed: "#FF453A"
    readonly property color iosYellow: "#FFD60A"
    readonly property color purple: "#BF5AF2"
    readonly property color teal: "#64D2FF"

    // === Dynamic Wallust Accent Color (Default macOS System Blue) ===
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
    readonly property real springExpandTension: 4.8
    /** Notch expansion spring damping */
    readonly property real springExpandDamping: 0.32
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
    readonly property int notchWidthExpanded: 600
    readonly property int notchHeightExpanded: 136

    // === Corner Radii (px) ===
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 14

    // === System Typography ===
    readonly property string fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', 'Cantarell', sans-serif"
    readonly property string fontFamilyMono: "'SF Pro Mono', 'Menlo', 'Monaco', monospace"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeTitle: 18
}
