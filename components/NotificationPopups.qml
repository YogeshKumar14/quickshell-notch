import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Item {
    id: root

    width: 374
    implicitHeight: popupListView.contentHeight + 72

    // --- Data Layer ---
    ListModel { id: popupModel }

    property var notifObjectMap: ({})
    property var notifTimestamps: ({})
    property var pausedTimestamps: ({})
    property int nextNotifId: 0

    // Shared auto-dismiss timer (no per-notification QML object creation)
    Timer {
        id: dismissTimer
        interval: 1000
        repeat: true
        running: popupModel.count > 0
        onTriggered: {
            var now = Date.now();
            for (var i = 0; i < popupModel.count; i++) {
                var nid = popupModel.get(i).nid;
                if (root.pausedTimestamps[nid]) continue;
                var ts = root.notifTimestamps[nid];
                if (ts && now - ts > 5000) {
                    root.removeById(nid);
                    break;
                }
            }
        }
    }

    function addNotification(notif) {
        var nid = root.nextNotifId++;

        var omap = root.notifObjectMap;
        omap[nid] = notif;
        root.notifObjectMap = omap;

        var tsmap = root.notifTimestamps;
        tsmap[nid] = Date.now();
        root.notifTimestamps = tsmap;

        popupModel.insert(0, {
            nid: nid,
            summary: notif.summary || "",
            body: notif.body || "",
            appName: notif.appName || "System",
            appIcon: notif.appIcon || "",
            urgency: notif.urgency || 0
        });

        if (popupModel.count > 4) {
            var oldestIdx = popupModel.count - 1;
            var oldestNid = popupModel.get(oldestIdx).nid;
            popupModel.remove(oldestIdx, 1);
            dismissAndCleanup(oldestNid);
        }
    }

    function removeById(nid) {
        for (var i = 0; i < popupModel.count; i++) {
            if (popupModel.get(i).nid === nid) {
                popupModel.remove(i, 1);
                break;
            }
        }
        dismissAndCleanup(nid);
    }

    function removeAtIndex(idx) {
        if (idx >= 0 && idx < popupModel.count) {
            var nid = popupModel.get(idx).nid;
            popupModel.remove(idx, 1);
            dismissAndCleanup(nid);
        }
    }

    function dismissAndCleanup(nid) {
        var omap = root.notifObjectMap;
        if (omap[nid]) {
            omap[nid].dismiss();
            delete omap[nid];
            root.notifObjectMap = omap;
        }
        delete root.notifTimestamps[nid];
        delete root.pausedTimestamps[nid];
    }

    function pauseTimer(nid) {
        root.pausedTimestamps[nid] = true;
    }

    function resumeTimer(nid) {
        delete root.pausedTimestamps[nid];
    }

    // --- View Layer ---
    ListView {
        id: popupListView
        width: parent.width
        height: contentHeight
        interactive: false
        spacing: -24
        clip: true
        cacheBuffer: 400

        model: popupModel

        // Entrance: slide in from right with expressive decel
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: root.width; to: 0; duration: 500; easing.type: Easing.OutQuint }
            }
        }

        // Smooth reflow when items shift
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 500; easing.type: Easing.OutQuint }
        }

        delegate: Item {
            id: delegateRoot
            width: popupListView.width
            height: bgRect.height + 24
            clip: false

            readonly property int notifNid: model.nid
            readonly property bool isBottom: index === popupModel.count - 1

            property bool earShown: false
            property bool removing: false
            property real dragStartX: 0

            // Exit animation — delayRemove prevents instant destruction
            ListView.onRemove: SequentialAnimation {
                PropertyAction { target: delegateRoot; property: "removing"; value: true }
                PropertyAction { target: delegateRoot; property: "ListView.delayRemove"; value: true }
                ParallelAnimation {
                    NumberAnimation { target: contentItem; property: "opacity"; to: 0; duration: 250; easing.type: Easing.OutCubic }
                    NumberAnimation { target: contentItem; property: "x"; to: root.width * 1.5; duration: 400; easing.type: Easing.OutCubic }
                }
                PropertyAction { target: delegateRoot; property: "ListView.delayRemove"; value: false }
            }

            // Entrance complete — show ear after popup reaches top
            ListView.onAdd: SequentialAnimation {
                PauseAnimation { duration: 500 }
                PropertyAction { target: delegateRoot; property: "earShown"; value: true }
            }

            // Re-animate ear when becoming top item after dismissal
            Connections {
                target: popupListView
                function onCountChanged() {
                    if (index === 0 && delegateRoot.earShown) {
                        delegateRoot.earShown = false
                        Qt.callLater(function() { delegateRoot.earShown = true })
                    }
                }
            }

            // --- Draggable Content Wrapper ---
            Item {
                id: contentItem
                width: parent.width
                height: delegateRoot.height
                clip: false

                Behavior on x {
                    enabled: !dragArea.pressed && !delegateRoot.removing
                    NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
                }

                MouseArea {
                    id: dragArea
                    width: bgRect.width
                    height: bgRect.height
                    anchors.right: parent.right
                    drag.target: contentItem
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: root.width * 1.5

                    onEntered: root.pauseTimer(delegateRoot.notifNid)
                    onExited: root.resumeTimer(delegateRoot.notifNid)

                    onPressed: function(mouse) {
                        delegateRoot.dragStartX = contentItem.x;
                    }

                    onReleased: function(mouse) {
                        var deltaX = contentItem.x - delegateRoot.dragStartX;

                        // Tap to dismiss (no significant movement)
                        if (Math.abs(deltaX) < 10) {
                            root.removeAtIndex(index);
                            return;
                        }

                        // Horizontal dismiss threshold
                        if (deltaX > 80) {
                            root.removeAtIndex(index);
                            return;
                        }

                        // Snap back
                        contentItem.x = 0;
                    }
                }

                // --- Solid Black Notification Body ---
                Rectangle {
                    id: bgRect
                    width: 350
                    anchors.right: parent.right
                    height: notifLayout.implicitHeight + 32
                    color: "#000000"
                    bottomLeftRadius: index === popupModel.count - 1 ? Style.radiusMedium : 0

                    ColumnLayout {
                        id: notifLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.topMargin: 14
                        spacing: 4

                        // Header row: app icon + app name
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // App icon (circular)
                            Rectangle {
                                width: 24; height: 24
                                radius: 12
                                color: Style.cardBg
                                visible: model.appIcon.length > 0

                                Image {
                                    anchors.fill: parent
                                    source: model.appIcon
                                    fillMode: Image.PreserveAspectCrop
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: 24; height: 24
                                            radius: 12
                                        }
                                    }
                                }
                            }

                            // Fallback icon when no app icon
                            M3Icon {
                                name: "notifications"
                                color: {
                                    if (model.urgency === 2) return Style.danger;
                                    if (model.urgency === 1) return Style.accent;
                                    return Style.textSecondary;
                                }
                                size: 14
                                visible: model.appIcon.length === 0
                            }

                            // App name
                            Text {
                                text: model.appName
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontSizeSmall
                                color: {
                                    if (model.urgency === 2) return Style.danger;
                                    if (model.urgency === 1) return Style.accent;
                                    return Style.textSecondary;
                                }
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        // Summary (title)
                        Text {
                            text: model.summary
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeNormal
                            color: Style.textPrimary
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            wrapMode: Text.NoWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Layout.topMargin: 2
                        }

                        // Body (preview)
                        Text {
                            text: model.body
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeSmall
                            color: Style.textSecondary
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            visible: model.body.length > 0
                            Layout.topMargin: 2
                        }
                    }
                }

                // --- TOP LEFT INVERTED EAR (first item only — bridges to notch) ---
                Canvas {
                    width: 24; height: 24
                    x: 0; y: 0
                    visible: index === 0
                    opacity: delegateRoot.earShown ? 1 : 0
                    scale: delegateRoot.earShown ? 1 : 0
                    transformOrigin: Item.TopRight

                    Behavior on opacity {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 400; easing.type: Easing.OutBack }
                    }

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

                // --- BOTTOM RIGHT INVERTED EAR (last item only) ---
                // Always present in delegate, naturally occluded by overlapping delegate below
                Canvas {
                    width: 24; height: 24
                    anchors.top: bgRect.bottom
                    anchors.right: bgRect.right
                    opacity: delegateRoot.isBottom ? 1 : 0
                    scale: delegateRoot.isBottom ? 1 : 0
                    transformOrigin: Item.TopLeft

                    Behavior on opacity {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 400; easing.type: Easing.OutBack }
                    }

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
                }
            }
        }
    }

    // Hidden mask target for PanelWindow input region (350px bgRect only, no ear gap)
    Rectangle {
        id: inputMask
        width: 350
        anchors.right: parent.right
        height: popupListView.contentHeight
        visible: false
    }

    property alias popupArea: inputMask
}
