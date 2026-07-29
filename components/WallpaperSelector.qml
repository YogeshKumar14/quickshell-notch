import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../theme"

FocusScope {
    id: root

    property bool isOpen: true

    // Keyboard selection index (from parent TopNotch)
    property int selectedIndex: 0

    signal wallpaperSelected(string path)

    property var allWallpapers: []

    Process {
        id: scannerProc
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/desktop/scan_wallpapers.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var items = JSON.parse(this.text);
                    root.allWallpapers = [{
                        "name": "Random Wallpaper",
                        "filename": "random",
                        "path": "random",
                        "folder": "Action"
                    }];
                    for (var i = 0; i < items.length; i++) {
                        root.allWallpapers.push(items[i]);
                    }
                    root.filterWallpapers();
                } catch (e) {
                    console.log("Error parsing wallpaper JSON:", e);
                }
            }
        }
    }

    Component.onCompleted: {
        scannerProc.running = true;
    }

    function refresh() {
        if (!scannerProc.running) {
            scannerProc.running = true;
        }
    }

    function focusSearch() {
        searchInput.forceActiveFocus();
    }

    function filterWallpapers() {
        wallModel.clear();
        var query = searchInput.text.toLowerCase().trim();
        for (var i = 0; i < root.allWallpapers.length; i++) {
            var item = root.allWallpapers[i];
            if (query === "" || item.name.toLowerCase().indexOf(query) !== -1) {
                wallModel.append(item);
            }
        }
        // Auto-select first result when filtering
        root.selectedIndex = wallModel.count > 0 ? 0 : -1;
    }

    function selectWallpaper(path) {
        if (path === "random") {
            if (root.allWallpapers.length > 1) {
                var randIdx = Math.floor(Math.random() * (root.allWallpapers.length - 1)) + 1;
                path = root.allWallpapers[randIdx].path;
            } else {
                return;
            }
        }
        root.wallpaperSelected(path);
    }

    // Apply the currently selected wallpaper
    function applySelected() {
        if (root.selectedIndex >= 0 && root.selectedIndex < wallModel.count) {
            root.selectWallpaper(wallModel.get(root.selectedIndex).path);
        }
    }

    // Grid columns count for arrow key navigation
    function gridColumns() {
        return Math.max(1, Math.floor(gridContainer.width / gridContainer.targetCellWidth));
    }

    ListModel {
        id: wallModel
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
            border.color: searchInput.activeFocus ? Style.accent : Style.cardBorder

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                M3Icon { name: "search"; color: Style.textMuted; size: 16 }

                TextInput {
                    id: searchInput
                    focus: true
                    Layout.fillWidth: true
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: Style.textPrimary
                    clip: true
                    activeFocusOnPress: true
                    selectByMouse: true

                    onTextChanged: root.filterWallpapers()

                    // Keyboard navigation while search bar has focus
                    Keys.onPressed: function(event) {
                        var cols = root.gridColumns();
                        var count = wallModel.count;
                        if (count === 0) return;

                        if (event.key === Qt.Key_Down) {
                            root.selectedIndex = Math.min(root.selectedIndex + cols, count - 1);
                            gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.selectedIndex = Math.max(root.selectedIndex - cols, 0);
                            gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            root.selectedIndex = Math.min(root.selectedIndex + 1, count - 1);
                            gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                            gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.applySelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            root.selectedIndex = (root.selectedIndex + 1) % count;
                            gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            event.accepted = true;
                        }
                    }

                    Text {
                        text: "Search wallpapers..."
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeSmall
                        color: Style.textMuted
                        visible: searchInput.text.length === 0
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: searchInput.forceActiveFocus()
            }
        }

        // Symmetrically Centered Wallpaper Grid
        Item {
            id: gridContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            property int targetCellWidth: 160
            property int columns: Math.max(1, Math.floor(gridContainer.width / targetCellWidth))
            property int calculatedCellWidth: Math.floor(gridContainer.width / columns)

            GridView {
                id: gridView
                anchors.fill: parent
                clip: true
                cellWidth: gridContainer.calculatedCellWidth
                cellHeight: 110
                currentIndex: root.selectedIndex
                highlightFollowsCurrentItem: false

                highlight: Item {
                    z: 10
                    width: gridView.cellWidth
                    height: gridView.cellHeight
                    x: gridView.currentItem ? gridView.currentItem.x : 0
                    y: gridView.currentItem ? gridView.currentItem.y : 0
                    
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: parent.height - 10
                        radius: Style.radiusMedium
                        color: "#1AFFFFFF" // Subtle overlay
                        border.color: Style.accent
                        border.width: 2
                        scale: 1.04 // Matches the popped delegate
                    }
                }

                model: wallModel

                delegate: Item {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    property bool isSelected: index === root.selectedIndex
                    property bool isHovered: cardMouse.containsMouse

                    Rectangle {
                        id: wallCard
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: parent.height - 10
                        radius: Style.radiusMedium
                        color: Style.cardBg
                        border.color: Style.cardBorder
                        border.width: 1
                        scale: isSelected ? 1.04 : 1.0

                        // Accent glow on selected item
                        layer.enabled: isSelected
                        layer.effect: null

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Style.radiusMedium - 2
                            color: "transparent"

                            Image {
                                anchors.fill: parent
                                source: model.path !== "random" ? "file://" + (model.thumb || model.path) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                visible: model.path !== "random"
                                sourceSize.width: 160
                                sourceSize.height: 110
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Style.cardBg
                                visible: model.path === "random"

                                M3Icon {
                                    anchors.centerIn: parent
                                    name: "shuffle"
                                    color: Style.accent
                                    size: 32
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectWallpaper(model.path)
                            onEntered: root.selectedIndex = index
                        }
                    }
                }
            }
        }
    }
}
