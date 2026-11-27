#!/usr/bin/env bash
set -euo pipefail

status="$1"
toggle="$2"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
bash_path="$(command -v bash)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$work/bin/systemctl" <<STUB
#!$bash_path
set -euo pipefail
case "\$*" in
  "--user show-environment")
    [ -f "\$OSK_ENV" ] && cat "\$OSK_ENV"
    ;;
  "--user set-environment OJUNY_OSK_AUTO="*)
    printf 'OJUNY_OSK_AUTO=%s\n' "\${3#*=}" >"\$OSK_ENV"
    printf '%s\n' "\$*" >>"\$OSK_LOG"
    ;;
  "--user restart ojuny-osk.service")
    printf '%s\n' "\$*" >>"\$OSK_LOG"
    ;;
  *)
    printf 'unexpected systemctl call: %s\n' "\$*" >&2
    exit 1
    ;;
esac
STUB
chmod +x "$work/bin/systemctl"

export PATH="$work/bin:$PATH"
export OSK_ENV="$work/env"
export OSK_LOG="$work/log"

"$status" || fail "the default auto state should be on"

"$toggle"
grep -qx 'OJUNY_OSK_AUTO=0' "$OSK_ENV" || fail "the toggle did not set auto off"
grep -qx -- '--user restart ojuny-osk.service' "$OSK_LOG" || fail "the toggle did not restart the unit"
if "$status"; then
  fail "the status still reports auto on"
fi

: >"$OSK_LOG"
"$toggle"
grep -qx 'OJUNY_OSK_AUTO=1' "$OSK_ENV" || fail "the toggle did not set auto on"
grep -qx -- '--user restart ojuny-osk.service' "$OSK_LOG" || fail "the toggle did not restart the unit"
"$status" || fail "the status does not report auto on"

printf 'ok: the OSK auto-popup toggle reads and writes the session state\n'
