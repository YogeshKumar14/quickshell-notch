import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Item {
    id: root

    width: 374
    implicitHeight: popupListView.contentHeight

    // --- Data Layer ---
    // ListModel stores SCALAR properties only (strings, ints).
    // QObject refs are kept in a separate JS map to avoid ListModel silently dropping them.
    ListModel {
        id: popupModel
    }

    property var notifObjectMap: ({})
    property int nextNotifId: 0

    function addNotification(notif) {
        var nid = root.nextNotifId++;
        var map = root.notifObjectMap;
        map[nid] = notif;
        root.notifObjectMap = map;

        popupModel.insert(0, {
            nid: nid,
            summary: notif.summary || "",
            body: notif.body || "",
            appName: notif.appName || "System"
        });

        // Auto-dismiss after 5 seconds
        var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 5000; running: true }", root);
        var capturedNid = nid;
        timer.triggered.connect(function() {
            root.removeNotificationById(capturedNid);
            timer.destroy();
        });
    }

    function removeNotificationById(nid) {
        for (var i = 0; i < popupModel.count; i++) {
            if (popupModel.get(i).nid === nid) {
                popupModel.remove(i, 1);
                break;
            }
        }
        var map = root.notifObjectMap;
        if (map[nid]) {
            map[nid].dismiss();
            delete map[nid];
            root.notifObjectMap = map;
        }
    }

    function removeNotificationAtIndex(idx) {
        if (idx >= 0 && idx < popupModel.count) {
            var nid = popupModel.get(idx).nid;
            popupModel.remove(idx, 1);
            var map = root.notifObjectMap;
            if (map[nid]) {
                map[nid].dismiss();
                delete map[nid];
                root.notifObjectMap = map;
            }
        }
    }

    // --- View Layer ---
    ListView {
        id: popupListView
        width: parent.width
        height: contentHeight
        interactive: false
        spacing: 0
        clip: false

        model: popupModel

        // Slide in from the right with a spring bounce
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
                SpringAnimation { property: "x"; spring: 3.5; damping: 0.75; from: 374; to: 0 }
            }
        }

        // Slide out to the right on removal with spring
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
                SpringAnimation { property: "x"; spring: 3.5; damping: 0.75; velocity: 800 }
            }
        }

        // Spring-based repositioning when items shift for dynamic reflow
        displaced: Transition {
            SpringAnimation { properties: "y"; spring: 4.0; damping: 0.7 }
        }

        delegate: Item {
            id: delegateRoot
            width: popupListView.width
            // Last item is 24px taller to house the bottom-right ear inside its bounds
            height: bgRect.height + (isBottom ? 24 : 0)
            clip: false

            property bool isTop: index === 0
            property bool isBottom: index === popupModel.count - 1

            // --- Draggable Content Wrapper ---
            Item {
                id: contentItem
                width: parent.width
                height: delegateRoot.height
                clip: false

                // Spring snap-back when not actively dragging
                Behavior on x {
                    enabled: !dragArea.drag.active
                    SpringAnimation { spring: 4.0; damping: 0.7 }
                }

                MouseArea {
                    id: dragArea
                    // Cover only the visible notification body for dragging
                    width: bgRect.width
                    height: bgRect.height
                    anchors.right: parent.right
                    drag.target: contentItem
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: root.width

                    onReleased: {
                        if (contentItem.x > 100) {
                            root.removeNotificationAtIndex(index);
                        } else {
                            contentItem.x = 0;
                        }
                    }
                }

                // --- Solid Black Notification Body ---
                Rectangle {
                    id: bgRect
                    width: 350
                    anchors.right: parent.right
                    height: notifLayout.implicitHeight + 32

                    color: "#000000"
                    bottomLeftRadius: delegateRoot.isBottom ? 28 : 0

                    ColumnLayout {
                        id: notifLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 4

                        // Header: App Name + Close
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            M3Icon {
                                name: "notifications"
                                color: Style.accent
                                size: 14
                            }

                            Text {
                                text: model.appName
                                font.family: Style.fontFamily
                                font.pixelSize: 11
                                color: Style.accent
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                            }

                            // Close button
                            MouseArea {
                                width: 16; height: 16
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.removeNotificationAtIndex(index)

                                M3Icon {
                                    anchors.centerIn: parent
                                    name: "close"
                                    color: Style.textSecondary
                                    size: 14
                                }
                            }
                        }

                        // Title
                        Text {
                            text: model.summary
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
                            text: model.body
                            font.family: Style.fontFamily
                            font.pixelSize: 13
                            color: "#AAAAAA"
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: model.body.length > 0
                        }
                    }

                    // Thin separator between stacked notifications
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: "#22ffffff"
                        visible: !delegateRoot.isBottom
                    }
                }

                // --- TOP LEFT INVERTED EAR (first item only) ---
                Canvas {
                    width: 24; height: 24
                    x: 0; y: 0
                    visible: delegateRoot.isTop

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

                    Component.onCompleted: requestPaint()
                    onVisibleChanged: if (visible) requestPaint()
                }

                // --- BOTTOM RIGHT INVERTED EAR (last item only, INSIDE delegate) ---
                // By living inside the delegate, it inherits the displaced animation
                // and can never detach or jump ahead.
                Canvas {
                    width: 24; height: 24
                    anchors.top: bgRect.bottom
                    anchors.right: bgRect.right
                    visible: delegateRoot.isBottom

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

                    Component.onCompleted: requestPaint()
                    onVisibleChanged: if (visible) requestPaint()
                }
            }
        }
    }
}
