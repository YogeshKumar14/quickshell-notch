# Building a High-End Desktop Notch: A Complete Quickshell Masterclass

Quickshell is a powerful framework that allows you to build desktop widgets, panels, and overlays using **Qt Quick (QML)** and **Wayland**. This guide is a complete, beginner-friendly walkthrough that teaches you how to construct the Top Notch component from scratch, explaining every advanced compositor concept required to build your own custom desktop bars.

---

## 1. The Anatomy of Quickshell & QML

Quickshell acts as a bridge between the **Qt Quick rendering engine** and the **Wayland Compositor** (e.g., Hyprland). 

Unlike standard Qt applications that run in window borders, Quickshell instantiates surfaces directly on Wayland layer-shell levels. The main entry point is typically named `shell.qml`, and it uses **Scope** as the root container to host windows and services.

```qml
import Quickshell
import QtQuick

Scope {
    id: root
    // Your windows, servers, and services live here
}
```

---

## 2. Layer-Shell & Window Configurations

To place a panel on the screen, we use the `PanelWindow` component. This sets layer-shell parameters directly on the Wayland compositor.

```qml
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: notchWindow

    // Layer-Shell placement rules:
    // WlrLayer.Overlay ensures our notch draws on top of full-screen windows
    WlrLayershell.layer: WlrLayer.Overlay
    
    // exclusiveZone: 0 tells the window manager not to push other windows down.
    // This allows the notch to slide organically over windows.
    WlrLayershell.exclusiveZone: 0

    // Anchor the window to the center-top of the monitor
    anchors {
        top: true
        horizontalCenter: true
    }

    implicitWidth: 600
    implicitHeight: 450
    color: "transparent" // Keep the main window canvas fully transparent
}
```

---

## 3. The Input Passthrough Mask (Region Magic)

A common bug in layer-shell windows is that even if a window is `transparent`, its bounding box (e.g. 600×450) still blocks mouse clicks. Users cannot click on desktop icons or windows behind the invisible areas of the panel.

Quickshell solves this using **input masks**:

```qml
PanelWindow {
    id: notchWindow
    color: "transparent"

    // Crucial: Only pass clicks to the target item. All transparent areas of the
    // 600x450 canvas will let mouse clicks pass directly through to desktop windows!
    mask: Region { item: notchComp.notchBoxItem }

    TopNotch {
        id: notchComp
        anchors.fill: parent
    }
}
```
*Concept*: `mask: Region { item: target }` tells the Wayland compositor to map mouse pointer collision bounds *only* to the visible rectangle of `target`.

---

## 4. Size Morphing & Spring Physics

To create an organic, iOS-like notch, we design a single physical `Rectangle` (the pill) that dynamically morphs its width and height based on the current state.

### Declaring Spring Animations
Instead of linear movements, we bind properties to a `Behavior` containing a `SpringAnimation`. This creates natural physics-based elastic morphing.

```qml
Rectangle {
    id: notchBox
    color: "#000000"

    // Morph sizes based on states: Compact, Expanded, and Morphed Power Options
    width: root.isPowerMenuOpen ? 320 : (root.isExpanded ? 560 : 130)
    height: root.isPowerMenuOpen ? 260 : (root.isExpanded ? 420 : 30)
    
    // Dynamic bottom corner radius
    bottomLeftRadius: root.isPowerMenuOpen ? 24 : 12
    bottomRightRadius: root.isPowerMenuOpen ? 24 : 12

    // Apply elastic spring animation on size changes
    Behavior on width {
        SpringAnimation {
            spring: 5.5       // Stiffness/tension of the spring
            damping: 0.35     // Friction (lower means more bounce/elasticity)
            epsilon: 0.25     // Resolution accuracy before stopping
        }
    }

    Behavior on height {
        SpringAnimation {
            spring: 5.5
            damping: 0.35
            epsilon: 0.25
        }
    }
}
```

---

## 5. Keyboard Focus Routing & QML FocusScopes

When you open a panel using a global shortcut key, getting the cursor into the search bar has two major obstacles on Wayland:
1. **Compositor Focus**: Wayland does not automatically focus layer-shell windows during dynamic state changes.
2. **QML Focus Scope Chain**: In QML, active focus must cascade cleanly down from the root window. If any intermediate container lacks focus, calling `forceActiveFocus()` on a `TextInput` will fail.

