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

    /** Text width of the track title ticker, read by parent for dynamic pill width */
    readonly property real trackTitleWidth: trackTitleText.implicitWidth

    /** Emitted when user clicks compact pill to expand notch */
    signal expandRequested()
    /** Emitted when user clicks a specific workspace dot */
    signal workspaceSwitchRequested(int wsNum)

    // 1. COMPACT CLOCK DISPLAY
    Item {
        anchors.fill: parent
        opacity: (!root.isWorkspaceActive && !root.showVisualizer && !root.isOsdActive) ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.timeStr
                font.family: Style.fontFamily
                font.pixelSize: root.clockFontSize
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                style: Text.Raised
                styleColor: "#000000"
                color: Style.textPrimary
            }

            Rectangle {
                width: 14; height: 14; radius: 7
                color: Style.accent
                visible: root.notifCount > 0

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
        opacity: root.isWorkspaceActive ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expandRequested()
        }

        Item {
            anchors.centerIn: parent
            width: 218
            height: 14

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
        opacity: root.showVisualizer ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 14
            height: Style.notchHeightCompact
            spacing: 8

            // Mini Squircle Album Art Thumbnail (16x16px, radius 4px) with OpacityMask
            Item {
                width: 16
                height: 16
                Layout.alignment: Qt.AlignVCenter

                // 1. Source Image (hidden offscreen)
                Image {
                    id: compactArtImg
                    anchors.fill: parent
                    source: root.trackArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    sourceSize.width: 32
                    sourceSize.height: 32
                }

                // 2. Vector Mask Shape (Antialiased Squircle)
                Rectangle {
                    id: compactArtMask
                    anchors.fill: parent
                    radius: 4
                    color: "#000000"
                    visible: false
                    smooth: true
                    antialiasing: true
                }

                // 3. Fallback Placeholder Icon
                Rectangle {
                    id: compactArtFallback
                    anchors.fill: parent
                    radius: 4
                    color: "#2C2C2E"
                    border.color: "#3A3A3C"
                    border.width: 0.5
                    visible: compactArtImg.source.toString() === "" || compactArtImg.status !== Image.Ready
                    smooth: true
                    antialiasing: true

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
                    radius: 4
                    color: "transparent"
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 0.5
                    smooth: true
                    antialiasing: true
                }
            }

            Item { Layout.fillWidth: true } // Dynamic Left Spacer

            // Style 1: BARS (Spring Damped with Epsilon Deadband)
            Item {
                id: barContainer
                implicitWidth: 64
                implicitHeight: Style.notchHeightCompact
                Layout.alignment: Qt.AlignVCenter
                visible: root.visualizerStyle === "bars"

                property int barCount: Math.max(8, root.visualizerBarCount)
                property real barSpacing: Math.max(1, 4 - Math.floor((barCount - 8) / 4))
                property real barW: Math.max(2, Math.floor((64 - (barCount - 1) * barSpacing) / barCount))

                Repeater {
                    model: barContainer.barCount

                    Rectangle {
                        id: visBar
                        width: barContainer.barW
                        x: index * (barContainer.barW + barContainer.barSpacing)
                        anchors.verticalCenter: parent.verticalCenter

                        property real rawVal: (root.visualizerFrame && index < root.visualizerFrame.length) ? root.visualizerFrame[index] : 0
                        // Apply epsilon deadband (< 6% treated as 0 to eliminate floor noise)
                        property real cleanVal: rawVal < 6 ? 0 : rawVal
                        property real targetH: Math.max(2, Math.min(root.visualizerHeight, Math.round((cleanVal / 100.0) * root.visualizerHeight)))

                        height: targetH
                        radius: 1
                        color: Style.accent

                        Behavior on height {
                            SpringAnimation {
                                spring: 4.5
                                damping: 0.35
                                epsilon: 0.1
                            }
                        }
                    }
                }
            }

            // Style 2: WAVE (2D Canvas Frequency Sine Soundwave)
            Canvas {
                id: waveCanvas
                implicitWidth: 100
                implicitHeight: Style.notchHeightCompact
                Layout.alignment: Qt.AlignVCenter
                visible: root.visualizerStyle === "wave"

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Style.accent;
                    ctx.lineWidth = root.visualizerWaveWidth;
                    ctx.beginPath();

                    var count = root.visualizerFrame ? root.visualizerFrame.length : 10;
                    var step = width / Math.max(1, count - 1);
                    for (var i = 0; i < count; i++) {
                        var x = i * step;
                        var val = root.visualizerFrame[i] || 0;
                        var amp = (val / 100.0) * (root.visualizerHeight / 2);
                        var y = (height / 2) + (i % 2 === 0 ? -amp : amp);
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
