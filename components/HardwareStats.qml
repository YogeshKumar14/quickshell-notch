/**
 * HardwareStats.qml — System Resource Monitoring Dashboard for QuickShell Notch
 *
 * Renders PAGE 3 of the expanded notch:
 *   - CPU Usage percentage with history sparkline canvas
 *   - RAM Memory utilization percentage with history sparkline canvas
 *   - Network I/O throughput rate with auto-scaling unit formatting (B/s, KB/s, MB/s)
 *   - Disk Storage percentage with custom 2D radial arc canvas gauge
 */

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    /** Current CPU utilization percentage (0..100) */
    property int cpuUsage: 0
    /** Array of recent CPU usage history values for sparkline */
    property var cpuHistory: []

    /** Current RAM memory utilization percentage (0..100) */
    property int ramUsage: 0
    /** Array of recent RAM usage history values for sparkline */
    property var ramHistory: []

    /** Network receive throughput in bytes/second */
    property real netRxSpeed: 0
    /** Network transmit throughput in bytes/second */
    property real netTxSpeed: 0
    /** Array of recent network activity history values for sparkline */
    property var netHistory: []

    /** Current Root disk partition usage percentage (0..100) */
    property int diskUsage: 0

    /** True if this tab is currently visible, used to guard Canvas repaints */
    property bool isActiveTab: true

    /** Expose content height to parent for dynamic notch height sizing */
    readonly property int statsContentHeight: statsRow.implicitHeight

    /** Formats raw byte rates into human-readable network speed strings */
    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + "B/s";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(0) + "K/s";
        return (bytes / (1024 * 1024)).toFixed(1) + "M/s";
    }

    RowLayout {
        id: statsRow
        anchors.fill: parent
        spacing: 8

        // CPU Usage Card
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: "#1C1C1E"
            border.color: "#2C2C2E"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    M3Icon { name: "memory"; color: Style.accent; size: 13 }
                    Text { text: "CPU"; font.family: Style.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                    Item { Layout.fillWidth: true }
                    Text { text: root.cpuUsage + "%"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Black; color: Style.accent }
                }

                SparklineCanvas {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    hist: root.cpuHistory
                    currentVal: root.cpuUsage
                    thresholdColors: true
                }
            }
        }

        // RAM Usage Card
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: "#1C1C1E"
            border.color: "#2C2C2E"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    M3Icon { name: "memory"; color: "#BF5AF2"; size: 13 }
                    Text { text: "RAM"; font.family: Style.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                    Item { Layout.fillWidth: true }
                    Text { text: root.ramUsage + "%"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Black; color: "#BF5AF2" }
                }

                SparklineCanvas {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    hist: root.ramHistory
                    currentVal: root.ramUsage
                    thresholdColors: true
                }
            }
        }

        // Network Usage Card
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: "#1C1C1E"
            border.color: "#2C2C2E"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    M3Icon { name: "wifi"; color: "#30D158"; size: 13 }
                    Text { text: "NET"; font.family: Style.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                    Item { Layout.fillWidth: true }
                    Text { 
                        text: "⇣" + root.formatBytes(root.netRxSpeed)
                        font.family: Style.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: "#30D158"
                    }
                }

                SparklineCanvas {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    hist: root.netHistory
                }
            }
        }

        // Disk Storage Radial Gauge
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: "#1C1C1E"
            border.color: "#2C2C2E"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    M3Icon { name: "hard_drive"; color: "#FF9F0A"; size: 13 }
                    Text { text: "DISK"; font.family: Style.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                    Item { Layout.fillWidth: true }
                    Text { text: root.diskUsage + "%"; font.family: Style.fontFamily; font.pixelSize: 11; font.weight: Font.Black; color: "#FF9F0A" }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Canvas {
                        id: diskRadial
                        anchors.fill: parent
                        property real val: root.diskUsage
                        onValChanged: if (visible && root.isActiveTab) requestPaint()
                        onVisibleChanged: if (visible && root.isActiveTab) requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var cx = width / 2;
                            var cy = height / 2;
                            var r = Math.min(width, height) / 2 - 3;

                            // Background track
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                            ctx.lineWidth = 4;
                            ctx.strokeStyle = "#2C2C2E";
                            ctx.stroke();

                            // Accent progress
                            ctx.beginPath();
                            var endAngle = (root.diskUsage / 100.0) * 2 * Math.PI;
                            ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + endAngle);
                            ctx.strokeStyle = "#FF9F0A";
                            ctx.lineWidth = 4;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                    }
                }
            }
        }
    }
}
