import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    required property bool isOpen
    property bool wifiPower: false
    property string wifiActiveSsid: ""
    property var wifiNetworks: []
    property bool isPasswordPromptOpen: false
    property string promptSsid: ""
    property string passwordText: ""
    property bool showPassword: false

    anchors.fill: parent
    z: 99

    opacity: isOpen ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    onIsOpenChanged: {
        if (!isOpen) {
            isPasswordPromptOpen = false;
            passwordText = "";
            promptSsid = "";
            showPassword = false;
            wifiScanner.running = false;
            wifiToggler.running = false;
        } else {
            if (!wifiScanner.running && !wifiToggler.running) wifiScanner.running = true;
        }
    }

    Process {
        id: wifiScanner
        command: ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_wifi.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.wifiPower = data && data.power !== undefined ? data.power : false;
                    root.wifiActiveSsid = (data && data.active) || "";
                    root.wifiNetworks = (data && Array.isArray(data.networks)) ? data.networks : [];
                } catch(e) {}
            }
        }
    }

    Process {
        id: wifiToggler
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.wifiPower = data && data.power !== undefined ? data.power : false;
                    root.wifiActiveSsid = (data && data.active) || "";
                    root.wifiNetworks = (data && Array.isArray(data.networks)) ? data.networks : [];
                } catch(e) {}
                scanTimer.restart();
            }
        }
    }

    Timer {
        id: scanTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: if (!wifiScanner.running && !wifiToggler.running) wifiScanner.running = true
    }

    function connect(ssid, password) {
        wifiToggler.running = false;
        wifiToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_wifi.py", "connect", ssid, password || ""];
        wifiToggler.running = true;
    }

    function togglePower(val) {
        root.wifiPower = val;
        wifiToggler.running = false;
        wifiToggler.command = ["python3", "/home/yogesh/.config/quickshell/scripts/network/manage_wifi.py", val ? "on" : "off"];
        wifiToggler.running = true;
    }

    function rescan() {
        if (wifiScanner.running) return;
        wifiScanner.running = true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.isPasswordPromptOpen ? "Enter Password" : "Wi-Fi Network"
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeLarge
                font.weight: Font.Bold
                color: Style.textPrimary
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 24; height: 24; radius: 12
                color: wifiRefM.containsMouse ? Style.cardBgHover : Style.cardBg
                border.color: Style.cardBorder
                visible: !root.isPasswordPromptOpen && root.wifiPower
                M3Icon {
                    id: wifiRefText
                    anchors.centerIn: parent
                    name: "restart_alt"
                    size: 14
                    color: Style.textPrimary

                    transformOrigin: Item.Center
                    RotationAnimation on rotation {
                        running: wifiScanner.running || wifiToggler.running
                        from: 0; to: 360; loops: Animation.Infinite; duration: 1000
                        onRunningChanged: {
                            if (!running) wifiRefText.rotation = 0;
                        }
                    }
                }
                MouseArea {
                    id: wifiRefM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.rescan()
                }
            }

            CustomSwitch {
                visible: !root.isPasswordPromptOpen
                checked: root.wifiPower
                onToggled: function(val) {
                    root.togglePower(val);
                }
            }
        }

        Item {
            Layout.fillWidth: true; Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 12
                opacity: root.isPasswordPromptOpen ? 1.0 : 0.0
                scale: root.isPasswordPromptOpen ? 1.0 : 0.92
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Text {
                    Layout.alignment: Qt.AlignLeft
                    text: "Connecting to: " + root.promptSsid
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeNormal
                    font.weight: Font.DemiBold
                    color: Style.textSecondary
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: Style.radiusSmall
                    color: "#0E0E10"
                    border.color: wifiPasswordInput.activeFocus ? Style.accent : "#222225"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 8

                        M3Icon {
                            name: "lock"
                            color: Style.textMuted
                            size: 16
                        }

                        TextInput {
                            id: wifiPasswordInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeNormal
                            color: Style.textPrimary
                            selectByMouse: true
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            text: root.passwordText
                            focus: root.isPasswordPromptOpen
                            onTextChanged: root.passwordText = text
                            verticalAlignment: TextInput.AlignVCenter

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Escape) {
                                    root.isPasswordPromptOpen = false;
                                    event.accepted = true;
                                }
                            }

                            KeyNavigation.tab: wifiCancelBtn

                            onAccepted: {
                                root.connect(root.promptSsid, root.passwordText);
                                root.isPasswordPromptOpen = false;
                            }
                        }

                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: "transparent"
                            M3Icon {
                                anchors.centerIn: parent
                                name: root.showPassword ? "visibility" : "visibility_off"
                                size: 16
                                color: wifiEyeM.containsMouse ? Style.textPrimary : Style.textMuted
                            }
                            MouseArea {
                                id: wifiEyeM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.showPassword = !root.showPassword
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    spacing: 10

                    Rectangle {
                        id: wifiCancelBtn
                        implicitWidth: 80; implicitHeight: 32; radius: 16
                        color: wifiCancelM.containsMouse ? "#2C2C2E" : "#1C1C1E"
                        border.color: "#3A3A3C"

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold
                            color: Style.textPrimary
                        }
                        MouseArea {
                            id: wifiCancelM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.isPasswordPromptOpen = false
                        }
                    }

                    Rectangle {
                        implicitWidth: 80; implicitHeight: 32; radius: 16
                        color: Style.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; font.weight: Font.Bold; color: "#000000"
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.connect(root.promptSsid, root.passwordText);
                                root.isPasswordPromptOpen = false;
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 6
                opacity: root.isPasswordPromptOpen ? 0.0 : 1.0
                scale: root.isPasswordPromptOpen ? 0.92 : 1.0
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Style.radiusSmall
                    color: "#0F0F12"
                    border.color: Style.accent
                    border.width: 1
                    visible: root.wifiPower && (root.wifiActiveSsid !== "" || wifiToggler.running)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 8
                            M3Icon {
                                id: wifiActiveIcon
                                name: wifiToggler.running ? "restart_alt" : "wifi"
                                color: Style.accent; size: 16
                                transformOrigin: Item.Center
                                RotationAnimation on rotation {
                                    running: wifiToggler.running
                                    from: 0; to: 360; loops: Animation.Infinite; duration: 1000
                                    onRunningChanged: {
                                        if (!running) wifiActiveIcon.rotation = 0;
                                    }
                                }
                            }
                        Text {
                            text: wifiToggler.running ? "Connecting to: " + root.promptSsid : "Connected: " + root.wifiActiveSsid
                            font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal
                            font.weight: Font.Bold
                            color: Style.textPrimary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        M3Icon { name: wifiToggler.running ? "" : "done"; color: Style.accent; size: 16 }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: "transparent"
                    visible: !root.wifiPower || !root.wifiNetworks || root.wifiNetworks.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        M3Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: !root.wifiPower ? "wifi_off" : "restart_alt"
                            size: 32
                            color: Style.textMuted
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: !root.wifiPower ? "Wi-Fi is Powered Off" : "Scanning networks..."
                            font.family: Style.fontFamily; font.pixelSize: Style.fontSizeNormal
                            color: Style.textSecondary
                        }
                    }
                }

                ListView {
                    id: wifiList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: root.wifiPower && root.wifiNetworks ? root.wifiNetworks : []
                    clip: true
                    spacing: 4
                    visible: root.wifiPower && root.wifiNetworks && root.wifiNetworks.length > 0

                    delegate: Rectangle {
                        width: wifiList.width; height: 32; radius: Style.radiusSmall
                        color: modelData.active ? "#1C1C1E" : (netM.containsMouse ? "#121214" : "#0A0A0C")
                        border.color: modelData.active ? Style.accent : "#222225"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 8

                            M3Icon {
                                name: "wifi"
                                color: modelData.active ? Style.accent : Style.textSecondary
                                size: 16
                                opacity: modelData.signal > 75 ? 1.0 : (modelData.signal > 50 ? 0.75 : (modelData.signal > 25 ? 0.5 : 0.25))
                            }

                            Text {
                                text: modelData.ssid
                                font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall
                                color: Style.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            M3Icon {
                                name: modelData.active ? "done" : (modelData.security ? "lock" : "")
                                color: modelData.active ? Style.accent : Style.textMuted
                                size: 16
                            }
                        }

                        MouseArea {
                            id: netM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.security && modelData.security !== "--" && !modelData.active && !modelData.saved) {
                                    root.promptSsid = modelData.ssid;
                                    root.passwordText = "";
                                    root.showPassword = false;
                                    root.isPasswordPromptOpen = true;
                                    wifiPasswordInput.forceActiveFocus();
                                } else {
                                    root.promptSsid = modelData.ssid;
                                    root.connect(modelData.ssid, "");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
