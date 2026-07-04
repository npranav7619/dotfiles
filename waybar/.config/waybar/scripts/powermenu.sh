#!/usr/bin/env bash
# Power menu: lock / logout / restart / shutdown, picked via wofi.
set -euo pipefail

icon_lock=$''
icon_logout=$''
icon_restart=$''
icon_shutdown=$''

options="${icon_lock}  Lock\n${icon_logout}  Logout\n${icon_restart}  Restart\n${icon_shutdown}  Shutdown"

chosen=$(echo -e "$options" | wofi --dmenu --prompt "Power" --width 300 --height 220 --cache-file /dev/null)

case "$chosen" in
    *Lock) exec swaylock -f ;;
    *Logout) exec swaymsg exit ;;
    *Restart) exec systemctl reboot ;;
    *Shutdown) exec systemctl poweroff ;;
esac
