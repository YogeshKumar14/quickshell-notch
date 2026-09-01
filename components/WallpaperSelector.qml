/**
 * WallpaperSelector.qml — Wallpaper Carousel & Thumbnail Selector for QuickShell Notch
 *
 * Renders PAGE 1 of the expanded notch:
 *   - Asynchronously scans wallpaper directories via Python backend
 *   - High-performance cached thumbnail grid with active selection highlight
 *   - Real-time search filtering by image name
 *   - Keyboard navigation (Arrow keys + Enter) and full focus management
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../theme"

FocusScope {
    id: root

    /** Whether wallpaper selector tab is active */
    property bool isOpen: true
    /** Keyboard focused thumbnail index */
    property int selectedIndex: 0
    /** Custom wallpaper source directory; empty uses defaults */
    property string wallpaperDir: ""

    /** Highlight animation mode ("spring", "smooth", "linear", "none") */
    property string highlightAnimType: "spring"
    /** Physics spring tension for highlight movement */
    property real highlightSpringTension: 5.5
    /** Physics spring damping for highlight movement */
    property real highlightSpringDamping: 0.25
    /** Grid thumbnail entrance transition duration */
    property int gridAnimDuration: 120
    /** Whether micro-interaction button animations are enabled */
    property bool buttonAnims: true

    /** Emitted when user selects a wallpaper thumbnail */
    signal wallpaperSelected(string path)
    /** Emitted when wallpaper drawer close/dismiss is requested */
    signal closeRequested()

    /** Complete list of scanned wallpaper objects [{path, name, thumb}] */
    property var allWallpapers: []

    property bool pendingRescan: false

    Process {
        id: scannerProc
        command: root.wallpaperDir !== ""
            ? ["python3", Quickshell.shellDir + "/scripts/desktop/scan_wallpapers.py", root.wallpaperDir]
            : ["python3", Quickshell.shellDir + "/scripts/desktop/scan_wallpapers.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.pendingRescan) {
                    root.pendingRescan = false;
                    root.rescanNow();
                    return;
                }
                try {
                    var items = JSON.parse(this.text);
                    root.allWallpapers = [{
                        "name": "Random Wallpaper",
                        "filename": "random",
                        "path": "random",
                        "folder": "Action"
                    }];
                    if (Array.isArray(items)) {
                        for (var i = 0; i < items.length; i++) {
                            root.allWallpapers.push(items[i]);
                        }
                    }
                    root.filterWallpapers();
                } catch (e) {
                    console.log("Error parsing wallpaper JSON:", e);
                }
            }
        }
    }

    function rescanNow() {
        if (!scannerProc.running) {
            scannerProc.running = true;
        } else {
            root.pendingRescan = true;
        }
    }

    onWallpaperDirChanged: root.rescanNow()

    Component.onCompleted: {
        if (!scannerProc.running) {
            scannerProc.running = true;
        }
    }

    function refresh() {
        root.rescanNow();
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

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Search Card Pill (Left Column, 130px)
        Rectangle {
            Layout.preferredWidth: 130
            Layout.preferredHeight: 60
            Layout.alignment: Qt.AlignVCenter
            radius: 12
            color: "#1C1C1E"
            border.color: searchInput.activeFocus ? Style.accent : "#2C2C2E"
            border.width: searchInput.activeFocus ? 1.5 : 1.0

            Behavior on border.color { ColorAnimation { duration: 120 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    M3Icon {
                        name: "search"
                        color: searchInput.activeFocus ? Style.accent : Style.textMuted
                        size: 13
                    }

                    TextInput {
                        id: searchInput
                        focus: true
                        Layout.fillWidth: true
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        color: Style.textPrimary
                        clip: true
                        activeFocusOnPress: true
                        selectByMouse: true

                        onTextChanged: root.filterWallpapers()

                        // Keyboard navigation while search bar has focus
                        Keys.onPressed: function(event) {
                            var count = wallModel.count;
                            if (count === 0) return;

                            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                                root.selectedIndex = Math.min(root.selectedIndex + 1, count - 1);
                                wallListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                                wallListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.applySelected();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                root.selectedIndex = (root.selectedIndex + 1) % count;
                                wallListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                if (searchInput.text.length > 0) {
                                    searchInput.text = "";
                                } else {
                                    root.closeRequested();
                                }
                                event.accepted = true;
                            }
                        }

                        Text {
                            text: "Search walls..."
                            font.family: Style.fontFamily
                            font.pixelSize: 11
                            color: Style.textMuted
                            visible: searchInput.text.length === 0
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: (wallModel.count - 1) + " wallpapers"
                        font.family: Style.fontFamily
                        font.pixelSize: 9
                        color: Style.textMuted
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: searchInput.forceActiveFocus()
            }
        }

        // Horizontal Wallpaper Carousel (Right Column)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: wallListView
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                currentIndex: root.selectedIndex
                boundsBehavior: Flickable.StopAtBounds

                model: wallModel

                delegate: Item {
                    width: 104
                    height: wallListView.height

                    property bool isSelected: index === root.selectedIndex
                    property bool isHovered: cardMouse.containsMouse

                    Item {
                        id: wallCard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 60

                        scale: (root.buttonAnims && cardMouse.pressed) ? 0.90 : ((root.buttonAnims && (isSelected || isHovered)) ? 1.05 : 1.0)
                        Behavior on scale { enabled: root.buttonAnims; SpringAnimation { spring: root.highlightSpringTension; damping: root.highlightSpringDamping } }

                        // 1. Source Image (hidden offscreen)
                        Image {
                            id: wallImg
                            anchors.fill: parent
                            source: model.path !== "random" ? "file://" + (model.thumb || model.path) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            mipmap: true
                            visible: false
                            sourceSize.width: 208
                            sourceSize.height: 120
                        }

                        // 2. Vector Mask Shape (Antialiased Squircle)
                        Rectangle {
                            id: wallMask
                            anchors.fill: parent
                            radius: 12
                            color: "#000000"
                            visible: false
                            smooth: true
                            antialiasing: true
                        }

                        // 3. Card Base Background
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: isSelected ? "#2C2C2E" : (isHovered ? "#242426" : "#1C1C1E")
                            smooth: true
                            antialiasing: true
                        }

                        // 4. Alpha-Masked Wallpaper Image
                        OpacityMask {
                            anchors.fill: parent
                            source: wallImg
                            maskSource: wallMask
                            visible: model.path !== "random" && wallImg.status === Image.Ready
                        }

                        // 5. Random Wallpaper Delegate Style
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "#242426"
                            visible: model.path === "random"
                            smooth: true
                            antialiasing: true

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                M3Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    name: "wallpaper"
                                    color: Style.accent
                                    size: 24
                                }

                                Text {
                                    text: "Random"
                                    font.family: Style.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }
                            }
                        }

                        // 6. Subtle bottom gradient vignette & name label
                        Item {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 22
                            visible: model.path !== "random"

                            Rectangle {
                                id: vignetteShape
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: "#D9000000" }
                                }
                                visible: false
                            }

                            Rectangle {
                                id: bottomMask
                                anchors.fill: parent
                                radius: 12
                                visible: false
                            }

                            OpacityMask {
                                anchors.fill: parent
                                source: vignetteShape
                                maskSource: bottomMask
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 5
                                text: model.name
                                font.family: Style.fontFamily
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                                elide: Text.ElideRight
                            }
                        }

                        // 7. Magic Highlight & Active Border Overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "transparent"
                            border.color: isSelected ? Style.accent : (isHovered ? "#5A5A5E" : Qt.rgba(255, 255, 255, 0.12))
                            border.width: isSelected ? 2.0 : 1.0
                            smooth: true
                            antialiasing: true

                            Behavior on border.color { ColorAnimation { duration: 120 } }
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
