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
if [[ "\$*" == *"Report copied to the clipboard."* ]]; then
  exit 0
fi
case "\${YAD_MODE:-close}" in
  close) exit 1 ;;
  relaunch)
    if [[ "\$*" == *"Raven failed:"* ]]; then exit 3; else exit 0; fi
    ;;
  cancel)
    if [[ "\$*" == *"Raven failed:"* ]]; then exit 3; else exit 1; fi
    ;;
  copy)
    if [[ "\$*" == *"Raven failed:"* ]]; then
      if [[ ! -f "\$YAD_COPY_ONCE" ]]; then
        : >"\$YAD_COPY_ONCE"
        exit 2
      fi
      exit 1
    fi
    exit 0
    ;;
esac
STUB
chmod +x "$work/bin/yad"

cat >"$work/bin/wl-copy" <<STUB
#!${BASH:-/usr/bin/env bash}
cat >"\$WL_COPY_LOG"
STUB
chmod +x "$work/bin/wl-copy"

cat >"$work/bin/relaunch-wrapper" <<STUB
#!${BASH:-/usr/bin/env bash}
printf '%s\n' "\$*" >>"\$WRAPPER_LOG"
exit 0
STUB
chmod +x "$work/bin/relaunch-wrapper"

export YAD_LOG="$work/yad.log"
export WRAPPER_LOG="$work/wrapper.log"
export WL_COPY_LOG="$work/wl-copy.log"
export YAD_COPY_ONCE="$work/copy-once"
export DISPLAY=:0
unset WAYLAND_DISPLAY
[ -n "${DISPLAY:-}" ] || fail "DISPLAY was not exported"
: >"$YAD_LOG"
: >"$WRAPPER_LOG"
: >"$WL_COPY_LOG"

report="$work/report.log"
head -c 300000 /dev/zero | tr '\0' 'a' >"$report"
printf 'second line\n' >>"$report"
[ "$(stat -c %s "$report")" -eq 300012 ] || fail "the fixture is not 300012 bytes"

grep -qF 'timeout 300s yad' "$source_script" || fail "the dialog is not bounded by a timeout"
grep -qF 'timeout 300s yad --title="Raven survey mode"' "$source_script" ||
  fail "the survey confirmation is not bounded by a timeout"
grep -qF 'max=262144' "$source_script" || fail "the report cap is not declared"
grep -qF 'fold -s -w 4000' "$source_script" || fail "the report is not folded"
grep -qF 'wl-copy < "$report"' "$source_script" || fail "the copy action does not use wl-copy"
if grep -qF -- '--text-info' "$source_script"; then
  fail "the report still uses the selectable text-info widget"
fi

YAD_MODE=close "$wrapper" "$report" "fake-app" "$work/bin/relaunch-wrapper" 7 --flag value 2>"$work/close.err"

size="$(stat -c %s "$report")"
[ "$size" -lt 262400 ] || fail "the report was not capped: $size bytes"
grep -qF -- '--- report truncated at 262144 bytes ---' "$report" ||
  fail "the truncation marker is missing"
if grep -qE '^.{4001}' "$report"; then
  fail "the report still contains a line longer than 4000 characters"
fi

for argument in \
  '--text=Report: ' \
  '--no-markup' \
  '--title=Raven failed: fake-app (exit 7)' \
  '--button=Copy report:2' \
  '--button=Close:0' \
  '--button=Relaunch in survey mode:3'; do
  grep -qF -- "$argument" "$YAD_LOG" || fail "the failure dialog lacks: $argument"
done
if grep -qF -- '--text-info' "$YAD_LOG"; then
  fail "the failure dialog opened a selectable text view"
fi
[ ! -s "$WRAPPER_LOG" ] || fail "the close button relaunched the app"

small="$work/small.log"
head -c 12000 /dev/zero | tr '\0' 'b' >"$small"
printf '\n' >>"$small"
YAD_MODE=close "$wrapper" "$small" "fake-app" "$work/bin/relaunch-wrapper" 7 2>"$work/small.err"
if grep -qE '^.{4001}' "$small"; then
  fail "a report under the cap was not folded"
fi
if grep -qF -- '--- report truncated at' "$small"; then
  fail "a report under the cap was truncated"
fi

: >"$WL_COPY_LOG"
YAD_MODE=copy "$wrapper" "$report" "fake-app" "$work/bin/relaunch-wrapper" 7 2>"$work/copy.err"
cmp -s "$WL_COPY_LOG" "$report" || fail "the Copy report action did not copy the full report"
grep -qF 'Report copied to the clipboard.' "$YAD_LOG" || fail "the copy action showed no confirmation"

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
OJUNY_RAVEN_SURVEY=1 YAD_MODE=close "$wrapper" "$report" "fake-app" "$work/bin/relaunch-wrapper" 7 2>"$work/survey.err"
grep -qF -- '--title=Raven failed: fake-app (survey mode)' "$YAD_LOG" ||
  fail "the survey-mode report dialog was not shown"
[ ! -s "$WRAPPER_LOG" ] || fail "the survey-mode report dialog relaunched the app"

: >"$YAD_LOG"
: >"$WRAPPER_LOG"
DISPLAY= "$wrapper" "$report" "fake-app" "$work/bin/relaunch-wrapper" 7 >"$work/out" 2>"$work/err"
[ ! -s "$YAD_LOG" ] || fail "the wrapper opened a dialog without a display"
head -c 64 "$work/err" | grep -q 'aaaa' || fail "the wrapper did not print the report without a display"

printf 'ok: Raven report is capped, folded, non-selectable and has a copy action\n'
