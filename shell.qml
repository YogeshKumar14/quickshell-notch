import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "components"
import "theme"

Scope {
    id: root
    
    // Global Notification Engine
    ListModel {
        id: notifHistoryModel
    }
    
    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        
        onNotification: notif => {
            // Push to History
            notifHistoryModel.insert(0, {
                summary: notif.summary,
                body: notif.body,
                appName: notif.appName,
                appIcon: notif.appIcon,
                image: notif.image,
                urgency: notif.urgency,
                timestamp: new Date().toLocaleTimeString()
            });
            
            // Push to transient Pop-ups
            if (!notchComp.dndActive) {
                popupsComp.addNotification(notif);
            }
        }
    }
    
    // Dripping Notification Pop-ups
    PanelWindow {
        id: notifPopupsWindow
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: 0
        
        anchors {
            top: true
            right: true
        }
        
        implicitWidth: 374
        implicitHeight: popupsComp.implicitHeight
        color: "transparent"
        
        NotificationPopups {
            id: popupsComp
        }
    }

    // Top Notch PanelWindow: 624x420 transparent window (allows 32px padding for inverted ears)
    PanelWindow {
        id: notchWindow

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: 0
        WlrLayershell.keyboardFocus: (notchComp.isExpanded || notchComp.isPowerMenuOpen || notchComp.isWifiMenuOpen || notchComp.isBluetoothMenuOpen) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
        active: notchComp.isExpanded || notchComp.isPowerMenuOpen || notchComp.isWifiMenuOpen || notchComp.isBluetoothMenuOpen
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
                        } else if (cmd.startsWith("osd:vol:")) {
                            var v = parseInt(cmd.split(":")[2]);
                            if (!isNaN(v)) notchComp.showOsd("volume", v);
                        } else if (cmd.startsWith("osd:bri:")) {
                            var b = parseInt(cmd.split(":")[2]);
                            if (!isNaN(b)) notchComp.showOsd("brightness", b);
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