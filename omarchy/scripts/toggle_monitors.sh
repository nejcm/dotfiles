#!/usr/bin/env bash
set -euo pipefail

LAPTOP="eDP-2"
EXTERNAL="HDMI-A-1"
LAPTOP_SCALE="1.67"
EXTERNAL_SCALE="1.07"

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.conf"
BEGIN="# >>> toggle_monitors (managed by toggle_monitors.sh)"
END="# <<< toggle_monitors"

write_monitor_block() {
	local conf="$1" m1="$2" m2="$3"
	[[ -f "$conf" ]] || {
		echo "toggle_monitors: missing ${conf}" >&2
		exit 1
	}
	local tmp found=0
	tmp=$(mktemp)
	while IFS= read -r line || [[ -n "${line}" ]]; do
		if [[ "${line}" == "${BEGIN}" ]]; then
			printf '%s\n' "${BEGIN}" "${m1}" "${m2}" "${END}"
			found=1
			while IFS= read -r line || [[ -n "${line}" ]]; do
				[[ "${line}" == "${END}" ]] && break
			done
			continue
		fi
		printf '%s\n' "${line}"
	done <"${conf}" >"${tmp}"
	if [[ "${found}" -eq 0 ]]; then
		printf '\n%s\n%s\n%s\n%s\n' "${BEGIN}" "${m1}" "${m2}" "${END}" >>"${tmp}"
	fi
	mv "${tmp}" "${conf}"
}

if hyprctl monitors | grep -q "^Monitor ${EXTERNAL} "; then
	m1="monitor=${LAPTOP},preferred,auto,${LAPTOP_SCALE}"
	m2="monitor=${EXTERNAL},disable"
else
	m1="monitor=${EXTERNAL},preferred,auto,${EXTERNAL_SCALE}"
	m2="monitor=${LAPTOP},disable"
fi

write_monitor_block "${CONFIG}" "${m1}" "${m2}"
hyprctl keyword monitor "${m1#monitor=}"
hyprctl keyword monitor "${m2#monitor=}"
