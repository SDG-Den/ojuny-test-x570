#!/usr/bin/env bash
set -euo pipefail

state="$(systemctl --user show -p LoadState --value ojuny-osk.service 2>/dev/null || true)"
if [ "$state" = "not-found" ] || [ -z "$state" ]; then
  message="The on-screen keyboard is disabled. Enable it in Settings > Accessibility."
  printf 'ojuny-osk-toggle: %s\n' "$message" >&2
  notify-send -a "On-screen keyboard" "$message" 2>/dev/null || true
  exit 0
fi

pid="$(systemctl --user show -p MainPID --value ojuny-osk.service 2>/dev/null || true)"
case "$pid" in
"" | 0) exec systemctl --user start ojuny-osk.service ;;
*) exec kill -s RTMIN "$pid" ;;
esac
