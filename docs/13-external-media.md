# 13 - External media

Copying to a USB drive must not require a manual `sync` before unplugging.
Two independent caches can hold data after `cp` returns:

1. The kernel page cache. `write(2)` returns when the data is in RAM. Dirty
   pages are written back later, normally within 30 seconds.
2. The drive's volatile write cache. The drive acknowledges a write before it
   has committed the data to the medium.

`sync` flushes both. Unmounting also flushes both. Removing the device without
either loses whatever is still cached.

## What ojuny does

`modules/07-system/10-mounts.nix` declares two switches, both on by default.

- **Synchronous writes on removable media** (`ojuny.mounts.syncWrites`) sets
  `sync` in the udisks mount options for USB filesystems through a udev
  override. Every mount through udisks, including devmon, gvfs and a direct
  `udisksctl mount`, passes the option. A file copy that returns from
  `write(2)` has been written and the device has acknowledged it.
- **Disable write cache on external drives** (`ojuny.mounts.disableWriteCache`)
  runs `hdparm -W0` on each USB disk when it appears. The drive acknowledges a
  write only after the data is on the medium, so the acknowledgement from the
  first switch becomes a media guarantee.

The switches are independent. Turning off the first restores asynchronous
mounts; turning off the second keeps the drive cache. Turning off both restores
the stock behaviour and the manual `sync` requirement.

## Guarantee

With both switches on, a copy to a USB filesystem that returns from `write(2)`
is on the medium, and the device can be unplugged without running `sync`.

## Limits

These are binding. Do not change the implementation to accept a shape listed
here as unsupported.

- Filesystems mounted from `/etc/fstab` are excluded from udisks mount option
  overrides. The switches apply to dynamic udisks mounts, which is what devmon
  and file browsers use for removable media.
- The sync mount option waits for the device to acknowledge the write. It does
  not force the device to commit. Only a device whose write cache was disabled
  by `hdparm -W0` gives the media guarantee.
- Devices that reject the ATA write-cache command keep their volatile cache.
  `hdparm -q -W0` fails quietly for those devices, and the mount stays
  synchronous. Data can still be lost from the device cache on a yank.
- The rule matches SCSI-style USB disks (`sd*`). Optical drives and internal
  drives are not matched.
- Mounts through `udevil` bypass udisks when `udevil` is setuid. NixOS does not
  make it setuid, so devmon uses `udisksctl` and the override applies.
- Unmount or eject remains the recommended removal path. It flushes, releases
  the mount and powers the device down cleanly.

## Checking a device

After mounting a USB filesystem:

```sh
findmnt -no FSTYPE,OPTIONS /run/media/$USER/LABEL
```

The options contain `sync`. For the drive cache:

```sh
hdparm -W /dev/sdX
```

The output reports write-caching off when the drive accepted the command.

## Opening disk images

`ojuny-mount-image` attaches an image read-only, waits for its partition nodes,
and mounts the first ISO9660 or UDF filesystem before falling back to another
filesystem. A hybrid image with an EFI partition therefore opens its ISO root,
not the EFI partition. If no partition node appears, the script falls back to
`gnome-disk-image-mounter --read-only`. The mount is opened in the file manager
or reported through a notification.
