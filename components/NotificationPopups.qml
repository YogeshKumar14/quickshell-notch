import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Item {
    id: root
    width: 350
    implicitHeight: popupColumn.implicitHeight
    
    property var activePopups: []
    
    function addNotification(notif) {
        var arr = root.activePopups.slice();
        arr.unshift(notif);
        root.activePopups = arr;
        
        var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 5000; running: true }", root);
        timer.triggered.connect(function() {
            removeNotification(notif);
            timer.destroy();
        });
    }
    
    function removeNotification(notif) {
        var arr = root.activePopups.slice();
        var idx = arr.indexOf(notif);
        if (idx !== -1) {
            arr.splice(idx, 1);
            root.activePopups = arr;
        }
    }

    Column {
        id: popupColumn
        width: parent.width
        spacing: 0
        
        Repeater {
            model: root.activePopups
            
            delegate: Item {
                width: popupColumn.width
                implicitHeight: notifLayout.implicitHeight + 24
                
                property var notif: modelData
                property bool isTop: index === 0
                property bool isBottom: index === root.activePopups.length - 1
                
                Rectangle {
                    anchors.fill: parent
                    color: Style.cardBg
                    bottomLeftRadius: isBottom ? Style.radiusLarge : 0
                }
                
                // Top-Left Inverted Ear
                Canvas {
                    id: topLeftEar
                    width: 24; height: 24
                    anchors.right: parent.left
                    anchors.top: parent.top
                    visible: isTop
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = Style.cardBg;
                        ctx.beginPath();
                        ctx.moveTo(width, 0);
                        ctx.lineTo(width, height);
                        ctx.lineTo(0, 0);
                        ctx.arcTo(width, 0, width, height, width);
                        ctx.fill();
                    }
                }
                
                // Bottom-Right Inverted Ear
                Canvas {
                    id: bottomRightEar
                    width: 24; height: 24
                    anchors.right: parent.right
                    anchors.top: parent.bottom
                    visible: isBottom
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = Style.cardBg;
                        ctx.beginPath();
                        ctx.moveTo(width, 0);
                        ctx.lineTo(0, 0);
                        ctx.lineTo(width, height);
                        ctx.arcTo(width, 0, 0, 0, width);
                        ctx.fill();
                    }
                }
                
                ColumnLayout {
                    id: notifLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    
                    Text {
                        text: notif.appName || "Notification"
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        color: Style.accent
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: notif.summary
                        font.family: Style.fontFamily
                        font.pixelSize: 13
                        color: Style.textPrimary
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: notif.body
                        font.family: Style.fontFamily
                        font.pixelSize: 12
                        color: Style.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                    }
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#22ffffff"
                    visible: !isBottom
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: removeNotification(notif)
                }
            }
        }
    }
}
