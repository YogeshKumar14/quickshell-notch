import QtQuick
import "../theme"

Canvas {
    id: root

    // History series (0-100 scale) drawn as a stroked line with a gradient fill.
    property var hist: []
    // Current value for optional danger/warning threshold coloring.
    property int currentVal: 0
    // When true, line color shifts to warning (>60) / danger (>80).
    property bool thresholdColors: false

    implicitHeight: 42

    onHistChanged: requestPaint()

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
        ctx.lineWidth = 1.3;
        ctx.beginPath();

        var step = width / (hist.length - 1);
        for (var i = 0; i < hist.length; i++) {
            var x = i * step;
            var y = height - (hist[i] / 100.0 * (height - 4)) - 2;
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        var grad = ctx.createLinearGradient(0, 0, 0, height);
        grad.addColorStop(0, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.08));
        grad.addColorStop(1, Qt.rgba(colorObj.r, colorObj.g, colorObj.b, 0.0));
        ctx.fillStyle = grad;
        ctx.fill();
    }
}
