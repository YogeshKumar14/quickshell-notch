/**
 * AppLauncher.qml — Application Grid & Fuzzy Launcher for QuickShell Notch
 *
 * Renders PAGE 2 of the expanded notch:
 *   - Parses system .desktop entries with intelligent icon resolution
 *   - Real-time search query filtering and name matching
 *   - Dynamic grid layout with configurable columns
 *   - Full keyboard navigation (Arrow keys + Enter) and quick application execution
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

FocusScope {
    id: root

    /** Number of grid columns for application cards */
    property int appColumns: 4
    /** Highlight animation mode ("spring", "smooth", "linear", "none") */
    property string highlightAnimType: "spring"
    /** Physics spring tension for highlight movement */
    property real highlightSpringTension: 5.5
    /** Physics spring damping for highlight movement */
    property real highlightSpringDamping: 0.25
    /** Grid application item entrance transition duration */
    property int gridAnimDuration: 120
    /** Whether micro-interaction button animations are enabled */
    property bool buttonAnims: true

    /** Emitted when an application is launched */
    signal appLaunched()
    /** Emitted when launcher close/dismiss is requested */
    signal closeRequested()

    /** Keyboard selection index */
    property int selectedIndex: 0
    /** Complete list of parsed desktop applications [{name, exec, icon, comment}] */
    property var allApps: []

    // Fast process scanner
    Process {
        id: appScanner
        command: ["python3", Quickshell.shellDir + "/scripts/desktop/get_apps.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    root.allApps = Array.isArray(parsed) ? parsed : [];
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
            border.color: searchAppInput.activeFocus ? Style.accent : "#2C2C2E"
            border.width: searchAppInput.activeFocus ? 1.5 : 1.0

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
                        color: searchAppInput.activeFocus ? Style.accent : Style.textMuted
                        size: 13
                    }

                    TextInput {
                        id: searchAppInput
                        focus: true
                        Layout.fillWidth: true
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        color: Style.textPrimary
                        clip: true
                        activeFocusOnPress: true
                        selectByMouse: true

                        onTextChanged: root.filterApps()

                        // Keyboard navigation while search bar has focus
                        Keys.onPressed: function(event) {
                            var count = appModel.count;
                            if (count === 0) return;

                            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                                root.selectedIndex = Math.min(root.selectedIndex + 1, count - 1);
                                appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                                appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.launchSelected();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                root.selectedIndex = (root.selectedIndex + 1) % count;
                                appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                if (searchAppInput.text.length > 0) {
                                    searchAppInput.text = "";
                                } else {
                                    root.closeRequested();
                                }
                                event.accepted = true;
                            }
                        }

                        Text {
                            text: "Search apps..."
                            font.family: Style.fontFamily
                            font.pixelSize: 11
                            color: Style.textMuted
                            visible: searchAppInput.text.length === 0
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: appModel.count + " applications"
                        font.family: Style.fontFamily
                        font.pixelSize: 9
                        color: Style.textMuted
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: searchAppInput.forceActiveFocus()
            }
        }

        // Horizontal App Squircles List (Right Column)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: appListView
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                currentIndex: root.selectedIndex
                boundsBehavior: Flickable.StopAtBounds

                model: appModel

                delegate: Item {
                    width: 56
                    height: appListView.height

                    property bool isSelected: index === root.selectedIndex
                    property bool isHovered: appM.containsMouse

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 60
                        radius: 12
                        color: isSelected ? "#2C2C2E" : (isHovered ? "#242426" : "#1C1C1E")
                        border.color: isSelected ? Style.accent : (isHovered ? "#5A5A5E" : Qt.rgba(255, 255, 255, 0.12))
                        border.width: isSelected ? 2.0 : 1.0
                        smooth: true
                        antialiasing: true

                        scale: (root.buttonAnims && appM.pressed) ? 0.90 : ((root.buttonAnims && (isSelected || isHovered)) ? 1.05 : 1.0)
                        Behavior on scale {
                            enabled: root.buttonAnims
                            SpringAnimation { spring: root.highlightSpringTension; damping: root.highlightSpringDamping }
                        }

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28

                                Image {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: model.iconPath ? "file://" + model.iconPath : ""
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 56
                                    sourceSize.height: 56
                                    smooth: true
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                M3Icon {
                                    anchors.centerIn: parent
                                    visible: appIcon.status !== Image.Ready
                                    name: "apps"
                                    color: Style.accent
                                    size: 22
                                }
                            }

                            Text {
                                text: model.name
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                font.weight: isSelected ? Font.Bold : Font.Normal
                                color: isSelected ? "#FFFFFF" : Style.textSecondary
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                Layout.maximumWidth: 50
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
