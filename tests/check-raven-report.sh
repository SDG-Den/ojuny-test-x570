#!/usr/bin/env bash
set -euo pipefail

wrapper="$1"
source_script="$2"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
export PATH="$work/bin:$PATH"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$work/bin/yad" <<STUB
#!${BASH:-/usr/bin/env bash}
printf '%s\n' "\$*" >>"\$YAD_LOG"
case "\${YAD_MODE:-close}" in
  close) exit 1 ;;
  relaunch)
    if [[ "\$*" == *--text-info* ]]; then exit 3; else exit 0; fi
    ;;
  cancel)
    if [[ "\$*" == *--text-info* ]]; then exit 3; else exit 1; fi
    ;;
esac
STUB
chmod +x "$work/bin/yad"

cat >"$work/bin/relaunch-wrapper" <<STUB
#!${BASH:-/usr/bin/env bash}
printf '%s\n' "\$*" >>"\$WRAPPER_LOG"
exit 0
STUB
chmod +x "$work/bin/relaunch-wrapper"

export YAD_LOG="$work/yad.log"
export WRAPPER_LOG="$work/wrapper.log"
export DISPLAY=:0
unset WAYLAND_DISPLAY
[ -n "${DISPLAY:-}" ] || fail "DISPLAY was not exported"
: >"$YAD_LOG"
: >"$WRAPPER_LOG"

report="$work/report.log"
head -c 300000 /dev/zero | tr '\0' 'a' >"$report"
printf 'second line\n' >>"$report"
[ "$(stat -c %s "$report")" -eq 300012 ] || fail "the fixture is not 300012 bytes"

grep -qF 'timeout 300s yad' "$source_script" || fail "the dialog is not bounded by a timeout"
grep -qF 'max=262144' "$source_script" || fail "the report cap is not declared"

YAD_MODE=close "$wrapper" "$report" "fake-app" "$work/bin/relaunch-wrapper" 7 --flag value 2>"$work/close.err"

size="$(stat -c %s "$report")"
[ "$size" -lt 262400 ] || fail "the report was not capped: $size bytes"
grep -qF -- '--- report truncated at 262144 bytes ---' "$report" ||
  fail "the truncation marker is missing"
if grep -qE '^.{4001}' "$report"; then
  fail "the report still contains a line longer than 4000 characters"
fi

if ! grep -qF -- '--text-info' "$YAD_LOG"; then
  printf 'yad log:\n' >&2
  cat "$YAD_LOG" >&2
  printf 'wrapper stderr:\n' >&2
  cat "$work/close.err" >&2
  fail "the failure dialog was not opened"
fi
for argument in \
  '--text-info' \
  "--filename=$report" \
  '--title=Raven failed: fake-app (exit 7)' \
  '--button=Close:0' \
  '--button=Relaunch in survey mode:3'; do
  grep -qF -- "$argument" "$YAD_LOG" || fail "the failure dialog lacks: $argument"
done
[ ! -s "$WRAPPER_LOG" ] || fail "the close button relaunched the app"

: >"$YAD_LOG"
: >"$WRAPPER_LOG"
YAD_MODE=cancel "$wrapper" "$report" "fake-app" "$work/bin/relaunch-wrapper" 7 --flag value 2>"$work/cancel.err"
[ ! -s "$WRAPPER_LOG" ] || fail "the cancel button relaunched the app"

: >"$YAD_LOG"
: >"$WRAPPER_LOG"
YAD_MODE=relaunch "$wrapper" "$report" "fake-app" "$work/bin/relaunch-wrapper" 7 --flag value 2>"$work/relaunch.err"
grep -qF -- '--flag value' "$WRAPPER_LOG" || fail "the relaunch button did not pass the arguments"
grep -qF -- '--title=Raven survey mode' "$YAD_LOG" || fail "the survey confirmation was not shown"

: >"$YAD_LOG"
: >"$WRAPPER_LOG"
DISPLAY= "$wrapper" "$report" "fake-app" "$work/bin/relaunch-wrapper" 7 >"$work/out" 2>"$work/err"
[ ! -s "$YAD_LOG" ] || fail "the wrapper opened a dialog without a display"
head -c 64 "$work/err" | grep -q 'aaaa' || fail "the wrapper did not print the report without a display"

printf 'ok: Raven report is capped and the failure dialog is bounded\n'
