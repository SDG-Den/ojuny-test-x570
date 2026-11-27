#!/usr/bin/env bash
set -euo pipefail

attempt=1
while [ "$attempt" -le 5 ]; do
  if udisksctl status >/dev/null 2>&1; then
    break
  fi
  sleep 1
  attempt=$((attempt + 1))
done

devices="$(lsblk --json -o NAME,PATH,TYPE,TRAN,RM,FSTYPE,MOUNTPOINTS)" || exit 1

printf '%s' "$devices" |
  jq -r '
    .blockdevices[]
    | select(.type == "part" or .type == "disk")
    | select((.tran // "") == "usb" or .rm == true)
    | select((.fstype // "") != "")
    | select(((.mountpoints // []) | map(select(. != null and . != "")) | length) == 0)
    | .path
  ' |
  while IFS= read -r device; do
    [ -n "$device" ] || continue
    udisksctl mount -b "$device" --no-user-interaction || true
  done
