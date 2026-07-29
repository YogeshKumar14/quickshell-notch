import os
import re

filepath = '/home/yogesh/.config/quickshell/components/SettingsWindow.qml'
with open(filepath, 'r') as f:
    content = f.read()

replacements = {
    r'Text\s*\{\s*text:\s*index\s*<\s*2\s*\?\s*"󰍹"\s*:\s*"󰒓";\s*font\.family:\s*Style\.fontFamilyMono;\s*color:\s*root\.currentTab\s*===\s*index\s*\?\s*"#000"\s*:\s*Style\.textSecondary;\s*font\.pixelSize:\s*13\s*\}': 
    'M3Icon { name: index < 2 ? "desktop_windows" : "settings"; color: root.currentTab === index ? "#000" : Style.textSecondary; size: 16 }',

    r'Text\s*\{\s*text:\s*"󰍹";\s*font\.family:\s*Style\.fontFamilyMono;\s*font\.pixelSize:\s*13;\s*color:\s*Style\.accent\s*\}':
    'M3Icon { name: "desktop_windows"; color: Style.accent; size: 16 }',

    r'Text\s*\{\s*text:\s*"󰒓";\s*font\.family:\s*Style\.fontFamilyMono;\s*font\.pixelSize:\s*13;\s*color:\s*Style\.accent\s*\}':
    'M3Icon { name: "settings"; color: Style.accent; size: 16 }',

    r'Text\s*\{\s*text:\s*"󰍽";\s*font\.family:\s*Style\.fontFamilyMono;\s*font\.pixelSize:\s*13;\s*color:\s*Style\.accent\s*\}':
    'M3Icon { name: "keyboard"; color: Style.accent; size: 16 }',

    r'Text\s*\{\s*text:\s*"󰎆";\s*font\.family:\s*Style\.fontFamilyMono;\s*font\.pixelSize:\s*13;\s*color:\s*Style\.accent\s*\}':
    'M3Icon { name: "music_note"; color: Style.accent; size: 16 }',

    r'Text\s*\{\s*text:\s*"󰸉";\s*font\.family:\s*Style\.fontFamilyMono;\s*font\.pixelSize:\s*13;\s*color:\s*Style\.accent\s*\}':
    'M3Icon { name: "wallpaper"; color: Style.accent; size: 16 }',

    r'Text\s*\{\s*text:\s*"󰁹";\s*font\.family:\s*Style\.fontFamilyMono;\s*font\.pixelSize:\s*13;\s*color:\s*Style\.accent\s*\}':
    'M3Icon { name: "battery_charging_full"; color: Style.accent; size: 16 }',

    r'Text\s*\{\s*text:\s*"󰻠";\s*font\.family:\s*Style\.fontFamilyMono;\s*font\.pixelSize:\s*13;\s*color:\s*Style\.accent\s*\}':
    'M3Icon { name: "memory"; color: Style.accent; size: 16 }',

    r'Text\s*\{\s*text:\s*"󰑐";\s*font\.family:\s*Style\.fontFamilyMono;\s*color:\s*Style\.accent;\s*font\.pixelSize:\s*13\s*\}':
    'M3Icon { name: "refresh"; color: Style.accent; size: 16 }',
    
    # Text { text: "Reset"; font.family: Style.fontFamily; font.pixelSize: Style.fontSizeSmall; color: Style.textPrimary; font.weight: Font.Bold }
    # wait, Reset text is fine, just the icon before it!
}

for pattern, replacement in replacements.items():
    content = re.sub(pattern, replacement, content)

with open(filepath, 'w') as f:
    f.write(content)
