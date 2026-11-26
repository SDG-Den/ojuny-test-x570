#!/usr/bin/env bash
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

write_stub() {
  local name="$1" body="$2"
  {
    printf '#!%s\n' "$BASH"
    printf '%s\n' "$body"
  } >"$tmp/bin/$name"
  chmod +x "$tmp/bin/$name"
}

write_stub slurp 'printf "1,1 10x10\n"'
write_stub grim 'cat >/dev/null'
write_stub zbarimg 'printf "https://example.com/payload\n"'
write_stub wl-copy 'printf "%s\n" "$*" >"$WL_LOG"; cat >>"$WL_LOG"'
write_stub notify-send 'printf "%s\n" "$*" >>"$NOTIFY_LOG"'

export WL_LOG="$tmp/wl.log"
export NOTIFY_LOG="$tmp/notify.log"
: >"$WL_LOG"
: >"$NOTIFY_LOG"

PATH="$tmp/bin:$PATH" bash "$root/scripts/ojuny-capture-qr"

grep -qF 'https://example.com/payload' "$WL_LOG" || {
  echo "FAIL: QR payload was not copied" >&2
  exit 1
}
if grep -qF -- '--sensitive' "$WL_LOG"; then
  echo "FAIL: QR payload used --sensitive and is skipped by history" >&2
  exit 1
fi
grep -qF 'https://example.com/payload' "$NOTIFY_LOG" || {
  echo "FAIL: QR payload was not reported" >&2
  exit 1
}

echo "ok: QR capture copies and reports the payload"
