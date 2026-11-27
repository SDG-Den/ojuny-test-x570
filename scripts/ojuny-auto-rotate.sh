#!/usr/bin/env bash
set -euo pipefail

[ "$#" -gt 0 ] || exit 0

transform_for() {
  case "$1" in
    normal) printf 'normal' ;;
    left-up) printf '90' ;;
    bottom-up) printf '180' ;;
    right-up) printf '270' ;;
    *) return 1 ;;
  esac
}

apply_orientation() {
  local orientation="$1" transform output
  shift

  transform="$(transform_for "$orientation")" || return 0
  for output in "$@"; do
    wlr-randr --output "$output" --transform "$transform" >/dev/null 2>&1 || true
  done
}

monitor-sensor --accel 2>/dev/null | while IFS= read -r line; do
  case "$line" in
    *"Has accelerometer (orientation: "*)
      orientation="${line##*Has accelerometer (orientation: }"
      orientation="${orientation%%,*}"
      orientation="${orientation%%)*}"
      apply_orientation "$orientation" "$@"
      ;;
    *"orientation changed: "*)
      orientation="${line##*orientation changed: }"
      orientation="${orientation%% *}"
      apply_orientation "$orientation" "$@"
      ;;
  esac
done
