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
    def walk($tran; $rm):
      . as $dev
      | (if (($dev.tran // "") | tostring) == "" then $tran else $dev.tran end) as $t
      | (if $dev.rm == true then true else $rm end) as $r
      | { dev: $dev, tran: $t, rm: $r },
        (($dev.children // [])[] | walk($t; $r));
    .blockdevices[]
    | walk(""; false)
    | select(.dev.type == "part" or .dev.type == "disk")
    | select((.tran // "") == "usb" or .rm == true)
    | select((.dev.fstype // "") != "")
    | "\(.dev.path)\t\(.tran)\t\(.rm)\t\((.dev.mountpoints // [])[0] // "")"
  ' |
  while IFS=$'\t' read -r device tran rm mountpoint; do
    [ -n "$device" ] || continue
    printf 'ojuny-automount-present: %s tran=%s rm=%s mount=%s\n' "$device" "$tran" "$rm" "${mountpoint:-none}" >&2
    if [ -n "$mountpoint" ]; then
      options="$(findmnt -n -o OPTIONS -S "$device" 2>/dev/null || true)"
      case "$options" in
      *uid=*)
        owner="${options##*uid=}"
        owner="${owner%%,*}"
        if [ "$owner" = "$(id -u)" ]; then
          continue
        fi
        udisksctl unmount -b "$device" --no-user-interaction >/dev/null 2>&1 || true
        ;;
      *) continue ;;
      esac
    fi
    if ! udisksctl mount -b "$device" --no-user-interaction; then
      printf 'ojuny-automount-present: failed to mount %s\n' "$device" >&2
    fi
  done
