#!/usr/bin/env bash
set -euo pipefail

profile="${1:?usage: seed-firefox-extension-storage <profile-dir> [user-id]}"
user_id="${2:-$(cat /proc/sys/kernel/random/uuid)}"
storage="$profile/browser-extension-data/sponsorBlocker@ajay.app/storage.js"

if [ -e "$storage" ]; then
  exit 0
fi

mkdir -p "$(dirname "$storage")"
printf '{"alreadyInstalled":true,"userID":"%s"}\n' "$user_id" >"$storage"
