import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    property bool isOpen: false
    property int currentTab: 0 // 0: Hyprland Options, 1: Top Notch Bar Options

    signal notchSettingsChanged()

    function toggle() {
        isOpen = !isOpen;
        if (isOpen) {
            hasPendingChanges = false;
            getOptionsProc.running = true;
            getNotchProc.running = true;
        }
    }

    visible: isOpen
    implicitWidth: 780
    implicitHeight: 720

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
    property int notchAutoClose: 5000
    property int notchCompactWidth: 130
    property int notchExpandedHeight: 420
    property int notchBottomRadius: 16
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

    Process {
        id: getOptionsProc
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/hyprland/get_hypr_options.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim());
                    if (data.gaps_in !== undefined) root.gapsInVal = data.gaps_in;
                    if (data.gaps_out !== undefined) root.gapsOutVal = data.gaps_out;
                    if (data.rounding !== undefined) root.roundingVal = data.rounding;
                    if (data.border_size !== undefined) root.borderWidthVal = data.border_size;
                    if (data.blur_enabled !== undefined) root.blurEnabledVal = data.blur_enabled;
                    if (data.active_border !== undefined) root.activeBorderVal = data.active_border;
                    if (data.inactive_border !== undefined) root.inactiveBorderVal = data.inactive_border;
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
                } catch (e) {
                    console.log("Error parsing hypr options:", e);
                }
            }
        }
    }

    Process {
        id: getNotchProc
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/notch/get_notch_settings.py"]
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
                    if (data.expand_tension !== undefined) root.expandSpringTension = data.expand_tension;
                    if (data.expand_damping !== undefined) root.expandSpringDamping = data.expand_damping;
                    if (data.tab_tension !== undefined) root.tabSpringTension = data.tab_tension;
                    if (data.tab_damping !== undefined) root.tabSpringDamping = data.tab_damping;
                    if (data.stats_interval !== undefined) root.sysStatsIntervalVal = data.stats_interval;
                    if (data.osd_timeout !== undefined) root.osdTimeoutVal = data.osd_timeout;
                    if (data.clock_format !== undefined) root.clockFormatVal = data.clock_format;
                    if (data.clock_font_size !== undefined) root.clockFontSizeVal = data.clock_font_size;
                    if (data.battery_warning_threshold !== undefined) root.batteryWarningThresholdVal = data.battery_warning_threshold;
                } catch (e) {
                    console.log("Error parsing notch settings:", e);
                }
            }
        }
    }

    // Atomic Single Process Batch Executor
    Process {
        id: applyAllProc
        stdout: StdioCollector {
            onStreamFinished: {
                var statusText = this.text;
                if (statusText.indexOf("\"status\": \"partial\"") >= 0 || statusText.indexOf("\"status\": \"error\"") >= 0) {
                    root.isApplyFailed = true;
                    applyFailedTimer.restart();
                    return;
                }
                root.hasPendingChanges = false;
                root.isAppliedSuccess = true;
                appliedSuccessTimer.restart();
                root.notchSettingsChanged();
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.isApplyFailed = true;
                applyFailedTimer.restart();
            }
        }
    }

    // Reset Defaults Process
    Process {
        id: resetDefaultsProc
        stdout: StdioCollector {
            onStreamFinished: {
                // Delay re-fetch to let the reset script finish writing
                resetRefetchTimer.restart();
            }
        }
    }

    Timer {
        id: resetRefetchTimer
        interval: 300
        repeat: false
        onTriggered: {
            getOptionsProc.running = true;
            getNotchProc.running = true;
            root.hasPendingChanges = false;
        }
    }

    function applyAllSettings() {
        applyAllProc.running = false;
        var payload = {
            "hypr": {
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
                "dim_inactive": root.dimInactiveVal,
                "master_ratio": root.masterRatioVal,
                "active_border": root.activeBorderVal,
                "inactive_border": root.inactiveBorderVal,
                "shadow_range": root.shadowRangeVal,
                "blur_size": root.blurSizeVal,
                "blur_passes": root.blurPassesVal,
                "input_sensitivity": root.inputSensitivityVal,
                "input_tap_to_click": root.inputTapToClickVal,
                "input_natural_scroll": root.inputNaturalScrollVal
            },
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
                "expand_tension": root.expandSpringTension,
                "expand_damping": root.expandSpringDamping,
                "tab_tension": root.tabSpringTension,
                "tab_damping": root.tabSpringDamping,
                "stats_interval": root.sysStatsIntervalVal,
                "osd_timeout": root.osdTimeoutVal,
                "clock_format": root.clockFormatVal,
                "clock_font_size": root.clockFontSizeVal,
                "battery_warning_threshold": root.batteryWarningThresholdVal
            }
        };

        applyAllProc.command = ["python3", "/home/yogesh/.config/quickshell/scripts/hyprland/apply_all_settings.py", JSON.stringify(payload)];
        applyAllProc.running = true;
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.radiusLarge
        color: Style.surfaceWindow
        border.color: Style.cardBorder
        border.width: 1

        opacity: root.isOpen ? 1.0 : 0.0
        scale: root.isOpen ? 1.0 : 0.96

        Behavior on opacity { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutQuad } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Header Bar with Segmented Control, Apply Changes Button & Reset Defaults
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Segmented Tab Switcher Control
                Rectangle {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 700
                    implicitHeight: 34
                    radius: 17
                    color: Style.cardBg
                    border.color: Style.cardBorder

                    // Sliding Hover Pill (master handle — springs to the hovered tab)
                    Rectangle {
                        id: settingsHoverPill
                        height: 28
                        radius: 14
                        color: Style.cardBgHover
                        z: 0
                        anchors.top: parent.top
                        anchors.topMargin: 3

                        property var hoveredItem: settingsSegRow.hoveredIndex >= 0 ? settingsSegRepeater.itemAt(settingsSegRow.hoveredIndex) : null
                        x: hoveredItem ? hoveredItem.x + 3 : settingsSlidingPill.x
                        width: hoveredItem ? hoveredItem.width : settingsSlidingPill.width
                        opacity: settingsSegRow.hoveredIndex >= 0 && settingsSegRow.hoveredIndex !== root.currentTab ? 1 : 0

                        Behavior on x { enabled: settingsHoverPill.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                        Behavior on width { enabled: settingsHoverPill.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                        Behavior on opacity { NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                    }

                    // Sliding Highlight Pill (master highlight handle — springs to the active tab)
                    Rectangle {
                        id: settingsSlidingPill
                        height: 28
                        radius: 14
                        color: Style.accent
                        z: 0
                        anchors.top: parent.top
                        anchors.topMargin: 3

                        property var currentItem: (settingsSegRepeater.count > 0) ? settingsSegRepeater.itemAt(root.currentTab) : null
                        x: currentItem ? currentItem.x + 3 : 0
                        width: currentItem ? currentItem.width : 0

                        Behavior on x { enabled: settingsSlidingPill.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                        Behavior on width { enabled: settingsSlidingPill.width > 0; SpringAnimation { spring: root.tabSpringTension; damping: root.tabSpringDamping } }
                    }

                    RowLayout {
                        id: settingsSegRow
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 0
                        z: 1 // Keep tabs above the sliding pills

                        property int hoveredIndex: -1

                        Repeater {
                            id: settingsSegRepeater
                            model: ["General", "Input", "Looks", "System"]
                            delegate: Rectangle {
                                property bool isHovered: tabMouse.containsMouse
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: "transparent"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    M3Icon {
                                        name: index === 0 ? "settings" : (index === 1 ? "memory" : (index === 2 ? "wallpaper" : "hard_drive"))
                                        size: 16
                                        color: root.currentTab === index ? Style.textOnAccent : Style.textPrimary
                                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                    }

                                    Text {
                                        text: modelData
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontSizeSmall
                                        font.weight: root.currentTab === index ? Font.Bold : Font.Normal
                                        color: root.currentTab === index ? Style.textOnAccent : Style.textPrimary
                                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                                    }
                                }

                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentTab = index
                                    onEntered: settingsSegRow.hoveredIndex = index
                                    onExited: if (settingsSegRow.hoveredIndex === index) settingsSegRow.hoveredIndex = -1
                                }

                                // Dynamic M3 Divider
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 1
                                    height: 16
                                    color: Style.cardBorder
                                    visible: index < 3 && root.currentTab !== index && root.currentTab !== index + 1
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }



                // Close Button
                Rectangle {
                    width: 34; height: 34; radius: 17
                    color: closeM.containsMouse ? Style.danger : Style.cardBg
                    border.color: Style.cardBorder

                    scale: (root.buttonAnimsVal && closeM.pressed) ? 0.95 : ((root.buttonAnimsVal && closeM.containsMouse) ? 1.08 : 1.0)
                    Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                    M3Icon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 16
                        color: closeM.containsMouse ? Style.textPrimary : Style.textSecondary
                        Behavior on color { ColorAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
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

            // Scrollable Content Viewport
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: {
                    if (root.currentTab === 0) return hyprCol.height + 24;
                    if (root.currentTab === 1) return inputCol.height + 24;
                    if (root.currentTab === 2) return notchCol.height + 24;
                    if (root.currentTab === 3) return notchSysCol.height + 24;
                    return 0;
                }
                clip: true

                // TAB 0: HYPRLAND OPTIONS
                Column {
                    id: hyprCol
                    width: parent.width - 6
                    spacing: 20
                    opacity: root.currentTab === 0 ? 1.0 : 0.0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation { duration: Style.animFast; easing.type: Easing.OutQuad }
                    }

                    // SECTION 1: Window Layout & Gaps
                    Column {
                        width: parent.width
                        spacing: 8

                        RowLayout {
                            width: parent.width
                            spacing: 6
                            M3Icon { name: "desktop_windows"; color: Style.accent; size: 16 }
                            Text { text: "WINDOW LAYOUT & GAPS"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width
                            height: sec1Inner.height + 24
                            radius: Style.radiusMedium
                            color: Style.cardBg
                            border.color: Style.cardBorder

                            Column {
                                id: sec1Inner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                anchors.margins: 14; spacing: 14

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Window Layout Mode"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    RowLayout {
                                        spacing: 6; Layout.alignment: Qt.AlignVCenter
                                        Repeater {
                                            model: ["dwindle", "master"]
                                            Rectangle {
                                                implicitWidth: 76; implicitHeight: 28; radius: 14
                                                color: root.layoutVal === modelData ? Style.accent : Style.cardBgHover
                                                Text { anchors.centerIn: parent; text: modelData; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: root.layoutVal === modelData ? "#000" : Style.textSecondary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.layoutVal = modelData; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider; visible: root.layoutVal === "master" }

                                Column {
                                    width: parent.width; spacing: 6; visible: root.layoutVal === "master"
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Master Split Ratio (mfact)"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.masterRatioVal.toFixed(2); font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0.30; to: 0.70; value: root.masterRatioVal; stepSize: 0.05
                                        onMoved: function(val) { root.masterRatioVal = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Inner Gaps"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.gapsInVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0; to: 30; value: root.gapsInVal; stepSize: 1
                                        onMoved: function(val) { root.gapsInVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Outer Gaps"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.gapsOutVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0; to: 40; value: root.gapsOutVal; stepSize: 1
                                        onMoved: function(val) { root.gapsOutVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 2: Aesthetics & Opacity
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "settings"; color: Style.accent; size: 16 }
                            Text { text: "DECORATION & OPACITY"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: sec2Inner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: sec2Inner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Active Window Opacity"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(root.activeOpacityVal * 100) + " %"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0.50; to: 1.00; value: root.activeOpacityVal; stepSize: 0.05
                                        onMoved: function(val) { root.activeOpacityVal = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Inactive Window Opacity"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(root.inactiveOpacityVal * 100) + " %"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0.50; to: 1.00; value: root.inactiveOpacityVal; stepSize: 0.05
                                        onMoved: function(val) { root.inactiveOpacityVal = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Dim Inactive Windows"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.dimInactiveVal; onToggled: function(val) { root.dimInactiveVal = val; root.hasPendingChanges = true; } }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Window Drop Shadow"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.shadowEnabledVal; onToggled: function(val) { root.shadowEnabledVal = val; root.hasPendingChanges = true; } }
                                }

                                Column {
                                    width: parent.width; spacing: 6
                                    visible: root.shadowEnabledVal
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Shadow Spread Range"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.shadowRangeVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 1; to: 40; value: root.shadowRangeVal; stepSize: 1
                                        onMoved: function(val) { root.shadowRangeVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 3: Borders & Effects
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "settings"; color: Style.accent; size: 16 }
                            Text { text: "BORDERS & EFFECTS"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: sec3Inner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: sec3Inner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Corner Rounding Radius"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.roundingVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0; to: 25; value: root.roundingVal; stepSize: 1
                                        onMoved: function(val) { root.roundingVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Border Width"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.borderWidthVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0; to: 10; value: root.borderWidthVal; stepSize: 1
                                        onMoved: function(val) { root.borderWidthVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Window Blur Effect"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.blurEnabledVal; onToggled: function(val) { root.blurEnabledVal = val; root.hasPendingChanges = true; } }
                                }

                                Column {
                                    width: parent.width; spacing: 6
                                    visible: root.blurEnabledVal
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Blur Size"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.blurSizeVal; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 1; to: 16; value: root.blurSizeVal; stepSize: 1
                                        onMoved: function(val) { root.blurSizeVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Column {
                                    width: parent.width; spacing: 6
                                    visible: root.blurEnabledVal
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Blur Passes"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.blurPassesVal; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 1; to: 6; value: root.blurPassesVal; stepSize: 1
                                        onMoved: function(val) { root.blurPassesVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Hyprland Animations"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.animationsEnabledVal; onToggled: function(val) { root.animationsEnabledVal = val; root.hasPendingChanges = true; } }
                                }
                            }
                        }
                    }
                }

                // TAB 1: HYPRLAND INPUT
                Column {
                    id: inputCol
                    width: parent.width - 6
                    spacing: 20
                    opacity: root.currentTab === 1 ? 1.0 : 0.0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation { duration: Style.animFast; easing.type: Easing.OutQuad }
                    }

                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "keyboard"; color: Style.accent; size: 16 }
                            Text { text: "MOUSE & TOUCHPAD INPUT"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secInpInner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secInpInner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Pointer Sensitivity"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.inputSensitivityVal.toFixed(2); font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: -1.0; to: 1.0; value: root.inputSensitivityVal; stepSize: 0.1
                                        onMoved: function(val) { root.inputSensitivityVal = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Touchpad Tap-to-Click"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.inputTapToClickVal; onToggled: function(val) { root.inputTapToClickVal = val; root.hasPendingChanges = true; } }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Touchpad Natural Scrolling"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.inputNaturalScrollVal; onToggled: function(val) { root.inputNaturalScrollVal = val; root.hasPendingChanges = true; } }
                                }
                            }
                        }
                    }
                }

                // TAB 2: NOTCH APPEARANCE
                Column {
                    id: notchCol
                    width: parent.width - 6
                    spacing: 20
                    opacity: root.currentTab === 2 ? 1.0 : 0.0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation { duration: Style.animFast; easing.type: Easing.OutQuad }
                    }

                    // SECTION 1: MUSIC VISUALIZER OVERLAY & STYLES
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "music_note"; color: Style.accent; size: 16 }
                            Text { text: "MUSIC VISUALIZER OVERLAY & STYLES"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secvisInner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secvisInner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Music Visualizer Notch Overlay"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.visualizerEnabledVal; onToggled: function(val) { root.visualizerEnabledVal = val; root.hasPendingChanges = true; } }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Visualizer Style"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    RowLayout {
                                        spacing: 6; Layout.alignment: Qt.AlignVCenter
                                        Repeater {
                                            model: [
                                                { "id": "bars", "label": "Bars" },
                                                { "id": "wave", "label": "Wave" },
                                                { "id": "pulsar", "label": "Pulsar" }
                                            ]
                                            Rectangle {
                                                implicitWidth: 62; implicitHeight: 28; radius: 14
                                                color: root.visualizerStyleVal === modelData.id ? Style.accent : Style.cardBgHover
                                                Text { anchors.centerIn: parent; text: modelData.label; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: root.visualizerStyleVal === modelData.id ? "#000" : Style.textSecondary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.visualizerStyleVal = modelData.id; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                // Style-Specific Counterparts
                                Column {
                                    width: parent.width; spacing: 6; visible: root.visualizerStyleVal === "bars"
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Bars: Spectrum Count"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerBarCountVal + " Bars"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 8; to: 24; value: root.visualizerBarCountVal; stepSize: 2
                                        onMoved: function(val) { root.visualizerBarCountVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Column {
                                    width: parent.width; spacing: 6; visible: root.visualizerStyleVal === "wave"
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Wave: Line Thickness"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerWaveWidthVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 1; to: 5; value: root.visualizerWaveWidthVal; stepSize: 1
                                        onMoved: function(val) { root.visualizerWaveWidthVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Column {
                                    width: parent.width; spacing: 6; visible: root.visualizerStyleVal === "pulsar"
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Pulsar: Aura Expansion Sensitivity"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerPulsarScaleVal.toFixed(1) + "x"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0.5; to: 2.5; value: root.visualizerPulsarScaleVal; stepSize: 0.1
                                        onMoved: function(val) { root.visualizerPulsarScaleVal = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Visualizer Bar Max Height"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.visualizerHeightVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 10; to: 22; value: root.visualizerHeightVal; stepSize: 1
                                        onMoved: function(val) { root.visualizerHeightVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Visualizer Display Timeout"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: root.visualizerTimeoutVal === 0 ? "Continuous" : (Math.round(root.visualizerTimeoutVal / 1000) + "s")
                                            font.family: Style.fontFamilyMono
                                            font.pixelSize: Style.fontSizeSmall
                                            color: Style.accent
                                            font.weight: Font.Bold
                                        }
                                    }
                                    CustomSlider {
                                        width: parent.width
                                        from: 1
                                        to: 11
                                        stepSize: 1
                                        value: root.visualizerTimeoutVal === 0 ? 11 : Math.max(1, Math.min(10, Math.round(root.visualizerTimeoutVal / 1000)))
                                        onMoved: function(val) {
                                            var step = Math.round(val);
                                            if (step >= 11) {
                                                root.visualizerTimeoutVal = 0;
                                            } else {
                                                root.visualizerTimeoutVal = step * 1000;
                                            }
                                            root.hasPendingChanges = true;
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Pause / Stop Dismissal Delay"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: (root.visualizerPauseDelayVal / 1000).toFixed(1) + " s"
                                            font.family: Style.fontFamilyMono
                                            font.pixelSize: Style.fontSizeSmall
                                            color: Style.accent
                                            font.weight: Font.Bold
                                        }
                                    }
                                    CustomSlider {
                                        width: parent.width
                                        from: 0
                                        to: 5000
                                        stepSize: 500
                                        value: root.visualizerPauseDelayVal
                                        onMoved: function(val) {
                                            root.visualizerPauseDelayVal = Math.round(val);
                                            root.hasPendingChanges = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 2: BUTTON MICRO-ANIMATIONS
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "desktop_windows"; color: Style.accent; size: 16 }
                            Text { text: "BUTTON MICRO-ANIMATIONS"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secbtnInner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secbtnInner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Tactile Button Micro-Animations"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.buttonAnimsVal; onToggled: function(val) { root.buttonAnimsVal = val; root.hasPendingChanges = true; } }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Button Animation Speed"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    RowLayout {
                                        spacing: 6; Layout.alignment: Qt.AlignVCenter
                                        Repeater {
                                            model: [
                                                { "speed": 120, "label": "Fast" },
                                                { "speed": 180, "label": "Smooth" },
                                                { "speed": 280, "label": "Gentle" }
                                            ]
                                            Rectangle {
                                                implicitWidth: 62; implicitHeight: 28; radius: 14
                                                color: root.buttonSpeedVal === modelData.speed ? Style.accent : Style.cardBgHover
                                                Text { anchors.centerIn: parent; text: modelData.label; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: root.buttonSpeedVal === modelData.speed ? "#000" : Style.textSecondary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.buttonSpeedVal = modelData.speed; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 3: WORKSPACE HANDLE ANIMATION & TIMEOUT
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "desktop_windows"; color: Style.accent; size: 16 }
                            Text { text: "WORKSPACE OVERLAY & HANDLE ANIMATIONS"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secwsInner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secwsInner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Workspace Handle Animation"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    RowLayout {
                                        spacing: 6; Layout.alignment: Qt.AlignVCenter
                                        Repeater {
                                            model: [
                                                { "id": "stretch", "label": "Stretch" },
                                                { "id": "smooth", "label": "Smooth" },
                                                { "id": "linear", "label": "Linear" },
                                                { "id": "bounce", "label": "Bounce" }
                                            ]
                                            Rectangle {
                                                implicitWidth: 62; implicitHeight: 28; radius: 14
                                                color: root.wsAnimTypeVal === modelData.id ? Style.accent : Style.cardBgHover
                                                Text { anchors.centerIn: parent; text: modelData.label; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: root.wsAnimTypeVal === modelData.id ? "#000" : Style.textSecondary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.wsAnimTypeVal = modelData.id; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Workspace Switch Overlay"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.workspaceOverlayVal; onToggled: function(val) { root.workspaceOverlayVal = val; root.hasPendingChanges = true; } }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Workspace Notch Display Duration"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: (root.workspaceTimeoutVal / 1000.0).toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 1000; to: 6000; value: root.workspaceTimeoutVal; stepSize: 500
                                        onMoved: function(val) { root.workspaceTimeoutVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 4: APPEARANCE, CLOCK & APP LAUNCHER GRID
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "desktop_windows"; color: Style.accent; size: 16 }
                            Text { text: "BAR APPEARANCE, CLOCK & APP GRID"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secn1Inner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secn1Inner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Dripping Notch Inverted Ears"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch { Layout.alignment: Qt.AlignVCenter; checked: root.drippingEarsVal; onToggled: function(val) { root.drippingEarsVal = val; root.hasPendingChanges = true; } }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "12-Hour AM/PM Clock Format"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    CustomSwitch {
                                        Layout.alignment: Qt.AlignVCenter
                                        checked: root.clockFormatVal === "h:mm A"
                                        onToggled: function(val) { root.clockFormatVal = val ? "h:mm A" : "HH:mm"; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                RowLayout {
                                    width: parent.width; height: 32
                                    Text { text: "Clock String Format (Qt QML)"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 140; height: 28; radius: 6; color: Style.cardBgHover; border.color: Style.inputBorder
                                        TextInput {
                                            anchors.fill: parent; anchors.margins: 4
                                            verticalAlignment: TextInput.AlignVCenter
                                            horizontalAlignment: TextInput.AlignHCenter
                                            font.family: Style.fontFamilyMono
                                            font.pixelSize: Style.fontSizeSmall
                                            color: Style.accent
                                            text: root.clockFormatVal
                                            onEditingFinished: { root.clockFormatVal = text; root.hasPendingChanges = true; }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Clock Font Size"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.clockFontSizeVal + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 10; to: 24; value: root.clockFontSizeVal; stepSize: 1
                                        onMoved: function(val) { root.clockFontSizeVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "App Launcher Grid Columns"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.appColumnsVal + " Columns"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 3; to: 6; value: root.appColumnsVal; stepSize: 1
                                        onMoved: function(val) { root.appColumnsVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Expanded Notch Height"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.notchExpandedHeight + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 350; to: 480; value: root.notchExpandedHeight; stepSize: 10
                                        onMoved: function(val) { root.notchExpandedHeight = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Notch Bottom Corner Radius"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.notchBottomRadius + " px"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 8; to: 24; value: root.notchBottomRadius; stepSize: 1
                                        onMoved: function(val) { root.notchBottomRadius = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 5: WALLPAPER TRANSITION
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "wallpaper"; color: Style.accent; size: 16 }
                            Text { text: "WALLPAPER TRANSITION CONTROL"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secn2Inner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secn2Inner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Transition Effect"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    RowLayout {
                                        spacing: 6; Layout.alignment: Qt.AlignVCenter
                                        Repeater {
                                            model: [
                                                { "id": "outer", "label": "Outer" },
                                                { "id": "simple", "label": "Simple" },
                                                { "id": "grow", "label": "Grow" },
                                                { "id": "none", "label": "None" }
                                            ]
                                            Rectangle {
                                                implicitWidth: 56; implicitHeight: 28; radius: 14
                                                color: root.wallTypeVal === modelData.id ? Style.accent : Style.cardBgHover
                                                Text { anchors.centerIn: parent; text: modelData.label; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: root.wallTypeVal === modelData.id ? "#000" : Style.textSecondary }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.wallTypeVal = modelData.id; root.hasPendingChanges = true; } }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Transition Duration"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.wallDurationVal.toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0.2; to: 2.0; value: root.wallDurationVal; stepSize: 0.1
                                        onMoved: function(val) { root.wallDurationVal = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Wallpaper Folder"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary; Layout.alignment: Qt.AlignVCenter }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            width: 240; height: 28; radius: 6; color: Style.cardBgHover; border.color: Style.inputBorder
                                            TextInput {
                                                anchors.fill: parent; anchors.margins: 6
                                                verticalAlignment: TextInput.AlignVCenter
                                                font.family: Style.fontFamilyMono
                                                font.pixelSize: Style.fontSizeSmall
                                                color: Style.accent
                                                text: root.wallpaperDirVal
                                                onEditingFinished: { root.wallpaperDirVal = text.trim(); root.hasPendingChanges = true; }
                                            }
                                        }
                                    }
                                    Text { text: "Leave empty to scan the default folders (~/Pictures/Wallpapers, WallpaperMinimal)"; font.family: Style.fontFamily; font.pixelSize: 10; color: Style.textMuted; wrapMode: Text.Wrap }
                                }
                            }
                        }
                    }

                    // SECTION 6: NOTCH EXPANSION ANIMATION
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "desktop_windows"; color: Style.accent; size: 16 }
                            Text { text: "NOTCH EXPANSION ANIMATION"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secn3Inner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secn3Inner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Expansion Tension"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.expandSpringTension.toFixed(1); font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 1.0; to: 10.0; value: root.expandSpringTension; stepSize: 0.5
                                        onMoved: function(val) { root.expandSpringTension = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Expansion Damping"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.expandSpringDamping.toFixed(2); font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0.10; to: 0.80; value: root.expandSpringDamping; stepSize: 0.02
                                        onMoved: function(val) { root.expandSpringDamping = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Tab Slide Tension"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.tabSpringTension.toFixed(1); font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 1.0; to: 10.0; value: root.tabSpringTension; stepSize: 0.5
                                        onMoved: function(val) { root.tabSpringTension = val; root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Tab Slide Damping"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.tabSpringDamping.toFixed(2); font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 0.10; to: 0.80; value: root.tabSpringDamping; stepSize: 0.02
                                        onMoved: function(val) { root.tabSpringDamping = val; root.hasPendingChanges = true; }
                                    }
                                }
                            }
                        }
                    }

                } // End of Tab 2

                // TAB 3: NOTCH SYSTEM
                Column {
                    id: notchSysCol
                    width: parent.width - 6
                    spacing: 20
                    opacity: root.currentTab === 3 ? 1.0 : 0.0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation { duration: Style.animFast; easing.type: Easing.OutQuad }
                    }

                    // SECTION 5.1: POWER & OSD
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "battery_charging_full"; color: Style.accent; size: 16 }
                            Text { text: "POWER & OSD TIMEOUTS"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secPowerInner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secPowerInner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Battery Warning Threshold"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.batteryWarningThresholdVal + "%"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 5; to: 40; value: root.batteryWarningThresholdVal; stepSize: 1
                                        onMoved: function(val) { root.batteryWarningThresholdVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Style.divider }

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "OSD Notification Timeout"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: (root.osdTimeoutVal / 1000.0).toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 500; to: 5000; value: root.osdTimeoutVal; stepSize: 250
                                        onMoved: function(val) { root.osdTimeoutVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 5.5: SYSTEM MONITOR & POLLING RATE
                    Column {
                        width: parent.width; spacing: 8
                        RowLayout {
                            width: parent.width; spacing: 6
                            M3Icon { name: "memory"; color: Style.accent; size: 16 }
                            Text { text: "SYSTEM MONITOR & POLLING RATE"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: Style.textMuted }
                        }

                        Rectangle {
                            width: parent.width; height: secnSysInner.height + 24; radius: Style.radiusMedium; color: Style.cardBg; border.color: Style.cardBorder
                            Column {
                                id: secnSysInner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14

                                Column {
                                    width: parent.width; spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Hardware Stats Polling Rate"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal; color: Style.textPrimary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: (root.sysStatsIntervalVal / 1000.0).toFixed(1) + " s"; font.family: Style.fontFamilyMono; font.pixelSize: Style.fontSizeSmall; color: Style.accent; font.weight: Font.Bold }
                                    }
                                    CustomSlider {
                                        width: parent.width; from: 500; to: 5000; value: root.sysStatsIntervalVal; stepSize: 250
                                        onMoved: function(val) { root.sysStatsIntervalVal = Math.round(val); root.hasPendingChanges = true; }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Bottom Action Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                // Reset Defaults Button
                Rectangle {
                    implicitWidth: resetRow.implicitWidth + 14
                    implicitHeight: 34
                    radius: 17
                    color: resetM.containsMouse ? Style.cardBgHover : Style.cardBg
                    border.color: Style.cardBorder

                    scale: (root.buttonAnimsVal && resetM.pressed) ? 0.95 : ((root.buttonAnimsVal && resetM.containsMouse) ? 1.05 : 1.0)
                    Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }

                    RowLayout {
                        id: resetRow
                        anchors.centerIn: parent
                        spacing: 6
                        M3Icon { name: "refresh"; color: Style.accent; size: 16 }
                        Text { text: "Reset"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; color: Style.textPrimary; font.weight: Font.Bold }
                    }

                    MouseArea {
                        id: resetM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            resetDefaultsProc.command = ["bash", "/home/yogesh/.config/quickshell/scripts/hyprland/set_hypr_option.sh", "reset_defaults", ""];
                            resetDefaultsProc.running = true;
                        }
                    }
                }

                // APPLY CHANGES BUTTON (Highlights when changes exist, gives 2s "Applied ✓" feedback)
                Rectangle {
                    implicitWidth: applyRow.implicitWidth + 20
                    implicitHeight: 34
                    radius: 17
                    color: root.isApplyFailed ? Style.danger : (root.isAppliedSuccess ? Style.success : (root.hasPendingChanges ? Style.accent : (applyM.containsMouse ? Style.cardBgHover : Style.cardBg)))
                    border.color: root.hasPendingChanges ? Style.accent : Style.cardBorder

                    scale: (root.buttonAnimsVal && applyM.pressed) ? 0.95 : ((root.buttonAnimsVal && applyM.containsMouse) ? 1.05 : 1.0)
                    Behavior on scale { enabled: root.buttonAnimsVal; NumberAnimation { duration: root.buttonSpeedVal; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 180 } }

                    RowLayout {
                        id: applyRow
                        anchors.centerIn: parent
                        spacing: 6

                        M3Icon {
                            name: root.isApplyFailed ? "error" : (root.isAppliedSuccess ? "done" : (root.hasPendingChanges ? "auto_awesome" : "done"))
                            size: 16
                            color: (root.isApplyFailed || root.isAppliedSuccess) ? Style.textPrimary : (root.hasPendingChanges ? Style.textOnAccent : Style.textSecondary)
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutQuad } }
                        }

                        Text {
                            text: root.isApplyFailed ? "Apply Failed" : (root.isAppliedSuccess ? "Applied ✓" : (root.hasPendingChanges ? "Apply Changes *" : "Apply Changes"))
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            color: (root.isApplyFailed || root.isAppliedSuccess) ? Style.textPrimary : (root.hasPendingChanges ? Style.textOnAccent : Style.textPrimary)
                            font.weight: Font.Bold
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutQuad } }
                        }
                    }

                    MouseArea {
                        id: applyM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyAllSettings()
                    }
                }
            }
        }
    }
}
