import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Item {
    id: root
    
    // Popup container width is 350 + 24 (padding for the left ear) = 374
    width: 374
    implicitHeight: popupListView.contentHeight + 24 // extra 24 for bottom ear space
    
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

    ListView {
        id: popupListView
        width: parent.width
        height: contentHeight
        interactive: false
        spacing: 0
        
        model: root.activePopups
        
        // Add/Remove Spring Animations
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
                SpringAnimation { property: "x"; spring: 3.5; damping: 0.75; from: 374; to: 0 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; to: 374; duration: 200; easing.type: Easing.OutCubic }
            }
        }
        
        delegate: Item {
            width: popupListView.width
            implicitHeight: notifLayout.implicitHeight + 24
            
            property var notif: modelData
            property bool isTop: index === 0
            property bool isBottom: index === root.activePopups.length - 1
            
            // Solid Black Background for the 350px notification block
            Rectangle {
                width: 350
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                
                color: "#000000" // Solid Black matching the Notch
                
                bottomLeftRadius: isBottom ? 28 : 0
                
                ColumnLayout {
                    id: notifLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4
                    
                    // Header Row (App Name)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        M3Icon {
                            name: "notifications"
                            color: Style.accent
                            size: 14
                        }
                        
                        Text {
                            text: notif.appName || "System Notification"
                            font.family: Style.fontFamily
                            font.pixelSize: 11
                            color: Style.accent
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }
                        
                        // Close Button
                        MouseArea {
                            width: 16; height: 16
                            cursorShape: Qt.PointingHandCursor
                            onClicked: removeNotification(notif)
                            
                            M3Icon {
                                anchors.centerIn: parent
                                name: "close"
                                color: Style.textSecondary
                                size: 14
                            }
                        }
                    }
                    
                    // Summary (Title)
                    Text {
                        text: notif.summary
                        font.family: Style.fontFamily
                        font.pixelSize: 14
                        color: "#FFFFFF"
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    
                    // Body (Content)
                    Text {
                        text: notif.body
                        font.family: Style.fontFamily
                        font.pixelSize: 13
                        color: "#AAAAAA" // Subdued gray
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        visible: notif.body.length > 0
                    }
                }
                
                // Thin separator line between stacked notifications
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#22ffffff" // Very faint white
                    visible: !isBottom
                }
            }
            
            // --- TOP LEFT INVERTED EAR ---
            // Attached to the left of the 350px solid black box.
            Canvas {
                id: topLeftEar
                width: 24; height: 24
                
                x: 0 // In a 374px container, 350px box is at x=24. Ear is at x=0.
                anchors.top: parent.top
                visible: isTop
                
                onPaint: {
                    var ctx = getContext("2d");
                    var s = 24;
                    ctx.clearRect(0, 0, s, s);
                    ctx.fillStyle = "#000000";
                    ctx.beginPath();
                    ctx.arc(0, s, s, -Math.PI / 2, 0, false);
                    ctx.lineTo(s, 0);
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }
    }
    
    // --- BOTTOM RIGHT INVERTED EAR ---
    // Drawn beneath the bottom-most notification, against the right edge.
    Canvas {
        id: bottomRightEar
        width: 24; height: 24
        
        anchors.top: popupListView.bottom
        anchors.right: parent.right
        
        visible: root.activePopups.length > 0
        
        onPaint: {
            var ctx = getContext("2d");
            var s = 24;
            ctx.clearRect(0, 0, s, s);
            ctx.fillStyle = "#000000";
            ctx.beginPath();
            ctx.arc(0, s, s, -Math.PI / 2, 0, false);
            ctx.lineTo(s, 0);
            ctx.closePath();
            ctx.fill();
        }
    }
}