### Step A: Use QML FocusScopes
A `FocusScope` acts as a local focus boundary. If the parent focuses the scope, the scope automatically delegates active focus to the internal `TextInput` that has `focus: true`.

```qml
// WallpaperSelector.qml (FocusScope root)
FocusScope {
    id: root

    TextInput {
        id: searchInput
        focus: true // Marks this input as the default receiver inside this scope
        activeFocusOnPress: true
        selectByMouse: true
    }
}
```

### Step B: Setup Loaders in parent
In the parent window (`TopNotch.qml`), make sure all wrapping elements and loaders have `focus: true`:

```qml
Item {
    id: pageViewport
    focus: true
    
    Row {
        focus: true
        
        Loader {
            id: wallsLoader
            focus: true
            sourceComponent: WallpaperSelector {}
        }
    }
}
```

### Step C: Request Compositor Focus Grab (HyprlandFocusGrab)
To programmatically tell Hyprland to grab the keyboard and route keys to the Quickshell window when expanded, use the native `HyprlandFocusGrab` service in `shell.qml`:

```qml
import Quickshell.Hyprland

Scope {
    // 1. Tell layer-shell to support keyboard inputs
    WlrLayershell.keyboardFocus: (notchComp.isExpanded || notchComp.isPowerMenuOpen) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // 2. Lock compositor focus to our window when active
    HyprlandFocusGrab {
        id: focusGrab
        active: notchComp.isExpanded || notchComp.isPowerMenuOpen
        windows: [notchWindow]
    }
}
```

---

## 6. IPC Socket Communication

To allow external system shortcuts (like Hyprland keybinds `Super+W` and `Super+R`) to trigger notch pages, we instantiate a `SocketServer` in Quickshell listening on a local Unix socket.

```qml
import Quickshell.Io

SocketServer {
    id: ipcServer
    active: true
    path: "/tmp/quickshell-notch.sock"
    
    handler: Component {
        Socket {
            parser: SplitParser {
                split: "\n"
                onParsed: function(cmd) {
                    var command = cmd.trim();
                    if (command === "walls") {
                        notchComp.toggleTab(1); // Open walls tab
                    } else if (command === "apps") {
                        notchComp.toggleTab(2); // Open apps tab
                    } else if (command === "close") {
                        notchComp.isExpanded = false;
                    }
                }
            }
        }
    }
}
```

External keybinds can write to this socket using a simple helper utility or command:
`echo "walls" | socat - UNIX-CONNECT:/tmp/quickshell-notch.sock`

---

## 7. Performance Optimizations for Desktop Widgets

Because widgets run constantly in the background, minimizing CPU and memory usage is essential.

### A. Disable Redundant QML Animation Behaviors
Running a QML `Behavior on height` or `opacity` on items that update rapidly (like an audio visualizer updating 25 times per second) spawns hundreds of animation timers in the background.
*Optimization*: CAVA (or similar streams) already smooths frames. Remove `Behavior` blocks from repeating elements (like visualizer bars) and let them update heights instantly.

### B. Fast Python File-Scans with Cache Validation
Scanning directories like `/usr/share/applications` or `/usr/share/icons` recursively via Python's `os.walk` takes **3 to 4 seconds**.
*Optimization*:
1. Save scan results to a JSON cache file (`~/.cache/quickshell/apps.json`).
2. Before scanning, check if the cache file is newer than the directory modification times (`os.path.getmtime`). If yes, output the cache instantly (**0.01s**).
3. When walking directory trees, prune irrelevant directories (like `16x16`, `32x32`, `actions`, `mimetypes`) by modifying the `dirnames` list in-place:
   ```python
   for dirpath, dirnames, filenames in os.walk(root_dir):
       dirnames[:] = [d for d in dirnames if d.lower() not in ("16x16", "32x32", "actions")]
   ```
   This skips traversing 85% of folders, bringing cold scans down to **0.1s**.

---

## 8. Putting It All Together

By combining:
1. **`PanelWindow` with an input `mask`** for clicks passthrough.
2. **`SpringAnimation`** for organic notch physical expansion.
3. **`FocusScope` + `HyprlandFocusGrab`** for instant keyboard focus entry.
4. **`SocketServer`** for IPC compositor keybinds.

You get a fully integrated desktop bar that runs with **0.0% idle CPU** and responds with fluid animations!
