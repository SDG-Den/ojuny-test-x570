#!/usr/bin/env bash
set -euo pipefail

rotate="$1"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
bash_path="$(command -v bash)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$work/bin/monitor-sensor" <<STUB
#!$bash_path
printf '=== Has accelerometer (orientation: normal)\n'
printf '    Accelerometer orientation changed: left-up\n'
printf '    Accelerometer orientation changed: bottom-up\n'
printf '    Accelerometer orientation changed: right-up\n'
printf '    Accelerometer orientation changed: normal\n'
STUB

cat >"$work/bin/wlr-randr" <<STUB
#!$bash_path
printf '%s\n' "\$*" >>"\$WLR_LOG"
STUB

chmod +x "$work/bin/monitor-sensor" "$work/bin/wlr-randr"

export WLR_LOG="$work/wlr.log"
: >"$WLR_LOG"

PATH="$work/bin:$PATH" bash "$rotate" eDP-1 >/dev/null

grep -qx -- '--output eDP-1 --transform normal' "$WLR_LOG" || fail "the initial orientation was not applied"
grep -qx -- '--output eDP-1 --transform 90' "$WLR_LOG" || fail "left-up was not 90"
grep -qx -- '--output eDP-1 --transform 180' "$WLR_LOG" || fail "bottom-up was not 180"
grep -qx -- '--output eDP-1 --transform 270' "$WLR_LOG" || fail "right-up was not 270"

printf 'ok: the auto-rotate daemon maps every accelerometer orientation\n'
