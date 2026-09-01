/**
 * shell.qml — QuickShell Entry Point & Wayland LayerShell Surface Host
 *
 * Configures the top-level Wayland desktop integration:
 *   - NotificationServer daemon capturing desktop notifications into a persistent ListModel
 *   - PanelWindow anchored to Top with dynamic width/height driven by TopNotch.qml
 *   - LayerShell region masking to allow input passthrough outside the notch pill
 *   - Unix domain socket server (/tmp/quickshell-notch.sock) for external IPC commands
 *   - Lazy loader for the standalone SettingsWindow dialog
 */

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
            while (notifHistoryModel.count > 100) {
                notifHistoryModel.remove(notifHistoryModel.count - 1);
            }
            
            // Push to transient Notch Stack (opens the notch)
            notchComp.handleNewNotification();
        }
    }
    
    // Top Notch PanelWindow: 688x420 transparent window (allows 32px padding for inverted ears)
    PanelWindow {
        id: notchWindow

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: 0
        WlrLayershell.keyboardFocus: notchComp.grabsFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: true
        }

        implicitWidth: Style.notchWidthExpanded + 64
        implicitHeight: Math.max(340, Style.notchHeightExpanded, notchComp.maxPageNotchHeight, notchComp.notifStackHeight)
        color: "transparent"

        // Input passthrough: only the visible notchBox receives input, transparent area clicks through
        mask: Region { item: notchComp.notchBoxItem }

        TopNotch {
            id: notchComp
            anchors.fill: parent
            notifModel: notifHistoryModel
            onOpenFullSettings: {
                if (!settingsLoader.active) {
                    settingsLoader.active = true;
                } else if (settingsLoader.item) {
                    settingsLoader.item.toggle();
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: notchComp.grabsFocus
        windows: [notchWindow]
    }

    // IPC Socket Server: keybinds send commands here to open specific tabs
    SocketServer {
        id: ipcServer
        active: Quickshell.env("QUICKSHELL_SANDBOX") !== "1"
        path: "/tmp/quickshell-notch.sock"
        handler: Component {
            Socket {
                id: clientSocket
                parser: SplitParser {
                    onRead: function(data) {
                        var cmd = data.trim();
                        if (cmd === "nook") {
                            notchComp.toggleTab(0);
                        } else if (cmd === "apps" || cmd === "tray") {
                            notchComp.toggleTab(1);
                        } else if (cmd === "walls") {
                            notchComp.toggleTab(2);
                        } else if (cmd === "stats") {
                            notchComp.toggleTab(3);
                        } else if (cmd === "audio") {
                            notchComp.toggleAudioMenu();
                        } else if (cmd === "toggle") {
                            notchComp.isExpanded = !notchComp.isExpanded;
                            notchComp.isNotifMenuOpen = false;
                            notchComp.isPowerMenuOpen = false;
                            notchComp.isWifiMenuOpen = false;
                            notchComp.isBluetoothMenuOpen = false;
                            notchComp.isAudioMenuOpen = false;
                        } else if (cmd === "close") {
                            notchComp.isExpanded = false;
                            notchComp.isNotifMenuOpen = false;
                            notchComp.isPowerMenuOpen = false;
                            notchComp.isWifiMenuOpen = false;
                            notchComp.isBluetoothMenuOpen = false;
                            notchComp.isAudioMenuOpen = false;
                        } else if (cmd.startsWith("osd:vol:")) {
                            var v = parseInt(cmd.split(":")[2]);
                            notchComp.isAudioMenuOpen = false;
                            if (!isNaN(v)) notchComp.showOsd("volume", Math.max(0, Math.min(150, v)));
                        } else if (cmd.startsWith("osd:bri:")) {
                            var b = parseInt(cmd.split(":")[2]);
                            notchComp.isAudioMenuOpen = false;
                            if (!isNaN(b)) notchComp.showOsd("brightness", Math.max(0, Math.min(100, b)));
                        }
                        clientSocket.connected = false;
                    }
                }
            }
        }
    }

    // iOS-Style Hyprland Settings Window (Lazy-loaded on first open)
    LazyLoader {
        id: settingsLoader
        SettingsWindow {
            id: settingsWin
            onNotchSettingsChanged: notchComp.refreshNotchSettings()
            Component.onCompleted: settingsWin.isOpen = true
        }
    }
}