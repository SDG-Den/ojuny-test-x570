#!/usr/bin/env bash
set -euo pipefail

mode="${1:-focused}"
monitors="$(mmsg get all-monitors)" || exit 1
state_dir="${XDG_RUNTIME_DIR:-/tmp}/ojuny-display-toggle"
state="$state_dir/off.json"
mkdir -p "$state_dir"

focused_monitor() {
  mmsg get focusing-client 2>/dev/null |
    jq -r '.monitor // empty' 2>/dev/null |
    head -n 1 || true
}

focused_from_list() {
  printf '%s' "$monitors" | jq -r '.monitors[] | select(.active == true) | .name' | head -n 1
}

first_enabled() {
  printf '%s' "$monitors" | jq -r '.monitors[].name' | head -n 1
}

save_off() {
  local name="$1" object tmp
  object="$(printf '%s' "$monitors" | jq -c --arg name "$name" '.monitors[] | select(.name == $name)' 2>/dev/null || true)"
  [ -n "$object" ] || object='{}'
  tmp="$(mktemp)"
  if [ -f "$state" ]; then
    jq --arg name "$name" --argjson object "$object" '.[$name] = $object' "$state" >"$tmp"
  else
    jq -n --arg name "$name" --argjson object "$object" '{($name): $object}' >"$tmp"
  fi
  mv "$tmp" "$state"
}

restore_positions() {
  [ -f "$state" ] || return 0
  command -v wlr-randr >/dev/null 2>&1 || return 0
  while IFS=$'\t' read -r name x y; do
    [ -n "$name" ] && [ -n "$x" ] && [ -n "$y" ] || continue
    wlr-randr --output "$name" --pos "$x,$y" >/dev/null 2>&1 || true
  done < <(jq -r 'to_entries[] | [.key, (.value.x // ""), (.value.y // "")] | @tsv' "$state")
}

turn_off() {
  save_off "$1"
  mmsg dispatch "toggle_monitor,$1" >/dev/null
}

turn_on() {
  mmsg dispatch "toggle_monitor,$1" >/dev/null
}

case "$mode" in
all)
  off=""
  if [ -f "$state" ]; then
    off="$(jq -r 'keys[]' "$state")"
  fi
  inactive_off=""
  for name in $off; do
    if ! printf '%s' "$monitors" | jq -e --arg name "$name" '.monitors[] | select(.name == $name)' >/dev/null 2>&1; then
      inactive_off="$inactive_off $name"
    fi
  done
  if [ -n "$inactive_off" ]; then
    for name in $inactive_off; do turn_on "$name"; done
    mmsg dispatch reload_config >/dev/null 2>&1 || true
    restore_positions
    rm -f "$state"
  else
    names="$(printf '%s' "$monitors" | jq -r '.monitors[].name')"
    [ -n "$names" ] || exit 0
    for name in $names; do turn_off "$name"; done
    mmsg dispatch reload_config >/dev/null 2>&1 || true
  fi
  ;;
focused)
  name="$(focused_monitor)"
  [ -n "$name" ] || name="$(focused_from_list)"
  [ -n "$name" ] || name="$(first_enabled)"
  [ -n "$name" ] || exit 1
  turn_off "$name"
  mmsg dispatch reload_config >/dev/null 2>&1 || true
  ;;
*)
  printf 'usage: %s [focused|all]\n' "$0" >&2
  exit 2
  ;;
esac
