#!/usr/bin/env bash
set -euo pipefail

toggle="$1"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
export PATH="$work/bin:$PATH"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$work/bin/systemctl" <<STUB
#!${BASH:-/usr/bin/env bash}
if [ "\$1" = "--user" ] && [ "\$2" = "show" ]; then
  printf '%s\n' "\${SYSTEMCTL_PID:-0}"
  exit 0
fi
printf '%s\n' "\$*" >>"\$SYSTEMCTL_LOG"
STUB
chmod +x "$work/bin/systemctl"

cat >"$work/bin/kill" <<STUB
#!${BASH:-/usr/bin/env bash}
printf '%s\n' "\$*" >>"\$KILL_LOG"
STUB
chmod +x "$work/bin/kill"

export SYSTEMCTL_LOG="$work/systemctl.log"
export KILL_LOG="$work/kill.log"
: >"$SYSTEMCTL_LOG"
: >"$KILL_LOG"

SYSTEMCTL_PID=4242 "$toggle"
grep -qx -- '-s RTMIN 4242' "$KILL_LOG" || fail "a running keyboard was not toggled"
[ ! -s "$SYSTEMCTL_LOG" ] || fail "a running keyboard was started again"

: >"$SYSTEMCTL_LOG"
: >"$KILL_LOG"
SYSTEMCTL_PID=0 "$toggle"
grep -qx -- '--user start ojuny-osk.service' "$SYSTEMCTL_LOG" ||
  fail "an inactive keyboard service was not started"
[ ! -s "$KILL_LOG" ] || fail "an inactive keyboard service was signalled"

printf 'ok: the on-screen keyboard toggle starts and signals the service\n'
