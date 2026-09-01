/**
 * SparklineCanvas.qml — 2D History Sparkline Chart for QuickShell Notch
 *
 * Renders an anti-aliased continuous line chart with semi-transparent vertical gradient fill:
 *   - Supports dynamic threshold coloring (accent -> warning >60% -> danger >80%)
 *   - Auto-scales across variable history series lengths
 *   - Repaints only when visible and series data updates
 */

import QtQuick
import "../theme"

Canvas {
    id: root

    /** History series array (0-100 scale) drawn as a stroked line with a gradient fill */
    property var hist: []
    /** Current instantaneous value for threshold calculation */
    property int currentVal: 0
    /** When true, line color dynamically shifts to warning (>60) / danger (>80) */
    property bool thresholdColors: false

    implicitHeight: 42
    onHistChanged: if (visible && width > 0) requestPaint()
    onVisibleChanged: if (visible && width > 0) requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (!hist || hist.length < 2) return;

        var colorObj = Style.accent;
        if (thresholdColors) {
            var val = currentVal;
            if (val > 80) colorObj = Style.danger;
            else if (val > 60) colorObj = Style.warning;
        }

        ctx.strokeStyle = colorObj;
        ctx.lineWidth = 1.8;
        ctx.beginPath();

        var step = width / Math.max(1, hist.length - 1);
        for (var i = 0; i < hist.length; i++) {
            var x = i * step;
            var y = height - (Math.max(0, Math.min(100, hist[i])) / 100.0 * (height - 8)) - 4;
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        var grad = ctx.createLinearGradient(0, 0, 0, height);
        grad.addColorStop(0, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.25));
        grad.addColorStop(1, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.02));
        ctx.fillStyle = grad;
        ctx.fill();
    }
}
