#!/usr/bin/env bash
set -euo pipefail

seeder="$1"
firefox_seed="$2"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

profile="$work/firefox"
"$firefox_seed" "$profile" 11111111-1111-1111-1111-111111111111
storage="$profile/browser-extension-data/sponsorBlocker@ajay.app/storage.js"
[ -f "$storage" ] || fail "the Firefox storage file was not created"
grep -qF '"alreadyInstalled":true' "$storage" || fail "the Firefox storage lacks alreadyInstalled"
grep -qF '"userID":"11111111-1111-1111-1111-111111111111"' "$storage" ||
  fail "the Firefox storage lacks the generated userID"

cp "$storage" "$work/firefox-before"
"$firefox_seed" "$profile" 22222222-2222-2222-2222-222222222222
cmp -s "$work/firefox-before" "$storage" || fail "the Firefox seed overwrote existing storage"

database="$work/chromium/Local Extension Settings/mnjggcdmjocbbbhaepdhchncahnbgone"
mkdir -p "$(dirname "$database")"
"$seeder" "$database" 11111111-1111-1111-1111-111111111111
"$seeder" --check "$database" 11111111-1111-1111-1111-111111111111 ||
  fail "the Chromium storage does not contain the seeded keys"
if "$seeder" --check "$database" 22222222-2222-2222-2222-222222222222 2>/dev/null; then
  fail "the Chromium check accepted a different userID"
fi

printf 'ok: Firefox and Chromium SponsorBlock storage is seeded and preserved\n'
