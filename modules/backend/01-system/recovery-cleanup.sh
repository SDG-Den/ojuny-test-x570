recovery_dir="${OJUNY_RECOVERY_DIR:?}"
manifest="${OJUNY_MANIFEST:?}"
sbctl_conf="${OJUNY_SBCTL_CONF:-/var/lib/ojuny/sbctl.conf}"

if command -v sbctl ; then
    if [ -f "$sbctl_conf" ]; then
        sbctl --config "$sbctl_conf" --disable-landlock remove-file "$recovery_dir/ojuny-recovery.efi"  || true
    else
        sbctl --disable-landlock remove-file "$recovery_dir/ojuny-recovery.efi"  || true
    fi
fi

if [ -d "$recovery_dir" ]; then
    rm -rf "$recovery_dir"
fi
if [ -f "$manifest" ]; then
    rm -f "$manifest"
fi

entry="$(efibootmgr -v  | awk '/^Boot[0-9A-Fa-f]{4}/ && /Ojuny Recovery/ { print substr($1, 5, 4); exit }')"
if [ -n "$entry" ]; then
    efibootmgr -b "$entry" -B  || true
fi

sync
