#!/usr/bin/env bash
set -euo pipefail

state="$(systemctl --user show -p LoadState --value ojuny-osk.service 2>/dev/null || true)"
case "$state" in
not-found)
  message="The on-screen keyboard is disabled. Enable it in Settings > Accessibility."
  printf 'ojuny-osk-toggle: %s\n' "$message" >&2
  notify-send -a "On-screen keyboard" "$message" 2>/dev/null || true
  exit 0
  ;;
"")
  message="The on-screen keyboard service could not be queried. Check the systemd user manager."
  printf 'ojuny-osk-toggle: %s\n' "$message" >&2
  notify-send -a "On-screen keyboard" "$message" 2>/dev/null || true
  exit 1
  ;;
esac

pid="$(systemctl --user show -p MainPID --value ojuny-osk.service 2>/dev/null || true)"
case "$pid" in
"" | 0)
  if ! systemctl --user start ojuny-osk.service; then
    message="The on-screen keyboard failed to start. Run: journalctl --user -u ojuny-osk"
    printf 'ojuny-osk-toggle: %s\n' "$message" >&2
    notify-send -a "On-screen keyboard" "$message" 2>/dev/null || true
    exit 1
  fi
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    pid="$(systemctl --user show -p MainPID --value ojuny-osk.service 2>/dev/null || true)"
    [ "$pid" != "" ] && [ "$pid" != "0" ] && break
    sleep 0.1
  done
  if [ "$pid" != "" ] && [ "$pid" != "0" ]; then
    exec kill -s USR2 "$pid"
  fi
  ;;
*)
  exec kill -s RTMIN "$pid"
  ;;
esac
