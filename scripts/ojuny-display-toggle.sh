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

case "$mode" in
all)
  printf '%s' "$monitors" |
    jq -r '.monitors[].name' |
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      mmsg dispatch "toggle_monitor,$name" >/dev/null
    done
  ;;
focused)
  state="$state_dir/focused"
  if [ -f "$state" ]; then
    name="$(cat "$state")"
    rm -f "$state"
  else
    name="$(focused_monitor)"
    [ -n "$name" ] || name="$(first_active)"
    [ -n "$name" ] || exit 1
    printf '%s\n' "$name" >"$state"
  fi
  [ -n "$name" ] || exit 1
  mmsg dispatch "toggle_monitor,$name" >/dev/null
  ;;
*)
  printf 'usage: %s [focused|all]\n' "$0" >&2
  exit 2
  ;;
esac
