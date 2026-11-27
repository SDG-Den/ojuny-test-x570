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

fold_report() {
  local file="$1" max=262144 size tmp
  [ -f "$file" ] || return 0
  size="$(stat -c %s "$file" 2>/dev/null || printf 0)"
  tmp="$(mktemp)"
  {
    if [ "$size" -gt "$max" ]; then
      head -c "$max" "$file"
      printf '\n--- report truncated at %s bytes ---\n' "$max"
    else
      cat "$file"
    fi
  } | fold -s -w 4000 >"$tmp"
  mv "$tmp" "$file"
}
fold_report "$report"

report_preview() {
  local file="$1" max=8192 size
  size="$(stat -c %s "$file" 2>/dev/null || printf 0)"
  printf 'Report: %s\n\n' "$file"
  head -c "$max" "$file"
  if [ "$size" -gt "$max" ]; then
    printf '\n--- preview truncated; use Copy report for the full log ---\n'
  fi
}

show_report() {
  local title="$1" preview choice copy_status
  shift
  preview="$(report_preview "$report")"
  while :; do
    timeout 300s yad --text="$preview" --no-markup --title="$title" --width=900 --height=600 --class=ojuny-raven-report --name=ojuny-raven-report --center --on-top \
      --button="Copy report:2" --button="Close:0" "$@"
    choice=$?
    if [ "$choice" -ne 2 ]; then
      return "$choice"
    fi
    wl-copy < "$report"
    copy_status=$?
    if [ "$copy_status" -eq 0 ]; then
      timeout 5s yad --text="Report copied to the clipboard." --no-markup --title="Raven report" --timeout=2 --no-buttons --class=ojuny-raven-report --name=ojuny-raven-report --center --on-top
    fi
  done
}

if [ -n "${OJUNY_RAVEN_SURVEY:-}" ]; then
  if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    set +e
    show_report "Raven failed: $app_name (survey mode)"
    set -e
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
show_report "Raven failed: $app_name (exit $status)" --button="Relaunch in survey mode:3"
choice=$?
set -e

if [ "$choice" -ne 3 ]; then
  exit 0
fi

set +e
timeout 300s yad --title="Raven survey mode" --class=ojuny-raven-report --name=ojuny-raven-report --center --on-top \
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
