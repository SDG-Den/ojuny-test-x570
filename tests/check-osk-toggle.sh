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
if [ "\$1" = "--user" ] && [ "\$2" = "start" ]; then
  printf '%s\n' "\$*" >>"\$SYSTEMCTL_LOG"
  : >"\$SYSTEMCTL_STARTED"
  exit 0
fi
if [ "\$1" = "--user" ] && [ "\$2" = "show" ]; then
  [ "\${SYSTEMCTL_SHOW_FAIL:-0}" = "0" ] || exit 1
  case "\$*" in
    *LoadState*) printf '%s\n' "\${SYSTEMCTL_LOAD_STATE:-loaded}" ;;
    *) if [ -f "\$SYSTEMCTL_STARTED" ]; then printf '%s\n' "\${SYSTEMCTL_START_PID:-0}"; else printf '%s\n' "\${SYSTEMCTL_PID:-0}"; fi ;;
  esac
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

cat >"$work/bin/notify-send" <<STUB
#!${BASH:-/usr/bin/env bash}
printf '%s\n' "\$*" >>"\$NOTIFY_LOG"
STUB
chmod +x "$work/bin/notify-send"

export SYSTEMCTL_LOG="$work/systemctl.log"
export SYSTEMCTL_STARTED="$work/started"
export KILL_LOG="$work/kill.log"
export NOTIFY_LOG="$work/notify.log"
: >"$SYSTEMCTL_LOG"
: >"$KILL_LOG"
: >"$NOTIFY_LOG"

SYSTEMCTL_PID=4242 bash "$toggle"
grep -qx -- '-s RTMIN 4242' "$KILL_LOG" || fail "a running keyboard was not toggled"
[ ! -s "$SYSTEMCTL_LOG" ] || fail "a running keyboard was started again"

: >"$SYSTEMCTL_LOG"
: >"$KILL_LOG"
rm -f "$SYSTEMCTL_STARTED"
SYSTEMCTL_PID=0 bash "$toggle"
grep -qx -- '--user start ojuny-osk.service' "$SYSTEMCTL_LOG" ||
  fail "an inactive keyboard service was not started"
[ ! -s "$KILL_LOG" ] || fail "an inactive keyboard service was signalled without a pid"

: >"$SYSTEMCTL_LOG"
: >"$KILL_LOG"
rm -f "$SYSTEMCTL_STARTED"
SYSTEMCTL_PID=0 SYSTEMCTL_START_PID=5555 bash "$toggle"
grep -qx -- '-s USR2 5555' "$KILL_LOG" ||
  fail "a started keyboard was not shown"

: >"$SYSTEMCTL_LOG"
: >"$KILL_LOG"
: >"$NOTIFY_LOG"
SYSTEMCTL_LOAD_STATE=not-found SYSTEMCTL_PID=0 bash "$toggle" 2>"$work/missing.err" ||
  fail "a disabled keyboard toggle exited non-zero"
[ ! -s "$SYSTEMCTL_LOG" ] || fail "a disabled keyboard was started"
[ ! -s "$KILL_LOG" ] || fail "a disabled keyboard was signalled"
grep -qF 'The on-screen keyboard is disabled. Enable it in Settings > Accessibility.' "$NOTIFY_LOG" ||
  fail "a disabled keyboard was not reported"
grep -qF 'The on-screen keyboard is disabled. Enable it in Settings > Accessibility.' "$work/missing.err" ||
  fail "a disabled keyboard was not printed to stderr"

: >"$SYSTEMCTL_LOG"
: >"$KILL_LOG"
: >"$NOTIFY_LOG"
if SYSTEMCTL_SHOW_FAIL=1 bash "$toggle" 2>"$work/failed.err"; then
  fail "a failed service query exited zero"
fi
[ ! -s "$SYSTEMCTL_LOG" ] || fail "a missing unit was started after a failed query"
[ ! -s "$KILL_LOG" ] || fail "a missing unit was signalled after a failed query"
grep -qF 'The on-screen keyboard service could not be queried.' "$NOTIFY_LOG" ||
  fail "a failed service query was not reported"

printf 'ok: the on-screen keyboard toggle starts, signals and reports a disabled keyboard\n'
