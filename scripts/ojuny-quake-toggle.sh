#!/usr/bin/env bash
set -euo pipefail

appid="${1:?app id is required}"
title="${2:-none}"
shift 2
command="${*:-}"

focused="$(mmsg get focusing-client 2>/dev/null | jq -r '.monitor // empty' 2>/dev/null || true)"
if [ -z "$focused" ]; then
  focused="$(mmsg get all-monitors 2>/dev/null | jq -r '.monitors[] | select(.active == true) | .name' 2>/dev/null | head -n 1 || true)"
fi
[ -n "$focused" ] || exit 1

visible_count() {
  mmsg get all-clients 2>/dev/null |
    jq -r --arg appid "$appid" '[.[] | select(.appid == $appid and .is_visible == true)] | length' 2>/dev/null ||
    printf 0
}

client_json() {
  mmsg get all-clients 2>/dev/null |
    jq -c --arg appid "$appid" '.[] | select(.appid == $appid and .is_visible == true)' 2>/dev/null |
    head -n 1 || true
}

if [ "$(visible_count)" -gt 0 ]; then
  mmsg dispatch "toggle_named_scratchpad,$appid,$title,$command" >/dev/null
  exit 0
fi

mmsg dispatch "toggle_named_scratchpad,$appid,$title,$command" >/dev/null
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ "$(visible_count)" -gt 0 ] && break
  sleep 0.1
done

client="$(client_json)"
[ -n "$client" ] || exit 0
monitor="$(printf '%s' "$client" | jq -r '.monitor // empty')"
[ -n "$monitor" ] || exit 0

if [ "$monitor" != "$focused" ]; then
  mmsg dispatch "tagmon,$focused" >/dev/null 2>&1 || true
  sleep 0.2
  client="$(client_json)"
  monitor="$(printf '%s' "$client" | jq -r '.monitor // empty')"
fi

geometry="$(mmsg get monitor "$monitor" 2>/dev/null || true)"
if [ -z "$geometry" ]; then
  geometry="$(mmsg get all-monitors 2>/dev/null | jq -c --arg name "$monitor" '.monitors[] | select(.name == $name)' 2>/dev/null || true)"
fi

width="$(printf '%s' "$client" | jq -r '.width // 0')"
height="$(printf '%s' "$client" | jq -r '.height // 0')"
mx="$(printf '%s' "$geometry" | jq -r '.x // 0')"
my="$(printf '%s' "$geometry" | jq -r '.y // 0')"
mw="$(printf '%s' "$geometry" | jq -r '.width // 0')"
mh="$(printf '%s' "$geometry" | jq -r '.height // 0')"

[ "$mw" -gt 0 ] && [ "$mh" -gt 0 ] && [ "$width" -gt 0 ] && [ "$height" -gt 0 ] || exit 0

x=$((mx + (mw - width) / 2))
y=$my
mmsg dispatch "movewin,$x,$y" >/dev/null 2>&1 || true
