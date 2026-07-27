import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "components"
import "theme"

Scope {
    id: root

    // Top Notch PanelWindow: 624x420 transparent window (allows 32px padding for inverted ears)
    PanelWindow {
        id: notchWindow

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: 0
        WlrLayershell.keyboardFocus: (notchComp.isExpanded || notchComp.isPowerMenuOpen) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
        }

        implicitWidth: Style.notchWidthExpanded + 64
        implicitHeight: Style.notchHeightExpanded
        color: "transparent"

        // Input passthrough: only the visible notchBox receives input, transparent area clicks through
        mask: Region { item: notchComp.notchBoxItem }

        TopNotch {
            id: notchComp
            anchors.fill: parent
            onOpenFullSettings: settingsModal.toggle()
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: notchComp.isExpanded || notchComp.isPowerMenuOpen
        windows: [notchWindow]
    }

    // IPC Socket Server: keybinds send commands here to open specific tabs
    SocketServer {
        id: ipcServer
        active: true
        path: "/tmp/quickshell-notch.sock"
        handler: Component {
            Socket {
                id: clientSocket
                parser: SplitParser {
                    onRead: function(data) {
                        var cmd = data.trim();
                        if (cmd === "walls") {
                            notchComp.toggleTab(1);
                        } else if (cmd === "apps") {
                            notchComp.toggleTab(2);
                        } else if (cmd === "toggle") {
                            notchComp.isExpanded = !notchComp.isExpanded;
                        } else if (cmd === "close") {
                            notchComp.isExpanded = false;
                        }
                        clientSocket.connected = false;
                    }
                }
            }
        }
    }

    // iOS-Style Hyprland Settings Window
    SettingsWindow {
        id: settingsModal
        onNotchSettingsChanged: notchComp.refreshNotchSettings()
    }
}