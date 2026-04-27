#!/usr/bin/env bash
set -euo pipefail

LAPTOP="eDP-2"
EXTERNAL="HDMI-A-1"

if hyprctl monitors | grep -q "^Monitor ${EXTERNAL} "; then
    hyprctl keyword monitor "${EXTERNAL},preferred,auto,1.07"
    hyprctl keyword monitor "${LAPTOP},disable"
else
    hyprctl keyword monitor "${LAPTOP},preferred,auto,1.67"
fi
