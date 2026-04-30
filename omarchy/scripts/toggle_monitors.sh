#!/usr/bin/env bash
set -euo pipefail

LAPTOP="eDP-2"
EXTERNAL="HDMI-A-1"
LAPTOP_SCALE="1.67"
EXTERNAL_SCALE="1.07"

if hyprctl monitors | grep -q "^Monitor ${EXTERNAL} "; then
    hyprctl keyword monitor "${LAPTOP},preferred,auto,${LAPTOP_SCALE}"
    hyprctl keyword monitor "${EXTERNAL},disable"
else
    hyprctl keyword monitor "${EXTERNAL},preferred,auto,${EXTERNAL_SCALE}"
    hyprctl keyword monitor "${LAPTOP},disable"
fi
