#!/usr/bin/env bash
# Bluetooth menu: scan/pair/connect/disconnect/forget devices, picked via wofi.
set -euo pipefail

icon_bluetooth=$''
icon_power=$''
icon_refresh=$''
icon_check=$''
icon_x=$''

MAP_SEP=$'\x1f'
SCAN_SECONDS=6

notify() { notify-send "Bluetooth" "$1"; }

bt() { timeout 3 bluetoothctl "$@"; }

[[ -d /sys/class/bluetooth ]] || { notify "No Bluetooth adapter found"; exit 0; }
[[ -n "$(bt list)" ]] || { notify "No Bluetooth adapter found"; exit 0; }

is_powered() {
    bt show | awk -F': ' '/^[[:space:]]*Powered:/ { print $2; exit }' | grep -qx yes
}

toggle_power() {
    if is_powered; then
        bt power off && notify "Bluetooth turned off"
    else
        bt power on && notify "Bluetooth turned on"
    fi
}

ensure_agent() {
    bt agent NoInputNoOutput >/dev/null 2>&1 || true
    bt default-agent >/dev/null 2>&1 || true
}

list_paired_lines() {
    local map_file="$1" mac name connected icon row
    while read -r _ mac name; do
        [[ -z "$mac" ]] && continue
        connected=$(bt info "$mac" | awk -F': ' '/^[[:space:]]*Connected:/ { print $2; exit }')
        icon="$icon_bluetooth"
        [[ "$connected" == "yes" ]] && icon="$icon_check"
        row="${icon}  ${name:-$mac}"
        printf "%s${MAP_SEP}%s${MAP_SEP}%s${MAP_SEP}%s\n" "$row" "$mac" "$connected" "paired" >> "$map_file"
        echo "$row"
    done < <(bt devices Paired)
}

list_discovered_lines() {
    local map_file="$1" paired_macs mac name row
    paired_macs=$(bt devices Paired | awk '{print $2}')

    while read -r _ mac name; do
        [[ -z "$mac" ]] && continue
        grep -qxF "$mac" <<< "$paired_macs" && continue
        row="${icon_bluetooth}  ${name:-$mac}"
        printf "%s${MAP_SEP}%s${MAP_SEP}%s${MAP_SEP}%s\n" "$row" "$mac" "" "discovered" >> "$map_file"
        echo "$row"
    done < <(bt devices)
}

has_paired_devices() {
    [[ -n "$(bt devices Paired)" ]]
}

build_menu() {
    local map_file="$1" include_discovered="${2:-0}"

    if is_powered; then
        echo "${icon_power}  Turn Bluetooth Off"
    else
        echo "${icon_power}  Turn Bluetooth On"
        return 0
    fi

    echo "${icon_refresh}  Scan for Devices"
    has_paired_devices && echo "${icon_x}  Forget a Device"

    list_paired_lines "$map_file"

    if [[ "$include_discovered" == "1" ]]; then
        list_discovered_lines "$map_file"
    fi
}

do_scan() {
    notify "Scanning for devices (${SCAN_SECONDS}s)..."
    timeout $((SCAN_SECONDS + 2)) bluetoothctl --timeout "$SCAN_SECONDS" scan on >/dev/null 2>&1 || true
}

do_toggle_connection() {
    local mac="$1" name="$2" connected="$3"
    if [[ "$connected" == "yes" ]]; then
        if timeout 10 bluetoothctl disconnect "$mac" >/dev/null 2>&1; then
            notify "Disconnected ${name}"
        else
            notify "Failed to disconnect ${name}"
        fi
    else
        if timeout 10 bluetoothctl connect "$mac" >/dev/null 2>&1; then
            notify "Connected to ${name}"
        else
            notify "Failed to connect to ${name}"
        fi
    fi
}

do_pair() {
    local mac="$1" name="$2"
    notify "Pairing with ${name}..."
    ensure_agent

    if ! timeout 15 bluetoothctl pair "$mac" >/dev/null 2>&1; then
        notify "Failed to pair with ${name}"
        return
    fi

    bt trust "$mac" >/dev/null 2>&1 || true

    if timeout 10 bluetoothctl connect "$mac" >/dev/null 2>&1; then
        notify "Paired and connected to ${name}"
    else
        notify "Paired with ${name} (connect failed, will retry automatically)"
    fi
}

forget_menu() {
    local map_file="$1" mac name row list=""
    while read -r _ mac name; do
        [[ -z "$mac" ]] && continue
        row="${icon_x}  ${name:-$mac}"
        printf "%s${MAP_SEP}%s${MAP_SEP}%s${MAP_SEP}%s\n" "$row" "$mac" "" "forget" >> "$map_file"
        list+="${row}"$'\n'
    done < <(bt devices Paired)

    [[ -z "$list" ]] && { notify "No paired devices to forget"; return; }

    local chosen_forget
    chosen_forget=$(printf '%s' "$list" | wofi --dmenu --prompt "Forget Device" --width 380 --height 300 --cache-file /dev/null)
    [[ -z "$chosen_forget" ]] && return

    local row_data target
    row_data=$(awk -F"$MAP_SEP" -v r="$chosen_forget" '$1 == r { print; exit }' "$map_file")
    [[ -z "$row_data" ]] && return
    IFS="$MAP_SEP" read -r _ target _ _ <<< "$row_data"
    if bluetoothctl remove "$target" >/dev/null 2>&1; then
        notify "Forgot ${chosen_forget#*  }"
    else
        notify "Failed to forget device"
    fi
}

dispatch_row() {
    local map_file="$1" chosen="$2"
    local row_data mac extra kind
    row_data=$(awk -F"$MAP_SEP" -v r="$chosen" '$1 == r { print; exit }' "$map_file")
    [[ -z "$row_data" ]] && return
    IFS="$MAP_SEP" read -r _ mac extra kind <<< "$row_data"
    case "$kind" in
        paired) do_toggle_connection "$mac" "${chosen#*  }" "$extra" ;;
        discovered) do_pair "$mac" "${chosen#*  }" ;;
    esac
}

map_file=$(mktemp)
trap 'rm -f "$map_file"' EXIT

menu=$(build_menu "$map_file")
chosen=$(echo "$menu" | wofi --dmenu --prompt "Bluetooth" --width 380 --height 400 --cache-file /dev/null)

case "$chosen" in
    "") exit 0 ;;
    *"Turn Bluetooth"*) toggle_power ;;
    *"Scan for Devices")
        do_scan
        menu=$(build_menu "$map_file" 1)
        chosen=$(echo "$menu" | wofi --dmenu --prompt "Bluetooth" --width 380 --height 400 --cache-file /dev/null)
        case "$chosen" in
            "") exit 0 ;;
            *"Turn Bluetooth"*) toggle_power ;;
            *"Scan for Devices") exec "$0" ;;
            *"Forget a Device") forget_menu "$map_file" ;;
            *) dispatch_row "$map_file" "$chosen" ;;
        esac
        ;;
    *"Forget a Device") forget_menu "$map_file" ;;
    *) dispatch_row "$map_file" "$chosen" ;;
esac
