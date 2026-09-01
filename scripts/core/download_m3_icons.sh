#!/bin/bash
# download_m3_icons.sh — Utility script to download Material Symbols Rounded SVG icons.
#
# Usage:
#   bash scripts/core/download_m3_icons.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$(cd "${SCRIPT_DIR}/../../assets/icons" && pwd)"
mkdir -p "${ICONS_DIR}"

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
  "battery_6_bar"
  "battery_5_bar"
  "battery_4_bar"
  "battery_3_bar"
  "battery_2_bar"
  "battery_1_bar"
  "battery_0_bar"
  "battery_charging_full"
  "battery_charging_90"
  "battery_charging_80"
  "battery_charging_60"
  "battery_charging_50"
  "battery_charging_30"
  "battery_charging_20"
  "battery_alert"
  "bolt"
  "close"
  "error"
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
  target_file="${ICONS_DIR}/${icon}.svg"
  wget -q -O "${target_file}" "https://raw.githubusercontent.com/google/material-design-icons/master/symbols/web/${icon}/materialsymbolsrounded/${icon}_48px.svg"
  if [ -s "${target_file}" ]; then
    echo "Downloaded ${icon}.svg"
  else
    echo "Failed ${icon}.svg"
    rm -f "${target_file}"
  fi
done
