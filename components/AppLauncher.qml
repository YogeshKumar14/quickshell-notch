import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

FocusScope {
    id: root

    property int appColumns: 4
    signal appLaunched()

    // Keyboard selection index
    property int selectedIndex: 0

    property var allApps: []

    // Fast process scanner
    Process {
        id: appScanner
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/desktop/get_apps.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allApps = JSON.parse(this.text);
                    root.filterApps();
                } catch (e) {
                    console.log("Error parsing apps JSON:", e);
                }
            }
        }
    }

    Component.onCompleted: {
        appScanner.running = true;
    }

    function refresh() {
        if (!appScanner.running) {
            appScanner.running = true;
        }
    }

    function focusSearch() {
        searchAppInput.forceActiveFocus();
    }

    function filterApps() {
        appModel.clear();
        var query = searchAppInput.text.toLowerCase().trim();
        for (var i = 0; i < root.allApps.length; i++) {
            var item = root.allApps[i];
            if (query === "" || item.name.toLowerCase().indexOf(query) !== -1) {
                appModel.append(item);
            }
        }
        // Auto-select first result when filtering
        root.selectedIndex = appModel.count > 0 ? 0 : -1;
    }

    // Launch the currently selected app
    function launchSelected() {
        if (root.selectedIndex >= 0 && root.selectedIndex < appModel.count) {
            Quickshell.execDetached(["bash", "-c", appModel.get(root.selectedIndex).exec]);
            root.appLaunched();
        }
    }

    ListModel {
        id: appModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Search Bar with Focus Handler
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: Style.radiusMedium
            color: Style.cardBg
            border.color: searchAppInput.activeFocus ? Style.accent : Style.cardBorder

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                M3Icon { name: "search"; color: Style.textMuted; size: 16 }

                TextInput {
                    id: searchAppInput
                    focus: true
                    Layout.fillWidth: true
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: Style.textPrimary
                    clip: true
                    activeFocusOnPress: true
                    selectByMouse: true

                    onTextChanged: root.filterApps()

                    // Keyboard navigation while search bar has focus
                    Keys.onPressed: function(event) {
                        var cols = root.appColumns;
                        var count = appModel.count;
                        if (count === 0) return;

                        if (event.key === Qt.Key_Down) {
                            root.selectedIndex = Math.min(root.selectedIndex + cols, count - 1);
                            appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.selectedIndex = Math.max(root.selectedIndex - cols, 0);
                            appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            root.selectedIndex = Math.min(root.selectedIndex + 1, count - 1);
                            appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                            appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launchSelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            root.selectedIndex = (root.selectedIndex + 1) % count;
                            appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        }
                    }

                    Text {
                        text: "Search apps..."
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        color: Style.textMuted
                        visible: searchAppInput.text.length === 0
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: searchAppInput.forceActiveFocus()
            }
        }

        // Dynamically Centered App Grid
        Item {
            id: gridContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            property int calculatedCellWidth: Math.floor(gridContainer.width / Math.max(1, root.appColumns))

            GridView {
                id: appGrid
                anchors.fill: parent
                clip: true
                cellWidth: gridContainer.calculatedCellWidth
                cellHeight: 90
                currentIndex: root.selectedIndex
                highlightFollowsCurrentItem: false

                highlight: Item {
                    z: 10
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight
                    x: appGrid.currentItem ? appGrid.currentItem.x : 0
                    y: appGrid.currentItem ? appGrid.currentItem.y : 0
                    
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Style.radiusMedium
                        color: "#1AFFFFFF" // Subtle overlay
                        border.color: Style.accent
                        border.width: 2
                        scale: 1.03 // Matches the popped delegate
                    }
                }

                model: appModel

                delegate: Item {
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight

                    property bool isSelected: index === root.selectedIndex
                    property bool isHovered: appM.containsMouse

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Style.radiusMedium
                        color: Style.cardBg
                        border.color: Style.cardBorder
                        border.width: 1
                        scale: isSelected ? 1.03 : 1.0

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 32
                                implicitHeight: 32

                                Image {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: model.iconPath ? "file://" + model.iconPath : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: status === Image.Ready
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                }

                                M3Icon {
                                    anchors.centerIn: parent
                                    visible: appIcon.status !== Image.Ready
                                    name: "apps"
                                    color: Style.accent
                                    size: 24
                                }
                            }

                            Text {
                                text: model.name
                                font.family: Style.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: Style.textPrimary
                                elide: Text.ElideRight
                                Layout.maximumWidth: appGrid.cellWidth - 20
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: appM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", model.exec]);
                                root.appLaunched();
                            }
                            onEntered: root.selectedIndex = index
                        }
                    }
                }
            }
        }
    }
}
