import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Item {
    id: root
    
    width: 374
    implicitHeight: popupListView.contentHeight + 24
    
    ListModel {
        id: popupModel
    }
    
    function addNotification(notif) {
        // We inject the original QObject into the ListModel (supported in modern QtQuick)
        popupModel.insert(0, { "notifRef": notif });
        
        var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 5000; running: true }", root);
        timer.triggered.connect(function() {
            removeNotification(notif);
            timer.destroy();
        });
    }
    
    function removeNotification(notif) {
        for (var i = 0; i < popupModel.count; i++) {
            if (popupModel.get(i).notifRef === notif) {
                popupModel.remove(i, 1);
                notif.dismiss();
                break;
            }
        }
    }

    ListView {
        id: popupListView
        width: parent.width
        height: contentHeight
        interactive: false
        spacing: 0
        
        model: popupModel
        
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
        
        // This Displaced transition ensures other items slide up smoothly when one is dismissed!
        displaced: Transition {
            SpringAnimation { property: "y"; spring: 4.0; damping: 0.8 }
        }
        
        delegate: Item {
            id: delegateRoot
            width: popupListView.width
            implicitHeight: contentContainer.height
            
            property var notif: model.notifRef
            property bool isTop: index === 0
            property bool isBottom: index === popupModel.count - 1
            
            // The draggable container
            Item {
                id: contentContainer
                width: parent.width
                height: bgRect.height
                
                // Spring physics for dragging
                Behavior on x { 
                    enabled: !dragArea.drag.active
                    SpringAnimation { spring: 4.0; damping: 0.7 } 
                }
                
                // Dismiss physics logic
                onXChanged: {
                    if (!dragArea.drag.active && x > 150) {
                        // Dismiss if released past 150px
                        root.removeNotification(notif);
                    }
                }
                
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    drag.target: contentContainer
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: root.width
                    
                    onReleased: {
                        if (contentContainer.x > 100) {
                            // Swipe successfully!
                            root.removeNotification(notif);
                        } else {
                            // Snap back
                            contentContainer.x = 0;
                        }
                    }
                }
                
                // Solid Black Background
                Rectangle {
                    id: bgRect
                    width: 350
                    anchors.right: parent.right
                    // Fix geometry: height strictly wraps the Layout
                    height: notifLayout.implicitHeight + 32
                    
                    color: "#000000"
                    bottomLeftRadius: isBottom ? 28 : 0
                    
                    ColumnLayout {
                        id: notifLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 4
                        
                        // Header
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
                            
                            M3Icon {
                                name: "close"
                                color: Style.textSecondary
                                size: 14
                            }
                        }
                        
                        // Title
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
                        
                        // Body
                        Text {
                            text: notif.body
                            font.family: Style.fontFamily
                            font.pixelSize: 13
                            color: "#AAAAAA"
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: notif.body.length > 0
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: "#22ffffff"
                        visible: !isBottom
                    }
                }
                
                // TOP LEFT EAR (attached to contentContainer so it moves when dragged)
                Canvas {
                    id: topLeftEar
                    width: 24; height: 24
                    x: 0
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
    }
    
    // BOTTOM RIGHT EAR (anchored to the whole list view)
    Canvas {
        id: bottomRightEar
        width: 24; height: 24
        
        anchors.top: popupListView.bottom
        anchors.right: parent.right
        
        visible: popupModel.count > 0
        
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
