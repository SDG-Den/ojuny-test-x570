#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "usage: ojuny-raven-report REPORT APP WRAPPER STATUS [ARG...]" >&2
  exit 2
fi

report="$1"
app="$2"
wrapper="$3"
status="$4"
shift 4
app_name="$(basename "$app")"

trim_report() {
  local file="$1" max=262144 tmp
  [ -f "$file" ] || return 0
  if [ "$(stat -c %s "$file" 2>/dev/null || printf 0)" -gt "$max" ]; then
    tmp="$(mktemp)"
    {
      head -c "$max" "$file"
      printf '\n--- report truncated at %s bytes ---\n' "$max"
    } | fold -s -w 4000 >"$tmp"
    mv "$tmp" "$file"
  fi
}
trim_report "$report"

if [ -n "${OJUNY_RAVEN_SURVEY:-}" ]; then
  if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    yad --text-info --title="Raven failed: $app_name (survey mode)" --filename="$report" --width=900 --height=600 --class=ojuny-raven-report --name=ojuny-raven-report --center --on-top --button="Close:0" || true
  else
    cat "$report" >&2
  fi
  exit 0
fi

if [ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] || [ -t 2 ]; then
  cat "$report" >&2
  exit 0
fi

set +e
timeout 300s yad --text-info --title="Raven failed: $app_name (exit $status)" --filename="$report" --width=900 --height=600 --class=ojuny-raven-report --name=ojuny-raven-report --center --on-top \
  --button="Close:0" --button="Relaunch in survey mode:3"
choice=$?
set -e

if [ "$choice" -ne 3 ]; then
  exit 0
fi

set +e
yad --title="Raven survey mode" --class=ojuny-raven-report --name=ojuny-raven-report --center --on-top \
  --text="This may break your Raven configuration and might result in undefined behaviour.

Are you really sure?" \
  --button="Cancel:1" --button="Relaunch:0"
confirm=$?
set -e

if [ "$confirm" -ne 0 ]; then
  exit 0
fi

export RAVEN_SURVEY_MISSING=1
export OJUNY_RAVEN_SURVEY=1
exec "$wrapper" "$@"
