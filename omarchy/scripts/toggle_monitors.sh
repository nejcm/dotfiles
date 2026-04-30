#!/usr/bin/env bash
set -euo pipefail

DEFAULT_LAPTOP="eDP-2"
EXTERNAL="HDMI-A-1"
LAPTOP_SCALE="1.67"
EXTERNAL_SCALE="1.07"

MONITORS_OUTPUT="$(hyprctl monitors 2>/dev/null || true)"
MONITORS_ALL="$(hyprctl monitors all 2>/dev/null || true)"

monitor_listed() {
    local monitor=$1
    local output=$2

    printf '%s\n' "${output}" | grep -q "^Monitor ${monitor} "
}

detect_laptop() {
    awk '/^Monitor eDP-/ { print $2; exit }' <<<"${MONITORS_ALL}"
}

LAPTOP="$(detect_laptop)"
LAPTOP="${LAPTOP:-${DEFAULT_LAPTOP}}"

external_connected() {
    monitor_listed "${EXTERNAL}" "${MONITORS_ALL}"
}

external_active() {
    monitor_listed "${EXTERNAL}" "${MONITORS_OUTPUT}"
}

laptop_active() {
    monitor_listed "${LAPTOP}" "${MONITORS_OUTPUT}"
}

enable_external_only() {
    if ! external_connected; then
        enable_laptop_only
        notify-send "Monitor toggle" "External monitor ${EXTERNAL} is not connected." || true
        return 1
    fi

    hyprctl keyword monitor "${EXTERNAL},preferred,auto,${EXTERNAL_SCALE}"
    hyprctl keyword monitor "${LAPTOP},disable"
}

enable_laptop_only() {
    hyprctl keyword monitor "${LAPTOP},preferred,auto,${LAPTOP_SCALE}"
    # External may be disconnected; don't fail the whole script for that.
    hyprctl keyword monitor "${EXTERNAL},disable" >/dev/null 2>&1 || true
}

startup_layout() {
    if external_connected; then
        enable_external_only
    else
        enable_laptop_only
    fi
}

case "${1:-toggle}" in
    --startup|startup)
        startup_layout
        exit 0
        ;;
    toggle|"")
        ;;
    *)
        echo "Usage: $0 [toggle|--startup]" >&2
        exit 2
        ;;
esac

if external_active; then
    # External is currently active -> switch to laptop only.
    enable_laptop_only
elif laptop_active; then
    # Laptop is active and external is not active -> try switching to external-only.
    enable_external_only || true
else
    # Safety fallback: if no known monitor appears active, choose an available output.
    startup_layout
fi
