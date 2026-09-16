/**
 * CompactPill.qml — Collapsed Notch Pill Subsystem for QuickShell Notch
 *
 * Renders the compact state of the notch, managing 3 distinct dynamic modes:
 *   1. Default Clock Display + Notification Count Badge
 *   2. Realtime Workspace Overlay with spring-animated stretch/bounce indicator
 *   3. CAVA Audio Visualizer Overlay (Bars, Wave, Pulsar) with track title ticker
 */

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
import "../theme"

Item {
    id: root

    /** Formatted clock time string */
    property string timeStr: ""
    /** Clock typography size */
    property int clockFontSize: 14
    /** Unread notification badge count */
    property int notifCount: 0

    /** Realtime container dimensions from notch pill for spring bounce synchronization */
    property real containerWidth: width
    property real containerHeight: height
    property real targetWidth: width
    property real targetHeight: height
    property bool isExpanded: false

    /** Active Hyprland workspace ID (1..10) */
    property int activeWorkspace: 1
    /** Array of occupied workspace IDs */
    property var occupiedWorkspaces: [1]
    /** Workspace indicator animation mode ("stretch" or "smooth") */
    property string wsAnimType: "stretch"
    /** Whether workspace indicator is currently active/visible */
    property bool isWorkspaceActive: false
    /** Left coordinate for stretch handle */
    property real handleLeft: 0
    /** Right coordinate for stretch handle */
    property real handleRight: 16
    /** Position for smooth single-handle mode */
    property real singleHandleX: 0

    /** Whether audio visualizer overlay is active */
    property bool showVisualizer: false
    /** Visualizer rendering style ("bars", "wave", "pulsar") */
    property string visualizerStyle: "bars"
    /** Configured visualizer bar count */
    property int visualizerBarCount: 12
    /** Visualizer peak bar height in pixels */
    property int visualizerHeight: 16
    /** Wave canvas line stroke width */
    property int visualizerWaveWidth: 2
    /** Pulsar aura scaling multiplier */
    property real visualizerPulsarScale: 1.2
    /** Current audio frame amplitude array */
    property var visualizerFrame: []
    /** Current MPRIS playing track title */
    property string trackTitle: ""
    /** Current MPRIS playing track album art URL */
    property string trackArtUrl: ""
    /** True if OSD overlay is taking priority */
    property bool isOsdActive: false
    /** Whether visualizer was active prior to expansion / during collapse handoff */
    property bool wasVisualizerActive: false

    /** Text width of the track title ticker, read by parent for dynamic pill width */
    readonly property real trackTitleWidth: trackTitleText.implicitWidth

    // Realtime deviation factors driven by SpringAnimation on notchBox
    readonly property real hDelta: root.targetHeight > 0
        ? (root.containerHeight - root.targetHeight) / root.targetHeight
        : 0
    readonly property real wDelta: root.targetWidth > 0
        ? (root.containerWidth - root.targetWidth) / root.targetWidth
        : 0

    // Bound deviation inputs so macro-transitions glide smoothly into spring bounds
    readonly property real clampedH: Math.max(-0.25, Math.min(0.35, root.hDelta))
    readonly property real clampedW: Math.max(-0.45, Math.min(0.35, root.wDelta))

    // Realtime spring bounce scale synchronized with notch pill physical motion
    readonly property real pillSpringScale: {
        if (root.isExpanded) {
            // Smoothly follow outward expansion with the notch body
            var expDeltaW = (root.containerWidth - root.targetWidth) / Math.max(1, root.targetWidth);
            var expDeltaH = (root.containerHeight - root.targetHeight) / Math.max(1, root.targetHeight);
            var expProgress = (Math.max(0.0, expDeltaW) * 0.40) + (Math.max(0.0, expDeltaH) * 0.60);
            return 1.0 + Math.min(0.18, expProgress * 0.12);
        }

        // Dynamic spring scale:
        // Vertical compression squashes down on impact, rebounds past 1.0, and settles to 1.0.
        // Horizontal breathing flexes with width settling.
        var scaleVal = 1.0 + (root.clampedH * 0.45) + (root.clampedW * 0.35);
        return Math.max(0.80, Math.min(1.18, scaleVal));
    }

    // Vertical center follow-through clamped to physical notch bounds
    readonly property real bounceCenterY: {
        if (root.isExpanded) return 0;
        var diff = (root.containerHeight - root.targetHeight) * 0.5;
        return Math.max(-3.0, Math.min(3.0, diff));
    }

    /** Emitted when user clicks compact pill to expand notch */
    signal expandRequested()
    /** Emitted when user clicks a specific workspace dot */
    signal workspaceSwitchRequested(int wsNum)

    // 1. COMPACT CLOCK DISPLAY
    Item {
        id: clockDisplay
        anchors.fill: parent
        opacity: (!root.isWorkspaceActive && !root.showVisualizer && !root.isOsdActive) ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: (root.isOsdActive || root.isWorkspaceActive || root.isExpanded) ? 60 : 140
                easing.type: Easing.OutQuad
            }
        }

        RowLayout {
            id: clockRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.bounceCenterY
            spacing: 6

            transformOrigin: Item.Center
            scale: root.pillSpringScale

            Text {
                text: root.timeStr
                font.family: Style.fontFamily
                font.pixelSize: root.clockFontSize
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                style: Text.Raised
                styleColor: "#000000"
                color: Style.textPrimary
                smooth: true
            }

            Rectangle {
                width: 14; height: 14; radius: 7
                color: Style.accent
                visible: scale > 0.01
                smooth: true
                antialiasing: true

                scale: root.notifCount > 0 ? 1.0 : 0.0
                Behavior on scale {
                    SpringAnimation { spring: 5.5; damping: 0.3 }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.notifCount > 9 ? "9+" : root.notifCount.toString()
                    font.family: Style.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: "#000000"
                }
            }
        }
    }

    // 2. REALTIME WORKSPACE OVERLAY
    Item {
        anchors.fill: parent
        opacity: (root.isWorkspaceActive && !root.isOsdActive) ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: (root.isOsdActive || root.isExpanded) ? 60 : 140
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expandRequested()
        }

        Item {
            id: workspaceRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.bounceCenterY
            width: 218
            height: 14

            transformOrigin: Item.Center
            scale: root.pillSpringScale

            Row {
                anchors.centerIn: parent
                spacing: 16

                Repeater {
                    model: 10

                    Item {
                        width: 6; height: 6

                        property int wsNum: index + 1
                        property bool isOccupied: root.occupiedWorkspaces.indexOf(wsNum) !== -1

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width; height: parent.height; radius: 3
                            color: isOccupied ? '#ffffff' : Style.controlBorder

                            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (wsNum === root.activeWorkspace) {
                                    root.expandRequested();
                                } else {
                                    root.workspaceSwitchRequested(wsNum);
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                x: root.wsAnimType === "stretch" ? Math.min(root.handleLeft, root.handleRight) : root.singleHandleX
                width: root.wsAnimType === "stretch" ? Math.max(16, Math.abs(root.handleRight - root.handleLeft)) : 16
                height: 7
                radius: 4
                color: Style.accent
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // 3. REALTIME CAVA MUSIC VISUALIZER OVERLAY
    Item {
        anchors.fill: parent
        opacity: (root.showVisualizer && !root.isOsdActive && !root.isWorkspaceActive) ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: (root.isOsdActive || root.isWorkspaceActive || root.isExpanded) ? 60 : 140
                easing.type: Easing.OutQuad
            }
        }

        RowLayout {
            id: visRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.bounceCenterY
            anchors.leftMargin: Math.max(12, Style.bottomRadius - 8)
            anchors.rightMargin: Math.max(14, Style.bottomRadius - 2)
            height: Style.notchHeightCompact
            spacing: 8

            transformOrigin: Item.Center
            scale: root.pillSpringScale

            // Mini Squircle Album Art Thumbnail (18x18px) with OpacityMask
            Item {
                id: compactArtBox
                width: 18
                height: 18
                Layout.alignment: Qt.AlignVCenter

                readonly property real albumRadius: Math.max(4, Math.round(width * ((Style.bottomRadius > 0 ? Style.bottomRadius : Style.radiusLarge) / 78.0)))

                // 1. Source Image (hidden offscreen)
                Image {
                    id: compactArtImg
                    anchors.fill: parent
                    source: root.trackArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    sourceSize.width: 64
                    sourceSize.height: 64
                    smooth: true
                    mipmap: true
                    antialiasing: true
                }

                // 2. Vector Mask Shape (Antialiased Squircle)
                Rectangle {
                    id: compactArtMask
                    anchors.fill: parent
                    radius: compactArtBox.albumRadius
                    color: "#000000"
                    visible: false
                    smooth: true
                    antialiasing: true

                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                }

                // 3. Fallback Placeholder Icon
                Rectangle {
                    id: compactArtFallback
                    anchors.fill: parent
                    radius: compactArtBox.albumRadius
                    color: "#2C2C2E"
                    border.color: "#3A3A3C"
                    border.width: 0.5
                    visible: compactArtImg.source.toString() === "" || compactArtImg.status !== Image.Ready
                    smooth: true
                    antialiasing: true

                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                    M3Icon {
                        anchors.centerIn: parent
                        name: "music_note"
                        size: 11
                        color: Style.accent
                    }
                }

                // 4. Alpha-Masked Squircle Artwork
                OpacityMask {
                    anchors.fill: parent
                    source: compactArtImg
                    maskSource: compactArtMask
                    visible: compactArtImg.source.toString() !== "" && compactArtImg.status === Image.Ready
                }

                // 5. Crisp Structural Border Overlay
                Rectangle {
                    anchors.fill: parent
                    radius: compactArtBox.albumRadius
                    color: "transparent"
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 0.5
                    smooth: true
                    antialiasing: true

                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                }
            }

            Item { Layout.fillWidth: true } // Dynamic Left Spacer

            // Style 1: BARS (Clean Baseline Anchored + Independent Organic Physics)
            Item {
                id: barContainer
                Layout.alignment: Qt.AlignVCenter
                visible: root.visualizerStyle === "bars"

                property int barCount: Math.max(8, root.visualizerBarCount)
                property real barSpacing: barCount > 16 ? 1.5 : (barCount > 12 ? 2.0 : 2.5)
                property real barW: barCount > 16 ? 2.5 : (barCount > 12 ? 3.0 : 3.5)

                implicitWidth: Math.round(barCount * barW + (barCount - 1) * barSpacing)
                implicitHeight: root.visualizerHeight

                Repeater {
                    model: barContainer.barCount

                    Rectangle {
                        id: visBar
                        width: barContainer.barW
                        x: Math.round(index * (barContainer.barW + barContainer.barSpacing))
                        anchors.bottom: parent.bottom

                        property real rawVal: (root.visualizerFrame && index < root.visualizerFrame.length) ? root.visualizerFrame[index] : 0
                        // Apply epsilon deadband (< 6% treated as 0 to eliminate floor noise)
                        property real cleanVal: rawVal < 6 ? 0 : rawVal
                        property real minH: Math.max(2.5, root.visualizerHeight * 0.12)
                        property real targetH: Math.max(minH, Math.min(root.visualizerHeight, Math.round(minH + (cleanVal / 100.0) * (root.visualizerHeight - minH))))

                        height: targetH
                        radius: width / 2
                        color: Style.accent
                        smooth: true
                        antialiasing: true

                        // Independent organic physics per bar:
                        // Bass has more acoustic inertia and damping; treble has snappier bounce
                        Behavior on height {
                            SpringAnimation {
                                spring: 5.2 + (index / Math.max(1, barContainer.barCount - 1)) * 2.2
                                damping: 0.64 - (index / Math.max(1, barContainer.barCount - 1)) * 0.16
                                epsilon: 0.15
                            }
                        }
                    }
                }
            }

            // Style 2: WAVE (Smooth Frequency Sine Soundwave)
            Canvas {
                id: waveCanvas
                implicitWidth: Math.max(70, Math.min(120, root.visualizerBarCount * 6))
                implicitHeight: root.visualizerHeight
                Layout.alignment: Qt.AlignVCenter
                visible: root.visualizerStyle === "wave"

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Style.accent;
                    ctx.lineWidth = Math.max(1.5, root.visualizerWaveWidth);
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();

                    var count = (root.visualizerFrame && root.visualizerFrame.length > 0) ? root.visualizerFrame.length : 12;
                    var step = width / Math.max(1, count - 1);
                    var midY = height / 2;
                    for (var i = 0; i < count; i++) {
                        var x = i * step;
                        var val = (root.visualizerFrame && i < root.visualizerFrame.length) ? root.visualizerFrame[i] : 0;
                        var cleanVal = val < 6 ? 0 : val;
                        var amp = (cleanVal / 100.0) * (height / 2 - 1);
                        var y = midY + (i % 2 === 0 ? -amp : amp);
                        if (i === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }

                Connections {
                    target: root
                    function onVisualizerFrameChanged() {
                        if (root.showVisualizer && root.visualizerStyle === "wave") {
                            waveCanvas.requestPaint();
                        }
                    }
                }
            }

            // Style 3: PULSAR (Dynamic Core Pill + Concentric Aura Rings)
            Item {
                implicitWidth: 90
                implicitHeight: Style.notchHeightCompact
                Layout.alignment: Qt.AlignVCenter
                visible: root.visualizerStyle === "pulsar"

                function calcAvgAmp() {
                    if (!root.visualizerFrame || root.visualizerFrame.length === 0) return 0;
                    var sum = 0;
                    for (var i = 0; i < root.visualizerFrame.length; i++) sum += root.visualizerFrame[i];
                    return Math.min(1.0, ((sum / root.visualizerFrame.length) / 100.0) * root.visualizerPulsarScale);
                }

                // Outer Concentric Glow Ring 2
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(20, 78 * parent.calcAvgAmp())
                    height: Math.max(6, (root.visualizerHeight + 4) * parent.calcAvgAmp())
                    radius: height / 2
                    color: "transparent"
                    border.color: Style.accent
                    border.width: 1
                    opacity: 0.35 * parent.calcAvgAmp()
                }

                // Outer Concentric Glow Ring 1
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(16, 60 * parent.calcAvgAmp())
                    height: Math.max(5, (root.visualizerHeight + 2) * parent.calcAvgAmp())
                    radius: height / 2
                    color: "transparent"
                    border.color: Style.accent
                    border.width: 1.5
                    opacity: 0.6 * parent.calcAvgAmp()
                }

                // Inner Solid Glowing Core Pill
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(14, 46 * parent.calcAvgAmp())
                    height: Math.max(4, root.visualizerHeight * parent.calcAvgAmp())
                    radius: height / 2
                    color: Style.accent
                }
            }

            Item { Layout.fillWidth: true } // Dynamic Right Spacer

            Text {
                id: trackTitleText
                text: root.trackTitle
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                font.weight: Font.Bold
                color: Style.textPrimary
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                Layout.maximumWidth: 160
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
