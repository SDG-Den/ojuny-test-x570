#!/usr/bin/env bash
set -euo pipefail

doctor="$1"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
bash_path="$(command -v bash)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$work/bin/wl-paste" <<STUB
#!$bash_path
if [ "\${1:-}" = "--list-types" ]; then
  printf 'text/plain\n'
else
  printf 'wayland copied text\n'
fi
STUB

cat >"$work/bin/xclip" <<STUB
#!$bash_path
printf 'x11 copied text\n'
STUB

cat >"$work/bin/cliphist" <<STUB
#!$bash_path
printf '1\twayland copied text\n'
STUB

cat >"$work/bin/pgrep" <<STUB
#!$bash_path
case "\$*" in
  *" -x "*) printf '789 codium\n' ;;
  "-a -f"*) printf '123 wl-clip-persist --clipboard regular\n' ;;
  "-f"*) printf '456\n' ;;
esac
STUB

chmod +x "$work/bin/wl-paste" "$work/bin/xclip" "$work/bin/cliphist" "$work/bin/pgrep"

output="$(PATH="$work/bin:$PATH" DISPLAY=:0 XDG_SESSION_TYPE=wayland bash "$doctor")"

assert() {
  printf '%s' "$output" | grep -Fq -- "$1" || fail "missing '$1'"
}

assert "== session =="
assert "== clipboard processes =="
assert "wl-clip-persist"
assert "== wayland clipboard types =="
assert "text/plain"
assert "== wayland clipboard preview =="
assert "wayland copied text"
assert "== x11 clipboard preview =="
assert "x11 copied text"
assert "== cliphist =="
assert "== clients =="
assert "codium"
assert "== client protocols =="
assert "== capture order =="

printf 'ok: the clipboard doctor reports both protocols, owners and clients\n'
