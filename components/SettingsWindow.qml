/**
 * SettingsWindow.qml — macOS NotchNook Configuration Center for QuickShell Notch
 *
 * Provides a comprehensive, beautiful standalone GUI for managing:
 *   - Hyprland Options: Layout, Gaps, Rounding, Borders, Opacity, Blur, Shadow, Animations, Input
 *   - Notch Island Options: Compact Width, Corner Radius, Dripping Ears, Workspaces, Animations
 *   - Music Visualizer Options: Styles (Bars/Wave/Pulsar), Heights, Spectrum Count, Timeouts
 *   - System & Drawers: Magic Highlight, Wallpapers, Clock, Battery, OSD, Stats
 *   - Atomic Dual-Write persistence to ~/.config/hypr/quickshell_hypr.{lua,conf} and notch_settings.json
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    /** Whether the settings dialog window is open */
    property bool isOpen: false
    /** Active settings category tab index (0: Hyprland, 1: Notch Island, 2: Visualizer, 3: System & Apps) */
    property int currentTab: 0

    /** Emitted when notch options are saved and applied */
    signal notchSettingsChanged()

    /** Toggles window visibility and triggers options sync */
    function toggle() {
        isOpen = !isOpen;
    }

    /** Reads all persisted settings from disk into the draft properties */
    function syncFromDisk() {
        hasPendingChanges = false;
        getOptionsProc.running = true;
        getNotchProc.running = true;
    }

    // Foolproof: always re-read persisted settings from disk when opening
    onIsOpenChanged: {
        if (isOpen) syncFromDisk();
    }

    // Foolproof: read persisted settings immediately on first instantiation
    Component.onCompleted: syncFromDisk()

    visible: isOpen
    implicitWidth: 780
    implicitHeight: 740

    color: "transparent"

    Shortcut {
        sequence: "Escape"
        onActivated: root.isOpen = false
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Apply Button Feedback state
    property bool isAppliedSuccess: false
    property bool isApplyFailed: false
    property bool hasPendingChanges: false

    Timer {
        id: appliedSuccessTimer
        interval: 2000
        repeat: false
        onTriggered: root.isAppliedSuccess = false
    }

    Timer {
        id: applyFailedTimer
        interval: 4000
        repeat: false
        onTriggered: root.isApplyFailed = false
    }

    // --- HYPRLAND DRAFT & APPLIED OPTIONS ---
    property int gapsInVal: 5
    property int gapsOutVal: 10
    property int roundingVal: 10
    property int borderWidthVal: 2
    property bool blurEnabledVal: true
    property string activeBorderVal: "ff89b4fa"
    property string inactiveBorderVal: "ff585b70"
    property string layoutVal: "dwindle"
    property bool animationsEnabledVal: true
    property real activeOpacityVal: 1.0
    property real inactiveOpacityVal: 1.0
    property bool shadowEnabledVal: true
    property int shadowRangeVal: 4
    property bool dimInactiveVal: false
    property real masterRatioVal: 0.55
    property int blurSizeVal: 8
    property int blurPassesVal: 3

    property real inputSensitivityVal: 0.0
    property bool inputTapToClickVal: false
    property bool inputNaturalScrollVal: false

    // --- TOP NOTCH DRAFT & APPLIED OPTIONS ---
    property int notchAutoClose: 0
    property int notchCompactWidth: 130
    property int notchExpandedHeight: 106
    property int notchBottomRadius: 22
    property bool drippingEarsVal: true
    property real wallDurationVal: 0.5
    property string wallTypeVal: "outer"
    property string wallpaperDirVal: ""
    property int appColumnsVal: 4
    property bool workspaceOverlayVal: true
    property int workspaceTimeoutVal: 2500
    property string wsAnimTypeVal: "stretch"
    property bool buttonAnimsVal: true
    property int buttonSpeedVal: 180

    property bool visualizerEnabledVal: true
    property string visualizerStyleVal: "bars"
    property int visualizerHeightVal: 16
    property int visualizerTimeoutVal: 0
    property int visualizerBarCountVal: 12
    property int visualizerWaveWidthVal: 2
    property real visualizerPulsarScaleVal: 1.2
    property int visualizerPauseDelayVal: 1000

    property int sysStatsIntervalVal: 2000

    property int osdTimeoutVal: 2000
    property string clockFormatVal: "h:mm A"
    property int clockFontSizeVal: 14
    property int batteryWarningThresholdVal: 20

    property real expandSpringTension: 4.5
    property real expandSpringDamping: 0.28

    property real tabSpringTension: 5.5
    property real tabSpringDamping: 0.22

    property string highlightAnimTypeVal: "spring"
    property real highlightSpringTensionVal: 5.5
    property real highlightSpringDampingVal: 0.25
    property int gridAnimDurationVal: 120

    Process {
        id: getOptionsProc
        command: ["python3", Quickshell.shellDir + "/scripts/hyprland/get_hypr_options.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim());
                    if (data.gaps_in !== undefined) root.gapsInVal = data.gaps_in;
                    if (data.gaps_out !== undefined) root.gapsOutVal = data.gaps_out;
                    if (data.rounding !== undefined) root.roundingVal = data.rounding;
                    if (data.border_size !== undefined) root.borderWidthVal = data.border_size;
                    if (data.blur_enabled !== undefined) root.blurEnabledVal = data.blur_enabled;
                    if (data.col_active_border !== undefined) root.activeBorderVal = data.col_active_border;
                    if (data.col_inactive_border !== undefined) root.inactiveBorderVal = data.col_inactive_border;
                    if (data.layout !== undefined) root.layoutVal = data.layout;
                    if (data.animations_enabled !== undefined) root.animationsEnabledVal = data.animations_enabled;
                    if (data.active_opacity !== undefined) root.activeOpacityVal = data.active_opacity;
                    if (data.inactive_opacity !== undefined) root.inactiveOpacityVal = data.inactive_opacity;
                    if (data.shadow_enabled !== undefined) root.shadowEnabledVal = data.shadow_enabled;
                    if (data.shadow_range !== undefined) root.shadowRangeVal = data.shadow_range;
                    if (data.dim_inactive !== undefined) root.dimInactiveVal = data.dim_inactive;
                    if (data.master_ratio !== undefined) root.masterRatioVal = data.master_ratio;
                    if (data.blur_size !== undefined) root.blurSizeVal = data.blur_size;
                    if (data.blur_passes !== undefined) root.blurPassesVal = data.blur_passes;

                    if (data.input_sensitivity !== undefined) root.inputSensitivityVal = data.input_sensitivity;
                    if (data.input_tap_to_click !== undefined) root.inputTapToClickVal = data.input_tap_to_click;
                    if (data.input_natural_scroll !== undefined) root.inputNaturalScrollVal = data.input_natural_scroll;
                } catch(e) {}
            }
        }
    }

    Process {
        id: getNotchProc
        command: ["python3", Quickshell.shellDir + "/scripts/notch/get_notch_settings.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim());
                    if (data.auto_close !== undefined) root.notchAutoClose = data.auto_close;
                    if (data.compact_width !== undefined) root.notchCompactWidth = data.compact_width;
                    if (data.expanded_height !== undefined) root.notchExpandedHeight = data.expanded_height;
                    if (data.bottom_radius !== undefined) root.notchBottomRadius = data.bottom_radius;
                    if (data.dripping_ears !== undefined) root.drippingEarsVal = data.dripping_ears;
                    if (data.wall_duration !== undefined) root.wallDurationVal = data.wall_duration;
                    if (data.wall_type !== undefined) root.wallTypeVal = data.wall_type;
                    if (data.wallpaper_dir !== undefined) root.wallpaperDirVal = data.wallpaper_dir;
                    if (data.app_columns !== undefined) root.appColumnsVal = data.app_columns;
                    if (data.workspace_overlay !== undefined) root.workspaceOverlayVal = data.workspace_overlay;
                    if (data.workspace_timeout !== undefined) root.workspaceTimeoutVal = data.workspace_timeout;
                    if (data.ws_anim_type !== undefined) root.wsAnimTypeVal = data.ws_anim_type;
                    if (data.button_anims !== undefined) root.buttonAnimsVal = data.button_anims;
                    if (data.button_speed !== undefined) root.buttonSpeedVal = data.button_speed;
                    if (data.visualizer_enabled !== undefined) root.visualizerEnabledVal = data.visualizer_enabled;
                    if (data.visualizer_style !== undefined) root.visualizerStyleVal = data.visualizer_style;
                    if (data.visualizer_height !== undefined) root.visualizerHeightVal = data.visualizer_height;
                    if (data.visualizer_timeout !== undefined) root.visualizerTimeoutVal = data.visualizer_timeout;
                    if (data.visualizer_bar_count !== undefined) root.visualizerBarCountVal = data.visualizer_bar_count;
                    if (data.visualizer_wave_width !== undefined) root.visualizerWaveWidthVal = data.visualizer_wave_width;
                    if (data.visualizer_pulsar_scale !== undefined) root.visualizerPulsarScaleVal = data.visualizer_pulsar_scale;
                    if (data.visualizer_pause_delay !== undefined) root.visualizerPauseDelayVal = data.visualizer_pause_delay;
                    if (data.stats_interval !== undefined) root.sysStatsIntervalVal = data.stats_interval;
                    if (data.osd_timeout !== undefined) root.osdTimeoutVal = data.osd_timeout;
                    if (data.clock_format !== undefined) root.clockFormatVal = data.clock_format;
                    if (data.clock_font_size !== undefined) root.clockFontSizeVal = data.clock_font_size;
                    if (data.battery_warning_threshold !== undefined) root.batteryWarningThresholdVal = data.battery_warning_threshold;
                    if (data.expand_tension !== undefined) root.expandSpringTension = data.expand_tension;
                    if (data.expand_damping !== undefined) root.expandSpringDamping = data.expand_damping;
                    if (data.tab_tension !== undefined) root.tabSpringTension = data.tab_tension;
                    if (data.tab_damping !== undefined) root.tabSpringDamping = data.tab_damping;
                    if (data.highlight_anim_type !== undefined) root.highlightAnimTypeVal = data.highlight_anim_type;
                    if (data.highlight_spring_tension !== undefined) root.highlightSpringTensionVal = data.highlight_spring_tension;
                    if (data.highlight_spring_damping !== undefined) root.highlightSpringDampingVal = data.highlight_spring_damping;
                    if (data.grid_anim_duration !== undefined) root.gridAnimDurationVal = data.grid_anim_duration;
                } catch(e) {}
            }
        }
    }

    Process {
        id: applyProc
        command: []
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.isAppliedSuccess = true;
                root.isApplyFailed = false;
                root.hasPendingChanges = false;
                appliedSuccessTimer.restart();
                root.notchSettingsChanged();
            } else {
                root.isApplyFailed = true;
                applyFailedTimer.restart();
            }
        }
    }

    function applySettings() {
        var hyprObj = {
            "gaps_in": root.gapsInVal,
            "gaps_out": root.gapsOutVal,
            "rounding": root.roundingVal,
            "border_size": root.borderWidthVal,
            "blur": root.blurEnabledVal,
            "layout": root.layoutVal,
            "animations": root.animationsEnabledVal,
            "active_opacity": root.activeOpacityVal,
            "inactive_opacity": root.inactiveOpacityVal,
            "shadow": root.shadowEnabledVal,
            "shadow_range": root.shadowRangeVal,
            "dim_inactive": root.dimInactiveVal,
            "master_ratio": root.masterRatioVal,
            "blur_passes": root.blurPassesVal,
            "blur_size": root.blurSizeVal,
            "input_sensitivity": root.inputSensitivityVal,
            "input_tap_to_click": root.inputTapToClickVal,
            "input_natural_scroll": root.inputNaturalScrollVal
        };

        var payload = {
            "hyprland": hyprObj,
            "hypr": hyprObj,
            "notch": {
                "auto_close": root.notchAutoClose,
                "compact_width": root.notchCompactWidth,
                "expanded_height": root.notchExpandedHeight,
                "bottom_radius": root.notchBottomRadius,
                "dripping_ears": root.drippingEarsVal,
                "wall_duration": root.wallDurationVal,
                "wall_type": root.wallTypeVal,
                "wallpaper_dir": root.wallpaperDirVal,
                "app_columns": root.appColumnsVal,
                "workspace_overlay": root.workspaceOverlayVal,
                "workspace_timeout": root.workspaceTimeoutVal,
                "ws_anim_type": root.wsAnimTypeVal,
                "button_anims": root.buttonAnimsVal,
                "button_speed": root.buttonSpeedVal,
                "visualizer_enabled": root.visualizerEnabledVal,
                "visualizer_style": root.visualizerStyleVal,
                "visualizer_height": root.visualizerHeightVal,
                "visualizer_timeout": root.visualizerTimeoutVal,
                "visualizer_bar_count": root.visualizerBarCountVal,
                "visualizer_wave_width": root.visualizerWaveWidthVal,
                "visualizer_pulsar_scale": root.visualizerPulsarScaleVal,
                "visualizer_pause_delay": root.visualizerPauseDelayVal,
                "stats_interval": root.sysStatsIntervalVal,
                "osd_timeout": root.osdTimeoutVal,
                "clock_format": root.clockFormatVal,
                "clock_font_size": root.clockFontSizeVal,
                "battery_warning_threshold": root.batteryWarningThresholdVal,
                "expand_tension": root.expandSpringTension,
                "expand_damping": root.expandSpringDamping,
                "tab_tension": root.tabSpringTension,
                "tab_damping": root.tabSpringDamping,
                "highlight_anim_type": root.highlightAnimTypeVal,
                "highlight_spring_tension": root.highlightSpringTensionVal,
                "highlight_spring_damping": root.highlightSpringDampingVal,
                "grid_anim_duration": root.gridAnimDurationVal
            }
        };

        applyProc.command = ["python3", Quickshell.shellDir + "/scripts/hyprland/apply_all_settings.py", JSON.stringify(payload)];
        applyProc.running = true;
    }

    function resetToDefaults() {
        if (root.currentTab === 0) {
            root.gapsInVal = 5;
            root.gapsOutVal = 10;
            root.roundingVal = 10;
            root.borderWidthVal = 2;
            root.blurEnabledVal = true;
            root.layoutVal = "dwindle";
            root.animationsEnabledVal = true;
            root.activeOpacityVal = 1.0;
            root.inactiveOpacityVal = 1.0;
            root.shadowEnabledVal = true;
            root.shadowRangeVal = 4;
            root.dimInactiveVal = false;
            root.masterRatioVal = 0.55;
            root.blurSizeVal = 8;
            root.blurPassesVal = 3;
            root.inputSensitivityVal = 0.0;
            root.inputTapToClickVal = false;
            root.inputNaturalScrollVal = false;
        } else if (root.currentTab === 1) {
            root.notchCompactWidth = 130;
            root.notchBottomRadius = 22;
            root.drippingEarsVal = true;
            root.workspaceOverlayVal = true;
            root.workspaceTimeoutVal = 2500;
            root.wsAnimTypeVal = "stretch";
            root.buttonAnimsVal = true;
            root.buttonSpeedVal = 180;
            root.expandSpringTension = 4.5;
            root.expandSpringDamping = 0.28;
            root.tabSpringTension = 5.5;
            root.tabSpringDamping = 0.22;
        } else if (root.currentTab === 2) {
            root.visualizerEnabledVal = true;
            root.visualizerStyleVal = "bars";
            root.visualizerHeightVal = 16;
            root.visualizerBarCountVal = 12;
            root.visualizerWaveWidthVal = 2;
            root.visualizerPulsarScaleVal = 1.2;
            root.visualizerTimeoutVal = 0;
            root.visualizerPauseDelayVal = 1000;
        } else if (root.currentTab === 3) {
            root.appColumnsVal = 4;
            root.highlightAnimTypeVal = "spring";
            root.highlightSpringTensionVal = 5.5;
            root.highlightSpringDampingVal = 0.25;
            root.gridAnimDurationVal = 120;
            root.wallTypeVal = "outer";
            root.wallDurationVal = 0.5;
            root.clockFormatVal = "h:mm A";
            root.clockFontSizeVal = 14;
            root.batteryWarningThresholdVal = 20;
            root.osdTimeoutVal = 2000;
            root.sysStatsIntervalVal = 2000;
        }
        root.hasPendingChanges = true;
    }

    // --- MAIN WINDOW CONTAINER ---
    Rectangle {
        id: mainCard
        anchors.fill: parent
        anchors.margins: 16
        radius: 24
        color: "#000000"
        border.color: "#2C2C2E"
        border.width: 1
        clip: true

        scale: root.isOpen ? 1.0 : 0.96
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on scale { SpringAnimation { spring: 5.5; damping: 0.28 } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // --- HEADER BAR & 4-TAB SEGMENTED CONTROLLER ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // App Brand Pill
                RowLayout {
                    spacing: 8
                    M3Icon {
                        name: "settings"
                        size: 20
                        color: Style.accent
                    }
                    Text {
                        text: "Settings"
                        font.family: Style.fontFamilyDisplay
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Style.textPrimary
                    }
                }

                Item { Layout.fillWidth: true }

                // 4-Tab Fluid Segmented Bar
                Rectangle {
                    implicitWidth: 460
                    implicitHeight: 36
                    radius: 18
                    color: "#1C1C1E"
                    border.color: "#2C2C2E"
                    border.width: 1

                    // Sliding Highlight Pill
                    Rectangle {
                        id: tabGlider
                        height: 30
                        radius: 15
                        color: Style.accent
                        anchors.top: parent.top
                        anchors.topMargin: 3

                        property var currentItem: (tabRepeater.count > 0) ? tabRepeater.itemAt(root.currentTab) : null
                        x: currentItem ? currentItem.x + 3 : 0
                        width: currentItem ? currentItem.width : 0

                        Behavior on x { enabled: tabGlider.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                        Behavior on width { enabled: tabGlider.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                    }

                    RowLayout {
                        id: tabRow
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 0
                        z: 2

                        Repeater {
                            id: tabRepeater
                            model: [
                                { label: "Hyprland", icon: "desktop_windows" },
                                { label: "Notch Island", icon: "space_dashboard" },
                                { label: "Visualizer", icon: "graphic_eq" },
                                { label: "System & Apps", icon: "apps" }
                            ]
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    M3Icon {
                                        name: modelData.icon
                                        size: 14
                                        color: root.currentTab === index ? Style.textOnAccent : (tabM.containsMouse ? Style.textPrimary : Style.textSecondary)
                                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                    }

                                    Text {
                                        text: modelData.label
                                        font.family: Style.fontFamily
                                        font.pixelSize: 11
                                        font.weight: root.currentTab === index ? Font.Bold : Font.Medium
                                        color: root.currentTab === index ? Style.textOnAccent : (tabM.containsMouse ? Style.textPrimary : Style.textSecondary)
                                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                    }
                                }

                                MouseArea {
                                    id: tabM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentTab = index
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Close Button
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: closeM.containsMouse ? Style.danger : "#1C1C1E"
                    border.color: "#2C2C2E"

                    scale: (root.buttonAnimsVal && closeM.pressed) ? 0.92 : ((root.buttonAnimsVal && closeM.containsMouse) ? 1.08 : 1.0)
                    Behavior on scale { enabled: root.buttonAnimsVal; SpringAnimation { spring: 5.5; damping: 0.25 } }
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                    M3Icon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 14
                        color: closeM.containsMouse ? "#FFFFFF" : Style.textSecondary
                    }

                    MouseArea {
                        id: closeM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.isOpen = false
                    }
                }
            }

            // --- SCROLLABLE CONTENT VIEWPORT ---
            Flickable {
                id: flickView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: activeCol.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    id: vScroll
                    active: flickView.moving || flickView.dragging
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Style.accent
                        opacity: vScroll.active ? 0.8 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                Connections {
                    target: root
                    function onCurrentTabChanged() {
                        flickView.contentY = 0;
                    }
                }

                Item {
                    id: activeCol
                    width: flickView.width - (vScroll.visible ? 12 : 4)
                    height: implicitHeight
                    implicitHeight: {
                        if (root.currentTab === 0) return tab0Col.implicitHeight;
                        if (root.currentTab === 1) return tab1Col.implicitHeight;
                        if (root.currentTab === 2) return tab2Col.implicitHeight;
                        if (root.currentTab === 3) return tab3Col.implicitHeight;
                        return 0;
                    }

                    // =========================================================
                    // TAB 0: HYPRLAND OPTIONS
                    // =========================================================
                    ColumnLayout {
                        id: tab0Col
                        width: parent.width
                        spacing: 14
                        visible: root.currentTab === 0

                        // CARD 1: Window Layout & Tiling
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: c1Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: c1Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                // Section Title
                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "space_dashboard"; size: 14; color: Style.accent }
                                    Text { text: "Window Layout & Tiling"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                // Layout Mode Selector
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Layout Engine"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        implicitWidth: 160; implicitHeight: 28; radius: 14; color: "#2C2C2E"
                                        RowLayout {
                                            anchors.fill: parent; spacing: 0
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.layoutVal === "dwindle" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Dwindle"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.layoutVal === "dwindle" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.layoutVal = "dwindle"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.layoutVal === "master" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Master"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.layoutVal === "master" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.layoutVal = "master"; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }

                                // Inner Gaps
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Inner Window Gaps"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.gapsInVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 0; to: 30; stepSize: 1; value: root.gapsInVal; onMoved: function(val) { root.gapsInVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                // Outer Gaps
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Outer Screen Gaps"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.gapsOutVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 0; to: 50; stepSize: 1; value: root.gapsOutVal; onMoved: function(val) { root.gapsOutVal = Math.round(val); root.hasPendingChanges = true; } }
                                }
                            }
                        }

                        // CARD 2: Decoration & Opacity
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: c2Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: c2Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "palette"; size: 14; color: Style.accent }
                                    Text { text: "Decoration, Borders & Opacity"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                // Window Rounding
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Window Corner Rounding"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.roundingVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 0; to: 30; stepSize: 1; value: root.roundingVal; onMoved: function(val) { root.roundingVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                // Border Thickness
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Border Thickness"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.borderWidthVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 0; to: 8; stepSize: 1; value: root.borderWidthVal; onMoved: function(val) { root.borderWidthVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                // Active Opacity
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Active Window Opacity"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(root.activeOpacityVal * 100) + " %"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 0.50; to: 1.00; stepSize: 0.05; value: root.activeOpacityVal; onMoved: function(val) { root.activeOpacityVal = Number(val.toFixed(2)); root.hasPendingChanges = true; } }
                                }

                                // Inactive Opacity
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Inactive Window Opacity"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(root.inactiveOpacityVal * 100) + " %"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 0.50; to: 1.00; stepSize: 0.05; value: root.inactiveOpacityVal; onMoved: function(val) { root.inactiveOpacityVal = Number(val.toFixed(2)); root.hasPendingChanges = true; } }
                                }

                                // Dim Inactive Windows Switch
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Dim Inactive Windows"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.dimInactiveVal; onToggled: function(val) { root.dimInactiveVal = val; root.hasPendingChanges = true; } }
                                }
                            }
                        }

                        // CARD 3: Blur & Drop Shadows
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: c3Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: c3Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "blur_on"; size: 14; color: Style.accent }
                                    Text { text: "Window Blur & Drop Shadows"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Dual Kawase Background Blur"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.blurEnabledVal; onToggled: function(val) { root.blurEnabledVal = val; root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4; visible: root.blurEnabledVal
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Blur Passes"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.blurPassesVal.toString(); font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 1; to: 5; stepSize: 1; value: root.blurPassesVal; onMoved: function(val) { root.blurPassesVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Window Drop Shadow"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.shadowEnabledVal; onToggled: function(val) { root.shadowEnabledVal = val; root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4; visible: root.shadowEnabledVal
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Shadow Spread Range"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.shadowRangeVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 1; to: 30; stepSize: 1; value: root.shadowRangeVal; onMoved: function(val) { root.shadowRangeVal = Math.round(val); root.hasPendingChanges = true; } }
                                }
                            }
                        }

                        // CARD 4: Animations & Touchpad Input
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: c4Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: c4Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "touch_app"; size: 14; color: Style.accent }
                                    Text { text: "Animations & Touchpad Input"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Hyprland Window Animations"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.animationsEnabledVal; onToggled: function(val) { root.animationsEnabledVal = val; root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Pointer Sensitivity"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.inputSensitivityVal.toFixed(2); font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: -1.0; to: 1.0; stepSize: 0.05; value: root.inputSensitivityVal; onMoved: function(val) { root.inputSensitivityVal = Number(val.toFixed(2)); root.hasPendingChanges = true; } }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Touchpad Tap-to-Click"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.inputTapToClickVal; onToggled: function(val) { root.inputTapToClickVal = val; root.hasPendingChanges = true; } }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Touchpad Natural Scrolling"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.inputNaturalScrollVal; onToggled: function(val) { root.inputNaturalScrollVal = val; root.hasPendingChanges = true; } }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // TAB 1: NOTCH ISLAND OPTIONS
                    // =========================================================
                    ColumnLayout {
                        id: tab1Col
                        width: parent.width
                        spacing: 14
                        visible: root.currentTab === 1

                        // CARD 1: Dimensions & Geometry
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: n1Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: n1Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "aspect_ratio"; size: 14; color: Style.accent }
                                    Text { text: "Notch Dimensions & Squircle Geometry"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                // Compact Pill Width
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Compact Idle Pill Width"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.notchCompactWidth + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 120; to: 220; stepSize: 5; value: root.notchCompactWidth; onMoved: function(val) { root.notchCompactWidth = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                // Corner Radius
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Bottom Corner Squircle Radius"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.notchBottomRadius + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 16; to: 28; stepSize: 1; value: root.notchBottomRadius; onMoved: function(val) { root.notchBottomRadius = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                // Dripping Ears
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Seamless Dripping Inverted Ears Canvas"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.drippingEarsVal; onToggled: function(val) { root.drippingEarsVal = val; root.hasPendingChanges = true; } }
                                }
                            }
                        }

                        // CARD 2: Workspace Indicator
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: n2Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: n2Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "view_carousel"; size: 14; color: Style.accent }
                                    Text { text: "Realtime Workspace Switch Overlay"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Show Workspace Indicator on Switch"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.workspaceOverlayVal; onToggled: function(val) { root.workspaceOverlayVal = val; root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4; visible: root.workspaceOverlayVal
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Workspace Overlay Auto-Dismiss Timeout"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: (root.workspaceTimeoutVal / 1000.0).toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 1000; to: 5000; stepSize: 500; value: root.workspaceTimeoutVal; onMoved: function(val) { root.workspaceTimeoutVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; visible: root.workspaceOverlayVal
                                    Text { text: "Indicator Physics Style"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        implicitWidth: 160; implicitHeight: 28; radius: 14; color: "#2C2C2E"
                                        RowLayout {
                                            anchors.fill: parent; spacing: 0
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.wsAnimTypeVal === "stretch" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Stretch"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.wsAnimTypeVal === "stretch" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.wsAnimTypeVal = "stretch"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.wsAnimTypeVal === "smooth" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Smooth"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.wsAnimTypeVal === "smooth" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.wsAnimTypeVal = "smooth"; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // CARD 3: Spring Physics & Motion Dynamics
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: nPhysicsCol.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: nPhysicsCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "tune"; size: 14; color: Style.accent }
                                    Text { text: "Spring Physics & Motion Dynamics"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                // Quick Motion Presets
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Motion Dynamics Presets"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        implicitWidth: 260; implicitHeight: 28; radius: 14; color: "#2C2C2E"
                                        property string activePreset: (Math.abs(root.expandSpringTension - 4.5) < 0.15 && Math.abs(root.expandSpringDamping - 0.22) < 0.03) ? "bouncy" :
                                                                      ((Math.abs(root.expandSpringTension - 6.5) < 0.15 && Math.abs(root.expandSpringDamping - 0.45) < 0.03) ? "snappy" :
                                                                      ((Math.abs(root.expandSpringTension - 3.5) < 0.15 && Math.abs(root.expandSpringDamping - 0.35) < 0.03) ? "gentle" : "custom"))
                                        RowLayout {
                                            anchors.fill: parent; spacing: 0
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: parent.parent.activePreset === "bouncy" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Bouncy"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: parent.parent.parent.activePreset === "bouncy" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.expandSpringTension = 4.5; root.expandSpringDamping = 0.22;
                                                        root.tabSpringTension = 5.5; root.tabSpringDamping = 0.22;
                                                        root.hasPendingChanges = true;
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: parent.parent.activePreset === "snappy" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Snappy"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: parent.parent.parent.activePreset === "snappy" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.expandSpringTension = 6.5; root.expandSpringDamping = 0.45;
                                                        root.tabSpringTension = 7.0; root.tabSpringDamping = 0.40;
                                                        root.hasPendingChanges = true;
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: parent.parent.activePreset === "gentle" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Gentle"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: parent.parent.parent.activePreset === "gentle" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.expandSpringTension = 3.5; root.expandSpringDamping = 0.35;
                                                        root.tabSpringTension = 4.0; root.tabSpringDamping = 0.30;
                                                        root.hasPendingChanges = true;
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: parent.parent.activePreset === "custom" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Custom"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: parent.parent.parent.activePreset === "custom" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                                            }
                                        }
                                    }
                                }

                                // Notch Expand Tension (Stiffness)
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Notch Expand / Collapse Spring Stiffness"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.expandSpringTension.toFixed(1); font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider {
                                        Layout.fillWidth: true; from: 2.0; to: 9.0; stepSize: 0.1; value: root.expandSpringTension
                                        onMoved: function(val) { root.expandSpringTension = Number(val.toFixed(1)); root.hasPendingChanges = true; }
                                    }
                                }

                                // Notch Expand Damping (Bounciness)
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Notch Expand / Collapse Damping (Bounciness)"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.expandSpringDamping.toFixed(2); font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider {
                                        Layout.fillWidth: true; from: 0.10; to: 0.80; stepSize: 0.02; value: root.expandSpringDamping
                                        onMoved: function(val) { root.expandSpringDamping = Number(val.toFixed(2)); root.hasPendingChanges = true; }
                                    }
                                }

                                // Tab Switch Tension
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Tab Glider Switch Spring Stiffness"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.tabSpringTension.toFixed(1); font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider {
                                        Layout.fillWidth: true; from: 2.0; to: 9.0; stepSize: 0.1; value: root.tabSpringTension
                                        onMoved: function(val) { root.tabSpringTension = Number(val.toFixed(1)); root.hasPendingChanges = true; }
                                    }
                                }

                                // Tab Switch Damping
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Tab Glider Switch Damping (Bounciness)"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.tabSpringDamping.toFixed(2); font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider {
                                        Layout.fillWidth: true; from: 0.10; to: 0.80; stepSize: 0.02; value: root.tabSpringDamping
                                        onMoved: function(val) { root.tabSpringDamping = Number(val.toFixed(2)); root.hasPendingChanges = true; }
                                    }
                                }
                            }
                        }

                        // CARD 4: Tactile Interactions
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: n3Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: n3Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "mouse"; size: 14; color: Style.accent }
                                    Text { text: "Tactile Button Micro-Animations"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Interactive Button Micro-Animations"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.buttonAnimsVal; onToggled: function(val) { root.buttonAnimsVal = val; root.hasPendingChanges = true; } }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; visible: root.buttonAnimsVal
                                    Text { text: "Animation Dynamics Profile"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        implicitWidth: 210; implicitHeight: 28; radius: 14; color: "#2C2C2E"
                                        RowLayout {
                                            anchors.fill: parent; spacing: 0
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.buttonSpeedVal === 120 ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Fast"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.buttonSpeedVal === 120 ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.buttonSpeedVal = 120; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.buttonSpeedVal === 180 ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Smooth"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.buttonSpeedVal === 180 ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.buttonSpeedVal = 180; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.buttonSpeedVal === 250 ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Gentle"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.buttonSpeedVal === 250 ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.buttonSpeedVal = 250; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // TAB 2: MUSIC VISUALIZER OPTIONS
                    // =========================================================
                    ColumnLayout {
                        id: tab2Col
                        width: parent.width
                        spacing: 14
                        visible: root.currentTab === 2

                        // CARD 1: Visualizer Style
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: v1Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: v1Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "graphic_eq"; size: 14; color: Style.accent }
                                    Text { text: "Music Visualizer Overlay & Styles"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Compact Music Visualizer Overlay"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { checked: root.visualizerEnabledVal; onToggled: function(val) { root.visualizerEnabledVal = val; root.hasPendingChanges = true; } }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; visible: root.visualizerEnabledVal
                                    Text { text: "Visualizer Rendering Style"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        implicitWidth: 210; implicitHeight: 28; radius: 14; color: "#2C2C2E"
                                        RowLayout {
                                            anchors.fill: parent; spacing: 0
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.visualizerStyleVal === "bars" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Bars"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.visualizerStyleVal === "bars" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.visualizerStyleVal = "bars"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.visualizerStyleVal === "wave" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Wave"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.visualizerStyleVal === "wave" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.visualizerStyleVal = "wave"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.visualizerStyleVal === "pulsar" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Pulsar"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.visualizerStyleVal === "pulsar" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.visualizerStyleVal = "pulsar"; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // CARD 2: Spectrum Geometry
                        Rectangle {
                            Layout.fillWidth: true; visible: root.visualizerEnabledVal
                            implicitHeight: v2Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: v2Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "tune"; size: 14; color: Style.accent }
                                    Text { text: "Spectrum Dimensions & Dynamics"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4; visible: root.visualizerStyleVal === "bars"
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Bars: Spectrum Count"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerBarCountVal + " Bars"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 8; to: 24; stepSize: 2; value: root.visualizerBarCountVal; onMoved: function(val) { root.visualizerBarCountVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4; visible: root.visualizerStyleVal === "bars"
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Visualizer Peak Height"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerHeightVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 10; to: 24; stepSize: 1; value: root.visualizerHeightVal; onMoved: function(val) { root.visualizerHeightVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4; visible: root.visualizerStyleVal === "wave"
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Wave Line Stroke Width"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerWaveWidthVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 1; to: 4; stepSize: 1; value: root.visualizerWaveWidthVal; onMoved: function(val) { root.visualizerWaveWidthVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4; visible: root.visualizerStyleVal === "pulsar"
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Pulsar Aura Max Scale"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerPulsarScaleVal.toFixed(1) + "x"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 1.0; to: 2.0; stepSize: 0.1; value: root.visualizerPulsarScaleVal; onMoved: function(val) { root.visualizerPulsarScaleVal = Number(val.toFixed(1)); root.hasPendingChanges = true; } }
                                }
                            }
                        }

                        // CARD 3: Timers & Smoothing
                        Rectangle {
                            Layout.fillWidth: true; visible: root.visualizerEnabledVal
                            implicitHeight: v3Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: v3Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "timer"; size: 14; color: Style.accent }
                                    Text { text: "Display Timers & DSP Smoothing"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Visualizer Display Timeout"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerTimeoutVal === 0 ? "Continuous" : (root.visualizerTimeoutVal / 1000.0).toFixed(0) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 0; to: 10000; stepSize: 1000; value: root.visualizerTimeoutVal; onMoved: function(val) { root.visualizerTimeoutVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Pause / Stop Dismissal Delay"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: (root.visualizerPauseDelayVal / 1000.0).toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 500; to: 3000; stepSize: 250; value: root.visualizerPauseDelayVal; onMoved: function(val) { root.visualizerPauseDelayVal = Math.round(val); root.hasPendingChanges = true; } }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // TAB 3: SYSTEM & DRAWERS OPTIONS
                    // =========================================================
                    ColumnLayout {
                        id: tab3Col
                        width: parent.width
                        spacing: 14
                        visible: root.currentTab === 3

                        // CARD 1: App Launcher & Wallpapers
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: s1Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: s1Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "apps"; size: 14; color: Style.accent }
                                    Text { text: "Application Launcher & Wallpapers Grid"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Magic Highlight Animation"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        implicitWidth: 260; implicitHeight: 28; radius: 14; color: "#2C2C2E"
                                        RowLayout {
                                            anchors.fill: parent; spacing: 0
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.highlightAnimTypeVal === "spring" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Spring"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.highlightAnimTypeVal === "spring" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.highlightAnimTypeVal = "spring"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.highlightAnimTypeVal === "smooth" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Smooth"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.highlightAnimTypeVal === "smooth" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.highlightAnimTypeVal = "smooth"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.highlightAnimTypeVal === "linear" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Linear"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.highlightAnimTypeVal === "linear" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.highlightAnimTypeVal = "linear"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.highlightAnimTypeVal === "off" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Off"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.highlightAnimTypeVal === "off" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.highlightAnimTypeVal = "off"; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }

                                // Magic Highlight Spring Tension (visible when style is spring)
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    visible: root.highlightAnimTypeVal === "spring"
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Magic Highlight Spring Stiffness"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.highlightSpringTensionVal.toFixed(1); font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider {
                                        Layout.fillWidth: true; from: 2.0; to: 9.0; stepSize: 0.1; value: root.highlightSpringTensionVal
                                        onMoved: function(val) { root.highlightSpringTensionVal = Number(val.toFixed(1)); root.hasPendingChanges = true; }
                                    }
                                }

                                // Magic Highlight Spring Damping (visible when style is spring)
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    visible: root.highlightAnimTypeVal === "spring"
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Magic Highlight Damping (Bounciness)"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.highlightSpringDampingVal.toFixed(2); font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider {
                                        Layout.fillWidth: true; from: 0.10; to: 0.80; stepSize: 0.02; value: root.highlightSpringDampingVal
                                        onMoved: function(val) { root.highlightSpringDampingVal = Number(val.toFixed(2)); root.hasPendingChanges = true; }
                                    }
                                }

                                // Grid Movement Duration (visible when style is smooth or linear)
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    visible: root.highlightAnimTypeVal === "smooth" || root.highlightAnimTypeVal === "linear"
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Grid Transition Duration"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.gridAnimDurationVal + " ms"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider {
                                        Layout.fillWidth: true; from: 60; to: 400; stepSize: 20; value: root.gridAnimDurationVal
                                        onMoved: function(val) { root.gridAnimDurationVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Wallpaper Transition Style"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        implicitWidth: 260; implicitHeight: 28; radius: 14; color: "#2C2C2E"
                                        RowLayout {
                                            anchors.fill: parent; spacing: 0
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.wallTypeVal === "outer" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Outer"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.wallTypeVal === "outer" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.wallTypeVal = "outer"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.wallTypeVal === "fade" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Fade"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.wallTypeVal === "fade" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.wallTypeVal = "fade"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.wallTypeVal === "wipe" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Wipe"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.wallTypeVal === "wipe" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.wallTypeVal = "wipe"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.wallTypeVal === "wave" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "Wave"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.wallTypeVal === "wave" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.wallTypeVal = "wave"; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Wallpaper Transition Duration"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.wallDurationVal.toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 0.2; to: 2.0; stepSize: 0.1; value: root.wallDurationVal; onMoved: function(val) { root.wallDurationVal = Number(val.toFixed(1)); root.hasPendingChanges = true; } }
                                }
                            }
                        }

                        // CARD 2: Clock & Status Bar
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: s2Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: s2Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "schedule"; size: 14; color: Style.accent }
                                    Text { text: "Clock Typography & Battery Alerts"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Clock Time Format"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        implicitWidth: 180; implicitHeight: 28; radius: 14; color: "#2C2C2E"
                                        RowLayout {
                                            anchors.fill: parent; spacing: 0
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.clockFormatVal === "h:mm A" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "12-Hour"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.clockFormatVal === "h:mm A" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.clockFormatVal = "h:mm A"; root.hasPendingChanges = true; } }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                                                color: root.clockFormatVal === "HH:mm" ? Style.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: "24-Hour"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: root.clockFormatVal === "HH:mm" ? Style.textOnAccent : Style.textPrimary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.clockFormatVal = "HH:mm"; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Clock Typography Size"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.clockFontSizeVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 12; to: 18; stepSize: 1; value: root.clockFontSizeVal; onMoved: function(val) { root.clockFontSizeVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Low Battery Alert Threshold"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.batteryWarningThresholdVal + " %"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 10; to: 35; stepSize: 5; value: root.batteryWarningThresholdVal; onMoved: function(val) { root.batteryWarningThresholdVal = Math.round(val); root.hasPendingChanges = true; } }
                                }
                            }
                        }

                        // CARD 3: Timers & Monitoring
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: s3Col.implicitHeight + 28
                            radius: 16
                            color: "#1C1C1E"
                            border.color: "#2C2C2E"

                            ColumnLayout {
                                id: s3Col
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    spacing: 8
                                    M3Icon { name: "monitoring"; size: 14; color: Style.accent }
                                    Text { text: "System Timers & Hardware Monitor"; font.family: Style.fontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "OSD Notification Timeout"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: (root.osdTimeoutVal / 1000.0).toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 1000; to: 5000; stepSize: 500; value: root.osdTimeoutVal; onMoved: function(val) { root.osdTimeoutVal = Math.round(val); root.hasPendingChanges = true; } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Hardware Stats Polling Rate"; font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: (root.sysStatsIntervalVal / 1000.0).toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: 12; font.weight: Font.Bold; color: Style.accent }
                                    }
                                    CustomSlider { Layout.fillWidth: true; from: 500; to: 5000; stepSize: 500; value: root.sysStatsIntervalVal; onMoved: function(val) { root.sysStatsIntervalVal = Math.round(val); root.hasPendingChanges = true; } }
                                }
                            }
                        }
                    }
                }
            }

            // --- BOTTOM STICKY ACTION FOOTER ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 16
                color: "#1C1C1E"
                border.color: "#2C2C2E"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    // Status readout
                    RowLayout {
                        spacing: 6
                        M3Icon {
                            name: root.isAppliedSuccess ? "done" : (root.isApplyFailed ? "error" : (root.hasPendingChanges ? "pending" : "check_circle"))
                            size: 14
                            color: root.isAppliedSuccess ? Style.success : (root.isApplyFailed ? Style.danger : (root.hasPendingChanges ? Style.warningYellow : Style.textSecondary))
                        }
                        Text {
                            text: root.isAppliedSuccess ? "Settings Applied Successfully!" : (root.isApplyFailed ? "Failed to apply settings" : (root.hasPendingChanges ? "Unsaved Changes" : "Configuration Synchronized"))
                            font.family: Style.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.isAppliedSuccess ? Style.success : (root.isApplyFailed ? Style.danger : (root.hasPendingChanges ? Style.warningYellow : Style.textSecondary))
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Reset to Defaults Button
                    Rectangle {
                        implicitWidth: 120; implicitHeight: 32; radius: 16
                        color: resetM.containsMouse ? "#2C2C2E" : "transparent"
                        border.color: "#2C2C2E"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            M3Icon { name: "restart_alt"; size: 14; color: Style.textPrimary }
                            Text { text: "Reset Tab"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: Style.textPrimary }
                        }

                        MouseArea {
                            id: resetM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.resetToDefaults()
                        }
                    }

                    // Apply Changes Primary Button
                    Rectangle {
                        implicitWidth: 130; implicitHeight: 32; radius: 16
                        color: root.hasPendingChanges ? Style.accent : "#2C2C2E"

                        scale: applyM.pressed ? 0.95 : ((applyM.containsMouse && root.hasPendingChanges) ? 1.05 : 1.0)
                        Behavior on scale { SpringAnimation { spring: 5.5; damping: 0.25 } }
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            M3Icon {
                                name: "done"
                                size: 14
                                color: root.hasPendingChanges ? Style.textOnAccent : Style.textSecondary
                            }
                            Text {
                                text: "Apply Changes"
                                font.family: Style.fontFamily; font.pixelSize: 11
                                font.weight: Font.Bold
                                color: root.hasPendingChanges ? Style.textOnAccent : Style.textSecondary
                            }
                        }

                        MouseArea {
                            id: applyM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: root.hasPendingChanges ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (root.hasPendingChanges) {
                                    root.applySettings();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
