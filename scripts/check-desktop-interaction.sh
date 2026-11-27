#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/run"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$work/bin/mmsg" <<STUB
#!${BASH:-/usr/bin/env bash}
set -euo pipefail
printf '%s\n' "\$*" >>"\$MMSG_LOG"
case "\$1 \$2" in
  "get keymode")
    printf '{"keymode":"%s"}\n' "\${MMSG_KEYMODE:-default}"
    ;;
  "get focusing-client")
    if [ "\${MMSG_NO_CLIENT:-0}" = "1" ]; then
      printf '{"error":"no focused client"}\n'
      exit 1
    fi
    printf '%s\n' "\${MMSG_FOCUS:-}"
    ;;
  "get all-monitors")
    printf '%s\n' "\$MMSG_MONITORS"
    ;;
  "dispatch "*) ;;
  *)
    printf 'unexpected mmsg call: %s\n' "\$*" >&2
    exit 1
    ;;
esac
STUB

cat >"$work/bin/ydotool" <<STUB
#!${BASH:-/usr/bin/env bash}
set -euo pipefail
printf '%s\n' "\$*" >>"\$YDOTOOL_LOG"
STUB

cat >"$work/bin/udisksctl" <<STUB
#!${BASH:-/usr/bin/env bash}
set -euo pipefail
if [ "\$1" = "status" ]; then
  exit 0
fi
printf '%s\n' "\$*" >>"\$UDISKS_LOG"
STUB

cat >"$work/bin/lsblk" <<STUB
#!${BASH:-/usr/bin/env bash}
set -euo pipefail
printf '%s\n' "\$LSBLK_JSON"
STUB

chmod +x "$work/bin/mmsg" "$work/bin/ydotool" "$work/bin/udisksctl" "$work/bin/lsblk"
export PATH="$work/bin:$PATH"
export XDG_RUNTIME_DIR="$work/run"
export MMSG_LOG="$work/mmsg.log"
export YDOTOOL_LOG="$work/ydotool.log"
export UDISKS_LOG="$work/udisks.log"

focus_tiling='{"is_fullscreen":false,"is_floating":false}'
focus_floating='{"is_fullscreen":false,"is_floating":true}'
focus_fullscreen='{"is_fullscreen":true,"is_floating":false}'

run_middle() {
  local focus="$1"
  local floating="$2"
  local tiling="$3"
  : >"$MMSG_LOG"
  : >"$YDOTOOL_LOG"
  MMSG_FOCUS="$focus" bash "$here"/ojuny-middle-click.sh "$floating" "$tiling"
}

run_middle "$focus_tiling" maximize zoom || fail "the tiling middle click failed"
grep -qx 'dispatch zoom' "$MMSG_LOG" || fail "a tiled window was not zoomed"
grep -qx 'dispatch setkeymode,middle-click-passthrough' "$MMSG_LOG" ||
  fail "the middle click did not enter the pass-through mode"
grep -qx 'dispatch setkeymode,default' "$MMSG_LOG" ||
  fail "the middle click did not restore the previous key mode"
grep -qx 'click 0xC2' "$YDOTOOL_LOG" || fail "the middle click was not re-emitted"

run_middle "$focus_floating" maximize zoom || fail "the floating middle click failed"
grep -qx 'dispatch togglemaximizescreen,0' "$MMSG_LOG" ||
  fail "a floating window was not maximized"
grep -qx 'click 0xC2' "$YDOTOOL_LOG" || fail "the floating middle click was not re-emitted"

run_middle "$focus_fullscreen" maximize zoom || fail "the fullscreen middle click failed"
if grep -qx 'dispatch zoom' "$MMSG_LOG" || grep -qx 'dispatch togglemaximizescreen,0' "$MMSG_LOG"; then
  fail "a fullscreen window received a layout action"
fi
grep -qx 'click 0xC2' "$YDOTOOL_LOG" || fail "a fullscreen window did not receive the middle click"

