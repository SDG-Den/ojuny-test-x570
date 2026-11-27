#!/usr/bin/env bash
set -euo pipefail

floating_action="${1:-maximize}"
tiling_action="${2:-zoom}"
pass_through_mode="middle-click-passthrough"

state_dir="${XDG_RUNTIME_DIR:-/tmp}/ojuny-middle-click"
mkdir -p "$state_dir"
exec 9>"$state_dir/click.lock"
flock -n 9 || exit 0

previous_mode="$(mmsg get keymode 2>/dev/null | jq -r '.keymode // "default"' 2>/dev/null || true)"
[ -n "$previous_mode" ] || previous_mode="default"
if [ "$previous_mode" = "$pass_through_mode" ]; then
  previous_mode="default"
fi

client="$(mmsg get focusing-client 2>/dev/null || true)"
if [ -z "$client" ] || [ "$(printf '%s' "$client" | jq -r 'has("error")')" = true ]; then
  exit 0
fi

is_fullscreen="$(printf '%s' "$client" | jq -r '.is_fullscreen // false')"
is_floating="$(printf '%s' "$client" | jq -r '.is_floating // false')"

apply_action() {
  case "$1" in
    maximize) mmsg dispatch "togglemaximizescreen,0" >/dev/null 2>&1 || true ;;
    zoom) mmsg dispatch zoom >/dev/null 2>&1 || true ;;
  esac
}

reemit_middle_click() {
  mmsg dispatch "setkeymode,$pass_through_mode" >/dev/null 2>&1 || return 0
  ydotool click 0xC2 >/dev/null 2>&1 || true
  sleep 0.2
  mmsg dispatch "setkeymode,$previous_mode" >/dev/null 2>&1 || true
}

if [ "$is_fullscreen" = true ]; then
  reemit_middle_click
  exit 0
fi

if [ "$is_floating" = true ]; then
  action="$floating_action"
else
  action="$tiling_action"
fi

apply_action "$action"
reemit_middle_click
