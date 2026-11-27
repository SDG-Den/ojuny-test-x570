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

devices="$(lsblk --json -o NAME,PATH,TYPE,TRAN,RM,FSTYPE,MOUNTPOINTS,OPTIONS)" || exit 1

printf '%s' "$devices" |
  jq -r --arg uid "$(id -u)" '
    .blockdevices[]
    | recurse(.children[]?)
    | select(.type == "part" or .type == "disk")
    | select((.tran // "") == "usb" or .rm == true)
    | select((.fstype // "") != "")
    | select(
        ((.mountpoints // []) | map(select(. != null and . != "")) | length) == 0
        or (
          (.options // "") as $options
          | ($options | test("(^|,)uid=[0-9]+(,|$)"))
          and (($options | capture("(^|,)uid=(?<owner>[0-9]+)(,|$)").owner) != $uid)
        )
      )
    | "\(.path)\t\((.mountpoints // [])[0] // "")"
  ' |
  while IFS=$'\t' read -r device mountpoint; do
    [ -n "$device" ] || continue
    if [ -n "$mountpoint" ]; then
      udisksctl unmount -b "$device" --no-user-interaction >/dev/null 2>&1 || true
    fi
    if ! udisksctl mount -b "$device" --no-user-interaction; then
      printf 'ojuny-automount-present: failed to mount %s\n' "$device" >&2
    fi
  done