run_middle "$focus_tiling" none none || fail "the disabled policy middle click failed"
if grep -qx 'dispatch zoom' "$MMSG_LOG" || grep -qx 'dispatch togglemaximizescreen,0' "$MMSG_LOG"; then
  fail "a disabled policy still applied a layout action"
fi
grep -qx 'click 0xC2' "$YDOTOOL_LOG" || fail "a disabled policy did not re-emit the click"

: >"$MMSG_LOG"
: >"$YDOTOOL_LOG"
MMSG_NO_CLIENT=1 MMSG_FOCUS='' bash "$here"/ojuny-middle-click.sh maximize zoom ||
  fail "the no-client middle click failed"
if [ -s "$YDOTOOL_LOG" ]; then
  fail "a middle click with no focused window was re-emitted"
fi

export MMSG_MONITORS='{"monitors":[{"name":"eDP-1","active":true},{"name":"HDMI-A-1","active":false}]}'
: >"$MMSG_LOG"
bash "$here"/ojuny-display-toggle.sh focused || fail "the focused display toggle failed"
grep -qx 'dispatch toggle_monitor,eDP-1' "$MMSG_LOG" || fail "the active monitor was not toggled"
if grep -qx 'dispatch toggle_monitor,HDMI-A-1' "$MMSG_LOG"; then
  fail "the focused toggle also changed another monitor"
fi
if grep -q 'sleep_toggle_monitor' "$MMSG_LOG"; then
  fail "the display toggle used sleep_toggle_monitor"
fi

: >"$MMSG_LOG"
bash "$here"/ojuny-display-toggle.sh focused || fail "the second focused display toggle failed"
grep -qx 'dispatch toggle_monitor,eDP-1' "$MMSG_LOG" ||
  fail "the second focused press did not re-enable the same display"

: >"$MMSG_LOG"
bash "$here"/ojuny-display-toggle.sh all || fail "the all-displays toggle failed"
grep -qx 'dispatch toggle_monitor,eDP-1' "$MMSG_LOG" || fail "all-displays skipped eDP-1"
grep -qx 'dispatch toggle_monitor,HDMI-A-1' "$MMSG_LOG" || fail "all-displays skipped HDMI-A-1"

