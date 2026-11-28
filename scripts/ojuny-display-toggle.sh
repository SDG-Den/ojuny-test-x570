#!/usr/bin/env bash
set -euo pipefail

mode="${1:-focused}"
monitors="$(mmsg get all-monitors)" || exit 1
state_dir="${XDG_RUNTIME_DIR:-/tmp}/ojuny-display-toggle"
mkdir -p "$state_dir"

first_active() {
  printf '%s' "$monitors" | jq -r '.monitors[] | select(.active == true) | .name' | head -n 1
}

focused_monitor() {
  mmsg get focusing-client 2>/dev/null |
    jq -r '.monitor // empty' 2>/dev/null |
    head -n 1 || true
}

reload_layout() {
  mmsg dispatch reload_config >/dev/null 2>&1 || true
}

case "$mode" in
all)
  active="$(printf '%s' "$monitors" | jq -r '.monitors[] | select(.active == true) | .name')"
  names="$active"
  if [ -z "$active" ]; then
    names="$(printf '%s' "$monitors" | jq -r '.monitors[].name')"
  fi
  printf '%s\n' "$names" |
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      mmsg dispatch "toggle_monitor,$name" >/dev/null
    done
  if [ -z "$active" ]; then
    reload_layout
  fi
  ;;
focused)
  state="$state_dir/focused"
  reenable=0
  if [ -f "$state" ]; then
    name="$(cat "$state")"
    rm -f "$state"
    reenable=1
  else
    name="$(focused_monitor)"
    [ -n "$name" ] || name="$(first_active)"
    [ -n "$name" ] || exit 1
    printf '%s\n' "$name" >"$state"
  fi
  [ -n "$name" ] || exit 1
  mmsg dispatch "toggle_monitor,$name" >/dev/null
  if [ "$reenable" -eq 1 ]; then
    reload_layout
  fi
  ;;
*)
  printf 'usage: %s [focused|all]\n' "$0" >&2
  exit 2
  ;;
esac
