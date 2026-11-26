#!/usr/bin/env bash
set -euo pipefail

flake="$1"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[ -f "$flake" ] || fail "flake.nix is missing"
grep -q 'mkFlake' "$flake" || fail "flake.nix does not call mkFlake"
grep -q 'import-tree ./modules' "$flake" || fail "flake.nix does not import the module tree"

if grep -nE 'perSystem|checks\.|apps\.|packages\.' "$flake"; then
  fail "flake.nix must only declare inputs and the mkFlake call"
fi

printf 'ok: flake.nix only declares inputs and mkFlake\n'