uid="$(id -u)"
export LSBLK_JSON="{\"blockdevices\":[
  {\"name\":\"sda\",\"path\":\"/dev/sda\",\"type\":\"disk\",\"tran\":\"sata\",\"rm\":false,\"fstype\":null,\"mountpoints\":[null],\"options\":null},
  {\"name\":\"sdb1\",\"path\":\"/dev/sdb1\",\"type\":\"part\",\"tran\":\"usb\",\"rm\":true,\"fstype\":\"exfat\",\"mountpoints\":[null],\"options\":null},
  {\"name\":\"sdc1\",\"path\":\"/dev/sdc1\",\"type\":\"part\",\"tran\":null,\"rm\":true,\"fstype\":\"vfat\",\"mountpoints\":[null],\"options\":null},
  {\"name\":\"sdd1\",\"path\":\"/dev/sdd1\",\"type\":\"part\",\"tran\":\"usb\",\"rm\":true,\"fstype\":\"ext4\",\"mountpoints\":[\"/run/media/user/sdd1\"],\"options\":\"rw,uid=${uid}\"},
  {\"name\":\"sdf1\",\"path\":\"/dev/sdf1\",\"type\":\"part\",\"tran\":\"usb\",\"rm\":true,\"fstype\":\"exfat\",\"mountpoints\":[\"/run/media/greeter/sdf1\"],\"options\":\"rw,uid=9999\"},
  {\"name\":\"sdg\",\"path\":\"/dev/sdg\",\"type\":\"disk\",\"tran\":\"usb\",\"rm\":true,\"fstype\":null,\"mountpoints\":[null],\"options\":null,\"children\":[
    {\"name\":\"sdg1\",\"path\":\"/dev/sdg1\",\"type\":\"part\",\"tran\":\"usb\",\"rm\":true,\"fstype\":\"exfat\",\"mountpoints\":[null],\"options\":null}
  ]},
  {\"name\":\"sde1\",\"path\":\"/dev/sde1\",\"type\":\"part\",\"tran\":\"usb\",\"rm\":true,\"fstype\":null,\"mountpoints\":[null],\"options\":null}
]}"
: >"$UDISKS_LOG"
bash "$here"/ojuny-automount-present.sh || fail "the present-device automount failed"
grep -qx 'mount -b /dev/sdb1 --no-user-interaction' "$UDISKS_LOG" ||
  fail "the USB partition was not mounted"
grep -qx 'mount -b /dev/sdc1 --no-user-interaction' "$UDISKS_LOG" ||
  fail "the removable partition was not mounted"
if grep -qx 'mount -b /dev/sda --no-user-interaction' "$UDISKS_LOG"; then
  fail "an internal disk was mounted"
fi
if grep -qx 'mount -b /dev/sdd1 --no-user-interaction' "$UDISKS_LOG"; then
  fail "an already mounted partition was mounted again"
fi
if grep -qx 'mount -b /dev/sde1 --no-user-interaction' "$UDISKS_LOG"; then
  fail "a partition without a filesystem was mounted"
fi
grep -qx 'unmount -b /dev/sdf1 --no-user-interaction' "$UDISKS_LOG" ||
  fail "a partition mounted for another uid was not unmounted"
grep -qx 'mount -b /dev/sdf1 --no-user-interaction' "$UDISKS_LOG" ||
  fail "a partition mounted for another uid was not remounted"
grep -qx 'mount -b /dev/sdg1 --no-user-interaction' "$UDISKS_LOG" ||
  fail "a nested USB partition was not mounted"

export LSBLK_JSON='{"blockdevices":[]}'
: >"$UDISKS_LOG"
bash "$here"/ojuny-automount-present.sh || fail "the empty automount pass failed"
[ ! -s "$UDISKS_LOG" ] || fail "the empty automount pass mounted something"

home="$work/home"
theme_source="$work/theme"
mkdir -p "$home" "$theme_source"
printf '{"name":"Adwaita"}\n' >"$theme_source/skin.json"
HOME="$home" bash "$here"/ojuny-steam-theme.sh "$theme_source" Adwaita ||
  fail "the Steam theme install failed"
[ -L "$home/.local/share/Steam/millennium/themes/Adwaita" ] || fail "the Steam theme was not linked"
[ "$(readlink "$home/.local/share/Steam/millennium/themes/Adwaita")" = "$theme_source" ] ||
  fail "the Steam theme link points at the wrong path"
jq -e '.themes.activeTheme == "Adwaita"' "$home/.config/millennium/config.json" ||
  fail "the Steam theme was not selected"

printf '{"name":"millennium"}\n' >"$home/.config/millennium/config.json"
HOME="$home" bash "$here"/ojuny-steam-theme.sh "$theme_source" Adwaita ||
  fail "the Steam theme install without a themes key failed"
jq -e '.themes.activeTheme == "Adwaita"' "$home/.config/millennium/config.json" ||
  fail "the Steam theme was not selected without a themes key"

printf '{"themes":{"activeTheme":"default"}}\n' >"$home/.config/millennium/config.json"
HOME="$home" bash "$here"/ojuny-steam-theme.sh "$theme_source" Adwaita ||
  fail "the Steam theme install with the default value failed"
jq -e '.themes.activeTheme == "Adwaita"' "$home/.config/millennium/config.json" ||
  fail "the Steam theme did not replace the default value"

printf '{"themes":{"activeTheme":"Other"}}\n' >"$home/.config/millennium/config.json"
HOME="$home" bash "$here"/ojuny-steam-theme.sh "$theme_source" Adwaita ||
  fail "the second Steam theme install failed"
jq -e '.themes.activeTheme == "Other"' "$home/.config/millennium/config.json" ||
  fail "the Steam theme install overwrote an existing choice"

printf 'ok: middle click, display toggle, automount and Steam theme scripts\n'
