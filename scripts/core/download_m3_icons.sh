#!/bin/bash
ICONS=(
  "play_arrow"
  "pause"
  "skip_next"
  "skip_previous"
  "volume_up"
  "volume_down"
  "volume_mute"
  "volume_off"
  "mic"
  "mic_off"
  "wifi"
  "bluetooth"
  "battery_full"
  "battery_charging_full"
  "battery_alert"
  "memory"
  "hard_drive"
  "notifications"
  "notifications_off"
  "search"
  "wallpaper"
  "apps"
  "mouse"
  "auto_awesome"
)

for icon in "${ICONS[@]}"; do
  wget -q -O "/home/yogesh/.config/quickshell/assets/icons/${icon}.svg" "https://raw.githubusercontent.com/google/material-design-icons/master/symbols/web/${icon}/materialsymbolsrounded/${icon}_48px.svg"
  if [ -s "/home/yogesh/.config/quickshell/assets/icons/${icon}.svg" ]; then
    echo "Downloaded ${icon}.svg"
  else
    echo "Failed ${icon}.svg"
    rm "/home/yogesh/.config/quickshell/assets/icons/${icon}.svg"
  fi
done
