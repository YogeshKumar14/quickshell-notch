---
name: m3-expressive-ui
description: Enforces the project's strict premium Material 3 Expressive UI design system. Use this skill whenever the user asks to create, modify, or debug UI components, layouts, or animations in QML.
---

# Material 3 Expressive UI Design System

When building or modifying UI components for this project, you MUST strictly adhere to the following premium design rules. Failure to do so will result in a subpar user experience.

## 1. Aesthetics & Shapes
- **M3 Expressive Shapes**: Go all-in on expressive shapes. Use full pill-shapes (e.g., `radius: height / 2`) for buttons, sliders, and highlights. Use large rounded corners (e.g., `28px+`) for outer cards and floating containers.
- **Solid Black & Wallust**: We DO NOT use glassmorphism in this project. Use solid black (`#000000` or `Style.cardBg`) for all backgrounds, and strictly use the dynamically updating Wallust accent colors (`Style.accent`) for highlights. Avoid opaque flat colors that aren't tied to the `Style` singleton.
- **Icons**: NEVER use legacy text-based NerdFonts (e.g., `text: "󰐥"`). ALWAYS use Google's Material Symbols Rounded via the custom `M3Icon` component mapped to an SVG file (e.g., `M3Icon { name: "power_settings_new" }`).

## 2. Micro-Animations & Fluid Motion
- **No Snapping**: UI elements should feel alive. Never snap layouts.
- **Physics**: Always use `SpringAnimation` with an `Easing.OutQuad` curve for state transitions, hover effects, and geometry morphing.
- **Startup Engine Quirks**: In QML, `Behavior` blocks trigger on initialization if a layout width starts at `0` and instantly snaps to a calculated width. To prevent components from "flying in" on startup, dynamically disable the behavior: `Behavior on width { enabled: item.width > 0; SpringAnimation { ... } }`.
- **Rotation Spinners**: QML `RotationAnimation` halts in place when stopped. If spinning an icon (e.g., for loading), always intercept the `onRunningChanged` signal and explicitly snap the rotation back to `0` when the animation stops to prevent diagonal icons.

## 3. Layout & Z-Index Rules
- **No Overflows**: Always use `clip: true` on parent containers to prevent child elements or morphed widths from bleeding outside of `radius` corners.
- **Dynamic Sizing**: Prefer `Layout.fillWidth: true` and `Layout.fillHeight: true` over hardcoded pixel dimensions to ensure the UI scales dynamically.
- **Z-Index Stacking**: QML native painting engine paints siblings in the exact order they are declared in the source code. To place a background hover highlight behind an active colored pill, you MUST declare the background highlight earlier in the QML file.
- **Reactive Engine Dependencies**: In QML, property math like `segRepeater.itemAt(index)` is NOT reactive to the repeater populating its children. Force reactive evaluation on startup by injecting `segRepeater.count > 0` into the ternary math so the UI renders instantly.
