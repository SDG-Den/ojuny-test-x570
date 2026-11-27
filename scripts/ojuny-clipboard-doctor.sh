#!/usr/bin/env bash
set -euo pipefail

section() {
  printf '\n== %s ==\n' "$*"
}

section "session"
printf 'XDG_SESSION_TYPE=%s\nWAYLAND_DISPLAY=%s\nDISPLAY=%s\n' \
  "${XDG_SESSION_TYPE:-}" "${WAYLAND_DISPLAY:-}" "${DISPLAY:-}"

section "clipboard processes"
pgrep -a -f 'wl-clip-persist|cliphist|wl-paste' || true

section "wayland clipboard types"
if command -v wl-paste >/dev/null 2>&1; then
  wl-paste --list-types 2>&1 || true
else
  printf 'wl-paste not found\n'
fi

section "wayland clipboard preview"
if command -v wl-paste >/dev/null 2>&1; then
  timeout 2 wl-paste --no-newline 2>/dev/null | head -c 200 || true
  printf '\n'
fi

section "x11 clipboard preview"
if command -v xclip >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
  timeout 2 xclip -selection clipboard -o 2>/dev/null | head -c 200 || true
  printf '\n'
else
  printf 'xclip or DISPLAY unavailable\n'
fi

section "cliphist"
if command -v cliphist >/dev/null 2>&1; then
  cliphist list 2>/dev/null | head -n 10 || true
else
  printf 'cliphist not found\n'
fi

section "clients"
for name in codium vscodium ghostty; do
  pgrep -a -x "$name" || true
done

section "client protocols"
for pid in $(pgrep -f 'codium|vscodium|ghostty' || true); do
  if [ -r "/proc/$pid/environ" ] &&
    tr '\0' '\n' <"/proc/$pid/environ" | grep -q '^WAYLAND_DISPLAY='; then
    printf '%s wayland\n' "$pid"
  else
    printf '%s x11\n' "$pid"
  fi
done

section "capture order"
printf 'Run this twice: once with VSCodium open first, once with the terminal open first.\n'
printf 'After each copy, record this output and the direction that failed.\n'
printf 'Also run: WAYLAND_DEBUG=1 codium >/tmp/codium-wayland.log 2>&1\n'
printf 'And: WAYLAND_DEBUG=1 ghostty >/tmp/ghostty-wayland.log 2>&1\n'
