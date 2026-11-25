#!/usr/bin/env bash
set -euo pipefail

notify() {
  if command -v notify-send; then
    notify-send "Disk image" "$1"
  else
    printf '%s\n' "$1" >&2
  fi
}

fail() {
  notify "$1"
  exit 1
}

[ "$#" -eq 1 ] || fail "Usage: ojuny-mount-image <image>"

image="$1"
[ -f "$image" ] || fail "Not a file: $image"

if ! command -v udisksctl; then
  fail "udisksctl is not installed"
fi

loop_device=""
mount_point=""

cleanup() {
  if [ -n "$loop_device" ] && [ -z "$mount_point" ]; then
    udisksctl loop-delete --block-device "$loop_device" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

loop_output="$(udisksctl loop-setup --file "$image")" || fail "Could not attach $image"
loop_device="$(printf '%s\n' "$loop_output" | sed -n 's/.* as \(\/dev\/loop[0-9]*\).*/\1/p' | sed -n '1p')"
[ -n "$loop_device" ] || fail "Could not find the loop device for $image"

for ((attempt = 0; attempt < 50; attempt++)); do
  if [ -b "$loop_device" ]; then
    break
  fi
  sleep 0.1
done
[ -b "$loop_device" ] || fail "Loop device $loop_device did not appear"

if command -v udevadm >/dev/null 2>&1; then
  udevadm settle --timeout=5 >/dev/null 2>&1 || true
fi

mount_device() {
  local device="$1" attempt output
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if output="$(udisksctl mount --block-device "$device" --options ro 2>&1)"; then
      printf '%s\n' "$output"
      return 0
    fi
    sleep 0.2
  done
  return 1
}

candidates=("$loop_device")
while IFS= read -r child; do
  if [ -n "$child" ]; then
    candidates+=("/dev/$child")
  fi
done < <(lsblk -ln -o NAME "$loop_device" 2>/dev/null | sed -n '2,$p')

for device in "${candidates[@]}"; do
  if [ ! -b "$device" ]; then
    continue
  fi
  fstype="$(lsblk -ln -o FSTYPE "$device" 2>/dev/null | sed -n '1p')"
  if [ -z "$fstype" ]; then
    continue
  fi
  if mount_device "$device"; then
    mount_point="$(findmnt -n -o TARGET --source "$device" | sed -n '1p' || true)"
    if [ -n "$mount_point" ]; then
      break
    fi
  fi
done

# Hybrid images whose partition nodes never appear need the GNOME mounter.
if [ -z "$mount_point" ] && command -v gnome-disk-image-mounter >/dev/null 2>&1; then
  udisksctl loop-delete --block-device "$loop_device" >/dev/null 2>&1 || true
  loop_device=""
  if gnome-disk-image-mounter --read-only "$image" >/dev/null 2>&1; then
    notify "Opened $image with the disk image mounter"
    exit 0
  fi
fi

[ -n "$mount_point" ] || fail "Attached $image but could not mount it"

if ! xdg-open "$mount_point"; then
  notify "Mounted at $mount_point"
fi
